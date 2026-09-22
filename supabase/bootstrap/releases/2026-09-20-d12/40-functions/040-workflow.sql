-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.act_on_contribution_suggestion(p_suggestion_id uuid, p_action text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare target_member uuid;
begin
  if p_action not in ('accepted','dismissed','resolved') then raise exception 'Invalid suggestion action.' using errcode='22023'; end if;
  select member_id into target_member from public.contribution_suggestions where id=p_suggestion_id;
  if target_member is null then raise exception 'Suggestion not found.' using errcode='P0002'; end if;
  if not public.is_admin() and not exists(select 1 from public.profiles where id=auth.uid() and member_id=target_member) then
    raise exception 'You cannot act on this suggestion.' using errcode='42501';
  end if;
  update public.contribution_suggestions set status=p_action,acted_by=auth.uid(),acted_at=now(),updated_at=now() where id=p_suggestion_id;
  insert into public.audit_log(actor_id,action,details) values(auth.uid(),'contribution_suggestion_'||p_action,jsonb_build_object('suggestion_id',p_suggestion_id,'member_id',target_member));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.begin_api_command_idempotency(p_command text, p_key text, p_request_hash text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); r public.api_command_idempotency; claimed boolean:=false;
begin
 if uid is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_command,'')))<1 or length(trim(coalesce(p_key,'')))<8 or length(trim(coalesce(p_key,'')))>128 or length(trim(coalesce(p_request_hash,'')))<16 then
  raise exception 'Invalid idempotency request.' using errcode='22023';
 end if;
 insert into public.api_command_idempotency(user_id,command_name,idempotency_key,request_hash)
 values(uid,trim(p_command),trim(p_key),trim(p_request_hash)) on conflict do nothing;
 select * into r from public.api_command_idempotency i
 where i.user_id=uid and i.command_name=trim(p_command) and i.idempotency_key=trim(p_key);
 if r.request_hash<>trim(p_request_hash) then
  raise exception 'Idempotency key was already used with a different request.' using errcode='23505';
 end if;
 if r.status='completed' then return jsonb_build_object('state','cached','response',r.response_body); end if;
 if r.created_at= r.updated_at and r.updated_at > now()-interval '5 minutes' then
  -- Freshly inserted by this or a competing request. Try to claim by changing updated_at once.
  update public.api_command_idempotency i set updated_at=clock_timestamp()
   where i.id=r.id and i.updated_at=r.updated_at returning true into claimed;
  if claimed then return jsonb_build_object('state','execute'); end if;
 end if;
 if r.updated_at <= now()-interval '5 minutes' then
  update public.api_command_idempotency i set updated_at=clock_timestamp()
   where i.id=r.id and i.status='pending' and i.updated_at=r.updated_at returning true into claimed;
  if claimed then return jsonb_build_object('state','execute'); end if;
 end if;
 return jsonb_build_object('state','in_progress');
end;$function$
;

