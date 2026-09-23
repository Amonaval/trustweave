-- TrustWeave post-D12 bootstrap tail — current through migration 130.
-- Base prerequisite: supabase/bootstrap/CURRENT (2026-09-20-d12), which covers 001..123.
--
-- This is a CURRENT-STATE DELTA, not a replay of migrations 124..130:
--   * 124 activation evidence contracts are retained;
--   * 125 RSVP visibility is represented by the later/final 126 implementation;
--   * 126 shared Community Object lifecycle is retained;
--   * 127 Platform Design Studio tables/RPCs are retained;
--   * 128 contributes only the notification-overload cleanup;
--   * 128/129 platform-storage guard attempts are superseded by the runtime-proven 130 contract.
--
-- Apply only after the D12 base bootstrap on a fresh database.
-- Do not apply this bootstrap tail to an existing TrustWeave database as an upgrade mechanism.

-- V1 Network Activation Autopilot — evidence persistence
-- Additive only. Reuses the existing G9.1-A governed evidence tables.
-- Included in the post-D12 bootstrap tail after source acceptance.

create or replace function public.submit_family_association_activation_evidence(
  p_source jsonb,
  p_records jsonb
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  nid uuid:=public.current_network_id();
  sid uuid;
  existing_source uuid;
  r jsonb;
  inserted_count integer:=0;
  ext_id text;
begin
  if nid is null
     or (select vertical_kind from public.networks where id=nid)<>'family-association'
  then
    raise exception 'Family Community network required.' using errcode='22023';
  end if;

  if not public.is_network_admin(nid) then
    raise exception 'Network admin access required.' using errcode='42501';
  end if;

  ext_id:=coalesce(
    nullif(trim(p_source->>'externalId'),''),
    'network-activation:'||md5(coalesce(p_source->>'title','Activation source'))
  );

  select id into existing_source
  from public.network_knowledge_sources
  where network_id=nid and external_id=ext_id
  order by created_at desc
  limit 1;

  if existing_source is null then
    insert into public.network_knowledge_sources(
      network_id,
      source_type,
      external_id,
      title,
      uri,
      visibility,
      authorization_refs,
      content_hash,
      source_updated_at,
      last_observed_at,
      metadata
    )
    values(
      nid,
      'upload',
      ext_id,
      coalesce(nullif(trim(p_source->>'title'),''),'Network activation source'),
      null,
      'restricted',
      array['network-admin'],
      nullif(p_source->>'contentHash',''),
      nullif(p_source->>'sourceUpdatedAt','')::timestamptz,
      now(),
      coalesce(p_source->'metadata','{}'::jsonb)
        || jsonb_build_object('purpose','network-activation-autopilot','schemaVersion',p_source->>'schemaVersion')
    )
    returning id into sid;
  else
    sid:=existing_source;
    update public.network_knowledge_sources
    set
      last_observed_at=now(),
      content_hash=coalesce(nullif(p_source->>'contentHash',''),content_hash),
      source_updated_at=coalesce(nullif(p_source->>'sourceUpdatedAt','')::timestamptz,source_updated_at),
      metadata=metadata
        || coalesce(p_source->'metadata','{}'::jsonb)
        || jsonb_build_object('purpose','network-activation-autopilot','schemaVersion',p_source->>'schemaVersion')
    where id=sid;
  end if;

  for r in
    select * from jsonb_array_elements(coalesce(p_records,'[]'::jsonb))
  loop
    insert into public.network_evidence_records(
      network_id,
      source_id,
      document_external_id,
      chunk_id,
      title,
      uri,
      section,
      breadcrumb,
      content_hash,
      excerpt,
      source_updated_at,
      visibility,
      authorization_refs,
      extraction_version,
      metadata
    )
    values(
      nid,
      sid,
      nullif(r->>'documentExternalId',''),
      coalesce(nullif(r->>'chunkId',''),md5(coalesce(r->>'excerpt',''))),
      nullif(r->>'title',''),
      null,
      nullif(r->>'section',''),
      coalesce(r->'breadcrumb','[]'::jsonb),
      coalesce(nullif(r->>'contentHash',''),md5(coalesce(r->>'excerpt',''))),
      nullif(r->>'excerpt',''),
      nullif(r->>'sourceUpdatedAt','')::timestamptz,
      'restricted',
      array['network-admin'],
      coalesce(nullif(r->>'extractionVersion',''),'network-activation-candidate.v1'),
      coalesce(r->'metadata','{}'::jsonb)
        || jsonb_build_object('purpose','network-activation-autopilot')
    )
    on conflict(network_id,source_id,chunk_id,content_hash) do nothing;

    if found then inserted_count:=inserted_count+1;end if;
  end loop;

  insert into public.audit_log(network_id,actor_id,action,details)
  values(
    nid,
    auth.uid(),
    'family_association_activation_evidence_recorded',
    jsonb_build_object('source_id',sid,'inserted_evidence',inserted_count,'external_id',ext_id)
  );

  return jsonb_build_object('sourceId',sid,'insertedEvidence',inserted_count);
end
$$;

revoke all on function public.submit_family_association_activation_evidence(jsonb,jsonb) from public;
grant execute on function public.submit_family_association_activation_evidence(jsonb,jsonb) to authenticated;

create or replace function public.get_family_association_activation_evidence(
  p_limit integer default 200
)
returns table(
  evidence_id uuid,
  source_id uuid,
  source_title text,
  source_external_id text,
  chunk_id text,
  section text,
  excerpt text,
  captured_at timestamptz,
  metadata jsonb
)
language sql
security definer
stable
set search_path=public
as $$
  select
    e.id,
    e.source_id,
    s.title,
    s.external_id,
    e.chunk_id,
    e.section,
    e.excerpt,
    e.captured_at,
    e.metadata
  from public.network_evidence_records e
  join public.network_knowledge_sources s on s.id=e.source_id and s.network_id=e.network_id
  where e.network_id=public.current_network_id()
    and public.is_network_admin(e.network_id)
    and s.metadata->>'purpose'='network-activation-autopilot'
  order by e.captured_at desc,e.id
  limit greatest(1,least(coalesce(p_limit,200),1000));
$$;

revoke all on function public.get_family_association_activation_evidence(integer) from public;
grant execute on function public.get_family_association_activation_evidence(integer) to authenticated;

-- LIFE2 — Generic Community Object Depth
-- Shared lifecycle for every productized vertical using network_activities/network_groups.
-- Included in the post-D12 bootstrap tail after source acceptance.

create or replace function public.update_network_activity(
  p_activity_id uuid,
  p_title text,
  p_body text default null,
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null,
  p_place text default null
) returns void
language plpgsql security definer set search_path='' as $$
declare
  nid uuid:=public.current_network_id();
  row_activity public.network_activities%rowtype;
begin
  if auth.uid() is null or nid is null or not public.is_network_member(nid) then
    raise exception 'Network membership required.' using errcode='42501';
  end if;
  select * into row_activity from public.network_activities where id=p_activity_id and network_id=nid;
  if not found then raise exception 'Community item not found.' using errcode='P0002'; end if;
  if row_activity.created_by is distinct from auth.uid() and not public.is_network_admin(nid) then
    raise exception 'Only the creator or a network administrator can edit this item.' using errcode='42501';
  end if;
  if length(trim(coalesce(p_title,'')))<2 then raise exception 'Title is required.' using errcode='22023'; end if;
  update public.network_activities
     set title=left(trim(p_title),220),
         body=nullif(trim(coalesce(p_body,'')),''),
         starts_at=p_starts_at,
         ends_at=p_ends_at,
         place=nullif(trim(coalesce(p_place,'')),''),
         updated_at=now()
   where id=p_activity_id and network_id=nid;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_activity_updated',jsonb_build_object('activity_id',p_activity_id,'activity_type',row_activity.activity_type));
end $$;
revoke all on function public.update_network_activity(uuid,text,text,timestamptz,timestamptz,text) from public,anon;
grant execute on function public.update_network_activity(uuid,text,text,timestamptz,timestamptz,text) to authenticated;

create or replace function public.delete_network_activity(p_activity_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare
  nid uuid:=public.current_network_id();
  row_activity public.network_activities%rowtype;
begin
  if auth.uid() is null or nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501'; end if;
  select * into row_activity from public.network_activities where id=p_activity_id and network_id=nid;
  if not found then raise exception 'Community item not found.' using errcode='P0002'; end if;
  if row_activity.created_by is distinct from auth.uid() and not public.is_network_admin(nid) then
    raise exception 'Only the creator or a network administrator can delete this item.' using errcode='42501';
  end if;
  delete from public.network_activity_comments where activity_id=p_activity_id and network_id=nid;
  delete from public.network_activity_reactions where activity_id=p_activity_id and network_id=nid;
  delete from public.network_activity_rsvps where activity_id=p_activity_id and network_id=nid;
  delete from public.network_activities where id=p_activity_id and network_id=nid;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_activity_deleted',jsonb_build_object('activity_id',p_activity_id,'activity_type',row_activity.activity_type,'title',row_activity.title));
end $$;
revoke all on function public.delete_network_activity(uuid) from public,anon;
grant execute on function public.delete_network_activity(uuid) to authenticated;

create or replace function public.delete_network_activity_comment(p_comment_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare
  nid uuid:=public.current_network_id();
  owner_id uuid;
begin
  if auth.uid() is null or nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501'; end if;
  select user_id into owner_id from public.network_activity_comments where id=p_comment_id and network_id=nid;
  if owner_id is null then raise exception 'Comment not found.' using errcode='P0002'; end if;
  if owner_id<>auth.uid() and not public.is_network_admin(nid) then raise exception 'Not allowed to delete this comment.' using errcode='42501'; end if;
  delete from public.network_activity_comments where id=p_comment_id and network_id=nid;
end $$;
revoke all on function public.delete_network_activity_comment(uuid) from public,anon;
grant execute on function public.delete_network_activity_comment(uuid) to authenticated;

create or replace function public.get_network_group_members(p_group_id uuid)
returns table(user_id uuid,member_label text,role varchar,joined_at timestamptz)
language sql security definer stable set search_path='' as $$
 select gm.user_id,
        coalesce(
          (select e.label from public.network_entities e
            where e.network_id=gm.network_id and e.owner_user_id=gm.user_id and e.kind='person'
            order by e.updated_at desc limit 1),
          'Member'
        )::text as member_label,
        gm.role,
        gm.created_at
   from public.network_group_memberships gm
  where gm.network_id=public.current_network_id()
    and gm.group_id=p_group_id
    and public.is_network_member(gm.network_id)
  order by case gm.role when 'lead' then 0 else 1 end, member_label;
$$;
revoke all on function public.get_network_group_members(uuid) from public,anon;
grant execute on function public.get_network_group_members(uuid) to authenticated;

create or replace function public.update_network_group(
  p_group_id uuid,
  p_name text,
  p_group_type text default 'group',
  p_description text default null
) returns void
language plpgsql security definer set search_path='' as $$
declare nid uuid:=public.current_network_id();
begin
  if auth.uid() is null or nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501'; end if;
  if length(trim(coalesce(p_name,'')))<2 then raise exception 'Group name is required.' using errcode='22023'; end if;
  update public.network_groups
     set name=left(trim(p_name),180),
         group_type=left(coalesce(nullif(trim(p_group_type),''),'group'),50),
         description=nullif(trim(coalesce(p_description,'')),''),
         updated_at=now()
   where id=p_group_id and network_id=nid;
  if not found then raise exception 'Group not found.' using errcode='P0002'; end if;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_group_updated',jsonb_build_object('group_id',p_group_id));
end $$;
revoke all on function public.update_network_group(uuid,text,text,text) from public,anon;
grant execute on function public.update_network_group(uuid,text,text,text) to authenticated;

create or replace function public.delete_network_group(p_group_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare nid uuid:=public.current_network_id(); group_name text;
begin
  if auth.uid() is null or nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501'; end if;
  select name into group_name from public.network_groups where id=p_group_id and network_id=nid;
  if group_name is null then raise exception 'Group not found.' using errcode='P0002'; end if;
  delete from public.network_group_memberships where group_id=p_group_id and network_id=nid;
  delete from public.network_groups where id=p_group_id and network_id=nid;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_group_deleted',jsonb_build_object('group_id',p_group_id,'name',group_name));
end $$;
revoke all on function public.delete_network_group(uuid) from public,anon;
grant execute on function public.delete_network_group(uuid) to authenticated;


-- LIFE2 keeps attendee-name visibility inside the shared object contract as well.
create or replace function public.get_network_event_rsvps(p_activity_id uuid)
returns table(user_id uuid,member_label text,response varchar,updated_at timestamptz)
language sql security definer stable set search_path='' as $$
 select r.user_id,
        coalesce(
          (select e.label from public.network_entities e
            where e.network_id=r.network_id and e.owner_user_id=r.user_id and e.kind='person'
            order by e.updated_at desc limit 1),
          'Member'
        )::text as member_label,
        r.response,
        r.updated_at
   from public.network_activity_rsvps r
  where r.network_id=public.current_network_id()
    and r.activity_id=p_activity_id
    and public.is_network_member(r.network_id)
  order by case r.response when 'going' then 0 when 'maybe' then 1 else 2 end, member_label;
$$;
revoke all on function public.get_network_event_rsvps(uuid) from public,anon;
grant execute on function public.get_network_event_rsvps(uuid) to authenticated;


-- Admin-managed group membership keeps committees and working groups useful
-- without duplicating vertical-specific membership implementations.
create or replace function public.add_network_group_member(
  p_group_id uuid,
  p_user_id uuid,
  p_role text default 'member'
) returns void
language plpgsql security definer set search_path='' as $$
declare nid uuid:=public.current_network_id();
begin
  if auth.uid() is null or nid is null or not public.is_network_admin(nid) then
    raise exception 'Network admin access required.' using errcode='42501';
  end if;
  if p_role not in ('member','lead') then raise exception 'Invalid group role.' using errcode='22023'; end if;
  if not exists(select 1 from public.network_groups where id=p_group_id and network_id=nid) then
    raise exception 'Group not found.' using errcode='P0002';
  end if;
  if not exists(select 1 from public.network_memberships where network_id=nid and user_id=p_user_id and status='active') then
    raise exception 'User is not an active network member.' using errcode='22023';
  end if;
  insert into public.network_group_memberships(group_id,network_id,user_id,role)
  values(p_group_id,nid,p_user_id,p_role)
  on conflict(group_id,user_id) do update set role=excluded.role;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_group_member_added',jsonb_build_object('group_id',p_group_id,'user_id',p_user_id,'role',p_role));
end $$;
revoke all on function public.add_network_group_member(uuid,uuid,text) from public,anon;
grant execute on function public.add_network_group_member(uuid,uuid,text) to authenticated;

create or replace function public.set_network_group_member_role(
  p_group_id uuid,
  p_user_id uuid,
  p_role text
) returns void
language plpgsql security definer set search_path='' as $$
declare nid uuid:=public.current_network_id();
begin
  if auth.uid() is null or nid is null or not public.is_network_admin(nid) then
    raise exception 'Network admin access required.' using errcode='42501';
  end if;
  if p_role not in ('member','lead') then raise exception 'Invalid group role.' using errcode='22023'; end if;
  update public.network_group_memberships
     set role=p_role
   where group_id=p_group_id and network_id=nid and user_id=p_user_id;
  if not found then raise exception 'Group member not found.' using errcode='P0002'; end if;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_group_member_role_updated',jsonb_build_object('group_id',p_group_id,'user_id',p_user_id,'role',p_role));
end $$;
revoke all on function public.set_network_group_member_role(uuid,uuid,text) from public,anon;
grant execute on function public.set_network_group_member_role(uuid,uuid,text) to authenticated;

create or replace function public.remove_network_group_member(
  p_group_id uuid,
  p_user_id uuid
) returns void
language plpgsql security definer set search_path='' as $$
declare nid uuid:=public.current_network_id();
begin
  if auth.uid() is null or nid is null or not public.is_network_admin(nid) then
    raise exception 'Network admin access required.' using errcode='42501';
  end if;
  delete from public.network_group_memberships
   where group_id=p_group_id and network_id=nid and user_id=p_user_id;
  if not found then raise exception 'Group member not found.' using errcode='P0002'; end if;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_group_member_removed',jsonb_build_object('group_id',p_group_id,'user_id',p_user_id));
end $$;
revoke all on function public.remove_network_group_member(uuid,uuid) from public,anon;
grant execute on function public.remove_network_group_member(uuid,uuid) to authenticated;

-- VIS1 — Founder-controlled platform visual system.
-- Reuses the existing private community-media bucket.
-- Consolidated into the validated post-D12 bootstrap tail.

create table if not exists public.platform_design_settings (
  singleton boolean primary key default true check(singleton),
  settings jsonb not null default '{"font_key":"humanist","layout_key":"balanced","hero_key":"immersive","corner_key":"rounded"}'::jsonb,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now()
);
insert into public.platform_design_settings(singleton) values(true) on conflict(singleton) do nothing;
alter table public.platform_design_settings enable row level security;
revoke all on public.platform_design_settings from anon,authenticated;

create table if not exists public.platform_visual_assets (
  slot_key varchar(140) primary key,
  bucket varchar(40) not null default 'community-media' check(bucket='community-media'),
  object_path text not null,
  thumbnail_path text,
  mime_type varchar(100) not null default 'image/webp',
  bytes bigint not null default 0 check(bytes>=0),
  thumbnail_bytes bigint not null default 0 check(thumbnail_bytes>=0),
  width integer,
  height integer,
  updated_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default now(),
  constraint platform_visual_slot_chk check(slot_key ~ '^[a-z0-9][a-z0-9._-]{1,139}$'),
  constraint platform_visual_path_chk check(object_path like 'platform/%' and (thumbnail_path is null or thumbnail_path like 'platform/%'))
);
alter table public.platform_visual_assets enable row level security;
revoke all on public.platform_visual_assets from anon,authenticated;

create or replace function public.get_platform_design()
returns jsonb language sql security definer stable set search_path='' as $$
 select jsonb_build_object(
   'settings',coalesce((select s.settings from public.platform_design_settings s where s.singleton=true),'{}'::jsonb),
   'assets',coalesce((select jsonb_agg(jsonb_build_object(
     'slot_key',a.slot_key,'bucket',a.bucket,'object_path',a.object_path,'thumbnail_path',a.thumbnail_path,
     'mime_type',a.mime_type,'bytes',a.bytes,'thumbnail_bytes',a.thumbnail_bytes,'width',a.width,'height',a.height,'updated_at',a.updated_at
   ) order by a.slot_key) from public.platform_visual_assets a),'[]'::jsonb)
 );
$$;
revoke all on function public.get_platform_design() from public;
grant execute on function public.get_platform_design() to anon,authenticated;

create or replace function public.set_platform_design_settings(p_settings jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare next_settings jsonb;
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
 next_settings:=jsonb_build_object(
   'font_key',coalesce(nullif(trim(p_settings->>'font_key'),''),'humanist'),
   'layout_key',coalesce(nullif(trim(p_settings->>'layout_key'),''),'balanced'),
   'hero_key',coalesce(nullif(trim(p_settings->>'hero_key'),''),'immersive'),
   'corner_key',coalesce(nullif(trim(p_settings->>'corner_key'),''),'rounded')
 );
 if next_settings->>'font_key' not in ('humanist','editorial','modern','system') then raise exception 'Unknown font preset.' using errcode='22023'; end if;
 if next_settings->>'layout_key' not in ('compact','balanced','spacious') then raise exception 'Unknown layout preset.' using errcode='22023'; end if;
 if next_settings->>'hero_key' not in ('immersive','split','clean') then raise exception 'Unknown hero preset.' using errcode='22023'; end if;
 if next_settings->>'corner_key' not in ('soft','rounded','square') then raise exception 'Unknown corner preset.' using errcode='22023'; end if;
 insert into public.platform_design_settings(singleton,settings,updated_by,updated_at)
 values(true,next_settings,auth.uid(),now())
 on conflict(singleton) do update set settings=excluded.settings,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
 return next_settings;
end $$;
revoke all on function public.set_platform_design_settings(jsonb) from public,anon;
grant execute on function public.set_platform_design_settings(jsonb) to authenticated;

create or replace function public.set_platform_visual_asset(
  p_slot_key text,p_object_path text,p_thumbnail_path text default null,p_mime_type text default 'image/webp',
  p_bytes bigint default 0,p_thumbnail_bytes bigint default 0,p_width integer default null,p_height integer default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare previous public.platform_visual_assets%rowtype;
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
 if p_slot_key !~ '^[a-z0-9][a-z0-9._-]{1,139}$' then raise exception 'Invalid visual slot.' using errcode='22023'; end if;
 if coalesce(p_object_path,'') not like 'platform/'||auth.uid()::text||'/%' then raise exception 'Platform asset path is not owned by this account.' using errcode='42501'; end if;
 if nullif(p_thumbnail_path,'') is not null and p_thumbnail_path not like 'platform/'||auth.uid()::text||'/%' then raise exception 'Platform thumbnail path is not owned by this account.' using errcode='42501'; end if;
 select * into previous from public.platform_visual_assets where slot_key=p_slot_key;
 insert into public.platform_visual_assets(slot_key,bucket,object_path,thumbnail_path,mime_type,bytes,thumbnail_bytes,width,height,updated_by,updated_at)
 values(p_slot_key,'community-media',p_object_path,nullif(p_thumbnail_path,''),coalesce(nullif(p_mime_type,''),'image/webp'),greatest(coalesce(p_bytes,0),0),greatest(coalesce(p_thumbnail_bytes,0),0),p_width,p_height,auth.uid(),now())
 on conflict(slot_key) do update set object_path=excluded.object_path,thumbnail_path=excluded.thumbnail_path,mime_type=excluded.mime_type,
 bytes=excluded.bytes,thumbnail_bytes=excluded.thumbnail_bytes,width=excluded.width,height=excluded.height,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
 return jsonb_build_object('previous_object_path',previous.object_path,'previous_thumbnail_path',previous.thumbnail_path);
end $$;
revoke all on function public.set_platform_visual_asset(text,text,text,text,bigint,bigint,integer,integer) from public,anon;
grant execute on function public.set_platform_visual_asset(text,text,text,text,bigint,bigint,integer,integer) to authenticated;

create or replace function public.remove_platform_visual_asset(p_slot_key text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare previous public.platform_visual_assets%rowtype;
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
 delete from public.platform_visual_assets where slot_key=p_slot_key returning * into previous;
 if not found then return '{}'::jsonb; end if;
 return jsonb_build_object('object_path',previous.object_path,'thumbnail_path',previous.thumbnail_path);
end $$;
revoke all on function public.remove_platform_visual_asset(text) from public,anon;
grant execute on function public.remove_platform_visual_asset(text) to authenticated;

-- Final notification contract: remove the obsolete no-argument wrapper so
-- PostgREST has one unambiguous callable get_my_notifications contract.
drop function if exists public.get_my_notifications();

-- VIS3 final platform-media repair.
-- Runtime-proven on the active Supabase project before promotion to source.
--
-- Design principle:
--   * platform/<owner-id>/... objects are authorized by explicit Storage RLS;
--   * the shared BEFORE trigger validates media shape/size when available but does not
--     duplicate platform-owner authorization;
--   * ordinary network media keeps the strong Mission-2 membership/user/path/quota guard.
--
-- This supersedes the platform branch introduced by 128 and refined by 129.

create or replace function public.a5_storage_guard()
returns trigger
language plpgsql
security definer
set search_path=public,storage
as $$
declare
  nid uuid;
  actor uuid;
  request_uid uuid:=auth.uid();
  bytes bigint:=0;
  old_bytes bigint:=0;
  lim bigint;
  max_file integer;
  current_usage bigint;
  mime text;
begin
  if new.bucket_id not in ('profile-photos','community-media') then
    return new;
  end if;

  -- Platform visuals are not tenant-network media. Storage RLS below is the
  -- authorization boundary for the platform/<signed-in-owner>/... namespace.
  if new.bucket_id='community-media' and new.name like 'platform/%' then
    bytes:=public.storage_object_metadata_bytes(new.metadata);
    mime:=lower(coalesce(
      new.metadata->>'mimetype',
      new.metadata->>'contentType',
      new.metadata->>'content_type',
      ''
    ));

    if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then
      raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023';
    end if;

    -- Storage BEFORE triggers do not expose byte metadata consistently across
    -- storage-api versions. Enforce the limit here only when bytes are known;
    -- the client already compresses Design Studio assets before upload.
    if bytes>2097152 then
      raise exception 'Platform image exceeds the 2 MB storage guard.' using errcode='22023';
    end if;

    return new;
  end if;

  -- Normal network media retains explicit tenant + uploader ownership checks.
  nid:=public.storage_path_network_id(new.name);
  actor:=public.storage_path_owner_user_id(new.name);

  if nid is null then
    raise exception 'Network media path must begin with the network id.' using errcode='22023';
  end if;
  if actor is null then
    raise exception 'Network media path must include the uploading user id.' using errcode='22023';
  end if;
  if request_uid is not null and actor<>request_uid then
    raise exception 'Media path does not belong to the signed-in user.' using errcode='42501';
  end if;
  if not public.has_active_network_membership(nid,actor) then
    raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501';
  end if;

  bytes:=public.storage_object_metadata_bytes(new.metadata);
  mime:=lower(coalesce(
    new.metadata->>'mimetype',
    new.metadata->>'contentType',
    new.metadata->>'content_type',
    ''
  ));

  if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then
    raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023';
  end if;

  select storage_limit_bytes,photo_max_bytes,media_usage_bytes
    into lim,max_file,current_usage
    from public.networks
   where id=nid
   for update;

  if lim is null then
    raise exception 'Network was not found.' using errcode='P0002';
  end if;

  current_usage:=greatest(
    coalesce(current_usage,0),
    coalesce((
      select sum(m.bytes+m.thumbnail_bytes)
        from public.network_media_assets m
       where m.network_id=nid
    ),0)
  );

  if bytes>0 and bytes>max_file then
    raise exception 'Image exceeds this network''s % KB upload limit.',
      ceil(max_file/1024.0) using errcode='22023';
  end if;

  if tg_op='UPDATE' then
    old_bytes:=public.storage_object_metadata_bytes(old.metadata);
  end if;

  if bytes>0 and current_usage-old_bytes+bytes>lim then
    raise exception 'Network storage limit reached. Remove older photos or use a smaller image.'
      using errcode='22023';
  end if;

  return new;
end
$$;

notify pgrst, 'reload schema';
