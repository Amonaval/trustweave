-- TrustWeave Housing Society complaint contract full repair.
-- Consolidates the complaint-specific contracts originally introduced by HS-2 / HS-4.
-- Additive + idempotent: preserves existing complaint/vendor/comment/route data.

-- Fail early only for true platform prerequisites. Complaint-owned objects are repaired below.
do $$
begin
  if to_regclass('public.networks') is null then raise exception 'Prerequisite missing: public.networks'; end if;
  if to_regclass('public.network_entities') is null then raise exception 'Prerequisite missing: public.network_entities'; end if;
  if to_regclass('public.network_memberships') is null then raise exception 'Prerequisite missing: public.network_memberships'; end if;
  if to_regprocedure('public.hs2_assert_network()') is null then raise exception 'Prerequisite missing: public.hs2_assert_network()'; end if;
end $$;

-- -----------------------------------------------------------------------------
-- Complaint-owned tables. CREATE IF NOT EXISTS never drops existing data.
-- -----------------------------------------------------------------------------
create table if not exists public.hs_vendors(
 id uuid primary key default gen_random_uuid(),
 network_id uuid not null references public.networks(id) on delete cascade,
 name varchar(220) not null,
 category varchar(100) not null,
 contact_name varchar(160), phone varchar(60), email varchar(320),
 status varchar(20) not null default 'active',
 metadata jsonb not null default '{}'::jsonb,
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(network_id,name,category)
);

create table if not exists public.hs_complaints(
 id uuid primary key default gen_random_uuid(),
 network_id uuid not null references public.networks(id) on delete cascade,
 unit_entity_id uuid references public.network_entities(id) on delete set null,
 category varchar(100) not null,
 title varchar(220) not null,
 description text,
 attachments jsonb not null default '[]'::jsonb,
 priority varchar(20) not null default 'normal',
 status varchar(20) not null default 'open',
 assigned_to uuid references auth.users(id) on delete set null,
 assigned_vendor_id uuid references public.hs_vendors(id) on delete set null,
 sla_due_at timestamptz,
 resolution_note text,
 resolved_at timestamptz,
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

-- Repair partially-created / older live tables without replacing them.
alter table public.hs_complaints add column if not exists unit_entity_id uuid references public.network_entities(id) on delete set null;
alter table public.hs_complaints add column if not exists category varchar(100);
alter table public.hs_complaints add column if not exists title varchar(220);
alter table public.hs_complaints add column if not exists description text;
alter table public.hs_complaints add column if not exists attachments jsonb not null default '[]'::jsonb;
alter table public.hs_complaints add column if not exists priority varchar(20) not null default 'normal';
alter table public.hs_complaints add column if not exists status varchar(20) not null default 'open';
alter table public.hs_complaints add column if not exists assigned_to uuid references auth.users(id) on delete set null;
alter table public.hs_complaints add column if not exists assigned_vendor_id uuid references public.hs_vendors(id) on delete set null;
alter table public.hs_complaints add column if not exists sla_due_at timestamptz;
alter table public.hs_complaints add column if not exists resolution_note text;
alter table public.hs_complaints add column if not exists resolved_at timestamptz;
alter table public.hs_complaints add column if not exists created_by uuid references auth.users(id) on delete set null;
alter table public.hs_complaints add column if not exists created_at timestamptz not null default now();
alter table public.hs_complaints add column if not exists updated_at timestamptz not null default now();
update public.hs_complaints set attachments='[]'::jsonb where attachments is null;

create table if not exists public.hs_complaint_comments(
 id uuid primary key default gen_random_uuid(),
 network_id uuid not null references public.networks(id) on delete cascade,
 complaint_id uuid not null references public.hs_complaints(id) on delete cascade,
 body text not null,
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now()
);

create table if not exists public.hs_complaint_routes(
 network_id uuid not null references public.networks(id) on delete cascade,
 category_key varchar(80) not null,
 role_key varchar(60) not null,
 updated_by uuid references auth.users(id) on delete set null,
 updated_at timestamptz not null default now(),
 primary key(network_id,category_key)
);

create index if not exists idx_hs_complaints_network_status on public.hs_complaints(network_id,status,priority,created_at desc);
create index if not exists idx_hs_complaint_comments_complaint on public.hs_complaint_comments(network_id,complaint_id,created_at);

alter table public.hs_complaints enable row level security;
alter table public.hs_complaint_comments enable row level security;
alter table public.hs_complaint_routes enable row level security;
alter table public.hs_vendors enable row level security;

-- Direct writes remain RPC-only. Reads stay member/workflow scoped.
revoke all on public.hs_complaints, public.hs_complaint_comments, public.hs_complaint_routes, public.hs_vendors from anon,authenticated;

do $$ begin
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='hs_complaints' and policyname='hs_complaints_member_read') then
   create policy hs_complaints_member_read on public.hs_complaints for select
   using(public.is_network_member(network_id) and (created_by=auth.uid() or assigned_to=auth.uid() or public.is_network_admin(network_id)));
 end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='hs_complaint_comments' and policyname='hs_comments_member_read') then
   create policy hs_comments_member_read on public.hs_complaint_comments for select
   using(public.is_network_member(network_id) and exists(
     select 1 from public.hs_complaints c where c.id=complaint_id and c.network_id=network_id
       and (c.created_by=auth.uid() or c.assigned_to=auth.uid() or public.is_network_admin(c.network_id))));
 end if;
 if not exists(select 1 from pg_policies where schemaname='public' and tablename='hs_vendors' and policyname='hs_vendors_member_read') then
   create policy hs_vendors_member_read on public.hs_vendors for select using(public.is_network_member(network_id));
 end if;