CREATE OR REPLACE FUNCTION public.complete_api_command_idempotency(p_command text, p_key text, p_response jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
 update public.api_command_idempotency i set status='completed',response_body=p_response,updated_at=now()
 where i.user_id=auth.uid() and i.command_name=trim(p_command) and i.idempotency_key=trim(p_key);
 if not found then raise exception 'Idempotency record not found.' using errcode='P0002'; end if;
end;$function$
;

CREATE OR REPLACE FUNCTION public.create_change_request(p_action character varying, p_target_member_id uuid DEFAULT NULL::uuid, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare request_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode='42501';
  end if;
  if p_action not in ('create_member','update_member','add_relationship','remove_relationship','import','other') then
    raise exception 'Invalid change-request action.' using errcode='22023';
  end if;
  if not public.is_admin() and p_action in ('add_relationship','remove_relationship','import') then
    raise exception 'Administrator access is required for this change type.' using errcode='42501';
  end if;
  if not public.is_admin() and p_target_member_id is not null
     and not exists(select 1 from public.profiles where id=auth.uid() and member_id=p_target_member_id) then
    raise exception 'You can only submit changes for your own profile.' using errcode='42501';
  end if;
  insert into public.change_requests(action,target_member_id,submitted_by,payload)
  values(p_action,p_target_member_id,auth.uid(),coalesce(p_payload,'{}'::jsonb))
  returning id into request_id;
  return request_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_contribution_suggestions(p_status text DEFAULT 'open'::text)
 RETURNS SETOF contribution_suggestions
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select s.* from public.contribution_suggestions s
  where auth.uid() is not null and (p_status is null or s.status=p_status)
    and (public.is_admin() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.member_id=s.member_id))
  order by s.priority desc,s.created_at;
$function$
;

CREATE OR REPLACE FUNCTION public.get_guide_feedback_signals()
 RETURNS TABLE(guide_key text, feedback_type text, family_count bigint, feedback_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select f.guide_key,f.feedback_type,count(distinct f.network_id) filter(where f.network_id is not null),count(*)
 from public.guide_feedback f where public.is_platform_owner()
 group by f.guide_key,f.feedback_type order by count(distinct f.network_id) desc,count(*) desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_platform_guide_feedback(p_status text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, network_id uuid, guide_key text, screen text, feedback_type text, message text, role text, experience_mode text, app_version text, status text, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select f.id,f.network_id,f.guide_key,f.screen,f.feedback_type,f.message,f.role,f.experience_mode,f.app_version,f.status,f.created_at,f.updated_at
 from public.guide_feedback f
 where public.is_platform_owner() and (p_status is null or f.status=p_status)
 order by case f.status when 'new' then 0 when 'reviewing' then 1 else 2 end,f.created_at desc limit 300;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_contribution_suggestions()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare affected integer:=0;
begin
  if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
  -- Any previously-open rule result that no longer reproduces becomes resolved.
  update public.contribution_suggestions set status='resolved',updated_at=now()
    where status='open' and kind in ('missing_field','orphan','possible_duplicate','incomplete_relationship');
  insert into public.contribution_suggestions(signature,member_id,kind,title,detail,action_payload,priority,status,updated_at)
  select 'missing:'||fm.id::text,fm.id,'missing_field','Complete '||fm.full_name||'''s profile',
    'Add '||array_to_string(array_remove(array[
      case when fm.date_of_birth is null then 'date of birth' end,
      case when nullif(trim(fm.city),'') is null then 'city' end,
      case when nullif(trim(fm.profession),'') is null then 'profession' end,
      case when nullif(trim(fm.bio),'') is null then 'a short introduction' end
    ],null),', '),jsonb_build_object('member_id',fm.id,'action','edit_profile'),70,'open',now()
  from public.family_members fm where fm.profile_status='approved' and
    (fm.date_of_birth is null or nullif(trim(fm.city),'') is null or nullif(trim(fm.profession),'') is null or nullif(trim(fm.bio),'') is null)
    and (public.is_admin() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.member_id=fm.id))
  on conflict(signature) do update set title=excluded.title,detail=excluded.detail,action_payload=excluded.action_payload,
    priority=excluded.priority,status=case when contribution_suggestions.status in ('dismissed','accepted') then contribution_suggestions.status else 'open' end,updated_at=now();
  get diagnostics affected=row_count;
  if public.is_admin() then
    insert into public.contribution_suggestions(signature,member_id,kind,title,detail,action_payload,priority,status,updated_at)
    select 'orphan:'||fm.id::text,fm.id,'orphan','Connect '||fm.full_name,
      'This profile has no recorded relationship. Add a parent, child or spouse.',jsonb_build_object('member_id',fm.id,'action','manage_relationship'),90,'open',now()
    from public.family_members fm where fm.profile_status='approved' and not exists(
      select 1 from public.family_relationships r where r.person_id=fm.id or r.related_person_id=fm.id)
    on conflict(signature) do update set status=case when contribution_suggestions.status in ('dismissed','accepted') then contribution_suggestions.status else 'open' end,updated_at=now();

    insert into public.contribution_suggestions(signature,member_id,kind,title,detail,action_payload,priority,status,updated_at)
    select 'duplicate:'||least(a.id,b.id)::text||':'||greatest(a.id,b.id)::text,a.id,'possible_duplicate','Review possible duplicate',
      a.full_name||' appears more than once' || case when a.date_of_birth=b.date_of_birth and a.date_of_birth is not null then ' with the same birth date.' else '.' end,
      jsonb_build_object('member_id',a.id,'other_member_id',b.id,'action','review_duplicate'),85,'open',now()
    from public.family_members a join public.family_members b on a.id<b.id and lower(trim(a.full_name))=lower(trim(b.full_name))
    where a.profile_status='approved' and b.profile_status='approved'
    on conflict(signature) do update set detail=excluded.detail,status=case when contribution_suggestions.status in ('dismissed','accepted') then contribution_suggestions.status else 'open' end,updated_at=now();

    insert into public.contribution_suggestions(signature,member_id,kind,title,detail,action_payload,priority,status,updated_at)
    select 'relationship:'||r.id::text,r.person_id,'incomplete_relationship','Review one-way relationship',
      'Confirm that this parent/child relationship is represented consistently.',jsonb_build_object('relationship_id',r.id,'member_id',r.person_id,'action','manage_relationship'),75,'open',now()
    from public.family_relationships r where r.relationship_type in ('parent','child') and not exists(
      select 1 from public.family_relationships back where back.person_id=r.related_person_id and back.related_person_id=r.person_id
        and back.relationship_type=case when r.relationship_type='parent' then 'child' else 'parent' end)
    on conflict(signature) do update set status=case when contribution_suggestions.status in ('dismissed','accepted') then contribution_suggestions.status else 'open' end,updated_at=now();
  end if;
  return affected;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.release_api_command_idempotency(p_command text, p_key text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null then return; end if;
 delete from public.api_command_idempotency i where i.user_id=auth.uid() and i.command_name=trim(p_command) and i.idempotency_key=trim(p_key) and i.status='pending';
end;$function$
;

CREATE OR REPLACE FUNCTION public.review_change_request(p_request_id uuid, p_status character varying, p_review_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.change_requests; nid uuid; target_user uuid;
begin
 if not public.is_admin() then raise exception 'Administrator access is required.' using errcode='42501'; end if;
 if p_status not in ('approved','rejected','cancelled') then raise exception 'Invalid review status.' using errcode='22023'; end if;
 select * into r from public.change_requests where id=p_request_id for update;
 if r.id is null then raise exception 'Change request not found.' using errcode='P0002'; end if;
 update public.change_requests set status=p_status,review_note=p_review_note,reviewed_by=auth.uid(),reviewed_at=now() where id=p_request_id;
 insert into public.audit_log(actor_id,action,details) values(auth.uid(),'change_request_reviewed',jsonb_build_object('request_id',p_request_id,'status',p_status));
 target_user:=r.submitted_by;
 if target_user is not null then
   insert into public.notifications(user_id,type,title,body) values(target_user,'change_request_reviewed',case when p_status='approved' then 'Your change was approved' else 'Your change was not approved' end,coalesce(p_review_note,'Your submitted change request has been reviewed.')) returning id into nid;
 end if;
 return nid;
end; $function$
;

CREATE OR REPLACE FUNCTION public.set_guide_feedback_status(p_feedback_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if not public.is_platform_owner() then raise exception 'Platform-owner access required.' using errcode='42501'; end if;
 if p_status not in ('new','reviewing','planned','already_supported','not_planned','implemented') then raise exception 'Invalid feedback status.' using errcode='22023'; end if;
 update public.guide_feedback set status=p_status,updated_at=now() where id=p_feedback_id;
end;$function$
;

CREATE OR REPLACE FUNCTION public.submit_guide_feedback(p_guide_key text DEFAULT NULL::text, p_screen text DEFAULT NULL::text, p_feedback_type text DEFAULT 'other'::text, p_message text DEFAULT NULL::text, p_role text DEFAULT NULL::text, p_experience_mode text DEFAULT NULL::text, p_app_version text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); mid uuid; rid uuid;
begin
 if auth.uid() is null then raise exception 'Sign in to send feedback.' using errcode='42501'; end if;
 if p_feedback_type not in ('confusing','missing','feature_idea','improvement','bug','family_need','other','helpful_yes','helpful_no','future_interest') then raise exception 'Invalid feedback type.' using errcode='22023'; end if;
 if p_message is not null and length(p_message)>2000 then raise exception 'Feedback is too long.' using errcode='22023'; end if;
 select member_id into mid from public.profiles where id=auth.uid();
 insert into public.guide_feedback(network_id,user_id,member_id,guide_key,screen,feedback_type,message,role,experience_mode,app_version)
 values(nid,auth.uid(),mid,nullif(left(trim(coalesce(p_guide_key,'')),120),''),nullif(left(trim(coalesce(p_screen,'')),120),''),p_feedback_type,nullif(trim(p_message),''),nullif(left(trim(coalesce(p_role,'')),40),''),nullif(left(trim(coalesce(p_experience_mode,'')),40),''),nullif(left(trim(coalesce(p_app_version,'')),40),'')) returning id into rid;
 return rid;
end;$function$
;

SET check_function_bodies = on;
