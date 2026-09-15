-- Mission 1 — Runtime defect + launch seed integrity closure.
-- Additive repair only: preserves normal product authorization while making launch seeding
-- observable, restart-safe and independent of interactive HTTP burst limits.

-- -----------------------------------------------------------------------------
-- 1) Launch seed lineage may represent recoverable work, not only terminal rows.
-- -----------------------------------------------------------------------------
alter table public.launch_demo_seed_lineage
  drop constraint if exists launch_demo_seed_lineage_status_check;
alter table public.launch_demo_seed_lineage
  add constraint launch_demo_seed_lineage_status_check
  check(status in ('committed','skipped','warning','partial','error'));

create or replace function public.record_launch_demo_seed_lineage(
  p_dataset_version text,p_section_key text,p_row_ref text,p_payload_hash text,p_remote_id text,p_status text default 'committed',p_message text default null
) returns void
language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Launch dataset is not authorized for this network.' using errcode='42501'; end if;
 if trim(coalesce(p_section_key,''))='' or trim(coalesce(p_row_ref,''))='' or trim(coalesce(p_payload_hash,''))='' then raise exception 'Seed lineage requires section, row reference and payload hash.' using errcode='22023'; end if;
 if coalesce(p_status,'committed') not in ('committed','skipped','warning','partial','error') then raise exception 'Invalid seed lineage status.' using errcode='22023'; end if;
 insert into public.launch_demo_seed_lineage(network_id,dataset_version,section_key,row_ref,payload_hash,remote_id,status,last_message,created_by)
 values(nid,p_dataset_version,trim(p_section_key),trim(p_row_ref),trim(p_payload_hash),nullif(trim(coalesce(p_remote_id,'')),''),coalesce(p_status,'committed'),nullif(trim(coalesce(p_message,'')),''),auth.uid())
 on conflict(network_id,dataset_version,section_key,row_ref) do update set
   payload_hash=excluded.payload_hash,
   remote_id=coalesce(excluded.remote_id,public.launch_demo_seed_lineage.remote_id),
   status=excluded.status,last_message=excluded.last_message,updated_at=now();
end $$;
revoke all on function public.record_launch_demo_seed_lineage(text,text,text,text,text,text,text) from public;
grant execute on function public.record_launch_demo_seed_lineage(text,text,text,text,text,text,text) to authenticated;