end $$;

-- Engagement routing table is a complaint dependency for resolver assignment.
-- Recreate it if an older live schema skipped the E3 migration.
create table if not exists public.network_notification_roles(
 network_id uuid not null references public.networks(id) on delete cascade,
 role_key varchar(60) not null,
 user_id uuid not null references auth.users(id) on delete cascade,
 label varchar(100) not null,
 active boolean not null default true,
 set_by uuid references auth.users(id) on delete set null,
 updated_at timestamptz not null default now(),
 primary key(network_id,role_key,user_id)
);
create index if not exists idx_network_notification_roles_lookup on public.network_notification_roles(network_id,role_key,active);
alter table public.network_notification_roles enable row level security;
revoke all on public.network_notification_roles from anon,authenticated;

-- -----------------------------------------------------------------------------
-- HS-4 category + route contract.
-- -----------------------------------------------------------------------------
create or replace function public.hs4_category_key(p_category text) returns text
language sql immutable set search_path=public as $$
 select trim(both '-' from regexp_replace(lower(trim(coalesce(p_category,'other'))),'[^a-z0-9]+','-','g'));
$$;
revoke all on function public.hs4_category_key(text) from public;
grant execute on function public.hs4_category_key(text) to authenticated;

create or replace function public.hs4_get_complaint_routes()
returns table(category_key varchar,role_key varchar,role_label text,assignee_count bigint)
language sql security definer stable set search_path=public as $$
 select r.category_key,r.role_key,initcap(replace(r.role_key,'-',' '))::text,
        case when to_regclass('public.network_notification_roles') is null then 0::bigint else
          (select count(*) from public.network_notification_roles nr where nr.network_id=r.network_id and nr.role_key=r.role_key and nr.active)
        end
 from public.hs_complaint_routes r
 where r.network_id=public.hs2_assert_network()
 order by r.category_key;
$$;
revoke all on function public.hs4_get_complaint_routes() from public;
grant execute on function public.hs4_get_complaint_routes() to authenticated;

create or replace function public.hs4_set_complaint_route(p_category text,p_role_key text) returns void
language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.hs2_assert_network(); ckey text:=public.hs4_category_key(p_category); rkey text:=trim(both '-' from regexp_replace(lower(trim(p_role_key)),'[^a-z0-9]+','-','g'));
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if length(rkey)<2 then raise exception 'Responsibility role is required.' using errcode='22023'; end if;
 insert into public.hs_complaint_routes(network_id,category_key,role_key,updated_by,updated_at)
 values(nid,ckey,rkey,auth.uid(),now())
 on conflict(network_id,category_key) do update set role_key=excluded.role_key,updated_by=auth.uid(),updated_at=now();
end $$;
revoke all on function public.hs4_set_complaint_route(text,text) from public;
grant execute on function public.hs4_set_complaint_route(text,text) to authenticated;

