-- FINAL LAUNCH — explicit network-scoped authorization + idempotent lineage for synthetic launch datasets.
-- This migration intentionally does NOT provide arbitrary table-write or destructive reset RPCs.

create table if not exists public.launch_demo_seed_authorizations(
  network_id uuid not null references public.networks(id) on delete cascade,
  dataset_version varchar(120) not null,
  synthetic boolean not null default true check(synthetic),
  allow_real_network boolean not null default false,
  confirmed_network_name text not null,
  authorized_by uuid not null references auth.users(id) on delete cascade,
  authorized_at timestamptz not null default now(),
  primary key(network_id,dataset_version)
);

create table if not exists public.launch_demo_seed_lineage(
  network_id uuid not null references public.networks(id) on delete cascade,
  dataset_version varchar(120) not null,
  section_key varchar(120) not null,
  row_ref varchar(160) not null,
  payload_hash varchar(80) not null,
  remote_id text,
  status varchar(20) not null default 'committed' check(status in ('committed','skipped','warning')),
  last_message text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(network_id,dataset_version,section_key,row_ref),
  foreign key(network_id,dataset_version) references public.launch_demo_seed_authorizations(network_id,dataset_version) on delete cascade
);
create index if not exists launch_demo_seed_lineage_network_idx on public.launch_demo_seed_lineage(network_id,dataset_version,section_key);

alter table public.launch_demo_seed_authorizations enable row level security;
alter table public.launch_demo_seed_lineage enable row level security;
revoke all on public.launch_demo_seed_authorizations,public.launch_demo_seed_lineage from anon,authenticated;

create or replace function public.authorize_launch_demo_seed(
  p_dataset_version text,
  p_confirm_network_name text,
  p_allow_real_network boolean default false
) returns jsonb
language plpgsql security definer set search_path=public as $$
declare
  nid uuid:=public.current_network_id();
  nname text;
  nkind text;
  demo_like boolean;
begin
  if nid is null then raise exception 'Select a network before seeding.' using errcode='22023'; end if;
  if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
  select n.name,n.vertical_kind into nname,nkind from public.networks n where n.id=nid;
  if nname is null then raise exception 'Active network not found.' using errcode='22023'; end if;
  if trim(coalesce(p_confirm_network_name,''))<>nname then raise exception 'Network name confirmation does not match.' using errcode='22023'; end if;
  if nkind='housing-society' and coalesce(p_dataset_version,'') not like 'trustweave-launch-residential.%' then raise exception 'Residential launch dataset required for this network.' using errcode='22023'; end if;
  if nkind='family-association' and coalesce(p_dataset_version,'') not like 'trustweave-launch-family-community.%' then raise exception 'Family Community launch dataset required for this network.' using errcode='22023'; end if;
  if nkind not in ('housing-society','family-association') then raise exception 'Launch Demo Data Loader is limited to Residential and Family Community networks.' using errcode='22023'; end if;
  demo_like:=lower(nname) ~ '(demo|pilot|sample|sandbox|test)';
  if not demo_like and not coalesce(p_allow_real_network,false) then
    raise exception 'This network does not look like a demo/pilot network. Explicitly allow seeding a real network to continue.' using errcode='22023';
  end if;
  insert into public.launch_demo_seed_authorizations(network_id,dataset_version,synthetic,allow_real_network,confirmed_network_name,authorized_by,authorized_at)
  values(nid,trim(p_dataset_version),true,coalesce(p_allow_real_network,false),nname,auth.uid(),now())
  on conflict(network_id,dataset_version) do update set synthetic=true,allow_real_network=excluded.allow_real_network,confirmed_network_name=excluded.confirmed_network_name,authorized_by=auth.uid(),authorized_at=now();
  insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'launch_demo_seed_authorized',jsonb_build_object('dataset_version',p_dataset_version,'allow_real_network',coalesce(p_allow_real_network,false)));
  return jsonb_build_object('network_id',nid,'network_name',nname,'vertical_kind',nkind,'dataset_version',p_dataset_version,'authorized',true,'allow_real_network',coalesce(p_allow_real_network,false));
end $$;
revoke all on function public.authorize_launch_demo_seed(text,text,boolean) from public;
grant execute on function public.authorize_launch_demo_seed(text,text,boolean) to authenticated;

create or replace function public.get_launch_demo_seed_context(p_dataset_version text) returns jsonb
language plpgsql security definer stable set search_path=public as $$
declare nid uuid:=public.current_network_id();nname text;nkind text;authz boolean:=false;allow_real boolean:=false;
begin
 if nid is null then return jsonb_build_object('authorized',false); end if;
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 select name,vertical_kind into nname,nkind from public.networks where id=nid;
 select true,a.allow_real_network into authz,allow_real from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version;
 return jsonb_build_object('network_id',nid,'network_name',nname,'vertical_kind',nkind,'dataset_version',p_dataset_version,'authorized',coalesce(authz,false),'allow_real_network',coalesce(allow_real,false),'is_platform_owner',public.is_platform_owner(),'is_admin',public.is_network_admin(nid));