-- -----------------------------------------------------------------------------
-- 2) Persistent launch-seed run + row diagnostics.
-- -----------------------------------------------------------------------------
create table if not exists public.launch_demo_seed_runs(
  id uuid primary key default gen_random_uuid(),
  network_id uuid not null references public.networks(id) on delete cascade,
  dataset_version varchar(120) not null,
  vertical_kind varchar(50) not null,
  status varchar(30) not null default 'running' check(status in ('running','completed','completed_with_errors','failed')),
  total_rows integer not null default 0 check(total_rows>=0),
  created_count integer not null default 0 check(created_count>=0),
  updated_count integer not null default 0 check(updated_count>=0),
  skipped_count integer not null default 0 check(skipped_count>=0),
  error_count integer not null default 0 check(error_count>=0),
  warning_count integer not null default 0 check(warning_count>=0),
  created_by uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists launch_demo_seed_runs_network_idx on public.launch_demo_seed_runs(network_id,started_at desc);

create table if not exists public.launch_demo_seed_issues(
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.launch_demo_seed_runs(id) on delete cascade,
  network_id uuid not null references public.networks(id) on delete cascade,
  dataset_version varchar(120) not null,
  severity varchar(12) not null check(severity in ('error','warning')),
  section_key varchar(140) not null,
  row_ref varchar(180) not null,
  operation varchar(120) not null,
  error_code varchar(60),
  message text not null,
  details text,
  hint text,
  retryable boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists launch_demo_seed_issues_run_idx on public.launch_demo_seed_issues(run_id,severity,section_key,row_ref);

alter table public.launch_demo_seed_runs enable row level security;
alter table public.launch_demo_seed_issues enable row level security;
revoke all on public.launch_demo_seed_runs,public.launch_demo_seed_issues from anon,authenticated;

create or replace function public.start_launch_demo_seed_run(p_dataset_version text,p_vertical_kind text,p_total_rows integer)
returns uuid language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id(); rid uuid; actual_kind text;
begin
 if nid is null or (not public.is_network_admin(nid) and not public.is_platform_owner()) then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Launch dataset is not authorized for this network.' using errcode='42501'; end if;
 select vertical_kind into actual_kind from public.networks where id=nid;
 if actual_kind is distinct from p_vertical_kind then raise exception 'Launch seed vertical does not match the active network.' using errcode='22023'; end if;
 insert into public.launch_demo_seed_runs(network_id,dataset_version,vertical_kind,total_rows,created_by)
 values(nid,p_dataset_version,p_vertical_kind,greatest(coalesce(p_total_rows,0),0),auth.uid()) returning id into rid;
 return rid;
end $$;
revoke all on function public.start_launch_demo_seed_run(text,text,integer) from public;
grant execute on function public.start_launch_demo_seed_run(text,text,integer) to authenticated;

create or replace function public.record_launch_demo_seed_issue(
 p_run_id uuid,p_severity text,p_section_key text,p_row_ref text,p_operation text,p_error_code text default null,
 p_message text default '',p_details text default null,p_hint text default null,p_retryable boolean default false
) returns void language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id(); r public.launch_demo_seed_runs%rowtype;
begin
 select * into r from public.launch_demo_seed_runs where id=p_run_id and network_id=nid;
 if not found or (not public.is_network_admin(nid) and not public.is_platform_owner()) then raise exception 'Seed run is not available in the active network.' using errcode='42501'; end if;
 if r.status<>'running' then raise exception 'Seed run is already complete.' using errcode='22023'; end if;
 if p_severity not in ('error','warning') then raise exception 'Invalid seed issue severity.' using errcode='22023'; end if;
 insert into public.launch_demo_seed_issues(run_id,network_id,dataset_version,severity,section_key,row_ref,operation,error_code,message,details,hint,retryable)
 values(r.id,nid,r.dataset_version,p_severity,left(coalesce(nullif(trim(p_section_key),''),'unknown'),140),left(coalesce(nullif(trim(p_row_ref),''),'unknown'),180),left(coalesce(nullif(trim(p_operation),''),'seed-row'),120),nullif(left(trim(coalesce(p_error_code,'')),60),''),coalesce(nullif(trim(p_message),''),'Unknown seed issue'),nullif(p_details,''),nullif(p_hint,''),coalesce(p_retryable,false));
end $$;
revoke all on function public.record_launch_demo_seed_issue(uuid,text,text,text,text,text,text,text,text,boolean) from public;
grant execute on function public.record_launch_demo_seed_issue(uuid,text,text,text,text,text,text,text,text,boolean) to authenticated;

create or replace function public.finish_launch_demo_seed_run(
 p_run_id uuid,p_status text,p_created integer,p_updated integer,p_skipped integer,p_errors integer,p_warnings integer
) returns void language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id();
begin
 if p_status not in ('completed','completed_with_errors','failed') then raise exception 'Invalid seed run status.' using errcode='22023'; end if;
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 update public.launch_demo_seed_runs set status=p_status,created_count=greatest(coalesce(p_created,0),0),updated_count=greatest(coalesce(p_updated,0),0),skipped_count=greatest(coalesce(p_skipped,0),0),error_count=greatest(coalesce(p_errors,0),0),warning_count=greatest(coalesce(p_warnings,0),0),completed_at=now()
 where id=p_run_id and network_id=nid and status='running';
 if not found then raise exception 'Running seed run was not found in the active network.' using errcode='42501'; end if;
end $$;
revoke all on function public.finish_launch_demo_seed_run(uuid,text,integer,integer,integer,integer,integer) from public;
grant execute on function public.finish_launch_demo_seed_run(uuid,text,integer,integer,integer,integer,integer) to authenticated;

create or replace function public.get_launch_demo_seed_run_report(p_run_id uuid)
returns jsonb language plpgsql security definer stable set search_path=public as $$
declare nid uuid:=public.current_network_id(); r public.launch_demo_seed_runs%rowtype;
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 select * into r from public.launch_demo_seed_runs where id=p_run_id and network_id=nid;
 if not found then raise exception 'Seed run was not found in the active network.' using errcode='42501'; end if;
 return jsonb_build_object(
  'run',jsonb_build_object('id',r.id,'network_id',r.network_id,'dataset_version',r.dataset_version,'vertical_kind',r.vertical_kind,'status',r.status,'total_rows',r.total_rows,'created',r.created_count,'updated',r.updated_count,'skipped',r.skipped_count,'errors',r.error_count,'warnings',r.warning_count,'started_at',r.started_at,'completed_at',r.completed_at),
  'issues',coalesce((select jsonb_agg(jsonb_build_object('severity',i.severity,'section',i.section_key,'row_ref',i.row_ref,'operation',i.operation,'code',i.error_code,'message',i.message,'details',i.details,'hint',i.hint,'retryable',i.retryable,'created_at',i.created_at) order by i.created_at,i.section_key,i.row_ref) from public.launch_demo_seed_issues i where i.run_id=r.id),'[]'::jsonb)
 );
end $$;
revoke all on function public.get_launch_demo_seed_run_report(uuid) from public;
grant execute on function public.get_launch_demo_seed_run_report(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 3) Seed-only adapters use the real domain RPCs, but avoid interactive HTTP
--    burst limits and can make a family-representative demo poll usable without
--    manufacturing fake auth accounts.
-- -----------------------------------------------------------------------------
create or replace function public.launch_demo_create_relationship(
 p_dataset_version text,p_from_entity_id uuid,p_to_entity_id uuid,p_relationship_type text,p_metadata jsonb default '{}'::jsonb
) returns uuid language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Authorized launch dataset required.' using errcode='42501'; end if;
 return public.create_productized_network_relationship(p_from_entity_id,p_to_entity_id,p_relationship_type,coalesce(p_metadata,'{}'::jsonb));
end $$;
revoke all on function public.launch_demo_create_relationship(text,uuid,uuid,text,jsonb) from public;
grant execute on function public.launch_demo_create_relationship(text,uuid,uuid,text,jsonb) to authenticated;

create or replace function public.launch_demo_open_ballot(p_dataset_version text,p_ballot_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id(); cnt integer; b public.network_ballots%rowtype;
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Authorized launch dataset required.' using errcode='42501'; end if;
 begin
   return public.open_network_ballot(p_ballot_id);
 exception when others then
   if sqlstate<>'P0001' or sqlerrm not like 'No eligible voters were found%' then raise; end if;
 end;
 select * into b from public.network_ballots where id=p_ballot_id and network_id=nid and status='draft';
 if not found then raise exception 'Draft ballot not found.'; end if;
 if b.eligibility_mode<>'family_representatives' then raise exception 'No eligible voters were found for this ballot.'; end if;
 if (select count(*) from public.network_ballot_options o where o.ballot_id=b.id)<2 then raise exception 'Add at least two choices before opening voting.'; end if;
 insert into public.network_ballot_eligibility(network_id,ballot_id,user_id,source)
 values(nid,b.id,auth.uid(),'launch_demo_seed_operator') on conflict do nothing;
 select count(*) into cnt from public.network_ballot_eligibility where ballot_id=b.id;
 update public.network_ballots set status='open',opens_at=now(),updated_at=now() where id=b.id;
 perform public.create_network_notification(nid,auth.uid(),'ballot_opened',case when b.ballot_type='election' then 'Election voting is open' else 'New poll is open' end,b.title,'elections','ballot',b.id,'high',jsonb_build_object('ballot_type',b.ballot_type,'launch_demo_fallback',true),auth.uid());
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'launch_demo_ballot_opened',jsonb_build_object('ballot_id',b.id,'eligible_voters',cnt,'fallback','seed_operator'));
 return cnt;
end $$;
revoke all on function public.launch_demo_open_ballot(text,uuid) from public;
grant execute on function public.launch_demo_open_ballot(text,uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 4) Storage 22023 repair: Storage metadata keys vary by storage-api version.
--    Keep membership/path/quota enforcement, but do not reject a valid upload
--    merely because BEFORE-trigger metadata did not expose one exact key.
-- -----------------------------------------------------------------------------
create or replace function public.storage_object_metadata_bytes(p_metadata jsonb) returns bigint
language plpgsql immutable as $$
declare v text;
begin
 v:=coalesce(p_metadata->>'size',p_metadata->>'contentLength',p_metadata->>'content_length',p_metadata->>'content-length','');
 if v ~ '^\s*[0-9]+\s*$' then return trim(v)::bigint; end if;
 return 0;
end $$;
revoke all on function public.storage_object_metadata_bytes(jsonb) from public;
grant execute on function public.storage_object_metadata_bytes(jsonb) to authenticated;

create or replace function public.a5_storage_guard() returns trigger
language plpgsql security definer set search_path=public,storage as $$
declare nid uuid;bytes bigint;old_bytes bigint:=0;lim bigint;max_file integer;current_usage bigint;mime text;
begin
 if new.bucket_id not in ('profile-photos','community-media') then return new; end if;
 nid:=public.storage_path_network_id(new.name);
 if nid is null then raise exception 'Network media path must begin with the network id.' using errcode='22023'; end if;
 if not public.is_network_member(nid) then raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501'; end if;
 bytes:=public.storage_object_metadata_bytes(new.metadata);
 mime:=lower(coalesce(new.metadata->>'mimetype',new.metadata->>'contentType',new.metadata->>'content_type',''));
 if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023'; end if;
 select storage_limit_bytes,photo_max_bytes,media_usage_bytes into lim,max_file,current_usage from public.networks where id=nid for update;
 if lim is null then raise exception 'Network was not found.' using errcode='P0002'; end if;
 current_usage:=greatest(coalesce(current_usage,0),coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid),0));
 -- A Storage BEFORE trigger does not have a stable byte-size metadata contract across storage-api releases.
 -- Enforce here when size is known; register_network_media_asset re-checks the concrete client/object size.
 if bytes>0 and bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
 if tg_op='UPDATE' then old_bytes:=public.storage_object_metadata_bytes(old.metadata); end if;
 if bytes>0 and current_usage-old_bytes+bytes>lim then raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023'; end if;
 return new;