insert into public.hs_complaint_routes(network_id,category_key,role_key)
select n.id,x.category_key,x.role_key
from public.networks n cross join (values
 ('common-area','complaint-resolver'),('lift','facilities'),('electrical','facilities'),('plumbing','facilities'),
 ('security','security'),('housekeeping','facilities'),('parking','complaint-resolver'),('other','complaint-resolver')
) x(category_key,role_key)
where n.vertical_kind='housing-society'
on conflict(network_id,category_key) do nothing;

-- -----------------------------------------------------------------------------
-- Complaint create/update/comment RPCs.
-- Notification routing is best-effort: complaint persistence must not fail solely
-- because optional engagement-role data is absent in a drifted live schema.
-- -----------------------------------------------------------------------------
drop function if exists public.hs4_create_complaint(uuid,text,text,text,text,text);
create function public.hs4_create_complaint(
 p_unit_entity_id uuid,
 p_category text,
 p_title text,
 p_description text default null,
 p_priority text default 'normal',
 p_photo_path text default null
) returns jsonb
language plpgsql security definer set search_path=public as $$
declare
 nid uuid:=public.hs2_assert_network(); rid uuid; resolved_unit uuid:=p_unit_entity_id; person_id uuid;
 ckey text; rkey text; assignee uuid; target uuid; notification_ids uuid[]:='{}'; notification_id uuid;
begin
 if length(trim(coalesce(p_title,'')))<2 then raise exception 'Complaint title is required.' using errcode='22023'; end if;
 if p_priority not in ('low','normal','high','urgent') then raise exception 'Invalid priority.' using errcode='22023'; end if;

 if resolved_unit is null and to_regclass('public.hs_unit_occupancy_history') is not null then
   select id into person_id from public.network_entities where network_id=nid and kind='person' and owner_user_id=auth.uid() order by updated_at desc limit 1;
   if person_id is not null then
     execute 'select unit_entity_id from public.hs_unit_occupancy_history where network_id=$1 and subject_entity_id=$2 and ends_on is null order by is_primary desc,starts_on desc limit 1'
       into resolved_unit using nid,person_id;
   end if;
 end if;

 if resolved_unit is not null and not exists(select 1 from public.network_entities where id=resolved_unit and network_id=nid and kind='unit') then
   raise exception 'Unit not found in this society.' using errcode='22023';
 end if;
 if nullif(trim(coalesce(p_photo_path,'')),'') is not null and p_photo_path not like nid::text||'/community/'||auth.uid()::text||'/%' then
   raise exception 'Complaint photo must be uploaded by the signed-in resident.' using errcode='42501';
 end if;

 ckey:=public.hs4_category_key(p_category);
 select role_key into rkey from public.hs_complaint_routes where network_id=nid and category_key=ckey;

 if to_regclass('public.network_notification_roles') is not null then
   execute 'select nr.user_id from public.network_notification_roles nr where nr.network_id=$1 and nr.active and nr.role_key=$2 order by nr.updated_at desc limit 1'
     into assignee using nid,coalesce(rkey,'complaint-resolver');
 end if;

 insert into public.hs_complaints(network_id,unit_entity_id,category,title,description,attachments,priority,assigned_to,created_by)
 values(nid,resolved_unit,coalesce(nullif(trim(p_category),''),'Other'),trim(p_title),nullif(trim(coalesce(p_description,'')),''),
   case when nullif(trim(coalesce(p_photo_path,'')),'') is null then '[]'::jsonb else jsonb_build_array(jsonb_build_object('kind','photo','path',trim(p_photo_path))) end,
   p_priority,assignee,auth.uid()) returning id into rid;

 -- Notifications are useful but must not roll back a valid complaint if engagement objects drift.
 begin
   if to_regclass('public.network_notification_roles') is not null and to_regprocedure('public.create_network_notification(uuid,uuid,text,text,text,text,text,uuid,text,jsonb,uuid)') is not null then
     for target in execute
       'select distinct x.user_id from ('||
       'select nr.user_id from public.network_notification_roles nr where nr.network_id=$1 and nr.active and nr.role_key=$2 '||
       'union all select nm.user_id from public.network_memberships nm where nm.network_id=$1 and nm.status=''active'' and nm.role in (''owner'',''admin'') and $3 is null) x'
       using nid,coalesce(rkey,'complaint-resolver'),assignee
     loop
       if target=auth.uid() then continue; end if;
       notification_id:=public.create_network_notification(nid,target,'complaint-created','New complaint · '||trim(p_title),nullif(trim(coalesce(p_description,'')),''),'complaints','hs_complaint',rid,case when p_priority in ('urgent','high') then p_priority else 'normal' end,jsonb_build_object('surface','complaints','category',p_category),auth.uid());
       notification_ids:=array_append(notification_ids,notification_id);
     end loop;
   end if;
 exception when others then
   -- Do not lose the complaint because notification routing is temporarily degraded.
   null;
 end;

 if to_regclass('public.audit_log') is not null then
   insert into public.audit_log(network_id,actor_id,action,details)
   values(nid,auth.uid(),'hs4_complaint_created',jsonb_build_object('complaint_id',rid,'priority',p_priority,'route',rkey,'assignee',assignee));
 end if;
 return jsonb_build_object('complaint_id',rid,'assigned_to',assignee,'notification_ids',notification_ids);
