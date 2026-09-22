-- Mission 2 paused follow-up: restore the exact Housing Society complaint-create RPC
-- contract used by verticals/housing-society/runtime/operations-remote.ts.
-- Safe to apply after migration 118.

begin;

drop function if exists public.hs4_create_complaint(uuid,text,text,text,text,text);

create function public.hs4_create_complaint(
  p_unit_entity_id uuid,
  p_category text,
  p_title text,
  p_description text default null,
  p_priority text default 'normal',
  p_photo_path text default null
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  nid uuid:=public.hs2_assert_network();
  rid uuid;
  resolved_unit uuid:=p_unit_entity_id;
  person_id uuid;
  ckey text;
  rkey text;
  assignee uuid;
  target uuid;
  notification_ids uuid[]:='{}';
  notification_id uuid;
begin
  if resolved_unit is null then
    select id into person_id
    from public.network_entities
    where network_id=nid and kind='person' and owner_user_id=auth.uid()
    order by updated_at desc
    limit 1;

    if person_id is not null then
      select unit_entity_id into resolved_unit
      from public.hs_unit_occupancy_history
      where network_id=nid and subject_entity_id=person_id and ends_on is null
      order by is_primary desc, starts_on desc
      limit 1;
    end if;
  end if;

  if p_priority not in ('low','normal','high','urgent') then
    raise exception 'Invalid priority.';
  end if;

  if resolved_unit is not null and not exists(
    select 1 from public.network_entities
    where id=resolved_unit and network_id=nid and kind='unit'
  ) then
    raise exception 'Unit not found in this society.';
  end if;

  if nullif(trim(coalesce(p_photo_path,'')),'') is not null
     and p_photo_path not like nid::text||'/community/'||auth.uid()::text||'/%' then
    raise exception 'Complaint photo must be uploaded by the signed-in resident.' using errcode='42501';
  end if;

  ckey:=public.hs4_category_key(p_category);
  select role_key into rkey
  from public.hs_complaint_routes
  where network_id=nid and category_key=ckey;

  select nr.user_id into assignee
  from public.network_notification_roles nr
  where nr.network_id=nid
    and nr.active
    and nr.role_key=coalesce(rkey,'complaint-resolver')
  order by nr.updated_at desc
  limit 1;

  insert into public.hs_complaints(
    network_id,unit_entity_id,category,title,description,attachments,priority,assigned_to,created_by
  ) values (
    nid,
    resolved_unit,
    coalesce(nullif(trim(p_category),''),'Other'),
    trim(p_title),
    nullif(trim(p_description),''),
    case
      when nullif(trim(coalesce(p_photo_path,'')),'') is null then '[]'::jsonb
      else jsonb_build_array(jsonb_build_object('kind','photo','path',trim(p_photo_path)))
    end,
    p_priority,
    assignee,
    auth.uid()
  ) returning id into rid;

  for target in
    select distinct x.user_id
    from (
      select nr.user_id
      from public.network_notification_roles nr
      where nr.network_id=nid
        and nr.active
        and nr.role_key=coalesce(rkey,'complaint-resolver')
      union all
      select nm.user_id
      from public.network_memberships nm
      where nm.network_id=nid
        and nm.status='active'
        and nm.role in ('owner','admin')
        and assignee is null
    ) x
  loop
    if target=auth.uid() then
      continue;
    end if;

    notification_id:=public.create_network_notification(
      nid,
      target,
      'complaint-created',
      'New complaint · '||trim(p_title),
      nullif(trim(p_description),''),
      'complaints',
      'hs_complaint',
      rid,
      case when p_priority in ('urgent','high') then p_priority else 'normal' end,
      jsonb_build_object('surface','complaints','category',p_category),
      auth.uid()
    );
    notification_ids:=array_append(notification_ids,notification_id);
  end loop;

  insert into public.audit_log(network_id,actor_id,action,details)
  values(
    nid,
    auth.uid(),
    'hs4_complaint_created',
    jsonb_build_object(
      'complaint_id',rid,
      'priority',p_priority,
      'route',rkey,
      'assignee',assignee
    )
  );

  return jsonb_build_object(
    'complaint_id',rid,
    'assigned_to',assignee,
    'notification_ids',notification_ids
  );
end
$$;

revoke all on function public.hs4_create_complaint(uuid,text,text,text,text,text) from public;
grant execute on function public.hs4_create_complaint(uuid,text,text,text,text,text) to authenticated;

-- Force PostgREST to refresh function signatures immediately.
notify pgrst, 'reload schema';

commit;