end $$;

create or replace function public.a5_storage_account() returns trigger
language plpgsql security definer set search_path=public,storage as $$
declare nid uuid;delta bigint;
begin
 if tg_op='INSERT' then
   if new.bucket_id not in ('profile-photos','community-media') then return new; end if;
   nid:=public.storage_path_network_id(new.name);if nid is null then return new;end if;
   delta:=public.storage_object_metadata_bytes(new.metadata);
   update public.networks set media_usage_bytes=media_usage_bytes+greatest(delta,0),updated_at=now() where id=nid;return new;
 elsif tg_op='DELETE' then
   if old.bucket_id not in ('profile-photos','community-media') then return old; end if;
   nid:=public.storage_path_network_id(old.name);if nid is null then return old;end if;
   delta:=public.storage_object_metadata_bytes(old.metadata);
   update public.networks set media_usage_bytes=greatest(0,media_usage_bytes-greatest(delta,0)),updated_at=now() where id=nid;return old;
 else
   if new.bucket_id not in ('profile-photos','community-media') then return new; end if;
   nid:=public.storage_path_network_id(new.name);if nid is null then return new;end if;
   delta:=public.storage_object_metadata_bytes(new.metadata)-public.storage_object_metadata_bytes(old.metadata);
   update public.networks set media_usage_bytes=greatest(0,media_usage_bytes+delta),updated_at=now() where id=nid;return new;
 end if;