end $$;
revoke all on function public.hs4_create_complaint(uuid,text,text,text,text,text) from public;
grant execute on function public.hs4_create_complaint(uuid,text,text,text,text,text) to authenticated;

create or replace function public.hs4_update_complaint(
 p_complaint_id uuid,p_status text default null,p_assigned_to uuid default null,p_assigned_vendor_id uuid default null,
 p_sla_due_at timestamptz default null,p_resolution_note text default null
) returns uuid[]
language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.hs2_assert_network(); oldrow public.hs_complaints; notification_ids uuid[]:='{}'; newstatus text;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 select * into oldrow from public.hs_complaints where id=p_complaint_id and network_id=nid;
 if oldrow.id is null then raise exception 'Complaint not found.'; end if;
 if p_status is not null and p_status not in ('open','in_progress','resolved','closed','reopened') then raise exception 'Invalid complaint status.' using errcode='22023'; end if;
 if p_assigned_to is not null and not exists(select 1 from public.network_memberships nm where nm.network_id=nid and nm.user_id=p_assigned_to and nm.status='active') then raise exception 'Assignee must be an active society member.' using errcode='22023'; end if;
 if p_assigned_vendor_id is not null and not exists(select 1 from public.hs_vendors where id=p_assigned_vendor_id and network_id=nid) then raise exception 'Vendor not found.'; end if;
 newstatus:=coalesce(p_status,oldrow.status);
 update public.hs_complaints set status=newstatus,assigned_to=coalesce(p_assigned_to,assigned_to),assigned_vendor_id=coalesce(p_assigned_vendor_id,assigned_vendor_id),sla_due_at=coalesce(p_sla_due_at,sla_due_at),resolution_note=coalesce(nullif(trim(coalesce(p_resolution_note,'')),''),resolution_note),resolved_at=case when newstatus in ('resolved','closed') then coalesce(resolved_at,now()) when p_status='reopened' then null else resolved_at end,updated_at=now() where id=p_complaint_id and network_id=nid;
 return notification_ids;
end $$;
revoke all on function public.hs4_update_complaint(uuid,text,uuid,uuid,timestamptz,text) from public;
grant execute on function public.hs4_update_complaint(uuid,text,uuid,uuid,timestamptz,text) to authenticated;

create or replace function public.hs4_add_complaint_comment(p_complaint_id uuid,p_body text) returns jsonb
language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.hs2_assert_network(); c public.hs_complaints; rid uuid;
begin
 select * into c from public.hs_complaints where id=p_complaint_id and network_id=nid;
 if c.id is null then raise exception 'Complaint not found.'; end if;
 if not public.is_network_admin(nid) and c.created_by is distinct from auth.uid() and c.assigned_to is distinct from auth.uid() then raise exception 'You are not part of this complaint workflow.' using errcode='42501'; end if;
 if length(trim(coalesce(p_body,'')))<2 then raise exception 'Comment is required.'; end if;
 insert into public.hs_complaint_comments(network_id,complaint_id,body,created_by) values(nid,p_complaint_id,trim(p_body),auth.uid()) returning id into rid;
 return jsonb_build_object('comment_id',rid,'notification_ids','[]'::jsonb);