end $$;
revoke all on function public.get_launch_demo_seed_context(text) from public;
grant execute on function public.get_launch_demo_seed_context(text) to authenticated;

create or replace function public.get_launch_demo_seed_lineage(p_dataset_version text)
returns table(section_key text,row_ref text,payload_hash text,remote_id text,status text,last_message text,updated_at timestamptz)
language plpgsql security definer stable set search_path=public as $$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Launch dataset is not authorized for this network.' using errcode='42501'; end if;
 return query select l.section_key::text,l.row_ref::text,l.payload_hash::text,l.remote_id,l.status::text,l.last_message,l.updated_at from public.launch_demo_seed_lineage l where l.network_id=nid and l.dataset_version=p_dataset_version order by l.section_key,l.row_ref;
end $$;
revoke all on function public.get_launch_demo_seed_lineage(text) from public;
grant execute on function public.get_launch_demo_seed_lineage(text) to authenticated;

create or replace function public.record_launch_demo_seed_lineage(
  p_dataset_version text,p_section_key text,p_row_ref text,p_payload_hash text,p_remote_id text,p_status text default 'committed',p_message text default null
) returns void
language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Launch dataset is not authorized for this network.' using errcode='42501'; end if;
 if trim(coalesce(p_section_key,''))='' or trim(coalesce(p_row_ref,''))='' or trim(coalesce(p_payload_hash,''))='' then raise exception 'Seed lineage requires section, row reference and payload hash.' using errcode='22023'; end if;
 if coalesce(p_status,'committed') not in ('committed','skipped','warning') then raise exception 'Invalid seed lineage status.' using errcode='22023'; end if;
 insert into public.launch_demo_seed_lineage(network_id,dataset_version,section_key,row_ref,payload_hash,remote_id,status,last_message,created_by)
 values(nid,p_dataset_version,trim(p_section_key),trim(p_row_ref),trim(p_payload_hash),nullif(trim(coalesce(p_remote_id,'')),''),coalesce(p_status,'committed'),nullif(trim(coalesce(p_message,'')),''),auth.uid())
 on conflict(network_id,dataset_version,section_key,row_ref) do update set payload_hash=excluded.payload_hash,remote_id=coalesce(excluded.remote_id,public.launch_demo_seed_lineage.remote_id),status=excluded.status,last_message=excluded.last_message,updated_at=now();
end $$;
revoke all on function public.record_launch_demo_seed_lineage(text,text,text,text,text,text,text) from public;
grant execute on function public.record_launch_demo_seed_lineage(text,text,text,text,text,text,text) to authenticated;

comment on table public.launch_demo_seed_lineage is 'Launch-only idempotency lineage. Stable workbook references map to real network-scoped records; direct table access is closed.';
comment on function public.authorize_launch_demo_seed(text,text,boolean) is 'Explicitly authorizes one synthetic launch dataset for the active Residential or Family Community network after exact-name confirmation.';

do $$ begin
 if to_regclass('public.launch_demo_seed_lineage') is null then raise exception 'Final launch seed compatibility check failed: lineage table missing.'; end if;
 if not exists(select 1 from pg_proc where proname='authorize_launch_demo_seed') then raise exception 'Final launch seed compatibility check failed: authorization RPC missing.'; end if;
end $$;

-- Narrow supplemental adapter for dataset-defined Family Community committee roles.
-- It remains inaccessible unless the active network has explicitly authorized the synthetic launch dataset.
create or replace function public.launch_demo_upsert_fca_role_catalog(
 p_dataset_version text,p_role_key text,p_label text,p_role_type text,p_portfolio text default null
) returns uuid
language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id();rid uuid;
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501';end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a join public.networks n on n.id=a.network_id where a.network_id=nid and a.dataset_version=p_dataset_version and n.vertical_kind='family-association') then raise exception 'Authorized Family Community launch dataset required.' using errcode='42501';end if;
 if p_role_type not in ('office_bearer','director','chairperson','committee','volunteer','mentor','other') then raise exception 'Invalid Family Community role type.' using errcode='22023';end if;
 insert into public.family_association_role_catalog(network_id,role_key,label,role_type,portfolio,active,sort_order)
 values(nid,trim(p_role_key),trim(p_label),p_role_type,nullif(trim(coalesce(p_portfolio,'')),''),true,100)
 on conflict(network_id,role_key) do update set label=excluded.label,role_type=excluded.role_type,portfolio=excluded.portfolio,active=true
 returning id into rid;
 return rid;
end $$;
revoke all on function public.launch_demo_upsert_fca_role_catalog(text,text,text,text,text) from public;
grant execute on function public.launch_demo_upsert_fca_role_catalog(text,text,text,text,text) to authenticated;
