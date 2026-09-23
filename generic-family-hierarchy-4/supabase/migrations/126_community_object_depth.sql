-- LIFE2 — Generic Community Object Depth
-- Shared lifecycle for every productized vertical using network_activities/network_groups.
-- Source-only until explicitly applied to a target Supabase project.

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
  delete from public.network_activity_likes where activity_id=p_activity_id and network_id=nid;
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
        )::text,
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
        )::text,
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