end $$;
revoke all on function public.hs4_add_complaint_comment(uuid,text) from public;
grant execute on function public.hs4_add_complaint_comment(uuid,text) to authenticated;

-- Complaint-focused snapshot expected by the Housing UI. Keep the broader key shape.
create or replace function public.hs4_get_operations_snapshot() returns jsonb
language plpgsql security definer stable set search_path=public as $$
declare nid uuid:=public.hs2_assert_network(); isadm boolean:=public.is_network_admin(nid);
begin
 return jsonb_build_object(
  'notices','[]'::jsonb,
  'complaints',coalesce((select jsonb_agg(jsonb_build_object(
    'id',c.id,'unitEntityId',c.unit_entity_id,'unitLabel',u.label,'category',c.category,'title',c.title,'description',c.description,
    'attachments',c.attachments,'priority',c.priority,'status',c.status,'slaDueAt',c.sla_due_at,'assignedTo',c.assigned_to,
    'assignedToLabel',coalesce(ae.label,au.email),'assignedVendorId',c.assigned_vendor_id,'resolutionNote',c.resolution_note,
    'createdAt',c.created_at,'updatedAt',c.updated_at,'createdBy',c.created_by,
    'comments',coalesce((select jsonb_agg(jsonb_build_object('id',cc.id,'body',cc.body,'createdAt',cc.created_at,'authorLabel',coalesce(ne.label,cu.email,'Member')) order by cc.created_at)
      from public.hs_complaint_comments cc left join auth.users cu on cu.id=cc.created_by left join public.network_entities ne on ne.network_id=nid and ne.owner_user_id=cc.created_by where cc.complaint_id=c.id),'[]'::jsonb)
   ) order by c.created_at desc)
   from public.hs_complaints c left join public.network_entities u on u.id=c.unit_entity_id and u.network_id=nid
   left join auth.users au on au.id=c.assigned_to left join public.network_entities ae on ae.network_id=nid and ae.owner_user_id=c.assigned_to
   where c.network_id=nid and (isadm or c.created_by=auth.uid() or c.assigned_to=auth.uid())),'[]'::jsonb),
  'vendors',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'name',v.name,'category',v.category,'contactName',v.contact_name,'phone',case when isadm then v.phone else null end,'email',case when isadm then v.email else null end,'status',v.status) order by v.name) from public.hs_vendors v where v.network_id=nid and (isadm or v.status='active')),'[]'::jsonb),
  'amenities','[]'::jsonb,
  'bookings','[]'::jsonb
 );
end $$;
revoke all on function public.hs4_get_operations_snapshot() from public;
grant execute on function public.hs4_get_operations_snapshot() to authenticated;

-- Re-enable Housing media defaults for complaint photo flow.
update public.networks set photo_upload_enabled=true,photo_max_bytes=greatest(coalesce(photo_max_bytes,0),262144),updated_at=now()
where vertical_kind='housing-society';

-- Explicit live-contract assertions. If this migration succeeds, these objects exist.
do $$
begin
 if to_regclass('public.hs_complaints') is null then raise exception 'Repair failed: hs_complaints missing'; end if;
 if to_regclass('public.hs_complaint_comments') is null then raise exception 'Repair failed: hs_complaint_comments missing'; end if;
 if to_regclass('public.hs_complaint_routes') is null then raise exception 'Repair failed: hs_complaint_routes missing'; end if;
 if to_regprocedure('public.hs4_category_key(text)') is null then raise exception 'Repair failed: hs4_category_key missing'; end if;
 if to_regprocedure('public.hs4_get_complaint_routes()') is null then raise exception 'Repair failed: hs4_get_complaint_routes missing'; end if;
 if to_regprocedure('public.hs4_create_complaint(uuid,text,text,text,text,text)') is null then raise exception 'Repair failed: hs4_create_complaint missing'; end if;
 if to_regprocedure('public.hs4_update_complaint(uuid,text,uuid,uuid,timestamptz,text)') is null then raise exception 'Repair failed: hs4_update_complaint missing'; end if;
 if to_regprocedure('public.hs4_add_complaint_comment(uuid,text)') is null then raise exception 'Repair failed: hs4_add_complaint_comment missing'; end if;
end $$;

notify pgrst,'reload schema';