end $$;

create or replace function public.register_network_media_asset(
  p_bucket text,p_object_path text,p_thumbnail_path text default null,p_media_kind text default 'other',p_entity_type text default null,p_entity_id text default null,
  p_mime_type text default 'image/webp',p_bytes bigint default 0,p_thumbnail_bytes bigint default 0,p_width integer default null,p_height integer default null
) returns uuid
language plpgsql security definer set search_path=public,storage as $$
declare nid uuid:=public.storage_path_network_id(p_object_path);rid uuid;expected_scope text;max_file integer;lim bigint;usage bigint;object_bytes bigint;thumb_bytes bigint;
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required for the media path.' using errcode='42501'; end if;
 if p_bucket not in ('profile-photos','community-media') then raise exception 'Unsupported media bucket.' using errcode='22023'; end if;
 if p_media_kind not in ('profile','memory','event','announcement','complaint','post','other') then raise exception 'Unsupported media kind.' using errcode='22023'; end if;
 expected_scope:=case when p_bucket='profile-photos' then 'profiles' else 'community' end;
 if coalesce(p_object_path,'') not like nid::text||'/'||expected_scope||'/'||auth.uid()::text||'/%' then raise exception 'Media path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 if nullif(p_thumbnail_path,'') is not null and p_thumbnail_path not like nid::text||'/'||expected_scope||'/'||auth.uid()::text||'/%' then raise exception 'Thumbnail path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 select photo_max_bytes,storage_limit_bytes,media_usage_bytes into max_file,lim,usage from public.networks where id=nid;
 select public.storage_object_metadata_bytes(o.metadata) into object_bytes from storage.objects o where o.bucket_id=p_bucket and o.name=p_object_path;
 if not found then raise exception 'Uploaded media object was not found.' using errcode='P0002'; end if;
 if nullif(p_thumbnail_path,'') is not null then select public.storage_object_metadata_bytes(o.metadata) into thumb_bytes from storage.objects o where o.bucket_id=p_bucket and o.name=p_thumbnail_path; end if;
 object_bytes:=greatest(coalesce(nullif(object_bytes,0),p_bytes,0),0);thumb_bytes:=greatest(coalesce(nullif(thumb_bytes,0),p_thumbnail_bytes,0),0);
 if object_bytes<=0 then raise exception 'Uploaded image size could not be verified after upload.' using errcode='22023'; end if;
 if object_bytes>max_file or thumb_bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
 -- When storage metadata was unavailable to the accounting trigger, the registry still records concrete bytes.
 -- Do not double-add to media_usage_bytes here; the quota check uses registry + legacy counter as a conservative ceiling.
 if coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid and not (m.bucket=p_bucket and m.object_path=p_object_path)),0)+object_bytes+thumb_bytes>lim then
   raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023';
 end if;
 insert into public.network_media_assets(network_id,owner_user_id,bucket,object_path,thumbnail_path,media_kind,entity_type,entity_id,mime_type,bytes,thumbnail_bytes,width,height)
 values(nid,auth.uid(),p_bucket,p_object_path,nullif(p_thumbnail_path,''),p_media_kind,nullif(trim(p_entity_type),''),nullif(trim(p_entity_id),''),coalesce(nullif(p_mime_type,''),'image/webp'),object_bytes,thumb_bytes,p_width,p_height)
 on conflict(bucket,object_path) do update set thumbnail_path=excluded.thumbnail_path,media_kind=excluded.media_kind,entity_type=coalesce(excluded.entity_type,network_media_assets.entity_type),entity_id=coalesce(excluded.entity_id,network_media_assets.entity_id),mime_type=excluded.mime_type,bytes=excluded.bytes,thumbnail_bytes=excluded.thumbnail_bytes,width=excluded.width,height=excluded.height,updated_at=now()
 returning id into rid;
 update public.networks n set media_usage_bytes=greatest(n.media_usage_bytes,coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid),0)),updated_at=now() where n.id=nid;
 return rid;
