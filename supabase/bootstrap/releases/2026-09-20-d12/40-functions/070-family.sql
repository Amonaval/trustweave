-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.clear_memory_reaction(p_memory_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
  delete from public.memory_reactions where network_id=nid and memory_id=p_memory_id and user_id=auth.uid();
end $function$
;

CREATE OR REPLACE FUNCTION public.create_member_life_event(p_member_id uuid, p_event_type character varying, p_title character varying, p_event_date date DEFAULT NULL::date, p_location character varying DEFAULT NULL::character varying, p_description text DEFAULT NULL::text, p_visibility character varying DEFAULT 'member'::character varying)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare event_id uuid; owner_id uuid;
begin
  select p.id into owner_id from public.profiles p where p.id=auth.uid();
  if not public.is_admin() and not exists(select 1 from public.profiles p where p.id=auth.uid() and p.member_id=p_member_id) then
    raise exception 'You can only edit your own profile timeline.' using errcode='42501';
  end if;
  if p_visibility not in ('public','member','admin') then raise exception 'Invalid visibility.' using errcode='22023'; end if;
  if p_visibility='admin' and not public.is_admin() then raise exception 'Only administrators can create admin-only events.' using errcode='42501'; end if;
  insert into public.member_life_events(member_id,event_type,title,event_date,location,description,visibility,created_by)
  values(p_member_id,p_event_type,p_title,p_event_date,p_location,p_description,p_visibility,auth.uid()) returning id into event_id;
  insert into public.audit_log(actor_id,action,details) values(auth.uid(),'life_event_created',jsonb_build_object('member_id',p_member_id,'event_id',event_id));
  return event_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_memory(p_member_id uuid, p_title character varying, p_story text DEFAULT NULL::text, p_photo_url text DEFAULT NULL::text, p_visibility character varying DEFAULT 'member'::character varying)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare memory_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
  if nullif(trim(p_title),'') is null then raise exception 'Memory title is required.' using errcode='22023'; end if;
  if p_visibility not in ('public','member','admin') then raise exception 'Invalid visibility.' using errcode='22023'; end if;
  if p_visibility='admin' and not public.is_admin() then raise exception 'Only administrators can create admin-only memories.' using errcode='42501'; end if;
  if not public.is_admin() and p_member_id is not null
     and not exists(select 1 from public.profiles where id=auth.uid() and member_id=p_member_id) then
    raise exception 'You can only create memories for your own profile.' using errcode='42501';
  end if;
  if p_photo_url is not null and p_photo_url <> ''
     and not public.is_admin()
     and p_photo_url not like 'community/' || auth.uid()::text || '/%' then
    raise exception 'You can only attach media uploaded by your account.' using errcode='42501';
  end if;
  insert into public.memories(member_id,title,story,photo_url,visibility,created_by)
  values(p_member_id,trim(p_title),p_story,nullif(p_photo_url,''),p_visibility,auth.uid())
  returning id into memory_id;
  insert into public.audit_log(actor_id,action,details)
  values(auth.uid(),'memory_created',jsonb_build_object('memory_id',memory_id,'member_id',p_member_id));
  return memory_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_member_life_event(p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare event_member uuid;
begin
  select member_id into event_member from public.member_life_events where id=p_event_id;
  if event_member is null then raise exception 'Timeline event not found.' using errcode='P0002'; end if;
  if not public.is_admin() and not exists(select 1 from public.profiles p where p.id=auth.uid() and p.member_id=event_member) then raise exception 'You can only edit your own profile timeline.' using errcode='42501'; end if;
  delete from public.member_life_events where id=p_event_id;
  insert into public.audit_log(actor_id,action,details) values(auth.uid(),'life_event_deleted',jsonb_build_object('event_id',p_event_id,'member_id',event_member));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_memory(p_memory_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare owner_id uuid;
begin
 select created_by into owner_id from public.memories where id=p_memory_id;
 if owner_id is null then raise exception 'Memory not found.' using errcode='P0002'; end if;
 if not public.is_admin() and owner_id<>auth.uid() then raise exception 'You can only delete your own memories.' using errcode='42501'; end if;
 delete from public.memories where id=p_memory_id;
 insert into public.audit_log(actor_id,action,details) values(auth.uid(),'memory_deleted',jsonb_build_object('memory_id',p_memory_id));
end; $function$
;

CREATE OR REPLACE FUNCTION public.get_member_life_events(p_member_id uuid)
 RETURNS TABLE(id uuid, member_id uuid, event_type character varying, title character varying, event_date date, location character varying, description text, visibility character varying, created_by uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select e.id,e.member_id,e.event_type,e.title,e.event_date,e.location,e.description,
         e.visibility,e.created_by,e.created_at,e.updated_at
  from public.member_life_events e
  join public.family_members fm on fm.id=e.member_id
  where e.member_id=p_member_id
    and (
      public.is_admin()
      or (
        fm.profile_status='approved'
        and fm.profile_visibility <> 'admin'
        and e.visibility <> 'admin'
      )
    );
$function$
;

CREATE OR REPLACE FUNCTION public.get_memory_people(p_memory_ids uuid[])
 RETURNS TABLE(memory_id uuid, member_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select mp.memory_id,mp.member_id from public.memory_people mp
 where mp.network_id=public.current_network_id() and mp.memory_id=any(coalesce(p_memory_ids,array[]::uuid[])) and auth.uid() is not null;
$function$
;

CREATE OR REPLACE FUNCTION public.get_memory_reactions(p_memory_ids uuid[])
 RETURNS TABLE(memory_id uuid, heart bigint, smile bigint, pray bigint, celebrate bigint, my_reaction text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select m.id,
    count(*) filter(where r.reaction='heart')::bigint,
    count(*) filter(where r.reaction='smile')::bigint,
    count(*) filter(where r.reaction='pray')::bigint,
    count(*) filter(where r.reaction='celebrate')::bigint,
    max(r.reaction) filter(where r.user_id=auth.uid())::text
  from public.memories m
  left join public.memory_reactions r on r.memory_id=m.id and r.network_id=m.network_id
  where auth.uid() is not null and m.network_id=public.current_network_id()
    and m.id=any(coalesce(p_memory_ids,array[]::uuid[]))
  group by m.id;
$function$
;

CREATE OR REPLACE FUNCTION public.link_memory_to_event(p_memory_id uuid, p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
 if not exists(select 1 from public.community_events where id=p_event_id and network_id=nid) then raise exception 'Gathering not found.' using errcode='22023'; end if;
 update public.memories set event_id=p_event_id where id=p_memory_id and network_id=nid and (created_by=auth.uid() or public.is_network_admin(nid));
 if not found then raise exception 'Memory not found or not editable.' using errcode='42501'; end if;
end;$function$
;

CREATE OR REPLACE FUNCTION public.review_profile_submission(p_submission_id uuid, p_status character varying, p_review_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  nid uuid := public.current_network_id();
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode='42501';
  end if;
  if p_status not in ('approved','rejected') then
    raise exception 'Review status must be approved or rejected.' using errcode='22023';
  end if;
  if nid is null or not public.is_network_admin(nid) then
    raise exception 'Family Owner or co-admin access is required.' using errcode='42501';
  end if;
  if not exists(select 1 from public.profile_submissions ps where ps.id=p_submission_id and ps.network_id=nid) then
    raise exception 'Profile submission was not found in the active family.' using errcode='P0002';
  end if;

  update public.profile_submissions
     set status=p_status
   where id=p_submission_id and network_id=nid;

  insert into public.audit_log(actor_id,action,details,network_id)
  values(auth.uid(),
         case when p_status='approved' then 'profile_submission_approved' else 'profile_submission_rejected' end,
         jsonb_build_object('submission_id',p_submission_id,'review_note',nullif(trim(coalesce(p_review_note,'')),'')),
         nid);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_memory_people(p_memory_id uuid, p_member_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
 if not exists(select 1 from public.memories where id=p_memory_id and network_id=nid and (created_by=auth.uid() or public.is_network_admin(nid))) then raise exception 'Memory not found or not editable.' using errcode='42501'; end if;
 delete from public.memory_people where memory_id=p_memory_id and network_id=nid;
 insert into public.memory_people(network_id,memory_id,member_id)
 select nid,p_memory_id,x from unnest(coalesce(p_member_ids,array[]::uuid[])) x
 where exists(select 1 from public.family_members fm where fm.id=x and fm.network_id=nid)
 on conflict do nothing;
end;$function$
;

CREATE OR REPLACE FUNCTION public.set_memory_reaction(p_memory_id uuid, p_reaction text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
  if p_reaction not in ('heart','smile','pray','celebrate') then raise exception 'Invalid reaction.' using errcode='22023'; end if;
  if not exists(select 1 from public.memories where id=p_memory_id and network_id=nid) then raise exception 'Memory not found.' using errcode='22023'; end if;
  insert into public.memory_reactions(network_id,memory_id,user_id,reaction)
  values(nid,p_memory_id,auth.uid(),p_reaction)
  on conflict(memory_id,user_id) do update set reaction=excluded.reaction,updated_at=now();
  insert into public.family_engagement_events(network_id,user_id,event_type,entity_type,entity_id)
  values(nid,auth.uid(),'memory_reaction','memory',p_memory_id);
end $function$
;

CREATE OR REPLACE FUNCTION public.update_member_life_event(p_event_id uuid, p_event_type character varying, p_title character varying, p_event_date date DEFAULT NULL::date, p_location character varying DEFAULT NULL::character varying, p_description text DEFAULT NULL::text, p_visibility character varying DEFAULT 'member'::character varying)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare event_member uuid;
begin
  select member_id into event_member from public.member_life_events where id=p_event_id;
  if event_member is null then raise exception 'Timeline event not found.' using errcode='P0002'; end if;
  if not public.is_admin() and not exists(select 1 from public.profiles p where p.id=auth.uid() and p.member_id=event_member) then raise exception 'You can only edit your own profile timeline.' using errcode='42501'; end if;
  if p_visibility='admin' and not public.is_admin() then raise exception 'Only administrators can create admin-only events.' using errcode='42501'; end if;
  update public.member_life_events set event_type=p_event_type,title=p_title,event_date=p_event_date,location=p_location,description=p_description,visibility=p_visibility,updated_at=now() where id=p_event_id;
  insert into public.audit_log(actor_id,action,details) values(auth.uid(),'life_event_updated',jsonb_build_object('event_id',p_event_id,'member_id',event_member));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_profile_submission_media()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.photo_url is not null and new.photo_url <> ''
     and not public.is_admin()
     and new.photo_url not like 'profiles/' || new.submitted_by::text || '/%' then
    raise exception 'You can only attach a profile photo uploaded by your account.' using errcode='42501';
  end if;
  return new;
end;
$function$
;

SET check_function_bodies = on;