end $$;
revoke all on function public.register_network_media_asset(text,text,text,text,text,text,text,bigint,bigint,integer,integer) from public;
grant execute on function public.register_network_media_asset(text,text,text,text,text,text,text,bigint,bigint,integer,integer) to authenticated;

comment on table public.launch_demo_seed_runs is 'Persistent network-scoped launch seed executions used to diagnose and reproduce row-level failures.';
comment on table public.launch_demo_seed_issues is 'Structured launch seed warnings/errors: section + row + operation + database/API error context.';
comment on function public.launch_demo_create_relationship(text,uuid,uuid,text,jsonb) is 'Launch-only relationship adapter. Uses the normal secured domain RPC while avoiding browser command burst limits during authorized synthetic seeding.';

-- Static compatibility assertions and an immediate PostgREST schema refresh.
do $$ begin
 if to_regclass('public.launch_demo_seed_runs') is null or to_regclass('public.launch_demo_seed_issues') is null then raise exception 'Mission 1 seed diagnostics tables are missing.'; end if;
 if not exists(select 1 from pg_proc where proname='launch_demo_create_relationship') then raise exception 'Mission 1 relationship seed adapter is missing.'; end if;
 if not exists(select 1 from pg_proc where proname='launch_demo_open_ballot') then raise exception 'Mission 1 ballot seed adapter is missing.'; end if;
end $$;
notify pgrst, 'reload schema';
