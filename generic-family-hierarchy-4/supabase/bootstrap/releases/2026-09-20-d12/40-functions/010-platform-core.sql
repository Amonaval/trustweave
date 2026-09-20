-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.a4_safe_external_url(p_url text, p_kind text DEFAULT 'other'::text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
declare u text:=lower(trim(coalesce(p_url,'')));
begin
  if u='' then return true; end if;
  if u !~ '^https://[^[:space:]]+$' then return false; end if;
  if p_kind='facebook' then return u ~ '^https://(www\.|m\.)?facebook\.com/'; end if;
  if p_kind='instagram' then return u ~ '^https://(www\.)?instagram\.com/'; end if;
  return true;
end $function$
;

CREATE OR REPLACE FUNCTION public.a5_storage_account()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'storage'
AS $function$
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
end $function$
;

CREATE OR REPLACE FUNCTION public.a5_storage_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'storage'
AS $function$
declare nid uuid;actor uuid;request_uid uuid:=auth.uid();bytes bigint;old_bytes bigint:=0;lim bigint;max_file integer;current_usage bigint;mime text;
begin
  if new.bucket_id not in ('profile-photos','community-media') then return new; end if;
  nid:=public.storage_path_network_id(new.name);actor:=public.storage_path_owner_user_id(new.name);
  if nid is null then raise exception 'Network media path must begin with the network id.' using errcode='22023'; end if;
  if actor is null then raise exception 'Network media path must include the uploading user id.' using errcode='22023'; end if;
  if request_uid is not null and actor<>request_uid then raise exception 'Media path does not belong to the signed-in user.' using errcode='42501'; end if;
  if not public.has_active_network_membership(nid,actor) then raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501'; end if;

  bytes:=public.storage_object_metadata_bytes(new.metadata);
  mime:=lower(coalesce(new.metadata->>'mimetype',new.metadata->>'contentType',new.metadata->>'content_type',''));
  if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023'; end if;
  select storage_limit_bytes,photo_max_bytes,media_usage_bytes into lim,max_file,current_usage from public.networks where id=nid for update;
  if lim is null then raise exception 'Network was not found.' using errcode='P0002'; end if;
  current_usage:=greatest(coalesce(current_usage,0),coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid),0));
  if bytes>0 and bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
  if tg_op='UPDATE' then old_bytes:=public.storage_object_metadata_bytes(old.metadata); end if;
  if bytes>0 and current_usage-old_bytes+bytes>lim then raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023'; end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.add_fca_finance_entry(p_year_id uuid, p_entry_type text, p_amount numeric, p_description text, p_visibility text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id(); rid uuid; begin
 if not public.is_network_admin(nid) then raise exception 'Association admin access required.' using errcode='42501'; end if;
 insert into public.family_association_finance_ledger(network_id,membership_year_id,entry_type,amount,description,visibility,created_by) values(nid,p_year_id,p_entry_type,p_amount,nullif(trim(coalesce(p_description,'')),''),p_visibility,auth.uid()) returning id into rid;return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.add_myself_to_family(p_full_name text, p_gender character varying DEFAULT NULL::character varying)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  uid uuid:=auth.uid(); nid uuid:=public.current_network_id(); mid uuid;
begin
  if uid is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
  if nid is null or not public.is_network_member(nid) then raise exception 'Open a family first.' using errcode='42501'; end if;
  if length(trim(coalesce(p_full_name,'')))<2 then raise exception 'Please enter your name.' using errcode='22023'; end if;
  if p_gender is not null and p_gender not in ('Male','Female','Other') then raise exception 'Choose Male, Female or Other.' using errcode='22023'; end if;
  select nm.member_id into mid from public.network_memberships nm where nm.network_id=nid and nm.user_id=uid and nm.status='active';
  if mid is not null then return mid; end if;

  insert into public.family_members(id,network_id,full_name,generation_level,profile_status,profile_visibility,contact_visibility,gender)
  values(gen_random_uuid(),nid,left(trim(p_full_name),150),3,'approved','member','admin',p_gender)
  returning id into mid;

  update public.network_memberships set member_id=mid where network_id=nid and user_id=uid and status='active';
  update public.profiles set member_id=mid,active_network_id=nid,updated_at=now() where id=uid;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,uid,'family_creator_profile_added',jsonb_build_object('member_id',mid));
  return mid;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.add_network_activity_comment(p_activity_id uuid, p_body text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id(); rid uuid; begin
 if not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501';end if;
 if length(trim(coalesce(p_body,'')))<1 then raise exception 'Comment is required.';end if;
 if not exists(select 1 from public.network_activities where id=p_activity_id and network_id=nid) then raise exception 'Activity not found.';end if;
 insert into public.network_activity_comments(activity_id,network_id,user_id,body) values(p_activity_id,nid,auth.uid(),left(trim(p_body),1000)) returning id into rid;return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.add_network_ballot_option(p_ballot_id uuid, p_label text, p_description text DEFAULT NULL::text, p_candidate_entity_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();rid uuid;ord int;begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;
 if not exists(select 1 from public.network_ballots where id=p_ballot_id and network_id=nid and status='draft') then raise exception 'Draft ballot not found.';end if;
 if p_candidate_entity_id is not null and not exists(select 1 from public.network_entities where id=p_candidate_entity_id and network_id=nid and kind='person') then raise exception 'Candidate is not a person in this network.';end if;
 select coalesce(max(sort_order),0)+10 into ord from public.network_ballot_options where ballot_id=p_ballot_id;
 insert into public.network_ballot_options(network_id,ballot_id,label,description,candidate_entity_id,sort_order) values(nid,p_ballot_id,left(trim(p_label),180),nullif(trim(coalesce(p_description,'')),''),p_candidate_entity_id,ord) returning id into rid;return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.add_network_post_comment(p_activity_id uuid, p_body text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  nid uuid:=public.current_network_id();
  postrow public.network_activities%rowtype;
  comment_id uuid;
  notification_id uuid;
begin
  if auth.uid() is null or nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501'; end if;
  if length(trim(coalesce(p_body,'')))<1 then raise exception 'Comment is required.' using errcode='22023'; end if;
  select * into postrow from public.network_activities
    where id=p_activity_id and network_id=nid and coalesce(metadata->>'content_kind','')='post';
  if not found then raise exception 'Post not found.' using errcode='P0002'; end if;
  insert into public.network_activity_comments(activity_id,network_id,user_id,body)
  values(p_activity_id,nid,auth.uid(),left(trim(p_body),1000)) returning id into comment_id;

  if postrow.created_by is not null and postrow.created_by<>auth.uid() then
    notification_id:=public.create_network_notification(
      nid,postrow.created_by,'community_post_comment','New comment · '||left(postrow.title,120),left(trim(p_body),500),
      'community','activity',p_activity_id,'normal',jsonb_build_object('surface','community','category','posts','comment_id',comment_id),auth.uid()
    );
  end if;
  return jsonb_build_object('comment_id',comment_id,'notification_id',notification_id);
end $function$
;

CREATE OR REPLACE FUNCTION public.add_platform_owner_by_email(p_email text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  v_target uuid;
begin
  if not public.is_platform_owner() then
    raise exception 'Platform owner access is required.' using errcode='42501';
  end if;
  select id into v_target from auth.users where lower(email)=lower(trim(p_email)) limit 1;
  if v_target is null then
    raise exception 'No Family Network account was found for that email. Ask them to create/sign in to an account first.' using errcode='P0002';
  end if;
  insert into public.platform_owners(user_id) values(v_target) on conflict(user_id) do nothing;
  if found then
    insert into public.platform_owner_audit(actor_user_id,target_user_id,action) values(auth.uid(),v_target,'added');
  end if;
  return v_target;
end $function$
;

CREATE OR REPLACE FUNCTION public.apply_alpha_day1_launch_preset()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_changed integer:=0; r record; v_new_state varchar;
begin
  if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
  for r in select feature_key,rollout_state from public.platform_feature_flags loop
    v_new_state:=case
      when r.feature_key in ('core.home','core.family','core.directory','core.profile','core.guide','celebrate.special_days','remember.memories','remember.history','remember.family_pulse','remember.quiet_digest','contribute.help_family','advanced.relationships','admin.center','admin.import','admin.governance') then 'released'
      when r.feature_key in ('connect.gatherings','share.family','contribute.branch_intake') then 'pilot'
      else 'test'
    end;
    if r.rollout_state is distinct from v_new_state then
      update public.platform_feature_flags set rollout_state=v_new_state,pilot_network_ids=case when v_new_state='pilot' then pilot_network_ids else '{}'::uuid[] end,updated_by=auth.uid(),updated_at=now() where feature_key=r.feature_key;
      v_changed:=v_changed+1;
    end if;
  end loop;
  return v_changed;
end $function$
;

CREATE OR REPLACE FUNCTION public.archive_owned_network(p_network_id uuid, p_confirm_name text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); nname text; next_id uuid;
begin
 if uid is null then raise exception 'Sign in required.' using errcode='42501'; end if;
 select n.name into nname from public.networks n join public.network_memberships nm on nm.network_id=n.id
 where n.id=p_network_id and nm.user_id=uid and nm.status='active' and nm.role='owner';
 if nname is null then raise exception 'Only the network Owner can archive this network.' using errcode='42501'; end if;
 if trim(coalesce(p_confirm_name,''))<>nname then raise exception 'Network name confirmation does not match.' using errcode='22023'; end if;
 delete from public.network_archive_membership_state where network_id=p_network_id;
 insert into public.network_archive_membership_state(network_id,user_id,previous_status)
 select network_id,user_id,status from public.network_memberships where network_id=p_network_id;
 update public.networks set status='archived',updated_at=now() where id=p_network_id;
 update public.network_memberships set status='suspended' where network_id=p_network_id and status='active';
 select nm.network_id into next_id from public.network_memberships nm join public.networks n on n.id=nm.network_id and n.status='active'
 where nm.user_id=uid and nm.status='active' and nm.network_id<>p_network_id order by nm.joined_at desc limit 1;
 update public.profiles set active_network_id=next_id,member_id=case when next_id is null then null else member_id end,updated_at=now()
 where active_network_id=p_network_id;
 return next_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.archive_productized_network(p_confirm_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$begin perform public.archive_owned_network(public.current_network_id(),p_confirm_name);end$function$
;

CREATE OR REPLACE FUNCTION public.assign_fca_role(p_year_id uuid, p_person_entity_id uuid, p_role_catalog_id uuid, p_starts_on date, p_ends_on date, p_notes text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id(); rid uuid; begin
 if not public.is_network_admin(nid) then raise exception 'Association admin access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_entities where id=p_person_entity_id and network_id=nid and kind='person') then raise exception 'Person not found.';end if;
 if not exists(select 1 from public.family_association_role_catalog where id=p_role_catalog_id and network_id=nid and active) then raise exception 'Role not found.';end if;
 insert into public.family_association_role_history(network_id,membership_year_id,person_entity_id,role_catalog_id,starts_on,ends_on,notes) values(nid,p_year_id,p_person_entity_id,p_role_catalog_id,p_starts_on,p_ends_on,nullif(trim(coalesce(p_notes,'')),'')) returning id into rid;return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.audit_platform_feature_rollout()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if old.rollout_state is distinct from new.rollout_state
     or old.pilot_network_ids is distinct from new.pilot_network_ids
     or old.announcement_version is distinct from new.announcement_version then
    insert into public.platform_feature_rollout_audit(feature_key,bundle_key,previous_state,new_state,pilot_network_ids,announced,changed_by,changed_at)
    values(new.feature_key,new.bundle_key,old.rollout_state,new.rollout_state,new.pilot_network_ids,new.announcement_version>old.announcement_version,new.updated_by,now());
  end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.authorize_launch_demo_seed(p_dataset_version text, p_confirm_network_name text, p_allow_real_network boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

CREATE OR REPLACE FUNCTION public.can_read_community_media(object_name text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select auth.uid() is not null and (
   (object_name like public.current_network_id()::text||'/%' and public.is_network_member(public.current_network_id())) or object_name like 'community/'||auth.uid()::text||'/%'
 ) and not exists(select 1 from public.network_media_assets z where z.network_id=public.current_network_id() and z.lifecycle_state in ('delete_pending','deleted') and (z.object_path=object_name or z.thumbnail_path=object_name)) and (
   public.is_network_admin() or object_name like public.current_network_id()::text||'/community/'||auth.uid()::text||'/%' or object_name like 'community/'||auth.uid()::text||'/%'
   or exists(select 1 from public.network_media_assets a where a.network_id=public.current_network_id() and a.bucket='community-media' and a.lifecycle_state in ('active','archived') and a.media_kind<>'complaint' and (a.object_path=object_name or a.thumbnail_path=object_name) and public.is_network_member(a.network_id))
   or exists(select 1 from public.memories m left join public.family_members fm on fm.id=m.member_id and fm.network_id=m.network_id where m.network_id=public.current_network_id() and (m.photo_url=object_name or m.photo_url like '%/community-media/'||object_name) and m.visibility<>'admin' and (m.member_id is null or (fm.profile_status='approved' and fm.profile_visibility<>'admin')))
   or exists(select 1 from public.hs_complaints c cross join lateral jsonb_array_elements(c.attachments) a where c.network_id=public.current_network_id() and coalesce(a->>'path',a->>'url')=object_name and (c.created_by=auth.uid() or c.assigned_to=auth.uid() or public.is_network_admin(c.network_id)))
 );
$function$
;

CREATE OR REPLACE FUNCTION public.can_read_profile_photo(object_name text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select auth.uid() is not null and (
   (object_name like public.current_network_id()::text||'/%' and public.is_network_member(public.current_network_id())) or object_name like 'profiles/'||auth.uid()::text||'/%'
 ) and not exists(select 1 from public.network_media_assets z where z.network_id=public.current_network_id() and z.lifecycle_state in ('delete_pending','deleted') and (z.object_path=object_name or z.thumbnail_path=object_name)) and (
   public.is_network_admin() or object_name like public.current_network_id()::text||'/profiles/'||auth.uid()::text||'/%' or object_name like 'profiles/'||auth.uid()::text||'/%'
   or exists(select 1 from public.network_media_assets a where a.network_id=public.current_network_id() and a.bucket='profile-photos' and a.lifecycle_state in ('active','archived') and (a.object_path=object_name or a.thumbnail_path=object_name) and public.is_network_member(a.network_id))
   or exists(select 1 from public.family_members fm where fm.network_id=public.current_network_id() and (fm.photo_url=object_name or fm.photo_url like '%/profile-photos/'||object_name) and fm.profile_status='approved' and fm.profile_visibility<>'admin')
 );
$function$
;

CREATE OR REPLACE FUNCTION public.cancel_community_introduction(p_request_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 update public.community_introduction_requests set status='cancelled',updated_at=now() where id=p_request_id and requester_user_id=auth.uid() and status='pending';
 if not found then raise exception 'Pending introduction request not found.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.cancel_federated_introduction_v2(p_introduction_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 update public.federated_introductions set status='cancelled',updated_at=now() where id=p_introduction_id and requester_user_id=auth.uid() and status='pending';
 if not found then raise exception 'Pending introduction not found or not owned by you.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.cast_network_ballot_vote(p_ballot_id uuid, p_option_ids uuid[])
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();b public.network_ballots%rowtype;token uuid:=gen_random_uuid();receipt uuid;choice uuid;choices uuid[];begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501';end if;select * into b from public.network_ballots where id=p_ballot_id and network_id=nid and status='open';if not found then raise exception 'Voting is not open.';end if;
 if b.opens_at is not null and now()<b.opens_at then raise exception 'Voting has not opened yet.';end if;if b.closes_at is not null and now()>b.closes_at then raise exception 'Voting has closed.';end if;
 if not exists(select 1 from public.network_ballot_eligibility where ballot_id=b.id and user_id=auth.uid()) then raise exception 'You are not eligible to vote in this ballot.' using errcode='42501';end if;
 if exists(select 1 from public.network_ballot_participation where ballot_id=b.id and user_id=auth.uid()) then raise exception 'Your vote has already been recorded.' using errcode='23505';end if;
 select array_agg(distinct x) into choices from unnest(coalesce(p_option_ids,'{}'::uuid[])) x;if choices is null or cardinality(choices)<1 or cardinality(choices)>b.max_choices then raise exception 'Choose between 1 and % option(s).',b.max_choices;end if;
 if exists(select 1 from unnest(choices) x where not exists(select 1 from public.network_ballot_options o where o.id=x and o.ballot_id=b.id and o.network_id=nid)) then raise exception 'One or more choices are invalid.';end if;
 insert into public.network_ballot_participation(network_id,ballot_id,user_id,choice_count) values(nid,b.id,auth.uid(),cardinality(choices)) returning receipt_id into receipt;
 foreach choice in array choices loop insert into public.network_ballot_votes(network_id,ballot_id,option_id,anonymous_token,voter_user_id) values(nid,b.id,choice,token,case when b.secret_ballot then null else auth.uid() end);end loop;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_ballot_vote_cast',jsonb_build_object('ballot_id',b.id,'choice_count',cardinality(choices),'secret_ballot',b.secret_ballot));return receipt;
end $function$
;

CREATE OR REPLACE FUNCTION public.claim_productized_network_entity_by_verified_email(p_entity_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_owner uuid; v_email text; v_kind text;
begin
 if auth.uid() is null or not public.is_network_member(v_network) then raise exception 'Network membership required.' using errcode='42501'; end if;
 select e.owner_user_id,e.metadata->>'email',n.vertical_kind into v_owner,v_email,v_kind
 from public.network_entities e join public.networks n on n.id=e.network_id
 where e.id=p_entity_id and e.network_id=v_network;
 if not found or not public.g8_productized_vertical(v_kind) then raise exception 'Claimable entity not found.' using errcode='22023'; end if;
 if v_owner is not null and v_owner<>auth.uid() then raise exception 'This entity is already claimed.' using errcode='23505'; end if;
 if exists(select 1 from public.network_entities mine where mine.network_id=v_network and mine.owner_user_id=auth.uid() and mine.id<>p_entity_id) then raise exception 'Your account is already linked to another entity in this network.' using errcode='23505'; end if;
 if lower(trim(coalesce(v_email,'')))<>lower(trim(coalesce(auth.jwt()->>'email',''))) or nullif(trim(coalesce(v_email,'')),'') is null then raise exception 'Verified email does not match this entity.' using errcode='42501'; end if;
 update public.network_entities set owner_user_id=auth.uid(),updated_at=now() where id=p_entity_id and network_id=v_network;
 insert into public.audit_log(network_id,actor_id,action,details) values(v_network,auth.uid(),'productized_entity_claimed',jsonb_build_object('entity_id',p_entity_id));
 return p_entity_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.claim_profile_by_verified_email(p_member_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); nid uuid; mail text;
begin
 select email into mail from auth.users where id=uid and email_confirmed_at is not null;
 if mail is null then raise exception 'Confirm your email before claiming a profile.' using errcode='42501'; end if;
 select network_id into nid from public.family_members where id=p_member_id and profile_status='approved' and lower(trim(coalesce(email,'')))=lower(trim(mail));
 if nid is null then raise exception 'No matching unclaimed profile was found for your verified email.' using errcode='P0002'; end if;
 if exists(select 1 from public.network_memberships where network_id=nid and member_id=p_member_id and user_id<>uid and status='active') then raise exception 'This family profile is already claimed.' using errcode='23505'; end if;
 insert into public.network_memberships(network_id,user_id,role,status,member_id) values(nid,uid,'member','active',p_member_id)
 on conflict(network_id,user_id) do update set status='active',member_id=excluded.member_id;
 update public.profiles set active_network_id=nid,member_id=p_member_id,updated_at=now() where id=uid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,uid,'profile_claimed_by_verified_email',jsonb_build_object('member_id',p_member_id));
 return nid;
end;$function$
;

CREATE OR REPLACE FUNCTION public.clear_family_lobby_on_activation()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  if new.active_network_id is not null then new.family_lobby_mode:=false; end if;
  return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.close_network_ballot(p_ballot_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();begin if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;update public.network_ballots set status='closed',closes_at=coalesce(closes_at,now()),updated_at=now() where id=p_ballot_id and network_id=nid and status='open';if not found then raise exception 'Open ballot not found.';end if;insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_ballot_closed',jsonb_build_object('ballot_id',p_ballot_id));end $function$
;

CREATE OR REPLACE FUNCTION public.commit_family_intake_branch(p_access_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); a public.family_intake_access%rowtype; p record; r record; canonical_id uuid; other_id uuid; rel_id uuid; base_generation integer:=4; matched_base integer; created_count integer:=0; matched_count integer:=0; rel_count integer:=0;
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family admin access is required.' using errcode='42501'; end if;
  select * into a from public.family_intake_access where id=p_access_id and network_id=nid for update;
  if a.id is null or a.status<>'submitted' then raise exception 'This branch is not waiting for commit.' using errcode='P0002'; end if;
  if exists(select 1 from public.family_intake_people p0 where p0.access_id=a.id and p0.status='ambiguous' and p0.matched_member_id is null) or exists(select 1 from public.family_intake_match_candidates c join public.family_intake_people p0 on p0.id=c.staged_person_id where p0.access_id=a.id and c.score>=65 and c.status in ('open','unsure')) then raise exception 'Resolve medium/high identity matches before committing this branch.' using errcode='23514'; end if;
  select fm.generation_level-p0.generation_offset into matched_base
  from public.family_intake_people p0 join public.family_members fm on fm.id=p0.matched_member_id
  where p0.access_id=a.id and p0.matched_member_id is not null limit 1;
  if matched_base is not null then base_generation:=greatest(3,matched_base); end if;
  if base_generation + (select coalesce(min(generation_offset),0) from public.family_intake_people where access_id=a.id) < 1 then base_generation:=1-(select min(generation_offset) from public.family_intake_people where access_id=a.id); end if;

  for p in select * from public.family_intake_people where access_id=a.id order by generation_offset,id loop
    canonical_id:=p.matched_member_id;
    if canonical_id is null then
      -- Accepted cross-branch identity can reuse/establish one canonical person.
      select sp.matched_member_id into canonical_id
      from public.family_intake_match_candidates c join public.family_intake_people sp on sp.id=c.candidate_staged_person_id
      where c.staged_person_id=p.id and c.status='accepted' and c.candidate_staged_person_id is not null limit 1;
    end if;
    if canonical_id is null then
      insert into public.family_members(network_id,full_name,date_of_birth,generation_level,city,gender,profile_status,profile_visibility,contact_visibility)
      values(nid,p.full_name,p.date_of_birth,greatest(1,base_generation+p.generation_offset),p.city,p.gender,'approved','member','admin') returning id into canonical_id;
      created_count:=created_count+1;
      -- If owner accepted a cross-branch duplicate, bind that other staged record to the same new member too.
      update public.family_intake_people sp set matched_member_id=canonical_id,status='matched',match_confidence=100
      where sp.id in (select c.candidate_staged_person_id from public.family_intake_match_candidates c where c.staged_person_id=p.id and c.status='accepted' and c.candidate_staged_person_id is not null) and sp.matched_member_id is null;
    else
      matched_count:=matched_count+1;
      -- Preserve contradictory facts instead of overwriting canonical data.
      insert into public.family_intake_conflicts(session_id,network_id,staged_person_id,member_id,field_name,existing_value,reported_value)
      select a.session_id,nid,p.id,canonical_id,'date_of_birth',fm.date_of_birth::text,p.date_of_birth::text from public.family_members fm where fm.id=canonical_id and p.date_of_birth is not null and fm.date_of_birth is not null and fm.date_of_birth<>p.date_of_birth on conflict do nothing;
      insert into public.family_intake_conflicts(session_id,network_id,staged_person_id,member_id,field_name,existing_value,reported_value)
      select a.session_id,nid,p.id,canonical_id,'city',fm.city,p.city from public.family_members fm where fm.id=canonical_id and nullif(trim(p.city),'') is not null and nullif(trim(fm.city),'') is not null and lower(trim(fm.city))<>lower(trim(p.city)) on conflict do nothing;
      insert into public.family_intake_conflicts(session_id,network_id,staged_person_id,member_id,field_name,existing_value,reported_value)
      select a.session_id,nid,p.id,canonical_id,'gender',fm.gender,p.gender from public.family_members fm where fm.id=canonical_id and p.gender is not null and fm.gender is not null and fm.gender<>p.gender on conflict do nothing;
    end if;
    update public.family_intake_people set matched_member_id=canonical_id,status='committed' where id=p.id;
  end loop;

  for r in select * from public.family_intake_relationships where access_id=a.id and status='staged' loop
    select matched_member_id into canonical_id from public.family_intake_people where id=r.from_staged_person_id;
    select matched_member_id into other_id from public.family_intake_people where id=r.to_staged_person_id;
    if canonical_id is null or other_id is null then raise exception 'Branch identity mapping is incomplete.' using errcode='23514'; end if;
    if canonical_id<>other_id then
      begin
        insert into public.family_relationships(network_id,person_id,related_person_id,relationship_type)
        values(nid,case when r.relationship_type='spouse' and canonical_id::text>other_id::text then other_id else canonical_id end,case when r.relationship_type='spouse' and canonical_id::text>other_id::text then canonical_id else other_id end,r.relationship_type)
        on conflict(person_id,related_person_id,relationship_type) do nothing
        returning id into rel_id;
        if rel_id is not null then rel_count:=rel_count+1; update public.family_intake_relationships set status='committed',canonical_relationship_id=rel_id where id=r.id; else update public.family_intake_relationships set status='committed' where id=r.id; end if;
      exception when check_violation or foreign_key_violation then
        raise exception 'A staged relationship conflicts with the existing family graph. Review this branch before committing.' using errcode='23514';
      end;
    else update public.family_intake_relationships set status='rejected' where id=r.id; end if;
  end loop;
  update public.family_intake_access set status='committed',committed_at=now() where id=a.id;
  if not exists(select 1 from public.family_intake_access x where x.session_id=a.session_id and x.status='submitted') then update public.family_intake_sessions set status='review',updated_at=now() where id=a.session_id; end if;
  insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'family_intake_branch_committed',jsonb_build_object('session_id',a.session_id,'access_id',a.id,'created_people',created_count,'matched_people',matched_count,'relationships',rel_count));
  insert into public.family_intake_events(network_id,session_id,access_id,event_name,properties,actor_id) values(nid,a.session_id,a.id,'branch_committed',jsonb_build_object('created_people',created_count,'matched_people',matched_count,'relationships',rel_count),auth.uid());
  return jsonb_build_object('created_people',created_count,'matched_people',matched_count,'relationships',rel_count);
end $function$
;

CREATE OR REPLACE FUNCTION public.create_community_space(p_name text, p_slug text, p_space_type text DEFAULT 'community'::text, p_parent_id uuid DEFAULT NULL::uuid, p_city text DEFAULT NULL::text, p_state text DEFAULT NULL::text, p_country text DEFAULT 'India'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare rid uuid;
begin
  if not public.is_platform_owner() then raise exception 'Platform owner access required.' using errcode='42501'; end if;
  if length(trim(p_name))<2 or length(trim(p_slug))<2 then raise exception 'Community name and slug are required.' using errcode='22023'; end if;
  insert into public.community_spaces(parent_id,name,slug,space_type,city,state,country,created_by)
  values(p_parent_id,trim(p_name),lower(regexp_replace(trim(p_slug),'[^a-zA-Z0-9]+','-','g')),p_space_type,p_city,p_state,p_country,auth.uid()) returning id into rid;
  return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_family(p_name text, p_slug text DEFAULT NULL::text, p_description text DEFAULT ''::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  uid uuid:=auth.uid(); nid uuid; base_slug text; final_slug text; suffix integer:=1; approval_required boolean:=false;
begin
  if uid is null then raise exception 'Sign in is required to create a family.' using errcode='42501'; end if;
  select coalesce(family_creation_approval_required,false) into approval_required from public.platform_onboarding_settings where id='default';
  if not public.is_platform_owner() and approval_required then
    raise exception 'Family creation requires platform-owner approval.' using errcode='42501';
  end if;
  if length(trim(coalesce(p_name,'')))<2 then raise exception 'Please give your family a name.' using errcode='22023'; end if;
  base_slug:=public.slugify_family_name(coalesce(nullif(trim(p_slug),''),p_name));
  if length(base_slug)<2 then base_slug:='family'; end if;
  base_slug:=left(base_slug,60); final_slug:=base_slug;
  while exists(select 1 from public.networks where slug=final_slug) loop suffix:=suffix+1; final_slug:=left(base_slug,54)||'-'||suffix::text; end loop;
  insert into public.networks(name,slug,created_by,photo_upload_enabled)
  values(left(trim(p_name),180),final_slug,uid,false) returning id into nid;
  insert into public.network_memberships(network_id,user_id,role,status) values(nid,uid,'owner','active');
  insert into public.network_settings(id,network_id,name,description,entity_label,entity_label_plural,level_label,level_label_plural,parent_label,child_label,peer_label,network_template,photo_upload_enabled)
  values('network',nid,left(trim(p_name),180),coalesce(p_description,''),'Member','Members','Generation','Generations','Parent','Child','Spouse','family',false);
  update public.profiles set active_network_id=nid,member_id=null,updated_at=now() where id=uid;
  return nid;
end;$function$
;

CREATE OR REPLACE FUNCTION public.create_family_intake_link(p_session_id uuid, p_representative_label text DEFAULT NULL::text, p_days integer DEFAULT 30)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); raw_token text; aid uuid;
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family admin access is required.' using errcode='42501'; end if;
  if not exists(select 1 from public.family_intake_sessions s where s.id=p_session_id and s.network_id=nid and s.status in ('draft','collecting','review')) then raise exception 'Intake session not found.' using errcode='P0002'; end if;
  raw_token:=encode(gen_random_bytes(32),'hex');
  insert into public.family_intake_access(session_id,network_id,token_hash,representative_label,created_by,expires_at)
  values(p_session_id,nid,digest(raw_token,'sha256'),nullif(trim(p_representative_label),''),auth.uid(),now()+make_interval(days=>greatest(1,least(coalesce(p_days,30),90)))) returning id into aid;
  insert into public.family_intake_events(network_id,session_id,access_id,event_name,actor_id) values(nid,p_session_id,aid,'intake_link_created',auth.uid());
  return raw_token;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_family_intake_session(p_title text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); sid uuid;
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family admin access is required.' using errcode='42501'; end if;
  if not public.s3a_intake_enabled(nid,auth.uid()) then raise exception 'Distributed family intake is not enabled for this family yet.' using errcode='42501'; end if;
  insert into public.family_intake_sessions(network_id,title,created_by)
  values(nid,coalesce(nullif(trim(p_title),''),'Build our family together'),auth.uid()) returning id into sid;
  insert into public.family_intake_events(network_id,session_id,event_name,actor_id) values(nid,sid,'intake_created',auth.uid());
  return sid;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_my_federated_request(p_network_id uuid, p_umbrella_id uuid, p_scope_key text, p_title text, p_description text DEFAULT NULL::text, p_location_label text DEFAULT NULL::text, p_tags text[] DEFAULT '{}'::text[])
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare rid uuid; sk text:=lower(trim(p_scope_key));
begin
 if auth.uid() is null or not public.is_network_member(p_network_id) then raise exception 'Active source-network membership required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_title,'')))<3 then raise exception 'Request title is required.' using errcode='22023'; end if;
 if coalesce(array_length(p_tags,1),0)>12 then raise exception 'Use at most 12 request tags.' using errcode='22023'; end if;
 if not exists(select 1 from public.network_umbrella_affiliations a join public.federation_umbrellas u on u.id=a.umbrella_id and u.status='active' where a.network_id=p_network_id and a.umbrella_id=p_umbrella_id and a.status='approved') then raise exception 'Approved umbrella affiliation required.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_passports p where p.network_id=p_network_id and p.visibility in ('federation','public') and exists(select 1 from unnest(p.participation_scopes) x where lower(x)=sk)) then raise exception 'The source Network Passport must currently declare this purpose.' using errcode='42501'; end if;
 insert into public.federated_requests(requester_user_id,source_network_id,umbrella_id,scope_key,title,description,location_label,tags)
 values(auth.uid(),p_network_id,p_umbrella_id,sk,trim(p_title),left(nullif(trim(coalesce(p_description,'')),''),1200),nullif(trim(coalesce(p_location_label,'')),''),coalesce(p_tags,'{}')) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_network_activity(p_activity_type text, p_title text, p_body text DEFAULT NULL::text, p_starts_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_ends_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_place text DEFAULT NULL::text, p_visibility text DEFAULT 'members'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_id uuid;
begin
 if not public.is_network_member(v_network) then raise exception 'Membership required.' using errcode='42501'; end if;
 if p_activity_type in ('event','announcement') and not public.is_network_admin(v_network) then raise exception 'Network admin access required for events and announcements.' using errcode='42501'; end if;
 if p_activity_type not in ('event','memory','milestone','announcement') then raise exception 'Invalid activity type.'; end if;
 if p_visibility not in ('members','private') then raise exception 'Invalid visibility.'; end if;
 if length(trim(coalesce(p_title,'')))<2 then raise exception 'Title is required.'; end if;
 insert into public.network_activities(network_id,activity_type,title,body,starts_at,ends_at,place,visibility,created_by)
 values(v_network,p_activity_type,trim(p_title),nullif(trim(p_body),''),p_starts_at,p_ends_at,nullif(trim(p_place),''),p_visibility,auth.uid()) returning id into v_id;
 return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_network_fund(p_name text, p_fund_kind text DEFAULT 'general'::text, p_purpose text DEFAULT NULL::text, p_target_amount numeric DEFAULT NULL::numeric, p_opening_balance numeric DEFAULT 0, p_visibility text DEFAULT 'members'::text, p_membership_year_id uuid DEFAULT NULL::uuid, p_activity_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); rid uuid;
begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_name,'')))<2 then raise exception 'Fund name is required.' using errcode='22023'; end if;
 if p_fund_kind not in ('general','membership','event','donation','reserve','maintenance','other') then raise exception 'Invalid fund kind.' using errcode='22023'; end if;
 if p_visibility not in ('admins','members','highlighted') then raise exception 'Invalid fund visibility.' using errcode='22023'; end if;
 if p_activity_id is not null and not exists(select 1 from public.network_activities a where a.id=p_activity_id and a.network_id=nid) then raise exception 'Event/activity not found in this network.' using errcode='22023'; end if;
 insert into public.network_funds(network_id,name,fund_kind,purpose,membership_year_id,activity_id,target_amount,opening_balance,visibility,created_by)
 values(nid,left(trim(p_name),160),p_fund_kind,nullif(trim(coalesce(p_purpose,'')),''),p_membership_year_id,p_activity_id,p_target_amount,coalesce(p_opening_balance,0),p_visibility,auth.uid()) returning id into rid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_fund_created',jsonb_build_object('fund_id',rid,'kind',p_fund_kind,'name',trim(p_name)));
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_network_group(p_name text, p_group_type text DEFAULT 'group'::text, p_description text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_id uuid;
begin
 if not public.is_network_admin(v_network) then raise exception 'Network admin access required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_name,'')))<2 then raise exception 'Group name is required.'; end if;
 insert into public.network_groups(network_id,name,group_type,description,created_by) values(v_network,trim(p_name),coalesce(nullif(trim(p_group_type),''),'group'),nullif(trim(p_description),''),auth.uid()) returning id into v_id;
 return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_network_post(p_title text, p_body text DEFAULT NULL::text, p_importance text DEFAULT 'normal'::text, p_notify_all boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  nid uuid:=public.current_network_id();
  activity_id uuid;
  target uuid;
  notification_id uuid;
  notification_ids uuid[]:=array[]::uuid[];
  meta jsonb;
begin
  if auth.uid() is null or nid is null or not public.is_network_member(nid) then
    raise exception 'Network membership required.' using errcode='42501';
  end if;
  if length(trim(coalesce(p_title,'')))<2 then raise exception 'Post title is required.' using errcode='22023'; end if;
  if p_importance not in ('normal','important','urgent') then raise exception 'Invalid importance.' using errcode='22023'; end if;
  if (p_importance<>'normal' or p_notify_all) and not public.is_network_admin(nid) then
    raise exception 'Only a network administrator can publish important or urgent broadcasts.' using errcode='42501';
  end if;

  meta:=jsonb_build_object(
    'content_kind','post',
    'importance',p_importance,
    'notify_all',coalesce(p_notify_all,false),
    'category','posts'
  );
  insert into public.network_activities(network_id,activity_type,title,body,visibility,metadata,created_by)
  values(nid,'announcement',left(trim(p_title),220),nullif(trim(coalesce(p_body,'')),''),'members',meta,auth.uid())
  returning id into activity_id;

  if p_notify_all then
    for target in
      select nm.user_id from public.network_memberships nm
      where nm.network_id=nid and nm.status='active' and nm.user_id<>auth.uid()
    loop
      notification_id:=public.create_network_notification(
        nid,target,'community_post_broadcast',
        case when p_importance='urgent' then 'Urgent community update' else 'Important community update' end,
        left(trim(p_title),180),
        'community','activity',activity_id,
        case when p_importance='urgent' then 'urgent' else 'high' end,
        jsonb_build_object('surface','community','category','posts','importance',p_importance),auth.uid()
      );
      notification_ids:=array_append(notification_ids,notification_id);
    end loop;
  end if;

  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),'network_post_created',jsonb_build_object('activity_id',activity_id,'importance',p_importance,'notify_all',p_notify_all));

  return jsonb_build_object('activity_id',activity_id,'notification_ids',to_jsonb(notification_ids));
end $function$
;

CREATE OR REPLACE FUNCTION public.create_productized_network(p_vertical_kind text, p_name text, p_context_value text, p_description text DEFAULT ''::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid;v_slug text;v_base text;v_entity text;v_entities text;v_level text;v_parent text;v_child text;v_peer text;v_context_label text;
begin
 if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501';end if;
 if not public.g8_productized_vertical(p_vertical_kind) then raise exception 'Unsupported productized network template.' using errcode='22023';end if;
 if length(trim(coalesce(p_name,'')))<2 or length(trim(coalesce(p_context_value,'')))<2 then raise exception 'Network name and context are required.';end if;
 v_base:=lower(regexp_replace(trim(p_name),'[^a-zA-Z0-9]+','-','g'));v_base:=trim(both '-' from v_base);if v_base='' then v_base:='network';end if;v_slug:=v_base;
 while exists(select 1 from public.networks where slug=v_slug) loop v_slug:=v_base||'-'||substr(gen_random_uuid()::text,1,6);end loop;
 if p_vertical_kind='housing-society' then v_entity:='Flat / Unit';v_entities:='Flats / Units';v_level:='Floor';v_parent:='Owner';v_child:='Resident';v_peer:='Neighbour';v_context_label:='Society / residential community';
 elsif p_vertical_kind='family-association' then v_entity:='Family';v_entities:='Families';v_level:='Membership Year';v_parent:='Representative';v_child:='Family Member';v_peer:='Community member';v_context_label:='Chapter / community';
 elsif p_vertical_kind='association' then v_entity:='Family / Household';v_entities:='Families / Households';v_level:='Membership';v_parent:='Representative';v_child:='Member';v_peer:='Community peer';v_context_label:='Association / chapter';
 elsif p_vertical_kind='organization' then v_entity:='Person';v_entities:='People';v_level:='Team';v_parent:='Manager';v_child:='Direct report';v_peer:='Colleague';v_context_label:='Organization / company';
 elsif p_vertical_kind='business-trust' then v_entity:='Business';v_entities:='Businesses';v_level:='Category';v_parent:='Recommender';v_child:='Recommended';v_peer:='Partner';v_context_label:='Network purpose / ecosystem';
 elsif p_vertical_kind='franchise' then v_entity:='Location';v_entities:='Locations';v_level:='Region';v_parent:='Owner';v_child:='Location';v_peer:='Peer location';v_context_label:='Brand / franchise system';
 else v_entity:='Professional';v_entities:='Professionals';v_level:='Expertise';v_parent:='Referrer';v_child:='Referred professional';v_peer:='Collaborator';v_context_label:='Association / professional community';end if;
 insert into public.networks(name,slug,created_by,vertical_kind) values(trim(p_name),v_slug,auth.uid(),p_vertical_kind) returning id into v_id;
 insert into public.network_memberships(network_id,user_id,role,status) values(v_id,auth.uid(),'owner','active');
 insert into public.network_settings(network_id,id,name,description,entity_label,entity_label_plural,level_label,level_label_plural,parent_label,child_label,peer_label,network_template,vertical_kind) values(v_id,'network',trim(p_name),coalesce(p_description,''),v_entity,v_entities,v_level,v_level||'s',v_parent,v_child,v_peer,p_vertical_kind,p_vertical_kind);
 insert into public.productized_network_settings(network_id,template_id,context_label,context_value,description) values(v_id,p_vertical_kind,v_context_label,trim(p_context_value),nullif(trim(coalesce(p_description,'')),''));
 perform public.g8_seed_productized_structure(v_id,p_vertical_kind);update public.profiles set active_network_id=v_id,updated_at=now() where id=auth.uid();
 insert into public.audit_log(network_id,actor_id,action,details) values(v_id,auth.uid(),'productized_network_created',jsonb_build_object('vertical_kind',p_vertical_kind,'context',trim(p_context_value)));return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_productized_network_relationship(p_from_entity_id uuid, p_to_entity_id uuid, p_relationship_type text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_kind text; v_id uuid;
begin
 if not public.is_network_admin(v_network) then raise exception 'Network admin access required.' using errcode='42501'; end if;
 select vertical_kind into v_kind from public.networks where id=v_network;
 if not public.g8_allowed_relationship(v_kind,p_relationship_type) then raise exception 'Relationship type is not allowed for this network.' using errcode='22023'; end if;
 insert into public.network_entity_relationships(network_id,from_entity_id,to_entity_id,relationship_type,metadata,created_by) values(v_network,p_from_entity_id,p_to_entity_id,p_relationship_type,coalesce(p_metadata,'{}'),auth.uid()) on conflict(network_id,from_entity_id,to_entity_id,relationship_type) do update set metadata=excluded.metadata,created_by=excluded.created_by returning id into v_id; return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.current_family_role(p_network_id uuid DEFAULT current_network_id())
 RETURNS character varying
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select nm.role
  from public.network_memberships nm
  where nm.network_id=p_network_id
    and nm.user_id=auth.uid()
    and nm.status='active'
  limit 1;
$function$
;

CREATE OR REPLACE FUNCTION public.current_network_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when coalesce(p.family_lobby_mode,false) then null else coalesce(
    (
      select p.active_network_id
      from public.network_memberships active_nm
      where active_nm.network_id=p.active_network_id
        and active_nm.user_id=p.id
        and active_nm.status='active'
      limit 1
    ),
    (
      select nm.network_id
      from public.network_memberships nm
      join public.networks n on n.id=nm.network_id and n.status='active'
      where nm.user_id=p.id and nm.status='active'
      order by nm.joined_at desc
      limit 1
    )
  ) end
  from public.profiles p
  where p.id=auth.uid()
  limit 1;
$function$
;

CREATE OR REPLACE FUNCTION public.decide_family_intake_match(p_candidate_id uuid, p_decision text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); c public.family_intake_match_candidates%rowtype; target_member uuid;
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family admin access is required.' using errcode='42501'; end if;
  if p_decision not in ('same','different','not_sure') then raise exception 'Invalid decision.' using errcode='22023'; end if;
  select * into c from public.family_intake_match_candidates where id=p_candidate_id and network_id=nid;
  if c.id is null then raise exception 'Match candidate not found.' using errcode='P0002'; end if;
  update public.family_intake_match_candidates set status=case p_decision when 'same' then 'accepted' when 'different' then 'rejected' else 'unsure' end where id=c.id;
  insert into public.family_intake_decisions(session_id,network_id,candidate_id,staged_person_id,decision,decision_source,decided_by)
  values(c.session_id,nid,c.id,c.staged_person_id,p_decision,'owner',auth.uid());
  if p_decision='same' then
    target_member:=c.candidate_member_id;
    if target_member is null and c.candidate_staged_person_id is not null then select matched_member_id into target_member from public.family_intake_people where id=c.candidate_staged_person_id; end if;
    if target_member is not null then update public.family_intake_people set matched_member_id=target_member,status='matched',match_confidence=c.score where id=c.staged_person_id; elsif c.candidate_staged_person_id is not null then update public.family_intake_people set status='new',match_confidence=c.score where id=c.staged_person_id; end if;
  elsif p_decision='different' then
    if not exists(select 1 from public.family_intake_match_candidates x where x.staged_person_id=c.staged_person_id and x.status='accepted') then update public.family_intake_people set matched_member_id=null,status='new' where id=c.staged_person_id; end if;
  else update public.family_intake_people set status='ambiguous' where id=c.staged_person_id; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.delete_owned_network_permanently(p_network_id uuid, p_confirm_name text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'storage'
AS $function$
declare uid uuid:=auth.uid(); nname text; next_id uuid; before_report jsonb; after_report jsonb;
begin
 if uid is null then raise exception 'Sign in required.' using errcode='42501'; end if;
 select n.name into nname
 from public.networks n join public.network_memberships nm on nm.network_id=n.id
 where n.id=p_network_id and nm.user_id=uid and nm.status in ('active','suspended') and nm.role='owner';
 if nname is null then raise exception 'Only the network Owner can permanently delete this network.' using errcode='42501'; end if;
 if trim(coalesce(p_confirm_name,''))<>nname then raise exception 'Network name confirmation does not match.' using errcode='22023'; end if;

 before_report:=public.xp0_network_residue_report(p_network_id);
 if coalesce((before_report->>'storageResidue')::bigint,0)>0 then
  raise exception 'Network storage must be purged through the Supabase Storage API before relational deletion. Remaining objects: %',before_report->>'storageResidue' using errcode='P0001';
 end if;

 update public.profiles set active_network_id=null,member_id=null,updated_at=now() where active_network_id=p_network_id;
 delete from public.networks where id=p_network_id;

 after_report:=public.xp0_network_residue_report(p_network_id);
 if not coalesce((after_report->>'clean')::boolean,false) then
  raise exception 'XP-0 purge residue verification failed: %',after_report::text using errcode='P0001';
 end if;
 insert into public.network_purge_receipts(purged_network_id,purged_by,relational_residue,storage_residue,verifier_version)
 values(p_network_id,uid,coalesce((after_report->>'relationalResidue')::bigint,0),coalesce((after_report->>'storageResidue')::bigint,0),'xp0-v2-storage-api');

 select nm.network_id into next_id from public.network_memberships nm join public.networks n on n.id=nm.network_id and n.status='active'
 where nm.user_id=uid and nm.status='active' order by nm.joined_at desc limit 1;
 update public.profiles set active_network_id=next_id,updated_at=now() where id=uid and active_network_id is null;
 return next_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.delete_productized_network_entity(p_entity_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin if not public.is_network_admin() then raise exception 'Network admin access required.' using errcode='42501'; end if; delete from public.network_entities where id=p_entity_id and network_id=public.current_network_id(); end $function$
;

CREATE OR REPLACE FUNCTION public.delete_productized_network_permanently(p_confirm_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin perform public.delete_owned_network_permanently(public.current_network_id(),p_confirm_name); end $function$
;

CREATE OR REPLACE FUNCTION public.delete_productized_network_relationship(p_relationship_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if not public.is_network_admin() then raise exception 'Network admin access required.' using errcode='42501'; end if; delete from public.network_entity_relationships where id=p_relationship_id and network_id=public.current_network_id(); end $function$
;

CREATE OR REPLACE FUNCTION public.diagnose_cross_network_discovery(p_source_network_id uuid, p_query text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare q text:=trim(coalesce(p_query,'')); target_networks integer:=0; eligible_people integer:=0; eligible_matches integer:=0; raw_matches integer:=0;
begin
 if auth.uid() is null or not public.is_network_member(p_source_network_id) then raise exception 'Membership in the source network is required.' using errcode='42501'; end if;
 if length(q)<2 then return jsonb_build_object('code','no_match','targetNetworks',0,'eligibleClaimedPeople',0); end if;
 with targets as(
  select distinct case when b.requester_network_id=p_source_network_id then b.recipient_network_id else b.requester_network_id end id
  from public.network_trust_bridges b
  where b.status='accepted' and p_source_network_id in(b.requester_network_id,b.recipient_network_id)
   and coalesce((b.capabilities->>'discovery')::boolean,false)
 ) select count(*) into target_networks from targets;
 if target_networks=0 then return jsonb_build_object('code','no_bridge','targetNetworks',0,'eligibleClaimedPeople',0); end if;

 with targets as(
  select distinct case when b.requester_network_id=p_source_network_id then b.recipient_network_id else b.requester_network_id end id
  from public.network_trust_bridges b
  where b.status='accepted' and p_source_network_id in(b.requester_network_id,b.recipient_network_id)
   and coalesce((b.capabilities->>'discovery')::boolean,false)
 ), claimed as(
  select ne.network_id,ne.owner_user_id uid,(ne.label||' '||coalesce(ne.metadata::text,'')) blob from public.network_entities ne join targets t on t.id=ne.network_id where ne.kind='person' and ne.owner_user_id is not null and ne.visibility='members'
  union all select ap.network_id,ap.claimed_by,(ap.full_name||' '||coalesce(ap.program,'')||' '||coalesce(ap.department,'')||' '||coalesce(ap.city,'')||' '||coalesce(ap.company,'')||' '||coalesce(ap.job_title,'')||' '||coalesce(ap.bio,'')) from public.alumni_profiles ap join targets t on t.id=ap.network_id where ap.claimed_by is not null and ap.visibility='members'
  union all select fm.network_id,nm.user_id,(fm.full_name||' '||coalesce(fm.profession,'')||' '||coalesce(fm.city,'')||' '||coalesce(fm.country,'')||' '||coalesce(fm.bio,'')) from public.family_members fm join targets t on t.id=fm.network_id join public.network_memberships nm on nm.network_id=fm.network_id and nm.member_id=fm.id and nm.status='active' where fm.profile_status='approved'
 ), raw as(
  select ne.network_id,(ne.label||' '||coalesce(ne.metadata::text,'')) blob from public.network_entities ne join targets t on t.id=ne.network_id where ne.kind='person'
  union all select ap.network_id,(ap.full_name||' '||coalesce(ap.program,'')||' '||coalesce(ap.department,'')||' '||coalesce(ap.city,'')||' '||coalesce(ap.company,'')||' '||coalesce(ap.job_title,'')||' '||coalesce(ap.bio,'')) from public.alumni_profiles ap join targets t on t.id=ap.network_id
  union all select fm.network_id,(fm.full_name||' '||coalesce(fm.profession,'')||' '||coalesce(fm.city,'')||' '||coalesce(fm.country,'')||' '||coalesce(fm.bio,'')) from public.family_members fm join targets t on t.id=fm.network_id where fm.profile_status='approved'
 )
 select (select count(*) from claimed where uid<>auth.uid()),(select count(*) from claimed where uid<>auth.uid() and lower(blob) like '%'||lower(q)||'%'),(select count(*) from raw where lower(blob) like '%'||lower(q)||'%')
 into eligible_people,eligible_matches,raw_matches;

 return jsonb_build_object('code',case when eligible_matches>0 then 'ready' when raw_matches>0 then 'matching_unclaimed' when eligible_people=0 then 'no_claimed_people' else 'no_match' end,'targetNetworks',target_networks,'eligibleClaimedPeople',eligible_people);
end $function$
;

CREATE OR REPLACE FUNCTION public.disable_my_push_subscription(p_endpoint text DEFAULT NULL::text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_count integer;
begin
 update public.push_subscriptions set active=false,updated_at=now() where user_id=auth.uid() and (p_endpoint is null or endpoint=p_endpoint);
 get diagnostics v_count=row_count; return v_count;
end $function$
;

CREATE OR REPLACE FUNCTION public.discover_across_trusted_networks(p_source_network_id uuid, p_query text, p_limit integer DEFAULT 8)
 RETURNS TABLE(candidate_id uuid, target_network_id uuid, target_network_name character varying, bridge_id uuid, relationship_type character varying, match_hint character varying, path_depth smallint, path_summary character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare q text:=trim(coalesce(p_query,'')); lim integer:=greatest(1,least(coalesce(p_limit,8),12)); rec record; v_candidate uuid; found_count integer:=0; multihop_count integer:=0;
begin
 if auth.uid() is null or not public.is_network_member(p_source_network_id) then raise exception 'Membership in the source network is required.' using errcode='42501'; end if;
 if length(q)<2 then raise exception 'Enter at least 2 characters to discover relevant people.' using errcode='22023'; end if;
 delete from public.cross_network_discovery_candidates c where c.requester_user_id=auth.uid() and c.expires_at<now();

 for rec in
  with edges as(
   select b.id,b.relationship_type,b.requester_network_id a,b.recipient_network_id z,
    coalesce((b.capabilities->>'pathTraversal')::boolean,false) path_ok
   from public.network_trust_bridges b
   where b.status='accepted' and coalesce((b.capabilities->>'discovery')::boolean,false)
  ),
  direct_paths as(
   select e.id first_bridge_id,array[e.id]::uuid[] bridge_ids,
    array[p_source_network_id,case when e.a=p_source_network_id then e.z else e.a end]::uuid[] network_ids,
    case when e.a=p_source_network_id then e.z else e.a end target_id,
    1::smallint depth,e.relationship_type,'Direct trusted bridge'::varchar(260) summary
   from edges e where p_source_network_id in(e.a,e.z)
  ),
  two_hop_paths as(
   select e1.id first_bridge_id,array[e1.id,e2.id]::uuid[] bridge_ids,
    array[p_source_network_id,mid.mid_id,case when e2.a=mid.mid_id then e2.z else e2.a end]::uuid[] network_ids,
    case when e2.a=mid.mid_id then e2.z else e2.a end target_id,
    2::smallint depth,'trusted_path'::varchar relationship_type,
    ('2 governed bridges via '||mn.name)::varchar(260) summary
   from edges e1
   cross join lateral (select case when e1.a=p_source_network_id then e1.z else e1.a end mid_id) mid
   join public.networks mn on mn.id=mid.mid_id
   join edges e2 on mid.mid_id in(e2.a,e2.z) and e2.id<>e1.id
   where p_source_network_id in(e1.a,e1.z) and e1.path_ok and e2.path_ok
     and (case when e2.a=mid.mid_id then e2.z else e2.a end)<>p_source_network_id
  ),
  paths as(select * from direct_paths union all select * from two_hop_paths),
  claimed_people as(
   -- Generic/productized verticals
   select e.network_id,'entity'::varchar(20) subject_kind,e.id ref_id,e.id entity_id,e.owner_user_id target_user_id,
    e.label::text label,(e.label||' '||coalesce(e.metadata::text,''))::text search_blob,e.updated_at
   from public.network_entities e
   where e.kind='person' and e.owner_user_id is not null and e.visibility='members'
   union all
   -- Alumni vertical
   select ap.network_id,'alumni'::varchar(20),ap.id,null::uuid,ap.claimed_by,
    ap.full_name::text,(ap.full_name||' '||coalesce(ap.program,'')||' '||coalesce(ap.department,'')||' '||coalesce(ap.city,'')||' '||coalesce(ap.company,'')||' '||coalesce(ap.job_title,'')||' '||coalesce(ap.bio,''))::text,ap.updated_at
   from public.alumni_profiles ap
   where ap.claimed_by is not null and ap.visibility='members'
   union all
   -- Family vertical: only approved profiles that are actually claimed by an active membership.
   select fm.network_id,'family'::varchar(20),fm.id,null::uuid,nm.user_id,
    fm.full_name::text,(fm.full_name||' '||coalesce(fm.profession,'')||' '||coalesce(fm.city,'')||' '||coalesce(fm.country,'')||' '||coalesce(fm.bio,''))::text,fm.updated_at
   from public.family_members fm
   join public.network_memberships nm on nm.network_id=fm.network_id and nm.member_id=fm.id and nm.status='active'
   where fm.profile_status='approved'
  ),
  matches as(
   select p.*,cp.subject_kind,cp.ref_id,cp.entity_id,cp.target_user_id,n.name network_name,cp.updated_at,
    row_number() over(partition by cp.target_user_id order by p.depth asc,cp.updated_at desc) rn
   from paths p
   join public.networks n on n.id=p.target_id
   join claimed_people cp on cp.network_id=p.target_id
   where cp.target_user_id<>auth.uid() and lower(cp.search_blob) like '%'||lower(q)||'%'
  )
  select * from matches where rn=1 order by depth asc,updated_at desc limit lim
 loop
  insert into public.cross_network_discovery_candidates(
    requester_user_id,source_network_id,bridge_id,target_network_id,target_entity_id,target_user_id,query_text,
    path_depth,path_bridge_ids,path_network_ids,path_summary,target_subject_kind,target_ref_id)
  values(auth.uid(),p_source_network_id,rec.first_bridge_id,rec.target_id,rec.entity_id,rec.target_user_id,q,
    rec.depth,rec.bridge_ids,rec.network_ids,rec.summary,rec.subject_kind,rec.ref_id)
  returning id into v_candidate;
  found_count:=found_count+1; if rec.depth=2 then multihop_count:=multihop_count+1; end if;
  candidate_id:=v_candidate; target_network_id:=rec.target_id; target_network_name:=rec.network_name;
  bridge_id:=rec.first_bridge_id; relationship_type:=rec.relationship_type;
  match_hint:='Relevant member found through a governed trusted path.'; path_depth:=rec.depth; path_summary:=rec.summary; return next;
 end loop;

 insert into public.network_effect_events(actor_user_id,source_network_id,event_type,event_count)
 values(auth.uid(),p_source_network_id,'discovery_search',1);
 if found_count>0 then insert into public.network_effect_events(actor_user_id,source_network_id,event_type,event_count)
 values(auth.uid(),p_source_network_id,'discovery_opportunity',found_count); end if;
 if multihop_count>0 then insert into public.network_effect_events(actor_user_id,source_network_id,event_type,event_count)
 values(auth.uid(),p_source_network_id,'trusted_path_opportunity',multihop_count); end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.e6_fund_signed_amount(p_kind text, p_amount numeric)
 RETURNS numeric
 LANGUAGE sql
 IMMUTABLE
AS $function$
 select case when p_kind in ('expense','refund','transfer_out') then -abs(coalesce(p_amount,0)) else abs(coalesce(p_amount,0)) end;
$function$
;

CREATE OR REPLACE FUNCTION public.ensure_federated_trust_receipt(p_introduction_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare rid uuid;
begin
 select tr.id into rid from public.federated_trust_receipts tr where tr.introduction_id=p_introduction_id;
 if rid is not null then return rid; end if;
 insert into public.federated_trust_receipts(introduction_id,request_id,route_id,scope_key,request_title,source_network_name,target_network_name,umbrella_name,trust_path_snapshot,routed_at,introduction_requested_at,accepted_at)
 select i.id,r.id,rr.id,r.scope_key,r.title,src.name,target.name,u.name,i.trust_path_snapshot,rr.generated_at,i.created_at,i.responded_at
 from public.federated_introductions i
 join public.federated_requests r on r.id=i.request_id
 join public.federated_request_routes rr on rr.id=i.route_id
 join public.networks src on src.id=r.source_network_id
 join public.federated_scope_profiles sp on sp.id=i.target_scope_profile_id
 join public.networks target on target.id=sp.network_id
 join public.federation_umbrellas u on u.id=r.umbrella_id
 where i.id=p_introduction_id and i.status='accepted' and i.responded_at is not null
 on conflict(introduction_id) do nothing
 returning id into rid;
 if rid is null then select tr.id into rid from public.federated_trust_receipts tr where tr.introduction_id=p_introduction_id; end if;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.enter_family_lobby()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'Sign in is required.' using errcode='42501'; end if;
  update public.profiles set active_network_id=null,family_lobby_mode=true,updated_at=now() where id=auth.uid();
end $function$
;

CREATE OR REPLACE FUNCTION public.finalize_network_creation(p_network_id uuid, p_previous_network_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_required boolean:=false;
  v_creator uuid;
  v_status text;
  v_name text;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;

  select n.created_by,n.name into v_creator,v_name
  from public.networks n where n.id=p_network_id;
  if v_creator is null then raise exception 'Network not found.' using errcode='P0002'; end if;
  if v_creator<>auth.uid() and not public.is_platform_owner() then
    raise exception 'Only the creator or platform owner can finalize this network.' using errcode='42501';
  end if;

  insert into public.profiles(id,full_name)
  select u.id,coalesce(nullif(trim(u.raw_user_meta_data->>'full_name'),''),split_part(coalesce(u.email,''),'@',1),'')
  from auth.users u where u.id=v_creator
  on conflict(id) do nothing;

  insert into public.network_memberships(network_id,user_id,role,status)
  values(p_network_id,v_creator,'owner','active')
  on conflict(network_id,user_id) do update
    set role=case when public.network_memberships.status<>'active' then 'owner' else public.network_memberships.role end,
        status='active';

  select public.get_network_creation_policy() into v_required;
  v_status:=case when public.is_platform_owner() or not v_required then 'approved' else 'pending' end;

  update public.networks
  set approval_status=v_status,
      approval_requested_at=coalesce(approval_requested_at,now()),
      approval_reviewed_at=case when v_status='approved' then now() else null end,
      approval_reviewed_by=case when v_status='approved' and public.is_platform_owner() then auth.uid() else null end,
      approval_note=case when v_status='approved' then 'Auto-approved by platform creation policy.' else null end,
      updated_at=now()
  where id=p_network_id;

  if v_status='approved' then
    update public.profiles
      set active_network_id=p_network_id,family_lobby_mode=false,updated_at=now()
      where id=v_creator;
  else
    -- Creation RPCs historically activate the network before approval is known.
    -- Restore the caller's previous valid context rather than dropping them into limbo.
    update public.profiles
      set active_network_id=(case
        when p_previous_network_id is not null
         and exists(select 1 from public.network_memberships x where x.network_id=p_previous_network_id and x.user_id=v_creator and x.status='active')
        then p_previous_network_id else null end),
        family_lobby_mode=true,updated_at=now()
      where id=v_creator;
  end if;

  return jsonb_build_object(
    'network_id',p_network_id,
    'network_name',v_name,
    'approval_status',v_status,
    'membership_ready',exists(select 1 from public.network_memberships nm where nm.network_id=p_network_id and nm.user_id=v_creator and nm.status='active'),
    'active_network_id',(select p.active_network_id from public.profiles p where p.id=v_creator)
  );
end $function$
;

CREATE OR REPLACE FUNCTION public.finish_launch_demo_seed_run(p_run_id uuid, p_status text, p_created integer, p_updated integer, p_skipped integer, p_errors integer, p_warnings integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if p_status not in ('completed','completed_with_errors','failed') then raise exception 'Invalid seed run status.' using errcode='22023'; end if;
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 update public.launch_demo_seed_runs set status=p_status,created_count=greatest(coalesce(p_created,0),0),updated_count=greatest(coalesce(p_updated,0),0),skipped_count=greatest(coalesce(p_skipped,0),0),error_count=greatest(coalesce(p_errors,0),0),warning_count=greatest(coalesce(p_warnings,0),0),completed_at=now()
 where id=p_run_id and network_id=nid and status='running';
 if not found then raise exception 'Running seed run was not found in the active network.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.g7_ensure_dimension(p_network uuid, p_key text, p_label text, p_sort integer DEFAULT 0)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid;
begin
 insert into public.network_dimensions(network_id,dimension_key,label,sort_order) values(p_network,trim(p_key),trim(p_label),p_sort)
 on conflict(network_id,dimension_key) do update set label=excluded.label,sort_order=excluded.sort_order
 returning id into v_id;
 return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.g7_set_entity_affiliation(p_entity uuid, p_network uuid, p_dimension_key text, p_label text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_dim uuid; v_value uuid; v_key text;
begin
 select id into v_dim from public.network_dimensions where network_id=p_network and dimension_key=p_dimension_key;
 if v_dim is null then return; end if;
 delete from public.network_entity_affiliations where network_id=p_network and entity_id=p_entity and dimension_id=v_dim;
 if nullif(trim(coalesce(p_label,'')),'') is null then return; end if;
 v_key:=public.g7_value_key(p_label); if v_key='' then v_key:=md5(trim(p_label)); end if;
 insert into public.network_dimension_values(network_id,dimension_id,value_key,label) values(p_network,v_dim,v_key,trim(p_label))
 on conflict(network_id,dimension_id,value_key) do update set label=excluded.label returning id into v_value;
 insert into public.network_entity_affiliations(network_id,entity_id,dimension_id,value_id) values(p_network,p_entity,v_dim,v_value)
 on conflict do nothing;
end $function$
;

CREATE OR REPLACE FUNCTION public.g7_value_key(p_label text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
 select lower(trim(both '-' from regexp_replace(trim(coalesce(p_label,'')),'[^a-zA-Z0-9]+','-','g')));
$function$
;

CREATE OR REPLACE FUNCTION public.g8_allowed_entity_kind(p_kind text, p_entity_kind text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
 select case p_kind
  when 'association' then p_entity_kind in ('household','person','committee','organization','location')
  when 'family-association' then p_entity_kind in ('family','person','committee','organization','location')
  when 'housing-society' then p_entity_kind in ('unit','household','person','building','wing','organization','location')
  when 'organization' then p_entity_kind in ('person','team','project','product','location')
  when 'business-trust' then p_entity_kind in ('person','organization','location','product')
  when 'franchise' then p_entity_kind in ('branch','person','organization','location')
  when 'professional' then p_entity_kind in ('person','organization','location') else false end;
$function$
;

CREATE OR REPLACE FUNCTION public.g8_allowed_relationship(p_kind text, p_rel text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
 select case p_kind
  when 'association' then p_rel in ('represented_by','member_of_household','spouse_of','parent_of','serves_on','supports')
  when 'family-association' then p_rel in ('represented_by','member_of_family','spouse_of','parent_of','serves_on','supports')
  when 'housing-society' then p_rel in ('owned_by','co_owned_by','occupied_by','tenanted_by','member_of_household','resident_of','serves_on','supports')
  when 'organization' then p_rel in ('reports_to','works_with','owns','depends_on')
  when 'business-trust' then p_rel in ('recommends','verified_by','supplies_to','worked_with')
  when 'franchise' then p_rel in ('owns','operates','manages','supports')
  when 'professional' then p_rel in ('worked_with','referred_by','collaborates_with','mentors') else false end;
$function$
;

CREATE OR REPLACE FUNCTION public.g8_generate_join_code()
 RETURNS text
 LANGUAGE plpgsql
AS $function$ declare c text; begin loop c:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)); exit when not exists(select 1 from public.network_join_codes where code=c); end loop; return c; end $function$
;

CREATE OR REPLACE FUNCTION public.g8_productized_vertical(p_kind text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$
 select p_kind in ('association','family-association','housing-society','organization','business-trust','franchise','professional');
$function$
;

CREATE OR REPLACE FUNCTION public.g8_seed_productized_structure(p_network uuid, p_kind text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if p_kind='housing-society' then
  perform public.g7_ensure_dimension(p_network,'building','Building / Tower',10);
  perform public.g7_ensure_dimension(p_network,'wing','Wing',20);
  perform public.g7_ensure_dimension(p_network,'floor','Floor',30);
  perform public.g7_ensure_dimension(p_network,'unit_type','Unit Type',40);
  perform public.g7_ensure_dimension(p_network,'occupancy_status','Occupancy Status',50);
  perform public.g7_ensure_dimension(p_network,'resident_type','Resident Type',60);
  perform public.g7_ensure_dimension(p_network,'parking_zone','Parking Zone',70);
  insert into public.network_projections(network_id,projection_key,label,levels,is_default,sort_order) values
   (p_network,'property-hierarchy','Building → Wing → Floor → Unit',array['building','wing','floor'],true,10),
   (p_network,'occupancy','Building → Occupancy',array['building','occupancy_status'],false,20),
   (p_network,'resident-type','Resident Type → Building',array['resident_type','building'],false,30),
   (p_network,'parking','Parking Zone → Building',array['parking_zone','building'],false,40)
  on conflict(network_id,projection_key) do update set label=excluded.label,levels=excluded.levels,is_default=excluded.is_default,sort_order=excluded.sort_order;
 elsif p_kind='family-association' then
  perform public.g7_ensure_dimension(p_network,'membership_year','Membership Year',10);perform public.g7_ensure_dimension(p_network,'membership_status','Membership Status',20);perform public.g7_ensure_dimension(p_network,'chapter','Chapter',30);perform public.g7_ensure_dimension(p_network,'city','City',40);perform public.g7_ensure_dimension(p_network,'area','Area / Locality',50);perform public.g7_ensure_dimension(p_network,'profession','Profession',60);perform public.g7_ensure_dimension(p_network,'committee','Committee / Role',70);perform public.g7_ensure_dimension(p_network,'interest','Interest / Activity',80);
  insert into public.network_projections(network_id,projection_key,label,levels,is_default,sort_order) values (p_network,'families','Chapter → Family',array['chapter','membership_status'],true,10),(p_network,'renewal','Membership Year → Status',array['membership_year','membership_status'],false,20),(p_network,'area','City → Area',array['city','area'],false,30),(p_network,'profession','Profession → Area',array['profession','area'],false,40),(p_network,'committee','Committee → Chapter',array['committee','chapter'],false,50) on conflict(network_id,projection_key) do update set label=excluded.label,levels=excluded.levels,is_default=excluded.is_default,sort_order=excluded.sort_order;
 elsif p_kind='association' then
  perform public.g7_ensure_dimension(p_network,'membership_year','Membership Year',10);perform public.g7_ensure_dimension(p_network,'membership_status','Membership Status',20);perform public.g7_ensure_dimension(p_network,'chapter','Chapter',30);perform public.g7_ensure_dimension(p_network,'city','City',40);perform public.g7_ensure_dimension(p_network,'committee','Committee / Role',50);perform public.g7_ensure_dimension(p_network,'interest','Interest / Activity',60);
  insert into public.network_projections(network_id,projection_key,label,levels,is_default,sort_order) values (p_network,'households','Chapter → Household',array['chapter','membership_status'],true,10),(p_network,'renewal','Membership Year → Status',array['membership_year','membership_status'],false,20),(p_network,'committee','Committee → Chapter',array['committee','chapter'],false,30),(p_network,'city','City → Chapter',array['city','chapter'],false,40) on conflict(network_id,projection_key) do update set label=excluded.label,levels=excluded.levels,is_default=excluded.is_default,sort_order=excluded.sort_order;
 elsif p_kind='organization' then
  perform public.g7_ensure_dimension(p_network,'region','Region',10);perform public.g7_ensure_dimension(p_network,'business_unit','Business Unit',20);perform public.g7_ensure_dimension(p_network,'department','Department',30);perform public.g7_ensure_dimension(p_network,'team','Team',40);perform public.g7_ensure_dimension(p_network,'project','Project',50);perform public.g7_ensure_dimension(p_network,'skill','Skill / Expertise',60);
  insert into public.network_projections(network_id,projection_key,label,levels,is_default,sort_order) values (p_network,'org-structure','Region → Business Unit → Department → Team',array['region','business_unit','department','team'],true,10),(p_network,'project-structure','Project → Team → Skill',array['project','team','skill'],false,20),(p_network,'expertise-structure','Skill → Department → Team',array['skill','department','team'],false,30) on conflict(network_id,projection_key) do update set label=excluded.label,levels=excluded.levels,is_default=excluded.is_default,sort_order=excluded.sort_order;
 elsif p_kind='business-trust' then
  perform public.g7_ensure_dimension(p_network,'region','Region',10);perform public.g7_ensure_dimension(p_network,'category','Business Category',20);perform public.g7_ensure_dimension(p_network,'service','Product / Service',30);
  insert into public.network_projections(network_id,projection_key,label,levels,is_default,sort_order) values (p_network,'region-category','Region → Category → Service',array['region','category','service'],true,10),(p_network,'category-region','Category → Region',array['category','region'],false,20) on conflict(network_id,projection_key) do update set label=excluded.label,levels=excluded.levels,is_default=excluded.is_default,sort_order=excluded.sort_order;
 elsif p_kind='franchise' then
  perform public.g7_ensure_dimension(p_network,'country','Country',10);perform public.g7_ensure_dimension(p_network,'state','State',20);perform public.g7_ensure_dimension(p_network,'city','City',30);perform public.g7_ensure_dimension(p_network,'store_type','Store Type',40);perform public.g7_ensure_dimension(p_network,'owner','Franchise Owner',50);
  insert into public.network_projections(network_id,projection_key,label,levels,is_default,sort_order) values (p_network,'geography','Country → State → City → Store Type',array['country','state','city','store_type'],true,10),(p_network,'ownership','Owner → State → City',array['owner','state','city'],false,20) on conflict(network_id,projection_key) do update set label=excluded.label,levels=excluded.levels,is_default=excluded.is_default,sort_order=excluded.sort_order;
 elsif p_kind='professional' then
  perform public.g7_ensure_dimension(p_network,'profession','Profession',10);perform public.g7_ensure_dimension(p_network,'specialty','Specialty / Expertise',20);perform public.g7_ensure_dimension(p_network,'industry','Industry',30);perform public.g7_ensure_dimension(p_network,'service','Service',40);perform public.g7_ensure_dimension(p_network,'country','Country',50);perform public.g7_ensure_dimension(p_network,'city','City',60);perform public.g7_ensure_dimension(p_network,'credential','Credential / Qualification',70);
  insert into public.network_projections(network_id,projection_key,label,levels,is_default,sort_order) values (p_network,'expertise-location','Expertise → Country → City',array['specialty','country','city'],true,10),(p_network,'profession-service','Profession → Service → Specialty',array['profession','service','specialty'],false,20),(p_network,'industry-expertise','Industry → Expertise → City',array['industry','specialty','city'],false,30) on conflict(network_id,projection_key) do update set label=excluded.label,levels=excluded.levels,is_default=excluded.is_default,sort_order=excluded.sort_order;
 end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.g8_set_entity_affiliations(p_entity uuid, p_network uuid, p_dimension_key text, p_values jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_dim uuid; v_value uuid; v_key text; v_label text; item jsonb;
begin
 select id into v_dim from public.network_dimensions where network_id=p_network and dimension_key=p_dimension_key;
 if v_dim is null then raise exception 'Unknown network dimension: %',p_dimension_key using errcode='22023'; end if;
 if not exists(select 1 from public.network_entities where id=p_entity and network_id=p_network) then raise exception 'Entity does not belong to active network.' using errcode='22023'; end if;
 delete from public.network_entity_affiliations where network_id=p_network and entity_id=p_entity and dimension_id=v_dim;
 if p_values is null or p_values='null'::jsonb then return; end if;
 if jsonb_typeof(p_values)='array' then
  for item in select value from jsonb_array_elements(p_values) loop
   v_label:=trim(both '"' from item::text);
   if nullif(v_label,'') is null then continue; end if;
   v_key:=public.g7_value_key(v_label); if v_key='' then v_key:=md5(v_label); end if;
   insert into public.network_dimension_values(network_id,dimension_id,value_key,label) values(p_network,v_dim,v_key,v_label)
   on conflict(network_id,dimension_id,value_key) do update set label=excluded.label returning id into v_value;
   insert into public.network_entity_affiliations(network_id,entity_id,dimension_id,value_id) values(p_network,p_entity,v_dim,v_value) on conflict do nothing;
  end loop;
 else
  v_label:=trim(both '"' from p_values::text);
  if nullif(v_label,'') is not null then
   v_key:=public.g7_value_key(v_label); if v_key='' then v_key:=md5(v_label); end if;
   insert into public.network_dimension_values(network_id,dimension_id,value_key,label) values(p_network,v_dim,v_key,v_label)
   on conflict(network_id,dimension_id,value_key) do update set label=excluded.label returning id into v_value;
   insert into public.network_entity_affiliations(network_id,entity_id,dimension_id,value_id) values(p_network,p_entity,v_dim,v_value) on conflict do nothing;
  end if;
 end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.g91b_assert_organization_network(p_network uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if p_network is null or (select vertical_kind from public.networks where id=p_network)<>'organization' then raise exception 'Organization network required.' using errcode='22023'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.generate_family_join_code()
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare c text;
begin
 loop
  c:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
  exit when not exists(select 1 from public.family_join_codes where code=c);
 end loop;
 return c;
end;$function$
;

CREATE OR REPLACE FUNCTION public.get_community_event_attendees(p_event_id uuid)
 RETURNS TABLE(member_id uuid, full_name text, response text, guest_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select p.member_id,coalesce(fm.full_name,'Family member')::text,r.response::text,r.guest_count
 from public.community_event_responses r
 join public.community_events e on e.id=r.event_id and e.network_id=public.current_network_id()
 left join public.profiles p on p.id=r.user_id
 left join public.family_members fm on fm.id=p.member_id and fm.network_id=e.network_id
 where r.event_id=p_event_id and auth.uid() is not null
 order by case r.response when 'going' then 0 when 'interested' then 1 else 2 end,coalesce(fm.full_name,'');
$function$
;

CREATE OR REPLACE FUNCTION public.get_community_events()
 RETURNS TABLE(id uuid, group_id uuid, group_name text, title text, description text, event_at timestamp with time zone, location text, status text, going bigint, interested bigint, my_response text, guest_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select e.id,e.group_id,g.name::text,e.title::text,e.description,e.event_at,e.location::text,e.status::text,
    count(*) filter(where r.response='going'),count(*) filter(where r.response='interested'),
    max(r.response) filter(where r.user_id=auth.uid())::text,
    coalesce(sum(case when r.response='going' then r.guest_count else 0 end),0)
  from public.community_events e left join public.community_groups g on g.id=e.group_id
  left join public.community_event_responses r on r.event_id=e.id
  where auth.uid() is not null group by e.id,g.name order by e.event_at nulls last,e.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_community_posts(p_space_id uuid, p_category text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, space_id uuid, space_name character varying, network_id uuid, family_name character varying, target_member_id uuid, category character varying, title character varying, body text, city character varying, status character varying, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with recursive scope as (select id from public.community_spaces where id=p_space_id union all select s.id from public.community_spaces s join scope p on s.parent_id=p.id)
  select p.id,p.space_id,s.name,p.network_id,n.name,p.target_member_id,p.category,p.title,p.body,p.city,p.status,p.created_at
  from public.community_posts p join public.community_spaces s on s.id=p.space_id join public.networks n on n.id=p.network_id
  where p.status='open' and p.space_id in(select id from scope) and public.community_space_is_allowed(p_space_id,public.current_network_id())
    and (p_category is null or p_category='' or p.category=p_category)
  order by p.created_at desc limit 200;
$function$
;

CREATE OR REPLACE FUNCTION public.get_community_spaces()
 RETURNS TABLE(id uuid, parent_id uuid, name character varying, slug character varying, space_type character varying, city character varying, state character varying, country character varying, family_status character varying, family_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with recursive tree(root_id,id) as (
    select id,id from public.community_spaces where status='active'
    union all
    select t.root_id,s.id from tree t join public.community_spaces s on s.parent_id=t.id where s.status='active'
  ), counts as (
    select t.root_id,count(distinct l.network_id)::bigint family_count
    from tree t left join public.community_family_links l on l.space_id=t.id and l.status='approved' group by t.root_id
  )
  select s.id,s.parent_id,s.name,s.slug,s.space_type,s.city,s.state,s.country,
    coalesce(l.status,case when public.community_space_is_allowed(s.id,public.current_network_id()) then 'approved'::varchar end),coalesce(c.family_count,0)
  from public.community_spaces s
  left join public.community_family_links l on l.space_id=s.id and l.network_id=public.current_network_id()
  left join counts c on c.root_id=s.id
  where s.status='active' and auth.uid() is not null
  order by coalesce(s.parent_id,s.id),s.parent_id nulls first,s.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_effective_platform_features()
 RETURNS TABLE(feature_key character varying, rollout_state character varying, enabled boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select f.feature_key,f.rollout_state,(case f.rollout_state when 'released' then true when 'test' then public.is_platform_owner() when 'pilot' then public.is_platform_owner() or coalesce(public.current_network_id()=any(f.pilot_network_ids),false) else false end and case when f.bundle_key='admin' then true else coalesce(s.enabled,true) end)
 from public.platform_feature_flags f left join public.network_feature_settings s on s.network_id=public.current_network_id() and s.feature_key=f.feature_key
 where f.vertical_kind=coalesce((select n.vertical_kind from public.networks n where n.id=public.current_network_id()),'family') order by f.bundle_key,f.feature_key;
$function$
;

CREATE OR REPLACE FUNCTION public.get_family_admin_summary()
 RETURNS TABLE(member_profiles bigint, claimed_profiles bigint, active_invitations bigint, admin_count bigint, media_usage_bytes bigint, storage_limit_bytes bigint, photo_max_bytes integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
 return query select
  (select count(*) from public.family_members m where m.network_id=nid),
  (select count(*) from public.network_memberships nm where nm.network_id=nid and nm.status='active' and nm.member_id is not null),
  (select count(*) from public.member_invitations i
    where i.network_id=nid
      and public.invitation_status(i.used_at,i.revoked_at,i.expires_at)='active'),
  (select count(*) from public.network_memberships nm where nm.network_id=nid and nm.status='active' and nm.role in ('owner','admin')),
  n.media_usage_bytes,n.storage_limit_bytes,n.photo_max_bytes
 from public.networks n where n.id=nid;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_family_creation_policy()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.get_network_creation_policy();
$function$
;

CREATE OR REPLACE FUNCTION public.get_family_feature_settings()
 RETURNS TABLE(feature_key character varying, enabled boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_admin(nid) then
    raise exception 'Family admin access is required.' using errcode='42501';
  end if;
  return query
  select f.feature_key,coalesce(s.enabled,true)
  from public.platform_feature_flags f
  left join public.network_feature_settings s on s.network_id=nid and s.feature_key=f.feature_key
  where f.bundle_key<>'admin'
  order by f.bundle_key,f.feature_key;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_family_intake_admin_dashboard()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); result jsonb;
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family admin access is required.' using errcode='42501'; end if;
  select jsonb_build_object(
    'sessions',coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'title',s.title,'status',s.status,'created_at',s.created_at,'access_count',(select count(*) from public.family_intake_access a where a.session_id=s.id),'submitted_count',(select count(*) from public.family_intake_access a where a.session_id=s.id and a.status in ('submitted','committed')),'committed_count',(select count(*) from public.family_intake_access a where a.session_id=s.id and a.status='committed')) order by s.created_at desc) from public.family_intake_sessions s where s.network_id=nid),'[]'::jsonb),
    'branches',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'session_id',a.session_id,'representative_label',a.representative_label,'status',a.status,'expires_at',a.expires_at,'submitted_at',a.submitted_at,'people_count',(select count(*) from public.family_intake_people p where p.access_id=a.id),'relationship_count',(select count(*) from public.family_intake_relationships r where r.access_id=a.id)) order by a.created_at desc) from public.family_intake_access a where a.network_id=nid),'[]'::jsonb),
    'people',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'access_id',p.access_id,'full_name',p.full_name,'birth_year',coalesce(p.birth_year,extract(year from p.date_of_birth)::int),'gender',p.gender,'city',p.city,'role_from_anchor',p.role_from_anchor,'generation_offset',p.generation_offset,'status',p.status,'matched_member_id',p.matched_member_id,'match_confidence',p.match_confidence) order by p.created_at) from public.family_intake_people p where p.network_id=nid),'[]'::jsonb),
    'candidates',coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'staged_person_id',c.staged_person_id,'candidate_member_id',c.candidate_member_id,'candidate_staged_person_id',c.candidate_staged_person_id,'candidate_name',coalesce(fm.full_name,sp.full_name),'score',c.score,'confidence_band',c.confidence_band,'status',c.status,'reasons',c.reasons) order by c.score desc) from public.family_intake_match_candidates c left join public.family_members fm on fm.id=c.candidate_member_id left join public.family_intake_people sp on sp.id=c.candidate_staged_person_id where c.network_id=nid),'[]'::jsonb),
    'conflicts',coalesce((select jsonb_agg(jsonb_build_object('id',x.id,'staged_person_id',x.staged_person_id,'member_id',x.member_id,'field_name',x.field_name,'existing_value',x.existing_value,'reported_value',x.reported_value,'status',x.status) order by x.created_at desc) from public.family_intake_conflicts x where x.network_id=nid),'[]'::jsonb),
    'metrics',jsonb_build_object('links_opened',(select count(*) from public.family_intake_events e where e.network_id=nid and e.event_name='intake_link_opened'),'submissions',(select count(*) from public.family_intake_events e where e.network_id=nid and e.event_name='intake_submitted'),'people_reported',coalesce((select sum((e.properties->>'people_reported')::int) from public.family_intake_events e where e.network_id=nid and e.event_name='intake_submitted'),0),'branches_committed',(select count(*) from public.family_intake_access a where a.network_id=nid and a.status='committed'))
  ) into result;
  return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_family_intake_preview(p_token text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.family_intake_access%rowtype; s public.family_intake_sessions%rowtype; family_name text;
begin
  select * into a from public.family_intake_access where token_hash=digest(coalesce(p_token,''),'sha256') limit 1;
  if a.id is null or a.status not in ('active','submitted') or a.expires_at<=now() then raise exception 'This contribution link is invalid or expired.' using errcode='42501'; end if;
  if not public.s3a_intake_enabled(a.network_id,a.created_by) then raise exception 'This family intake is not currently available.' using errcode='42501'; end if;
  select * into s from public.family_intake_sessions where id=a.session_id;
  if s.status not in ('collecting','review') then raise exception 'This family intake is closed.' using errcode='42501'; end if;
  select n.name into family_name from public.networks n where n.id=a.network_id;
  update public.family_intake_access set last_opened_at=now() where id=a.id;
  insert into public.family_intake_events(network_id,session_id,access_id,event_name,properties)
  values(a.network_id,a.session_id,a.id,'intake_link_opened',jsonb_build_object('representative_label',a.representative_label));
  return jsonb_build_object('family_name',family_name,'title',s.title,'representative_label',a.representative_label,'status',a.status,'already_submitted',a.submission_count>0,'expires_at',a.expires_at);
end $function$
;

CREATE OR REPLACE FUNCTION public.get_family_memberships()
 RETURNS TABLE(user_id uuid, role character varying, status character varying, member_id uuid, display_name text, email text, member_name character varying)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
 return query select nm.user_id,nm.role,nm.status,nm.member_id,
  coalesce(p.full_name,u.raw_user_meta_data->>'full_name',split_part(u.email,'@',1))::text,u.email::text,fm.full_name
 from public.network_memberships nm
 left join public.profiles p on p.id=nm.user_id
 left join auth.users u on u.id=nm.user_id
 left join public.family_members fm on fm.id=nm.member_id and fm.network_id=nid
 where nm.network_id=nid and nm.status='active'
 order by case nm.role when 'owner' then 0 when 'admin' then 1 else 2 end,coalesce(fm.full_name,p.full_name,u.email);
end $function$
;

CREATE OR REPLACE FUNCTION public.get_fca_admin_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid; result jsonb;
begin
 nid:=public.current_network_id();
 if not public.is_network_admin(nid) then raise exception 'Association admin access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.networks where id=nid and vertical_kind='family-association') then raise exception 'Family Community Association required.' using errcode='22023'; end if;
 select jsonb_build_object(
  'settings',coalesce((select to_jsonb(s)-'network_id'-'created_at'-'updated_at' from public.family_association_settings s where s.network_id=nid),'{}'::jsonb),
  'years',coalesce((select jsonb_agg(to_jsonb(y) order by y.start_date desc) from public.family_association_membership_years y where y.network_id=nid),'[]'::jsonb),
  'memberships',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'membership_year_id',m.membership_year_id,'year_label',y.label,'family_entity_id',m.family_entity_id,'family_label',f.label,'representative_entity_id',m.representative_entity_id,'representative_label',r.label,'status',m.status,'payment_status',m.payment_status,'amount_due',m.amount_due,'amount_paid',m.amount_paid,'payment_reference',m.payment_reference,'joined_on',m.joined_on,'renewed_on',m.renewed_on,'inactive_on',m.inactive_on) order by y.start_date desc,f.label) from public.family_association_family_memberships m join public.family_association_membership_years y on y.id=m.membership_year_id join public.network_entities f on f.id=m.family_entity_id left join public.network_entities r on r.id=m.representative_entity_id where m.network_id=nid),'[]'::jsonb),
  'roles',coalesce((select jsonb_agg(to_jsonb(rc) order by rc.sort_order,rc.label) from public.family_association_role_catalog rc where rc.network_id=nid and rc.active),'[]'::jsonb),
  'role_history',coalesce((select jsonb_agg(jsonb_build_object('id',h.id,'year_label',y.label,'person_label',p.label,'role_label',rc.label,'portfolio',rc.portfolio,'starts_on',h.starts_on,'ends_on',h.ends_on,'notes',h.notes) order by coalesce(h.starts_on,y.start_date) desc) from public.family_association_role_history h left join public.family_association_membership_years y on y.id=h.membership_year_id join public.network_entities p on p.id=h.person_entity_id join public.family_association_role_catalog rc on rc.id=h.role_catalog_id where h.network_id=nid),'[]'::jsonb),
  'finance',coalesce((select jsonb_agg(to_jsonb(l) order by l.created_at desc) from public.family_association_finance_ledger l where l.network_id=nid),'[]'::jsonb)
 ) into result;
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_geography_summary()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(jsonb_agg(jsonb_build_object(
    'city',coalesce(city,'Unknown'),
    'country',coalesce(country,''),
    'count',cnt,
    'latitude',latitude,
    'longitude',longitude
  ) order by cnt desc,city),'[]'::jsonb)
  from (
    select city,country,count(*)::int cnt,
           avg(latitude)::double precision latitude,
           avg(longitude)::double precision longitude
    from public.family_members
    where profile_status='approved' and latitude is not null and longitude is not null
      and (public.is_admin() or coalesce(profile_visibility,'member') <> 'admin')
    group by city,country
  ) x;
$function$
;

CREATE OR REPLACE FUNCTION public.get_invitation_preview(p_token text)
 RETURNS TABLE(member_name text, status text, expires_at timestamp with time zone, family_name text, family_slug text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare target_id uuid;
begin
  if length(coalesce(p_token,''))<32 then return; end if;
  select i.id into target_id from public.member_invitations i
    where i.token_hash=encode(digest(p_token,'sha256'),'hex') limit 1;
  if target_id is null then return; end if;
  update public.member_invitations set first_opened_at=coalesce(first_opened_at,now()) where id=target_id;
  return query
    select fm.full_name::text,public.invitation_status(i.used_at,i.revoked_at,i.expires_at),i.expires_at,
           n.name::text,n.slug::text
    from public.member_invitations i
    join public.family_members fm on fm.id=i.member_id and fm.network_id=i.network_id
    join public.networks n on n.id=i.network_id
    where i.id=target_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_launch_demo_seed_context(p_dataset_version text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();nname text;nkind text;authz boolean:=false;allow_real boolean:=false;
begin
 if nid is null then return jsonb_build_object('authorized',false); end if;
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 select name,vertical_kind into nname,nkind from public.networks where id=nid;
 select true,a.allow_real_network into authz,allow_real from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version;
 return jsonb_build_object('network_id',nid,'network_name',nname,'vertical_kind',nkind,'dataset_version',p_dataset_version,'authorized',coalesce(authz,false),'allow_real_network',coalesce(allow_real,false),'is_platform_owner',public.is_platform_owner(),'is_admin',public.is_network_admin(nid));
end $function$
;

CREATE OR REPLACE FUNCTION public.get_launch_demo_seed_lineage(p_dataset_version text)
 RETURNS TABLE(section_key text, row_ref text, payload_hash text, remote_id text, status text, last_message text, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Launch dataset is not authorized for this network.' using errcode='42501'; end if;
 return query select l.section_key::text,l.row_ref::text,l.payload_hash::text,l.remote_id,l.status::text,l.last_message,l.updated_at from public.launch_demo_seed_lineage l where l.network_id=nid and l.dataset_version=p_dataset_version order by l.section_key,l.row_ref;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_launch_demo_seed_run_report(p_run_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); r public.launch_demo_seed_runs%rowtype;
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 select * into r from public.launch_demo_seed_runs where id=p_run_id and network_id=nid;
 if not found then raise exception 'Seed run was not found in the active network.' using errcode='42501'; end if;
 return jsonb_build_object(
  'run',jsonb_build_object('id',r.id,'network_id',r.network_id,'dataset_version',r.dataset_version,'vertical_kind',r.vertical_kind,'status',r.status,'total_rows',r.total_rows,'created',r.created_count,'updated',r.updated_count,'skipped',r.skipped_count,'errors',r.error_count,'warnings',r.warning_count,'started_at',r.started_at,'completed_at',r.completed_at),
  'issues',coalesce((select jsonb_agg(jsonb_build_object('severity',i.severity,'section',i.section_key,'row_ref',i.row_ref,'operation',i.operation,'code',i.error_code,'message',i.message,'details',i.details,'hint',i.hint,'retryable',i.retryable,'created_at',i.created_at) order by i.created_at,i.section_key,i.row_ref) from public.launch_demo_seed_issues i where i.run_id=r.id),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.get_living_loop_metrics(p_days integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ 
declare nid uuid:=public.current_network_id(); result jsonb;
begin
 if not public.is_network_admin(nid) then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
 select jsonb_build_object(
   'shares',count(*) filter(where event_type like '%share%'),
   'memory_reactions',count(*) filter(where event_type='memory_reaction'),
   'contributions',count(*) filter(where event_type like 'contribution%'),
   'pulse_actions',count(*) filter(where event_type like 'pulse_%'),
   'digest_opens',count(*) filter(where event_type in ('digest_open','digest_return')),
   'digest_returns',count(*) filter(where event_type='digest_return'),
   'digest_shares',count(*) filter(where event_type='digest_share'),
   'active_people',count(distinct user_id),
   'returning_people',count(distinct user_id) filter(where user_id in (
     select user_id from public.family_engagement_events where network_id=nid and created_at>=now()-(greatest(1,least(coalesce(p_days,30),365))||' days')::interval group by user_id having count(distinct created_at::date)>1
   ))
 ) into result
 from public.family_engagement_events
 where network_id=nid and created_at>=now()-(greatest(1,least(coalesce(p_days,30),365))||' days')::interval;
 return coalesce(result,'{}'::jsonb);
end $function$
;

CREATE OR REPLACE FUNCTION public.get_memories(p_member_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id uuid, member_id uuid, title character varying, story text, photo_url text, visibility character varying, created_by uuid, created_at timestamp with time zone, related_member_ids uuid[])
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select m.id,m.member_id,m.title,m.story,m.photo_url,m.visibility,m.created_by,m.created_at,
   coalesce((select array_agg(mp.member_id order by mp.member_id) from public.memory_people mp where mp.memory_id=m.id),array[]::uuid[])
 from public.memories m
 where (p_member_id is null or m.member_id=p_member_id or exists(select 1 from public.memory_people mp where mp.memory_id=m.id and mp.member_id=p_member_id))
 and (public.is_admin() or m.visibility <> 'admin')
 order by m.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_archived_networks()
 RETURNS TABLE(network_id uuid, name character varying, slug character varying, role character varying, vertical_kind character varying, archived_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select n.id,n.name,n.slug,nm.role,n.vertical_kind,n.updated_at
 from public.network_memberships nm join public.networks n on n.id=nm.network_id
 where nm.user_id=auth.uid() and nm.role='owner' and nm.status in ('suspended','active') and n.status='archived'
 order by n.updated_at desc,n.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_claimable_productized_entities()
 RETURNS TABLE(entity_id uuid, entity_kind character varying, entity_label character varying, network_id uuid, network_name character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select e.id,e.kind,e.label,e.network_id,n.name
 from public.network_entities e
 join public.networks n on n.id=e.network_id
 join public.network_memberships m on m.network_id=e.network_id and m.user_id=auth.uid() and m.status='active'
 where e.network_id=public.current_network_id()
   and public.g8_productized_vertical(n.vertical_kind)
   and e.owner_user_id is null
   and not exists(select 1 from public.network_entities mine where mine.network_id=e.network_id and mine.owner_user_id=auth.uid())
   and nullif(trim(coalesce(e.metadata->>'email','')),'') is not null
   and lower(trim(e.metadata->>'email'))=lower(trim(coalesce(auth.jwt()->>'email','')))
 order by e.label;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_claimable_profiles()
 RETURNS TABLE(network_id uuid, family_name text, member_id uuid, member_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select fm.network_id,n.name::text,fm.id,fm.full_name::text
  from public.family_members fm
  join public.networks n on n.id=fm.network_id and n.status='active'
  join auth.users u on u.id=auth.uid()
  where u.email_confirmed_at is not null
    and lower(trim(coalesce(fm.email,'')))=lower(trim(coalesce(u.email,'')))
    and fm.profile_status='approved'
    and not exists(select 1 from public.network_memberships x where x.network_id=fm.network_id and x.member_id=fm.id and x.status='active')
  order by n.name,fm.full_name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_community_introductions()
 RETURNS TABLE(id uuid, direction character varying, status character varying, space_name character varying, other_family_name character varying, other_person_name character varying, category character varying, message text, path_snapshot jsonb, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select r.id,
   case when r.requester_user_id=auth.uid() then 'outgoing'::varchar else 'incoming'::varchar end,
   r.status,s.name,
   case when r.requester_user_id=auth.uid() then tn.name else rn.name end,
   c.display_name,c.category,r.message,r.path_snapshot,r.created_at
 from public.community_introduction_requests r
 join public.community_spaces s on s.id=r.space_id
 join public.community_profile_cards c on c.id=r.target_card_id
 join public.networks rn on rn.id=r.requester_network_id
 join public.networks tn on tn.id=r.target_network_id
 where r.requester_user_id=auth.uid() or r.target_user_id=auth.uid()
 order by r.created_at desc limit 200;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_family_creation_requests()
 RETURNS TABLE(id uuid, name character varying, status character varying, decision_note text, created_at timestamp with time zone, reviewed_at timestamp with time zone, network_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select r.id,r.name,r.status,r.decision_note,r.created_at,r.reviewed_at,r.network_id
  from public.family_creation_requests r
  where r.requester_user_id=auth.uid()
  order by r.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_family_digest(p_days integer DEFAULT 7)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 nid uuid:=public.current_network_id(); uid uuid:=auth.uid(); days integer:=greatest(1,least(coalesce(p_days,7),31));
 prefs public.notification_preferences; last_open timestamptz; result jsonb;
begin
 if uid is null or nid is null or not public.is_network_member(nid) then raise exception 'Active family membership is required.' using errcode='42501'; end if;
 select * into prefs from public.notification_preferences where network_id=nid and user_id=uid;
 select last_opened_at into last_open from public.family_digest_state where network_id=nid and user_id=uid;

 select jsonb_build_object(
   'generated_at',now(),
   'network_name',(select name from public.networks where id=nid),
   'days',days,
   'last_opened_at',last_open,
   'new_since_last_open',(
     select count(*) from public.family_engagement_events e
     where e.network_id=nid and e.user_id is distinct from uid and e.created_at>coalesce(last_open,now()-(days||' days')::interval)
   ),
   'recent_memories',case when coalesce(prefs.memories,false) then coalesce((
     select jsonb_agg(x order by x.created_at desc) from (
       select m.id,m.title,left(coalesce(m.story,''),180) body,m.created_at,
              coalesce(fm.full_name,'Family memory') member_name
       from public.memories m left join public.family_members fm on fm.id=m.member_id and fm.network_id=nid
       where m.network_id=nid and m.created_at>=now()-(days||' days')::interval
         and (m.visibility<>'admin' or public.is_network_admin(nid))
       order by m.created_at desc limit 3
     ) x
   ),'[]'::jsonb) else '[]'::jsonb end,
   'new_members',case when coalesce(prefs.family_changes,true) then coalesce((
     select jsonb_agg(x order by x.created_at desc) from (
       select fm.id,fm.full_name,fm.city,fm.profession,fm.created_at
       from public.family_members fm where fm.network_id=nid and fm.profile_status='approved'
         and fm.created_at>=now()-(days||' days')::interval
       order by fm.created_at desc limit 4
     ) x
   ),'[]'::jsonb) else '[]'::jsonb end,
   'gatherings',case when coalesce(prefs.gatherings,true) then coalesce((
     select jsonb_agg(x order by x.event_at) from (
       select ce.id,ce.title,ce.event_at,ce.location,ce.status
       from public.community_events ce where ce.network_id=nid and ce.status in ('planning','open')
         and ce.event_at between now() and now()+interval '30 days'
       order by ce.event_at limit 3
     ) x
   ),'[]'::jsonb) else '[]'::jsonb end,
   'open_contributions',case when coalesce(prefs.contributions,true) then (
     select count(*) from public.contribution_suggestions cs where cs.network_id=nid and cs.status='open'
       and (public.is_network_admin(nid) or cs.member_id=(select member_id from public.profiles where id=uid))
   ) else 0 end,
   'contribution_hint',case when coalesce(prefs.contributions,true) then (
     select cs.title from public.contribution_suggestions cs where cs.network_id=nid and cs.status='open'
       and (public.is_network_admin(nid) or cs.member_id=(select member_id from public.profiles where id=uid))
     order by cs.priority desc,cs.created_at desc limit 1
   ) else null end,
   'introductions',case when coalesce(prefs.introductions,true) and to_regclass('public.community_introduction_requests') is not null then coalesce((
     select jsonb_agg(x order by x.updated_at desc) from (
       select ir.id,ir.status,ir.updated_at,ir.created_at,
              case when ir.target_user_id=uid then 'incoming' else 'outgoing' end direction,
              coalesce(cpc.display_name,'Community introduction') person_name
       from public.community_introduction_requests ir
       left join public.community_profile_cards cpc on cpc.id=ir.target_card_id
       where (ir.requester_user_id=uid or ir.target_user_id=uid)
         and ir.updated_at>=now()-(days||' days')::interval
       order by ir.updated_at desc limit 4
     ) x
   ),'[]'::jsonb) else '[]'::jsonb end
 ) into result;
 return result;
end;$function$
;

CREATE OR REPLACE FUNCTION public.get_my_family_trust_connections(p_space_id uuid)
 RETURNS TABLE(id uuid, other_network_id uuid, other_family_name character varying, status character varying, direction character varying, context_label character varying, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select e.id,
   case when e.requester_network_id=public.current_network_id() then e.recipient_network_id else e.requester_network_id end,
   n.name,e.status,
   case when e.requester_network_id=public.current_network_id() then 'outgoing'::varchar else 'incoming'::varchar end,
   e.context_label,e.created_at
 from public.community_trust_edges e
 join public.networks n on n.id=case when e.requester_network_id=public.current_network_id() then e.recipient_network_id else e.requester_network_id end
 where e.space_id=p_space_id and public.current_network_id() in(e.requester_network_id,e.recipient_network_id)
 order by case e.status when 'pending' then 0 when 'accepted' then 1 else 2 end,e.updated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_feature_announcements()
 RETURNS TABLE(feature_key character varying, announcement_version integer, rollout_state character varying, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select f.feature_key,f.announcement_version,f.rollout_state,f.updated_at
  from public.platform_feature_flags f
  left join public.network_feature_settings s
    on s.network_id=public.current_network_id() and s.feature_key=f.feature_key
  where f.announcement_version>0
    and (
      case f.rollout_state
        when 'released' then true
        when 'test' then public.is_platform_owner()
        when 'pilot' then public.is_platform_owner() or coalesce(public.current_network_id()=any(f.pilot_network_ids),false)
        else false
      end
    )
    and (f.bundle_key='admin' or coalesce(s.enabled,true))
    and not exists(
      select 1 from public.user_feature_discoveries d
      where d.user_id=auth.uid() and d.feature_key=f.feature_key and d.announcement_version=f.announcement_version
    )
  order by f.updated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_federated_introductions_v2()
 RETURNS TABLE(id uuid, direction text, status character varying, scope_key character varying, request_title character varying, requester_alias character varying, message character varying, requester_contact_note text, target_response_note text, target_contact_note text, target_display_name character varying, target_headline character varying, target_network_name character varying, umbrella_name character varying, trust_path_label text, created_at timestamp with time zone, responded_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select i.id,
  case when i.target_user_id=auth.uid() then 'inbound' else 'outbound' end::text,
  i.status,r.scope_key,r.title,i.requester_alias,i.message,
  case when i.requester_user_id=auth.uid() or i.status='accepted' then i.requester_contact_note else null end::text,
  i.target_response_note::text,
  case when i.target_user_id=auth.uid() or i.status='accepted' then i.target_contact_note else null end::text,
  sp.display_name,sp.headline,n.name,u.name,i.trust_path_snapshot,i.created_at,i.responded_at,i.updated_at
 from public.federated_introductions i
 join public.federated_requests r on r.id=i.request_id
 join public.federated_scope_profiles sp on sp.id=i.target_scope_profile_id
 join public.networks n on n.id=sp.network_id
 join public.federation_umbrellas u on u.id=sp.umbrella_id
 where i.requester_user_id=auth.uid() or i.target_user_id=auth.uid()
 order by case when i.status='pending' then 0 else 1 end,i.updated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_federated_outcome_candidates()
 RETURNS TABLE(introduction_id uuid, request_id uuid, scope_key character varying, request_title character varying, requester_alias character varying, target_display_name character varying, source_network_name character varying, target_network_name character varying, umbrella_name character varying, trust_path_label text, accepted_at timestamp with time zone, my_role text, receipt_id uuid, receipt_created_at timestamp with time zone, my_outcome_code character varying, my_outcome_note character varying, counterparty_outcome_code character varying, counterparty_outcome_recorded_at timestamp with time zone, request_status character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select i.id,r.id,r.scope_key,r.title,i.requester_alias,sp.display_name,tr.source_network_name,tr.target_network_name,tr.umbrella_name,tr.trust_path_snapshot,i.responded_at,
  case when i.requester_user_id=auth.uid() then 'requester' else 'recipient' end::text,
  tr.id,tr.created_at,mine.outcome_code,mine.note,other.outcome_code,other.recorded_at,r.status
 from public.federated_introductions i
 join public.federated_requests r on r.id=i.request_id
 join public.federated_scope_profiles sp on sp.id=i.target_scope_profile_id
 join public.federated_trust_receipts tr on tr.introduction_id=i.id
 left join public.federated_introduction_outcomes mine on mine.introduction_id=i.id and mine.actor_user_id=auth.uid()
 left join public.federated_introduction_outcomes other on other.introduction_id=i.id and other.actor_user_id<>auth.uid()
 where i.status='accepted' and (i.requester_user_id=auth.uid() or i.target_user_id=auth.uid())
 order by coalesce(mine.updated_at,i.responded_at) desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_federated_request_routes(p_request_id uuid)
 RETURNS TABLE(id uuid, request_id uuid, target_scope_profile_id uuid, display_name character varying, headline character varying, summary character varying, location_label character varying, tags text[], contact_mode character varying, target_network_id uuid, target_network_name character varying, umbrella_id uuid, umbrella_name character varying, score integer, reasons text[], trust_path_label text, status character varying, generated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select rr.id,rr.request_id,rr.target_scope_profile_id,sp.display_name,sp.headline,sp.summary,sp.location_label,sp.tags,sp.contact_mode,sp.network_id,n.name,sp.umbrella_id,u.name,rr.score,rr.reasons,rr.trust_path_label,rr.status,rr.generated_at
 from public.federated_request_routes rr
 join public.federated_requests r on r.id=rr.request_id and r.requester_user_id=auth.uid()
 join public.federated_scope_profiles sp on sp.id=rr.target_scope_profile_id
 join public.networks n on n.id=sp.network_id
 join public.federation_umbrellas u on u.id=sp.umbrella_id
 join public.network_umbrella_affiliations a on a.network_id=sp.network_id and a.umbrella_id=sp.umbrella_id and a.status='approved'
 join public.network_passports np on np.network_id=sp.network_id and np.visibility in ('federation','public')
 where rr.request_id=p_request_id and sp.active and u.status='active' and lower(sp.scope_key)=lower(r.scope_key)
   and exists(select 1 from unnest(np.participation_scopes) x where lower(x)=lower(r.scope_key))
 order by case rr.status when 'shortlisted' then 0 when 'suggested' then 1 else 2 end,rr.score desc,rr.generated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_federated_requests()
 RETURNS TABLE(id uuid, scope_key character varying, title character varying, description character varying, location_label character varying, tags text[], status character varying, network_id uuid, network_name character varying, umbrella_id uuid, umbrella_name character varying, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select r.id,r.scope_key,r.title,r.description,r.location_label,r.tags,r.status,r.source_network_id,n.name,r.umbrella_id,u.name,r.created_at,r.updated_at
 from public.federated_requests r join public.networks n on n.id=r.source_network_id join public.federation_umbrellas u on u.id=r.umbrella_id
 where r.requester_user_id=auth.uid() order by r.updated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_federated_scope_contexts()
 RETURNS TABLE(network_id uuid, network_name character varying, umbrella_id uuid, umbrella_name character varying, scope_key text, passport_visibility character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select distinct n.id,n.name,u.id,u.name,s.scope_key,p.visibility
 from public.network_memberships nm
 join public.networks n on n.id=nm.network_id and n.status='active'
 join public.network_umbrella_affiliations a on a.network_id=n.id and a.status='approved'
 join public.federation_umbrellas u on u.id=a.umbrella_id and u.status='active'
 join public.network_passports p on p.network_id=n.id and p.visibility in ('federation','public')
 cross join lateral unnest(p.participation_scopes) s(scope_key)
 where nm.user_id=auth.uid() and nm.status='active'
 order by n.name,u.name,s.scope_key;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_federated_scope_profiles()
 RETURNS TABLE(id uuid, scope_key character varying, display_name character varying, headline character varying, summary character varying, location_label character varying, tags text[], contact_mode character varying, network_id uuid, network_name character varying, umbrella_id uuid, umbrella_name character varying, active boolean, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select p.id,p.scope_key,p.display_name,p.headline,p.summary,p.location_label,p.tags,p.contact_mode,p.network_id,n.name,p.umbrella_id,u.name,p.active,p.updated_at
 from public.federated_scope_profiles p join public.networks n on n.id=p.network_id join public.federation_umbrellas u on u.id=p.umbrella_id
 where p.owner_user_id=auth.uid() order by p.updated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_federated_trust_receipt(p_introduction_id uuid)
 RETURNS TABLE(id uuid, introduction_id uuid, request_id uuid, scope_key character varying, request_title character varying, source_network_name character varying, target_network_name character varying, umbrella_name character varying, trust_path_label text, routed_at timestamp with time zone, introduction_requested_at timestamp with time zone, accepted_at timestamp with time zone, created_at timestamp with time zone, requester_outcome_code character varying, recipient_outcome_code character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select tr.id,tr.introduction_id,tr.request_id,tr.scope_key,tr.request_title,tr.source_network_name,tr.target_network_name,tr.umbrella_name,tr.trust_path_snapshot,tr.routed_at,tr.introduction_requested_at,tr.accepted_at,tr.created_at,
  reqo.outcome_code,repo.outcome_code
 from public.federated_trust_receipts tr
 join public.federated_introductions i on i.id=tr.introduction_id
 left join public.federated_introduction_outcomes reqo on reqo.introduction_id=i.id and reqo.actor_user_id=i.requester_user_id
 left join public.federated_introduction_outcomes repo on repo.introduction_id=i.id and repo.actor_user_id=i.target_user_id
 where tr.introduction_id=p_introduction_id and (i.requester_user_id=auth.uid() or i.target_user_id=auth.uid());
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_network_launch_snapshots()
 RETURNS TABLE(network_id uuid, network_name character varying, vertical_kind character varying, role character varying, seeded_items bigint, active_members bigint, claimed_identities bigint, accepted_bridges bigint, accepted_introductions bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with mine as (
  select n.id,n.name,n.vertical_kind,nm.role
  from public.network_memberships nm join public.networks n on n.id=nm.network_id
  where nm.user_id=auth.uid() and nm.status='active' and nm.role in ('owner','admin') and n.status='active'
 )
 select m.id,m.name,m.vertical_kind,m.role,
  case when m.vertical_kind='family' then (select count(*) from public.family_members fm where fm.network_id=m.id and fm.profile_status='approved') when m.vertical_kind='alumni' then (select count(*) from public.alumni_profiles ap where ap.network_id=m.id) else (select count(*) from public.network_entities e where e.network_id=m.id) end,
  (select count(*) from public.network_memberships nm where nm.network_id=m.id and nm.status='active'),
  case when m.vertical_kind='family' then (select count(*) from public.network_memberships nm where nm.network_id=m.id and nm.status='active' and nm.member_id is not null) when m.vertical_kind='alumni' then (select count(*) from public.alumni_profiles ap where ap.network_id=m.id and ap.claimed_by is not null) else (select count(*) from public.network_entities e where e.network_id=m.id and e.owner_user_id is not null) end,
  (select count(*) from public.network_trust_bridges b where b.status='accepted' and m.id in (b.requester_network_id,b.recipient_network_id)),
  (select count(*) from public.trusted_introduction_requests r where r.status='accepted' and m.id in (r.source_network_id,r.target_network_id))
 from mine m order by m.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_network_passports()
 RETURNS TABLE(network_id uuid, network_name character varying, vertical_kind character varying, public_slug character varying, tagline character varying, summary character varying, location_label character varying, established_label character varying, external_url character varying, capabilities text[], participation_scopes text[], visibility character varying, directory_discoverable boolean, verification_state character varying, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select n.id,n.name,n.vertical_kind,coalesce(p.public_slug,n.slug),coalesce(p.tagline,''),coalesce(p.summary,''),coalesce(p.location_label,''),coalesce(p.established_label,''),coalesce(p.external_url,''),coalesce(p.capabilities,'{}'),coalesce(p.participation_scopes,'{}'),coalesce(p.visibility,'private'),coalesce(p.directory_discoverable,false),coalesce(p.verification_state,'self_declared'),p.updated_at
 from public.network_memberships nm join public.networks n on n.id=nm.network_id left join public.network_passports p on p.network_id=n.id
 where nm.user_id=auth.uid() and nm.status='active' and n.status='active'
 order by n.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_network_purge_receipt(p_network_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select coalesce((select jsonb_build_object('networkId',purged_network_id,'purgedAt',purged_at,'relationalResidue',relational_residue,'storageResidue',storage_residue,'verifierVersion',verifier_version,'clean',relational_residue=0 and storage_residue=0)
 from public.network_purge_receipts where purged_network_id=p_network_id and purged_by=auth.uid() order by purged_at desc limit 1),'{}'::jsonb);
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_network_trust_bridges()
 RETURNS TABLE(id uuid, requester_network_id uuid, requester_network_name character varying, recipient_network_id uuid, recipient_network_name character varying, relationship_type character varying, status character varying, context_label character varying, discovery_enabled boolean, introductions_enabled boolean, path_traversal_enabled boolean, direction character varying, can_review boolean, can_revoke boolean, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with mine as (
  select nm.network_id,nm.role from public.network_memberships nm where nm.user_id=auth.uid() and nm.status='active'
 )
 select b.id,b.requester_network_id,rn.name,b.recipient_network_id,tn.name,b.relationship_type,b.status,b.context_label,
  coalesce((b.capabilities->>'discovery')::boolean,false),coalesce((b.capabilities->>'introductions')::boolean,false),coalesce((b.capabilities->>'pathTraversal')::boolean,false),
  case when exists(select 1 from mine m where m.network_id=b.recipient_network_id) and not exists(select 1 from mine m where m.network_id=b.requester_network_id) then 'incoming'::varchar else 'outgoing'::varchar end,
  (b.status='pending' and public.is_network_admin(b.recipient_network_id)),
  (b.status='accepted' and (public.is_network_admin(b.requester_network_id) or public.is_network_admin(b.recipient_network_id))),
  b.created_at,b.updated_at
 from public.network_trust_bridges b
 join public.networks rn on rn.id=b.requester_network_id
 join public.networks tn on tn.id=b.recipient_network_id
 where (exists(select 1 from mine m where m.network_id in(b.requester_network_id,b.recipient_network_id)))
   and (b.status='accepted' or public.is_network_admin(b.requester_network_id) or public.is_network_admin(b.recipient_network_id))
 order by case b.status when 'pending' then 0 when 'accepted' then 1 else 2 end,b.updated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_networks()
 RETURNS TABLE(network_id uuid, name character varying, slug character varying, role character varying, status character varying, storage_limit_bytes bigint, photo_upload_enabled boolean, photo_max_bytes integer, is_active boolean, vertical_kind character varying, network_template character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select n.id,n.name,n.slug,nm.role,nm.status,n.storage_limit_bytes,n.photo_upload_enabled,n.photo_max_bytes,
         coalesce(p.active_network_id=n.id,false),n.vertical_kind,coalesce(ns.network_template,n.vertical_kind)
  from public.network_memberships nm
  join public.networks n on n.id=nm.network_id
  left join public.profiles p on p.id=nm.user_id
  left join public.network_settings ns on ns.network_id=n.id
  where nm.user_id=auth.uid() and nm.status='active' and n.status='active'
    and (n.approval_status='approved' or public.is_platform_owner())
  order by coalesce(p.active_network_id=n.id,false) desc,n.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_pilot_feedback_context()
 RETURNS TABLE(network_id uuid, network_name character varying, vertical_kind character varying, role character varying, suggested_moment character varying, last_signal_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with mine as(
  select n.id,n.name,n.vertical_kind,nm.role
  from public.network_memberships nm join public.networks n on n.id=nm.network_id
  where nm.user_id=auth.uid() and nm.status='active' and n.status='active'
 ),last_signal as(
  select distinct on(e.source_network_id) e.source_network_id,e.event_type,e.created_at
  from public.network_effect_events e join mine m on m.id=e.source_network_id
  where e.actor_user_id=auth.uid() and e.created_at>=now()-interval '30 days'
  order by e.source_network_id,e.created_at desc
 )
 select m.id,m.name,m.vertical_kind,m.role,
  case ls.event_type when 'introduction_accepted' then 'outcome' when 'introduction_declined' then 'introduction' when 'introduction_requested' then 'introduction' when 'discovery_opportunity' then 'discovery' when 'discovery_search' then 'discovery' else 'general' end::varchar,
  ls.created_at
 from mine m left join last_signal ls on ls.source_network_id=m.id
 order by ls.created_at desc nulls last,m.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_pilot_launch_console()
 RETURNS TABLE(network_id uuid, network_name character varying, vertical_kind character varying, role character varying, seeded_items bigint, active_members bigint, claimed_identities bigint, accepted_bridges bigint, discovery_searches_30d bigint, introduction_requests_30d bigint, accepted_introductions_30d bigint, last_activity_at timestamp with time zone, age_days integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with mine as(select n.id,n.name,n.vertical_kind,n.created_at,nm.role from public.network_memberships nm join public.networks n on n.id=nm.network_id where nm.user_id=auth.uid() and nm.status='active' and nm.role in ('owner','admin') and n.status='active'),events as(select e.source_network_id,coalesce(sum(e.event_count) filter(where e.event_type='discovery_search' and e.created_at>=now()-interval '30 days'),0)::bigint discovery_searches,coalesce(sum(e.event_count) filter(where e.event_type='introduction_requested' and e.created_at>=now()-interval '30 days'),0)::bigint introduction_requests,coalesce(sum(e.event_count) filter(where e.event_type='introduction_accepted' and e.created_at>=now()-interval '30 days'),0)::bigint accepted_introductions,max(e.created_at) last_event_at from public.network_effect_events e join mine m on m.id=e.source_network_id group by e.source_network_id)
 select m.id,m.name,m.vertical_kind,m.role,case when m.vertical_kind='family' then (select count(*) from public.family_members fm where fm.network_id=m.id and fm.profile_status='approved') when m.vertical_kind='alumni' then (select count(*) from public.alumni_profiles ap where ap.network_id=m.id) else (select count(*) from public.network_entities ne where ne.network_id=m.id) end,(select count(*) from public.network_memberships nm where nm.network_id=m.id and nm.status='active'),case when m.vertical_kind='family' then (select count(*) from public.network_memberships nm where nm.network_id=m.id and nm.status='active' and nm.member_id is not null) when m.vertical_kind='alumni' then (select count(*) from public.alumni_profiles ap where ap.network_id=m.id and ap.claimed_by is not null) else (select count(*) from public.network_entities ne where ne.network_id=m.id and ne.owner_user_id is not null) end,(select count(*) from public.network_trust_bridges b where b.status='accepted' and m.id in(b.requester_network_id,b.recipient_network_id)),coalesce(ev.discovery_searches,0),coalesce(ev.introduction_requests,0),coalesce(ev.accepted_introductions,0),greatest(m.created_at,coalesce((select max(nm.joined_at) from public.network_memberships nm where nm.network_id=m.id),m.created_at),coalesce(ev.last_event_at,m.created_at)),greatest(0,floor(extract(epoch from(now()-m.created_at))/86400))::integer from mine m left join events ev on ev.source_network_id=m.id order by m.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_pilot_learning_summary(p_days integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with cfg as(select greatest(7,least(coalesce(p_days,30),90)) d),
 admin_networks as(
  select n.id,n.name from public.network_memberships nm join public.networks n on n.id=nm.network_id
  where nm.user_id=auth.uid() and nm.status='active' and nm.role in('owner','admin') and n.status='active'
 ),f as(
  select pf.*,an.name network_name from public.pilot_feedback pf join admin_networks an on an.id=pf.network_id,cfg
  where pf.created_at>=now()-(cfg.d||' days')::interval
 ),friction as(
  select friction_code,count(*) c from f where friction_code<>'none' group by friction_code order by c desc,friction_code limit 1
 ),per_network as(
  select network_id,network_name,count(*) feedback,count(*) filter(where outcome='helpful') helpful,count(*) filter(where outcome='partial') partial,count(*) filter(where outcome='blocked') blocked
  from f group by network_id,network_name order by blocked desc,feedback desc,network_name
 ),notes as(
  select network_name,moment_type,outcome,friction_code,note,created_at from f where note is not null order by created_at desc limit 5
 )
 select jsonb_build_object(
  'days',(select d from cfg),
  'feedback',(select count(*) from f),
  'helpful',(select count(*) from f where outcome='helpful'),
  'partial',(select count(*) from f where outcome='partial'),
  'blocked',(select count(*) from f where outcome='blocked'),
  'helpfulRate',case when (select count(*) from f)=0 then 0 else round(100.0*(select count(*) from f where outcome='helpful')/(select count(*) from f))::int end,
  'topFriction',(select friction_code from friction),
  'networks',coalesce((select jsonb_agg(jsonb_build_object('networkId',network_id,'networkName',network_name,'feedback',feedback,'helpful',helpful,'partial',partial,'blocked',blocked)) from per_network),'[]'::jsonb),
  'recentNotes',coalesce((select jsonb_agg(jsonb_build_object('networkName',network_name,'moment',moment_type,'outcome',outcome,'friction',friction_code,'note',note,'createdAt',created_at)) from notes),'[]'::jsonb)
 );
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_pilot_product_decision_gate(p_days integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with cfg as(select greatest(7,least(coalesce(p_days,30),90)) d,5 minimum_evidence),
 admin_networks as(
  select distinct n.id,n.name from public.network_memberships nm join public.networks n on n.id=nm.network_id
  where nm.user_id=auth.uid() and nm.status='active' and nm.role in('owner','admin') and n.status='active'
 ),f as(
  select pf.* from public.pilot_feedback pf join admin_networks an on an.id=pf.network_id,cfg
  where pf.created_at>=now()-(cfg.d||' days')::interval
 ),moments as(
  select unnest(array['launch','participation','claim','bridge','discovery','introduction','outcome','general'])::text moment_type
 ),agg as(
  select m.moment_type,
   count(f.id)::int feedback,
   count(f.id) filter(where f.outcome='helpful')::int helpful,
   count(f.id) filter(where f.outcome='partial')::int partial,
   count(f.id) filter(where f.outcome='blocked')::int blocked
  from moments m left join f on f.moment_type=m.moment_type group by m.moment_type
 ),friction as(
  select moment_type,friction_code,count(*) c,row_number() over(partition by moment_type order by count(*) desc,friction_code) rn
  from f where friction_code<>'none' group by moment_type,friction_code
 ),scored as(
  select a.*,
   case when a.feedback=0 then 0 else round(100.0*a.helpful/a.feedback)::int end helpful_rate,
   fr.friction_code top_friction,
   case
    when a.feedback<(select minimum_evidence from cfg) then 'hold'
    when a.blocked::numeric/a.feedback>=0.40 then 'fix'
    when a.helpful::numeric/a.feedback>=0.70 then 'invest'
    when (a.partial+a.blocked)::numeric/a.feedback>=0.60 then 'fix'
    else 'hold'
   end recommendation,
   case when a.feedback>=12 then 'high' when a.feedback>=(select minimum_evidence from cfg) then 'medium' else 'low' end confidence,
   case
    when a.feedback=0 then 'No pilot evidence yet.'
    when a.feedback<(select minimum_evidence from cfg) then 'Evidence is still too thin for a durable product decision.'
    when a.blocked::numeric/a.feedback>=0.40 then 'Blocked feedback is high enough to fix friction before expanding capability.'
    when a.helpful::numeric/a.feedback>=0.70 then 'Helpful feedback is strong enough to justify deeper investment.'
    when (a.partial+a.blocked)::numeric/a.feedback>=0.60 then 'Most feedback still contains friction; improve the existing experience first.'
    else 'Evidence is mixed; hold scope until the signal becomes clearer.'
   end reason
  from agg a left join friction fr on fr.moment_type=a.moment_type and fr.rn=1
 ),latest as(
  select d.* from public.pilot_product_decisions d
  where d.decided_by=auth.uid()
  order by d.created_at desc limit 10
 )
 select jsonb_build_object(
  'days',(select d from cfg),
  'totalFeedback',(select count(*) from f),
  'minimumEvidence',(select minimum_evidence from cfg),
  'readyForDecision',(select count(*) from f)>=(select minimum_evidence from cfg),
  'evidence',coalesce((select jsonb_agg(jsonb_build_object(
    'moment',moment_type,'feedback',feedback,'helpful',helpful,'partial',partial,'blocked',blocked,
    'helpfulRate',helpful_rate,'topFriction',top_friction,'recommendation',recommendation,
    'confidence',confidence,'reason',reason
   ) order by feedback desc,moment_type) from scored),'[]'::jsonb),
  'latestDecisions',coalesce((select jsonb_agg(jsonb_build_object(
    'id',id,'moment',moment_type,'disposition',disposition,'evidenceDays',evidence_days,
    'rationale',rationale,'nextAction',next_action,'createdAt',created_at
   )) from latest),'[]'::jsonb)
 );
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_push_status()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select jsonb_build_object('active_subscriptions',count(*) filter(where active),'last_seen_at',max(last_seen_at))
 from public.push_subscriptions where user_id=auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_shortlisted_federated_routes()
 RETURNS TABLE(route_id uuid, request_id uuid, request_title character varying, scope_key character varying, target_scope_profile_id uuid, target_display_name character varying, target_headline character varying, target_network_name character varying, umbrella_name character varying, score integer, trust_path_label text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select rr.id,r.id,r.title,r.scope_key,sp.id,sp.display_name,sp.headline,n.name,u.name,rr.score,rr.trust_path_label
 from public.federated_request_routes rr
 join public.federated_requests r on r.id=rr.request_id and r.requester_user_id=auth.uid() and r.status='open'
 join public.federated_scope_profiles sp on sp.id=rr.target_scope_profile_id and sp.active and sp.owner_user_id<>auth.uid()
 join public.networks n on n.id=sp.network_id and n.status='active'
 join public.federation_umbrellas u on u.id=r.umbrella_id and u.status='active'
 join public.network_umbrella_affiliations a on a.network_id=sp.network_id and a.umbrella_id=r.umbrella_id and a.status='approved'
 join public.network_passports p on p.network_id=sp.network_id and p.visibility in ('federation','public')
 where rr.status='shortlisted'
   and sp.umbrella_id=r.umbrella_id
   and lower(sp.scope_key)=lower(r.scope_key)
   and exists(select 1 from unnest(p.participation_scopes) x where lower(x)=lower(r.scope_key))
   and not exists(select 1 from public.federated_introductions fi where fi.route_id=rr.id)
 order by rr.score desc,rr.generated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_showcase_runtime_certification()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
with mine as(
 select nm.network_id from public.network_memberships nm where nm.user_id=auth.uid() and nm.status='active'
),
bridges as(
 select b.* from public.network_trust_bridges b where b.status='accepted' and exists(select 1 from mine m where m.network_id in(b.requester_network_id,b.recipient_network_id))
),
vals as(
 select
  (select count(*) from mine)::int active_networks,
  (
   select count(*) from mine m join public.networks n on n.id=m.network_id
   where case
    when n.vertical_kind='family' then exists(select 1 from public.network_memberships nm where nm.network_id=m.network_id and nm.user_id=auth.uid() and nm.status='active' and nm.member_id is not null)
    when n.vertical_kind='alumni' then exists(select 1 from public.alumni_profiles ap where ap.network_id=m.network_id and ap.claimed_by=auth.uid())
    else exists(select 1 from public.network_entities ne where ne.network_id=m.network_id and ne.owner_user_id=auth.uid() and ne.kind='person')
   end
  )::int claimed_contexts,
  (select count(*) from bridges)::int accepted_bridges,
  (select count(*) from bridges where coalesce((capabilities->>'discovery')::boolean,false))::int discovery_bridges,
  (select count(*) from bridges where coalesce((capabilities->>'introductions')::boolean,false))::int introduction_bridges,
  (select count(*) from bridges where coalesce((capabilities->>'pathTraversal')::boolean,false))::int traversal_bridges,
  (select count(*) from public.trusted_introduction_requests i where i.requester_user_id=auth.uid() and i.status='accepted')::int accepted_outcomes
)
select jsonb_build_object(
 'activeNetworks',active_networks,'claimedContexts',claimed_contexts,'acceptedBridges',accepted_bridges,
 'discoveryBridges',discovery_bridges,'introductionBridges',introduction_bridges,'traversalBridges',traversal_bridges,'acceptedOutcomes',accepted_outcomes,
 'status',case when active_networks<1 then 'blocked' when active_networks>=2 and claimed_contexts>=1 and discovery_bridges>=1 and introduction_bridges>=1 then 'ready' else 'needs_setup' end
) from vals;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_trusted_network_reach()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with mine as (
    select nm.network_id,nm.role,n.vertical_kind
    from public.network_memberships nm
    join public.networks n on n.id=nm.network_id
    where nm.user_id=auth.uid() and nm.status='active' and n.status='active'
  ), all_members as (
    select nm.network_id,nm.user_id
    from public.network_memberships nm
    join mine m on m.network_id=nm.network_id
    where nm.status='active'
  ), claimed as (
    select m.network_id
    from mine m
    where
      (m.vertical_kind='family' and exists(
        select 1 from public.network_memberships own
        where own.network_id=m.network_id and own.user_id=auth.uid() and own.status='active' and own.member_id is not null
      ))
      or (m.vertical_kind='alumni' and exists(
        select 1 from public.alumni_profiles ap
        where ap.network_id=m.network_id and ap.claimed_by=auth.uid()
      ))
      or (m.vertical_kind in ('organization','business-trust','franchise','professional') and exists(
        select 1 from public.network_entities e
        where e.network_id=m.network_id and e.owner_user_id=auth.uid()
      ))
  )
  select jsonb_build_object(
    'active_networks',(select count(*) from mine),
    'owned_networks',(select count(*) from mine where role='owner'),
    'administered_networks',(select count(*) from mine where role in ('owner','admin')),
    'verticals',(select count(distinct vertical_kind) from mine),
    'unique_member_accounts',(select count(distinct user_id) from all_members),
    'membership_edges',(select count(*) from all_members),
    'claimed_contexts',(select count(*) from claimed)
  );
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_trusted_request_contexts()
 RETURNS TABLE(network_id uuid, network_name character varying, umbrella_id uuid, umbrella_name character varying, scope_key text, passport_visibility character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select distinct n.id,n.name,u.id,u.name,s.scope_key,p.visibility
 from public.network_memberships nm
 join public.networks n on n.id=nm.network_id and n.status='active'
 join public.network_umbrella_affiliations a on a.network_id=n.id and a.status='approved'
 join public.federation_umbrellas u on u.id=a.umbrella_id and u.status='active'
 join public.network_passports p on p.network_id=n.id and p.visibility in ('federation','public')
 cross join lateral unnest(p.participation_scopes) s(scope_key)
 where nm.user_id=auth.uid() and nm.status='active'
 order by n.name,u.name,s.scope_key;
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_activities(p_activity_type text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, activity_type character varying, title character varying, body text, starts_at timestamp with time zone, ends_at timestamp with time zone, place character varying, visibility character varying, created_by uuid, my_rsvp character varying, going_count bigint, my_liked boolean, like_count bigint, comment_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select a.id,a.activity_type,a.title,a.body,a.starts_at,a.ends_at,a.place,a.visibility,a.created_by,r.response,
   (select count(*) from public.network_activity_rsvps rr where rr.activity_id=a.id and rr.response='going'),
   exists(select 1 from public.network_activity_reactions lr where lr.activity_id=a.id and lr.user_id=auth.uid()),
   (select count(*) from public.network_activity_reactions lr where lr.activity_id=a.id),
   (select count(*) from public.network_activity_comments cc where cc.activity_id=a.id)
 from public.network_activities a left join public.network_activity_rsvps r on r.activity_id=a.id and r.user_id=auth.uid()
 where a.network_id=public.current_network_id() and public.is_network_member(a.network_id)
   and (a.visibility='members' or a.created_by=auth.uid() or public.is_network_admin(a.network_id))
   and (p_activity_type is null or p_activity_type='' or a.activity_type=p_activity_type)
 order by coalesce(a.starts_at,a.created_at) desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_activity_comments(p_activity_id uuid)
 RETURNS TABLE(id uuid, body character varying, created_at timestamp with time zone, author_label text, is_mine boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select c.id,c.body,c.created_at,coalesce(e.label,'Member')::text,(c.user_id=auth.uid())
 from public.network_activity_comments c
 left join public.network_entities e on e.network_id=c.network_id and e.owner_user_id=c.user_id
 where c.network_id=public.current_network_id() and c.activity_id=p_activity_id and public.is_network_member(c.network_id)
 order by c.created_at asc limit 100;
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_activity_social_flags()
 RETURNS TABLE(activity_id uuid, metadata jsonb, author_label text, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select a.id,
         coalesce(a.metadata,'{}'::jsonb),
         coalesce(e.label,'Community member')::text,
         a.created_at
  from public.network_activities a
  left join public.network_entities e
    on e.network_id=a.network_id and e.owner_user_id=a.created_by
  where a.network_id=public.current_network_id()
    and public.is_network_member(a.network_id)
    and (a.visibility='members' or a.created_by=auth.uid() or public.is_network_admin(a.network_id));
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_affiliated_entities()
 RETURNS TABLE(entity_id uuid, external_ref uuid, entity_kind character varying, entity_label character varying, owner_user_id uuid, metadata jsonb, visibility character varying, affiliations jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select e.id,e.external_ref,e.kind,e.label,e.owner_user_id,e.metadata,e.visibility,
 coalesce((select jsonb_object_agg(x.dimension_key,x.labels) from (select d.dimension_key,jsonb_agg(v.label order by v.label) labels from public.network_entity_affiliations a join public.network_dimensions d on d.id=a.dimension_id and d.network_id=a.network_id join public.network_dimension_values v on v.id=a.value_id and v.network_id=a.network_id where a.entity_id=e.id and a.network_id=e.network_id group by d.dimension_key)x),'{}'::jsonb)
 from public.network_entities e where e.network_id=public.current_network_id() and public.is_network_member(e.network_id) and (e.visibility='members' or e.owner_user_id=auth.uid() or public.is_network_admin(e.network_id)) order by e.label;
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_affiliated_entities_page(p_after_label text DEFAULT NULL::text, p_after_id uuid DEFAULT NULL::uuid, p_limit integer DEFAULT 50)
 RETURNS TABLE(entity_id uuid, external_ref uuid, entity_kind character varying, entity_label character varying, owner_user_id uuid, metadata jsonb, visibility character varying, affiliations jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select e.id,e.external_ref,e.kind,e.label,e.owner_user_id,e.metadata,e.visibility,
 coalesce((
   select jsonb_object_agg(x.dimension_key,x.labels)
   from (
     select d.dimension_key,jsonb_agg(v.label order by v.label) labels
     from public.network_entity_affiliations a
     join public.network_dimensions d on d.id=a.dimension_id and d.network_id=a.network_id
     join public.network_dimension_values v on v.id=a.value_id and v.network_id=a.network_id
     where a.entity_id=e.id and a.network_id=e.network_id
     group by d.dimension_key
   ) x
 ),'{}'::jsonb)
 from public.network_entities e
 where e.network_id=public.current_network_id()
   and public.is_network_member(e.network_id)
   and (e.visibility='members' or e.owner_user_id=auth.uid() or public.is_network_admin(e.network_id))
   and (p_after_label is null or p_after_id is null or (e.label,e.id)>(p_after_label,p_after_id))
 order by e.label,e.id
 limit least(greatest(coalesce(p_limit,50),1),200);
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_analytics()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare result jsonb;
begin
  if not public.is_admin() then raise exception 'Administrator access is required.' using errcode='42501'; end if;
  with base as (
    select * from public.family_members where profile_status='approved'
  ),
  gens as (
    select coalesce(jsonb_agg(jsonb_build_object('generation',generation_level,'count',cnt) order by generation_level),'[]'::jsonb) value
    from (select generation_level,count(*)::int cnt from base group by generation_level) x
  ),
  cities as (
    select coalesce(jsonb_agg(jsonb_build_object('city',city,'country',country,'count',cnt) order by cnt desc,city),'[]'::jsonb) value
    from (select coalesce(city,'Unknown') city,coalesce(country,'') country,count(*)::int cnt from base group by city,country) x
  ),
  professions as (
    select coalesce(jsonb_agg(jsonb_build_object('profession',profession,'count',cnt) order by cnt desc,profession),'[]'::jsonb) value
    from (select coalesce(nullif(trim(profession),''),'Not specified') profession,count(*)::int cnt from base group by 1) x
  )
  select jsonb_build_object(
    'members',(select count(*) from base),
    'living',(select count(*) from base where date_of_death is null),
    'deceased',(select count(*) from base where date_of_death is not null),
    'generations',(select value from gens),
    'cities',(select value from cities),
    'professions',(select value from professions),
    'relationships',(select count(*) from public.family_relationships r join base a on a.id=r.person_id join base b on b.id=r.related_person_id),
    'mapped',(select count(*) from base where latitude is not null and longitude is not null),
    'memories',(select count(*) from public.memories),
    'life_events',(select count(*) from public.member_life_events)
  ) into result;
  return result;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_approval_status(p_network_id uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select n.approval_status from public.networks n
  where n.id=p_network_id and (n.created_by=auth.uid() or public.is_network_member(n.id) or public.is_platform_owner());
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_ballots_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();admin boolean;begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501';end if;admin:=public.is_network_admin(nid);
 return jsonb_build_object(
  'is_admin',admin,
  'people',coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'label',e.label) order by e.label) from public.network_entities e where e.network_id=nid and e.kind='person'),'[]'::jsonb),
  'ballots',coalesce((select jsonb_agg(jsonb_build_object(
   'id',b.id,'ballot_type',b.ballot_type,'title',b.title,'description',b.description,'status',b.status,'eligibility_mode',b.eligibility_mode,'max_choices',b.max_choices,'secret_ballot',b.secret_ballot,'allow_nominations',b.allow_nominations,'opens_at',b.opens_at,'closes_at',b.closes_at,
   'eligible_count',(select count(*) from public.network_ballot_eligibility e where e.ballot_id=b.id),
   'participation_count',(select count(*) from public.network_ballot_participation p where p.ballot_id=b.id),
   'has_voted',exists(select 1 from public.network_ballot_participation p where p.ballot_id=b.id and p.user_id=auth.uid()),
   'can_vote',(b.status='open' and (b.opens_at is null or now()>=b.opens_at) and (b.closes_at is null or now()<=b.closes_at) and exists(select 1 from public.network_ballot_eligibility e where e.ballot_id=b.id and e.user_id=auth.uid()) and not exists(select 1 from public.network_ballot_participation p where p.ballot_id=b.id and p.user_id=auth.uid())),
   'options',coalesce((select jsonb_agg(jsonb_build_object('id',o.id,'label',o.label,'description',o.description,'candidate_entity_id',o.candidate_entity_id,'votes',case when b.status='published' or (admin and b.status in ('closed','published')) then (select count(*) from public.network_ballot_votes v where v.option_id=o.id) else null end) order by o.sort_order,o.label) from public.network_ballot_options o where o.ballot_id=b.id),'[]'::jsonb),
   'nominations',coalesce((select jsonb_agg(jsonb_build_object('id',n.id,'nominee_entity_id',n.nominee_entity_id,'nominee_label',n.nominee_label,'statement',n.statement,'status',n.status,'nominated_by_me',n.nominated_by=auth.uid()) order by n.created_at desc) from public.network_ballot_nominations n where n.ballot_id=b.id and (admin or n.status='approved' or n.nominated_by=auth.uid())),'[]'::jsonb)
  ) order by b.created_at desc) from public.network_ballots b where b.network_id=nid and (admin or b.status<>'draft' or (b.status='draft' and b.allow_nominations and b.ballot_type='election') or b.created_by=auth.uid())),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.get_network_creation_policy()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((select network_creation_approval_required from public.platform_onboarding_settings where id='default'),false);
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_funds_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); admin boolean; mode text:='admins'; result jsonb;
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501'; end if;
 admin:=public.is_network_admin(nid);
 if exists(select 1 from public.networks where id=nid and vertical_kind='family-association') then
   select coalesce(s.finance_visibility,'admins') into mode from public.family_association_settings s where s.network_id=nid;
 end if;
 result:=jsonb_build_object(
  'is_admin',admin,'visibility_mode',mode,
  'funds',coalesce((select jsonb_agg(jsonb_build_object(
    'id',f.id,'name',f.name,'fund_kind',f.fund_kind,'purpose',f.purpose,'target_amount',f.target_amount,'opening_balance',f.opening_balance,
    'visibility',f.visibility,'status',f.status,'membership_year_id',f.membership_year_id,'activity_id',f.activity_id,
    'activity_title',a.title,'year_label',y.label,
    'collected',coalesce((select sum(t.amount) from public.network_fund_transactions t where t.fund_id=f.id and t.transaction_kind in ('collection','transfer_in')),0),
    'spent',coalesce((select sum(t.amount) from public.network_fund_transactions t where t.fund_id=f.id and t.transaction_kind in ('expense','refund','transfer_out')),0),
    'balance',f.opening_balance+coalesce((select sum(public.e6_fund_signed_amount(t.transaction_kind,t.amount)) from public.network_fund_transactions t where t.fund_id=f.id),0)
   ) order by f.status,f.created_at desc)
   from public.network_funds f left join public.network_activities a on a.id=f.activity_id and a.network_id=f.network_id
   left join public.family_association_membership_years y on y.id=f.membership_year_id and y.network_id=f.network_id
   where f.network_id=nid and (admin or (mode<>'admins' and f.visibility<>'admins'))),'[]'::jsonb),
  'transactions',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'fund_id',t.fund_id,'fund_name',f.name,'transaction_kind',t.transaction_kind,'amount',t.amount,'signed_amount',public.e6_fund_signed_amount(t.transaction_kind,t.amount),'source_entity_id',t.source_entity_id,'source_label',e.label,'receipt_no',t.receipt_no,'payment_method',t.payment_method,'reference',t.reference,'note',t.note,'visibility',t.visibility,'occurred_on',t.occurred_on,'created_at',t.created_at) order by t.occurred_on desc,t.created_at desc)
   from public.network_fund_transactions t join public.network_funds f on f.id=t.fund_id left join public.network_entities e on e.id=t.source_entity_id and e.network_id=t.network_id
   where t.network_id=nid and (admin or (mode='members' and t.visibility<>'admins') or (mode='highlighted' and t.visibility='highlighted'))),'[]'::jsonb),
  'membership_dues',case when admin then coalesce((select jsonb_agg(jsonb_build_object('membership_id',m.id,'membership_year_id',m.membership_year_id,'year_label',y.label,'family_entity_id',m.family_entity_id,'family_label',f.label,'representative_label',r.label,'amount_due',m.amount_due,'amount_paid',m.amount_paid,'outstanding',greatest(m.amount_due-m.amount_paid,0),'payment_status',m.payment_status,'status',m.status) order by y.start_date desc,f.label)
    from public.family_association_family_memberships m join public.family_association_membership_years y on y.id=m.membership_year_id join public.network_entities f on f.id=m.family_entity_id left join public.network_entities r on r.id=m.representative_entity_id where m.network_id=nid and m.status in ('active','grace','pending')),'[]'::jsonb) else '[]'::jsonb end,
  'events',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'title',a.title,'starts_at',a.starts_at) order by a.starts_at desc nulls last) from public.network_activities a where a.network_id=nid and a.activity_type='event'),'[]'::jsonb)
 );
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_network_groups()
 RETURNS TABLE(id uuid, name character varying, group_type character varying, description text, member_count bigint, my_member boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select g.id,g.name,g.group_type,g.description,
   (select count(*) from public.network_group_memberships gm where gm.group_id=g.id and gm.network_id=g.network_id),
   exists(select 1 from public.network_group_memberships gm where gm.group_id=g.id and gm.network_id=g.network_id and gm.user_id=auth.uid())
 from public.network_groups g
 where g.network_id=public.current_network_id() and public.is_network_member(g.network_id) order by g.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_logical_backup(p_network_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
 actor_role text;
 network_row jsonb;
 datasets jsonb:='{}'::jsonb;
 rows jsonb;
 r record;
 excluded text[]:=array['network_join_codes','family_join_codes','network_bridge_codes','network_purge_receipts','alumni_invitations','hs_resident_invitations'];
begin
 select role into actor_role from public.network_memberships where network_id=p_network_id and user_id=auth.uid() and status='active';
 if actor_role is null or actor_role not in ('owner','admin') then raise exception 'Network administrator access required.' using errcode='42501'; end if;
 select to_jsonb(n) into network_row from public.networks n where n.id=p_network_id;
 if network_row is null then raise exception 'Network not found.' using errcode='P0002'; end if;
 for r in
  select distinct c.table_name
  from information_schema.columns c
  where c.table_schema='public' and c.column_name='network_id'
    and c.table_name<>'networks' and not (c.table_name=any(excluded))
  order by c.table_name
 loop
  execute format('select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),''[]''::jsonb) from public.%I t where t.network_id=$1',r.table_name) into rows using p_network_id;
  datasets:=datasets||jsonb_build_object(r.table_name,coalesce(rows,'[]'::jsonb));
 end loop;
 return jsonb_build_object(
  'format','trustweave-network-backup','version','xp5-1','schemaVersion','xp5-1','exportedAt',clock_timestamp(),
  'networkId',p_network_id,'network',network_row,'datasets',datasets,
  'excludedSecurityDatasets',excluded,
  'restore',jsonb_build_object('fullAutomaticRestore',false,'guidedWorkbookReimport',true,'reason','Security credentials and provider-owned identities are deliberately not portable.')
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.get_network_media_management_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();admin boolean;begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501';end if;admin:=public.is_network_admin(nid);
 return jsonb_build_object(
  'is_admin',admin,
  'media_usage_bytes',(select media_usage_bytes from public.networks where id=nid),
  'storage_limit_bytes',(select storage_limit_bytes from public.networks where id=nid),
  'assets',coalesce((select jsonb_agg(jsonb_build_object(
    'id',m.id,'bucket',m.bucket,'object_path',m.object_path,'thumbnail_path',m.thumbnail_path,'media_kind',m.media_kind,'entity_type',m.entity_type,'entity_id',m.entity_id,
    'mime_type',m.mime_type,'bytes',m.bytes,'thumbnail_bytes',m.thumbnail_bytes,'width',m.width,'height',m.height,'lifecycle_state',m.lifecycle_state,'created_at',m.created_at,'archived_at',m.archived_at,'deleted_at',m.deleted_at,'delete_reason',m.delete_reason,'owned_by_me',m.owner_user_id=auth.uid(),
    'unbound',m.entity_id is null
   ) order by m.created_at desc) from public.network_media_assets m where m.network_id=nid and (admin or m.owner_user_id=auth.uid())),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.get_network_media_summary()
 RETURNS TABLE(media_usage_bytes bigint, storage_limit_bytes bigint, registered_assets bigint, registered_main_bytes bigint, registered_thumbnail_bytes bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select n.media_usage_bytes,n.storage_limit_bytes,
   (select count(*) from public.network_media_assets m where m.network_id=n.id and m.lifecycle_state<>'deleted'),
   (select coalesce(sum(m.bytes),0) from public.network_media_assets m where m.network_id=n.id and m.lifecycle_state<>'deleted'),
   (select coalesce(sum(m.thumbnail_bytes),0) from public.network_media_assets m where m.network_id=n.id and m.lifecycle_state<>'deleted')
 from public.networks n where n.id=public.current_network_id() and public.is_network_member(n.id);
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_projections()
 RETURNS TABLE(projection_key character varying, label character varying, levels text[], is_default boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select p.projection_key,p.label,p.levels,p.is_default from public.network_projections p
 where p.network_id=public.current_network_id() and public.is_network_member(p.network_id) order by p.sort_order,p.label;
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_quick_start_state(p_network_id uuid)
 RETURNS TABLE(dismissed boolean, completed_step_ids text[], updated_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select q.dismissed,q.completed_step_ids,q.updated_at from public.network_quick_start_state q
 where q.network_id=p_network_id and q.user_id=auth.uid() and exists(select 1 from public.network_memberships m where m.network_id=p_network_id and m.user_id=auth.uid() and m.status='active');
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_timeline(p_limit integer DEFAULT 300, p_offset integer DEFAULT 0)
 RETURNS TABLE(id uuid, member_id uuid, event_type character varying, title character varying, event_date date, location character varying, description text, visibility character varying, created_by uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select e.id,e.member_id,e.event_type,e.title,e.event_date,e.location,e.description,
         e.visibility,e.created_by,e.created_at,e.updated_at
  from public.member_life_events e
  join public.family_members fm on fm.id=e.member_id
  where public.is_admin()
     or (
       fm.profile_status='approved'
       and fm.profile_visibility <> 'admin'
       and e.visibility <> 'admin'
     )
  order by e.event_date desc nulls last,e.created_at desc
  limit greatest(1,least(coalesce(p_limit,300),500))
  offset greatest(coalesce(p_offset,0),0);
$function$
;

CREATE OR REPLACE FUNCTION public.get_or_create_family_join_code()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); c text;
begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Family administrator access required.' using errcode='42501'; end if;
 select code into c from public.family_join_codes where network_id=nid;
 if c is null then c:=public.generate_family_join_code(); insert into public.family_join_codes(network_id,code,created_by) values(nid,c,auth.uid()); end if;
 return c;
end;$function$
;

CREATE OR REPLACE FUNCTION public.get_or_create_network_bridge_code(p_network_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare result text;
begin
 if auth.uid() is null or not public.is_network_admin(p_network_id) then raise exception 'Network administrator access is required.' using errcode='42501'; end if;
 select code into result from public.network_bridge_codes where network_id=p_network_id;
 if result is null then
  result:=upper(substr(encode(gen_random_bytes(8),'hex'),1,12));
  insert into public.network_bridge_codes(network_id,code,created_by) values(p_network_id,result,auth.uid())
  on conflict(network_id) do nothing;
  select code into result from public.network_bridge_codes where network_id=p_network_id;
 end if;
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_or_create_network_join_code()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();c text; begin if not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501'; end if; if not public.g8_productized_vertical((select vertical_kind from public.networks where id=nid)) then raise exception 'Generic join code is not used by this vertical.'; end if; select code into c from public.network_join_codes where network_id=nid; if c is null then c:=public.g8_generate_join_code();insert into public.network_join_codes(network_id,code,created_by) values(nid,c,auth.uid());end if; return c; end $function$
;

CREATE OR REPLACE FUNCTION public.get_organization_graph_aware_evidence(p_query text, p_limit integer DEFAULT 12)
 RETURNS TABLE(id uuid, title text, excerpt text, uri text, section text, source_updated_at timestamp with time zone, predicate text, subject jsonb, object jsonb, confidence numeric, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with ctx as (select public.current_network_id() nid),
 q as (select lower(trim(coalesce(p_query,''))) value),
 docs as (
  select e.id,coalesce(e.title,'Knowledge evidence') title,coalesce(e.excerpt,'') excerpt,e.uri,e.section,e.source_updated_at,null::text predicate,null::jsonb subject,null::jsonb object,null::numeric confidence,e.captured_at created_at,
   case when q.value='' then 0 else ts_rank_cd(to_tsvector('simple',coalesce(e.title,'')||' '||coalesce(e.excerpt,'')),plainto_tsquery('simple',q.value)) end rank
  from public.network_evidence_records e,ctx,q
  where e.network_id=ctx.nid and e.visibility='network' and exists(select 1 from public.network_memberships m where m.network_id=ctx.nid and m.user_id=auth.uid() and m.status='active')
 ), assertions as (
  select a.id,coalesce(a.metadata->>'title',a.predicate) title,coalesce(a.metadata->>'summary',concat_ws(' ',a.subject->>'label',a.predicate,a.object->>'label',a.object->>'value')) excerpt,null::text uri,null::text section,a.reviewed_at source_updated_at,a.predicate,a.subject,a.object,a.confidence,a.created_at,
   case when q.value='' then 0 else ts_rank_cd(to_tsvector('simple',coalesce(a.subject::text,'')||' '||a.predicate||' '||coalesce(a.object::text,'')||' '||coalesce(a.metadata::text,'')),plainto_tsquery('simple',q.value)) end rank
  from public.network_candidate_assertions a,ctx,q
  where a.network_id=ctx.nid and a.status='verified' and exists(select 1 from public.network_memberships m where m.network_id=ctx.nid and m.user_id=auth.uid() and m.status='active') and exists(select 1 from unnest(a.evidence_ids) evid join public.network_evidence_records er on er.id=evid and er.network_id=ctx.nid where er.visibility='network')
 )
 select x.id,x.title,x.excerpt,x.uri,x.section,x.source_updated_at,x.predicate,x.subject,x.object,x.confidence,x.created_at from (select * from assertions union all select * from docs) x
 where (select value from q)='' or x.rank>0 order by x.rank desc,x.created_at desc limit greatest(1,least(coalesce(p_limit,12),50));
$function$
;

CREATE OR REPLACE FUNCTION public.get_organization_knowledge_candidates(p_status text DEFAULT 'candidate'::text)
 RETURNS TABLE(id uuid, network_id uuid, kind text, subject jsonb, predicate text, object jsonb, evidence_ids uuid[], confidence numeric, status text, extraction_method text, extractor_version text, created_at timestamp with time zone, reviewed_at timestamp with time zone, reviewed_by uuid, metadata jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select a.id,a.network_id,coalesce(a.metadata->>'kind','decision'),a.subject,a.predicate,a.object,a.evidence_ids,a.confidence,a.status,a.extraction_method,a.extractor_version,a.created_at,a.reviewed_at,a.reviewed_by,a.metadata
 from public.network_candidate_assertions a where a.network_id=public.current_network_id() and public.is_network_admin(a.network_id) and (p_status is null or a.status=p_status) order by a.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_organization_knowledge_risk_signals()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();result jsonb;
begin
 perform public.g91b_assert_organization_network(nid);if not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;
 select jsonb_build_object(
  'evidenceCount',(select count(*) from public.network_evidence_records e where e.network_id=nid and e.visibility='network'),
  'staleEvidenceCount',(select count(*) from public.network_evidence_records e where e.network_id=nid and e.visibility='network' and coalesce(e.source_updated_at,e.captured_at)<now()-interval '365 days'),
  'verifiedAssertionCount',(select count(*) from public.network_candidate_assertions a where a.network_id=nid and a.status='verified'),
  'conflictedAssertionCount',(select count(*) from public.network_candidate_assertions a where a.network_id=nid and a.status='conflicted'),
  'unansweredQuestions',coalesce((select jsonb_agg(jsonb_build_object('question',x.question,'count',x.cnt,'lastAskedAt',x.last_asked,'intent',x.intent) order by x.cnt desc,x.last_asked desc) from (
    select lower(trim(q.question)) question,count(*) cnt,max(q.created_at) last_asked,(array_agg(q.intent order by q.created_at desc))[1] intent
    from public.organization_intelligence_query_signals q where q.network_id=nid and q.created_at>now()-interval '90 days' and (q.confidence='low' or q.evidence_count=0)
    group by lower(trim(q.question)) having count(*)>=2 order by count(*) desc,max(q.created_at) desc limit 10
  ) x),'[]'::jsonb)
 ) into result;return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_pending_community_links()
 RETURNS TABLE(id uuid, space_id uuid, space_name character varying, network_id uuid, family_name character varying, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select l.id,l.space_id,s.name,l.network_id,n.name,l.created_at
  from public.community_family_links l join public.community_spaces s on s.id=l.space_id join public.networks n on n.id=l.network_id
  where l.status='pending' and public.is_platform_owner() order by l.created_at;
$function$
;

CREATE OR REPLACE FUNCTION public.get_platform_family_creation_requests()
 RETURNS TABLE(id uuid, requester_user_id uuid, requester_email text, name character varying, description text, status character varying, created_at timestamp with time zone, reviewed_at timestamp with time zone, decision_note text, network_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select r.id,r.requester_user_id,u.email::text,r.name,r.description,r.status,r.created_at,r.reviewed_at,r.decision_note,r.network_id
  from public.family_creation_requests r
  join auth.users u on u.id=r.requester_user_id
  where public.is_platform_owner()
  order by (r.status='pending') desc,r.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_platform_family_targets()
 RETURNS TABLE(network_id uuid, name character varying, slug character varying, status character varying, member_count bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then
    raise exception 'Platform owner access is required.' using errcode='42501';
  end if;
  return query
  select n.id,n.name,n.slug,n.status,
    (select count(*) from public.network_memberships nm where nm.network_id=n.id and nm.status='active')
  from public.networks n
  order by n.created_at desc,n.name;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_platform_launch_console()
 RETURNS TABLE(feature_key character varying, bundle_key character varying, rollout_state character varying, pilot_network_ids uuid[], announcement_version integer, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then
    raise exception 'Platform owner access is required.' using errcode='42501';
  end if;
  return query
  select f.feature_key,f.bundle_key,f.rollout_state,f.pilot_network_ids,f.announcement_version,f.updated_at
  from public.platform_feature_flags f
  order by f.bundle_key,f.feature_key;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_platform_network_registry()
 RETURNS TABLE(network_id uuid, name character varying, slug character varying, vertical_kind character varying, approval_status character varying, network_status character varying, creator_user_id uuid, creator_email text, created_at timestamp with time zone, reviewed_at timestamp with time zone, approval_note text, member_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select n.id,n.name,n.slug,n.vertical_kind,n.approval_status,n.status,n.created_by,u.email::text,n.created_at,n.approval_reviewed_at,n.approval_note,
         (select count(*) from public.network_memberships nm where nm.network_id=n.id and nm.status='active')
  from public.networks n
  left join auth.users u on u.id=n.created_by
  where public.is_platform_owner()
  order by (n.approval_status='pending') desc,n.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_platform_network_targets()
 RETURNS TABLE(network_id uuid, name character varying, slug character varying, status character varying, member_count bigint, vertical_kind character varying)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
 return query select n.id,n.name,n.slug,n.status,(select count(*) from public.network_memberships nm where nm.network_id=n.id and nm.status='active'),n.vertical_kind
 from public.networks n order by n.created_at desc,n.name;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_platform_owner_audit(p_limit integer DEFAULT 20)
 RETURNS TABLE(id uuid, actor_email text, target_email text, action character varying, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
  select a.id,actor.email,target.email,a.action,a.created_at
  from public.platform_owner_audit a
  left join auth.users actor on actor.id=a.actor_user_id
  left join auth.users target on target.id=a.target_user_id
  where public.is_platform_owner()
  order by a.created_at desc
  limit greatest(1,least(coalesce(p_limit,20),100));
$function$
;

CREATE OR REPLACE FUNCTION public.get_platform_owners()
 RETURNS TABLE(user_id uuid, email text, created_at timestamp with time zone, is_me boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
  select po.user_id,u.email,po.created_at,(po.user_id=auth.uid())
  from public.platform_owners po
  join auth.users u on u.id=po.user_id
  where public.is_platform_owner()
  order by po.created_at,lower(coalesce(u.email,''));
$function$
;

CREATE OR REPLACE FUNCTION public.get_platform_rollout_audit(p_limit integer DEFAULT 30)
 RETURNS TABLE(id bigint, feature_key character varying, bundle_key character varying, previous_state character varying, new_state character varying, pilot_network_ids uuid[], announced boolean, changed_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then
    raise exception 'Platform owner access is required.' using errcode='42501';
  end if;
  return query
  select a.id,a.feature_key,a.bundle_key,a.previous_state,a.new_state,a.pilot_network_ids,a.announced,a.changed_at
  from public.platform_feature_rollout_audit a
  order by a.changed_at desc,a.id desc
  limit greatest(1,least(coalesce(p_limit,30),100));
end $function$
;

CREATE OR REPLACE FUNCTION public.get_platform_showcase_vertical_settings()
 RETURNS TABLE(vertical_kind character varying, create_enabled boolean, playground_enabled boolean, featured boolean, palette_key character varying, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
  return query select s.vertical_kind,s.create_enabled,s.playground_enabled,s.featured,s.palette_key,s.updated_at from public.platform_showcase_verticals s order by s.featured desc,s.vertical_kind;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_platform_vertical_launch_console(p_vertical_kind character varying)
 RETURNS TABLE(feature_key character varying, bundle_key character varying, rollout_state character varying, pilot_network_ids uuid[], announcement_version integer, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501';end if;if p_vertical_kind not in ('family','alumni','association','family-association','housing-society','organization','business-trust','franchise','professional') then raise exception 'Unknown vertical.' using errcode='22023';end if;return query select f.feature_key,f.bundle_key,f.rollout_state,f.pilot_network_ids,f.announcement_version,f.updated_at from public.platform_feature_flags f where f.vertical_kind=p_vertical_kind order by f.bundle_key,f.feature_key;end $function$
;

CREATE OR REPLACE FUNCTION public.get_playground_features()
 RETURNS TABLE(feature_key character varying, enabled boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select f.feature_key,coalesce(p.enabled,true)
  from public.platform_feature_flags f
  left join public.platform_playground_features p on p.feature_key=f.feature_key
  order by f.bundle_key,f.feature_key;
$function$
;

CREATE OR REPLACE FUNCTION public.get_playground_launch_console()
 RETURNS TABLE(feature_key character varying, enabled boolean, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
  return query
  select f.feature_key,coalesce(p.enabled,true),coalesce(p.updated_at,f.updated_at)
  from public.platform_feature_flags f
  left join public.platform_playground_features p on p.feature_key=f.feature_key
  order by f.bundle_key,f.feature_key;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_productized_network_contributions()
 RETURNS TABLE(id uuid, entity_id uuid, entity_label character varying, message text, payload jsonb, status character varying, created_at timestamp with time zone, created_by uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select c.id,c.entity_id,e.label,c.message,c.payload,c.status,c.created_at,c.created_by from public.network_contributions c left join public.network_entities e on e.id=c.entity_id and e.network_id=c.network_id where c.network_id=public.current_network_id() and (c.created_by=auth.uid() or public.is_network_admin(c.network_id)) order by c.created_at desc; $function$
;

CREATE OR REPLACE FUNCTION public.get_productized_network_relationships()
 RETURNS TABLE(id uuid, from_entity_id uuid, to_entity_id uuid, from_label character varying, to_label character varying, relationship_type character varying, relationship_label text, metadata jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select r.id,r.from_entity_id,r.to_entity_id,f.label,t.label,r.relationship_type,initcap(replace(r.relationship_type,'_',' ')),r.metadata from public.network_entity_relationships r join public.network_entities f on f.id=r.from_entity_id and f.network_id=r.network_id join public.network_entities t on t.id=r.to_entity_id and t.network_id=r.network_id where r.network_id=public.current_network_id() and public.is_network_member(r.network_id) order by f.label,t.label;
$function$
;

CREATE OR REPLACE FUNCTION public.get_productized_network_relationships_page(p_after_id uuid DEFAULT NULL::uuid, p_limit integer DEFAULT 100)
 RETURNS TABLE(id uuid, from_entity_id uuid, to_entity_id uuid, from_label character varying, to_label character varying, relationship_type character varying, relationship_label text, metadata jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select r.id,r.from_entity_id,r.to_entity_id,f.label,t.label,r.relationship_type,
        initcap(replace(r.relationship_type,'_',' ')),r.metadata
 from public.network_entity_relationships r
 join public.network_entities f on f.id=r.from_entity_id and f.network_id=r.network_id
 join public.network_entities t on t.id=r.to_entity_id and t.network_id=r.network_id
 where r.network_id=public.current_network_id()
   and public.is_network_member(r.network_id)
   and (p_after_id is null or r.id>p_after_id)
 order by r.id
 limit least(greatest(coalesce(p_limit,100),1),200);
$function$
;

CREATE OR REPLACE FUNCTION public.get_productized_network_settings()
 RETURNS TABLE(template_id character varying, context_label character varying, context_value character varying, description text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select s.template_id,s.context_label,s.context_value,s.description from public.productized_network_settings s where s.network_id=public.current_network_id() and public.is_network_member(s.network_id);
$function$
;

CREATE OR REPLACE FUNCTION public.get_public_family_member(p_member_id uuid)
 RETURNS TABLE(id uuid, full_name text, generation_level integer, profession text, city text, country text, bio text, date_of_death date, avatar_style character varying, facebook_url text, instagram_url text, other_social_url text, other_social_label character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select fm.id,fm.full_name::text,fm.generation_level,fm.profession::text,fm.city::text,fm.country::text,fm.bio,fm.date_of_death,fm.avatar_style,
   case when fm.facebook_public then fm.facebook_url else null end,
   case when fm.instagram_public then fm.instagram_url else null end,
   case when fm.other_social_public then fm.other_social_url else null end,
   case when fm.other_social_public then fm.other_social_label else null end
 from public.family_members fm where fm.id=p_member_id and fm.profile_status='approved' and fm.profile_visibility='public';
$function$
;

CREATE OR REPLACE FUNCTION public.get_public_family_members()
 RETURNS TABLE(id uuid, full_name text, generation_level integer, profession text, city text, country text, bio text, date_of_death date, avatar_style character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select fm.id,fm.full_name::text,fm.generation_level,fm.profession::text,fm.city::text,fm.country::text,fm.bio,fm.date_of_death,fm.avatar_style
 from public.family_members fm where fm.profile_status='approved' and fm.profile_visibility='public';
$function$
;

CREATE OR REPLACE FUNCTION public.get_public_network_info()
 RETURNS TABLE(name text, description text, entity_label text, entity_label_plural text, level_label text, level_label_plural text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    ns.name::text,
    coalesce(ns.description, '')::text,
    coalesce(ns.entity_label, 'Member')::text,
    coalesce(ns.entity_label_plural, 'Members')::text,
    coalesce(ns.level_label, 'Generation')::text,
    coalesce(ns.level_label_plural, 'Generations')::text
  from public.network_settings ns
  where ns.id = 'network'
  limit 1;
$function$
;

CREATE OR REPLACE FUNCTION public.get_public_network_passport(p_slug text)
 RETURNS TABLE(network_id uuid, network_name character varying, vertical_kind character varying, public_slug character varying, tagline character varying, summary character varying, location_label character varying, established_label character varying, external_url character varying, capabilities text[], participation_scopes text[], visibility character varying, directory_discoverable boolean, verification_state character varying, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select n.id,n.name,n.vertical_kind,p.public_slug,p.tagline,p.summary,p.location_label,p.established_label,p.external_url,p.capabilities,p.participation_scopes,p.visibility,p.directory_discoverable,p.verification_state,p.updated_at
 from public.network_passports p join public.networks n on n.id=p.network_id
 where p.public_slug=lower(trim(p_slug)) and p.visibility='public' and n.status='active'
 limit 1;
$function$
;

CREATE OR REPLACE FUNCTION public.get_showcase_vertical_settings()
 RETURNS TABLE(vertical_kind character varying, create_enabled boolean, playground_enabled boolean, featured boolean, palette_key character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select s.vertical_kind,s.create_enabled,s.playground_enabled,s.featured,s.palette_key
  from public.platform_showcase_verticals s
  order by s.featured desc,s.vertical_kind;
$function$
;

CREATE OR REPLACE FUNCTION public.get_trusted_connection_path(p_space_id uuid, p_target_network_id uuid)
 RETURNS TABLE(path_network_ids uuid[], path_family_names text[], hops integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with recursive walk(path,last_id,depth) as (
   select array[public.current_network_id()]::uuid[],public.current_network_id(),0
   where public.current_network_id() is not null and public.community_space_is_allowed(p_space_id,public.current_network_id())
   union all
   select w.path||x.next_id,x.next_id,w.depth+1
   from walk w
   join lateral(
     select case when e.requester_network_id=w.last_id then e.recipient_network_id else e.requester_network_id end next_id
     from public.community_trust_edges e
     where e.space_id=p_space_id and e.status='accepted' and w.last_id in(e.requester_network_id,e.recipient_network_id)
   ) x on true
   where w.depth<4 and not x.next_id=any(w.path)
 ), best as (
   select path,depth from walk where last_id=p_target_network_id order by depth limit 1
 )
 select b.path,array(select n.name::text from unnest(b.path) with ordinality p(id,ord) join public.networks n on n.id=p.id order by p.ord),b.depth
 from best b;
$function$
;

CREATE OR REPLACE FUNCTION public.get_visible_family_members()
 RETURNS TABLE(id uuid, full_name character varying, date_of_birth date, date_of_death date, generation_level integer, profession character varying, city character varying, country character varying, photo_url text, bio text, phone character varying, email character varying, latitude numeric, longitude numeric, profile_status character varying, profile_visibility character varying, contact_visibility character varying, created_at timestamp with time zone, updated_at timestamp with time zone, avatar_style character varying, facebook_url text, facebook_public boolean, instagram_url text, instagram_public boolean, other_social_url text, other_social_label character varying, other_social_public boolean, gender character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select fm.id,fm.full_name,fm.date_of_birth,fm.date_of_death,fm.generation_level,fm.profession,
    case when public.is_network_admin(fm.network_id) or fm.profile_visibility <> 'admin' then fm.city else null end,
    case when public.is_network_admin(fm.network_id) or fm.profile_visibility <> 'admin' then fm.country else null end,
    case when public.is_network_admin(fm.network_id) or fm.profile_visibility <> 'admin' then fm.photo_url else null end,
    case when public.is_network_admin(fm.network_id) or fm.profile_visibility <> 'admin' then fm.bio else null end,
    case when public.is_network_admin(fm.network_id) or fm.contact_visibility = 'member' then fm.phone else null end,
    case when public.is_network_admin(fm.network_id) or fm.contact_visibility = 'member' then fm.email else null end,
    fm.latitude,fm.longitude,fm.profile_status,fm.profile_visibility,fm.contact_visibility,fm.created_at,fm.updated_at,
    fm.avatar_style,fm.facebook_url,fm.facebook_public,fm.instagram_url,fm.instagram_public,fm.other_social_url,fm.other_social_label,fm.other_social_public,fm.gender
  from public.family_members fm
  where fm.network_id=public.current_network_id() and (fm.profile_status='approved' or public.is_network_admin(fm.network_id));
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  first_user boolean;
begin
  -- Serialize first-user evaluation so two concurrent signups cannot both
  -- observe an empty profiles table and both become administrators.
  perform pg_advisory_xact_lock(739281);
  select not exists(select 1 from public.profiles) into first_user;
  insert into public.profiles(id,full_name,role)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),
         case when first_user then 'admin' else 'member' end)
  on conflict (id) do nothing;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.has_capability(p_capability character varying)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(
    select 1
    from public.network_role_capabilities rc
    join public.profiles p on p.role = rc.role
    where p.id = auth.uid() and rc.capability = p_capability
  );
$function$
;

CREATE OR REPLACE FUNCTION public.import_productized_network_entities(p_rows jsonb)
 RETURNS TABLE(inserted integer, updated integer, skipped integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r jsonb; v_id uuid; existing_id uuid; i integer:=0;u integer:=0;s integer:=0; v_kind text; v_label text; v_metadata jsonb; v_aff jsonb;
begin
 if not public.is_network_admin() then raise exception 'Network admin access required.' using errcode='42501'; end if;
 if jsonb_typeof(p_rows)<>'array' then raise exception 'Rows must be an array.'; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
  v_label:=trim(coalesce(r->>'label','')); if length(v_label)<2 then s:=s+1; continue; end if;
  v_kind:=coalesce(nullif(r->>'kind',''),(select case vertical_kind when 'organization' then 'person' when 'business-trust' then 'organization' else 'branch' end from public.networks where id=public.current_network_id()));
  v_metadata:=coalesce(r->'metadata','{}'::jsonb); v_aff:=coalesce(r->'affiliations','{}'::jsonb);
  select id into existing_id from public.network_entities where network_id=public.current_network_id() and kind=v_kind and lower(label)=lower(v_label) order by created_at limit 1;
  v_id:=public.upsert_productized_network_entity(existing_id,v_kind,v_label,v_metadata,v_aff,'members');
  if existing_id is null then i:=i+1; else u:=u+1; end if;
 end loop;
 return query select i,u,s;
end $function$
;

CREATE OR REPLACE FUNCTION public.invitation_status(p_used_at timestamp with time zone, p_revoked_at timestamp with time zone, p_expires_at timestamp with time zone)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  select case when p_used_at is not null then 'accepted'
              when p_revoked_at is not null then 'revoked'
              when p_expires_at <= now() then 'expired'
              else 'active' end;
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_network_admin(public.current_network_id());
$function$
;

CREATE OR REPLACE FUNCTION public.is_network_admin(p_network_id uuid DEFAULT current_network_id())
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select auth.uid() is not null and exists(
    select 1 from public.network_memberships nm
    where nm.network_id=p_network_id and nm.user_id=auth.uid() and nm.status='active' and nm.role in ('owner','admin')
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_network_member(p_network_id uuid DEFAULT current_network_id())
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select auth.uid() is not null and exists(
    select 1 from public.network_memberships nm
    where nm.network_id=p_network_id and nm.user_id=auth.uid() and nm.status='active'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_platform_owner()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select auth.uid() is not null and exists(
    select 1 from public.platform_owners po where po.user_id=auth.uid()
  );
$function$
;

CREATE OR REPLACE FUNCTION public.join_family_by_code(p_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); nid uuid;
begin
 if uid is null then raise exception 'Sign in is required.' using errcode='42501'; end if;
 select network_id into nid from public.family_join_codes where upper(code)=upper(trim(coalesce(p_code,'')));
 if nid is null then raise exception 'That family code was not found. Check the code and try again.' using errcode='P0002'; end if;
 insert into public.network_memberships(network_id,user_id,role,status) values(nid,uid,'member','active')
 on conflict(network_id,user_id) do update set status='active';
 update public.profiles set active_network_id=nid,member_id=(select member_id from public.network_memberships where network_id=nid and user_id=uid),updated_at=now() where id=uid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,uid,'family_joined_by_code','{}'::jsonb);
 return nid;
end;$function$
;

CREATE OR REPLACE FUNCTION public.join_network_group(p_group_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id();
begin
 if not public.is_network_member(v_network) then raise exception 'Membership required.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_groups where id=p_group_id and network_id=v_network) then raise exception 'Group not found.'; end if;
 insert into public.network_group_memberships(group_id,network_id,user_id) values(p_group_id,v_network,auth.uid()) on conflict do nothing;
end $function$
;

CREATE OR REPLACE FUNCTION public.join_productized_network_by_code(p_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid; begin if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;select j.network_id into nid from public.network_join_codes j join public.networks n on n.id=j.network_id where upper(j.code)=upper(trim(p_code)) and public.g8_productized_vertical(n.vertical_kind) and n.status='active';if nid is null then raise exception 'Network code not found.';end if;insert into public.network_memberships(network_id,user_id,role,status) values(nid,auth.uid(),'member','active') on conflict(network_id,user_id) do update set status='active';update public.profiles set active_network_id=nid,updated_at=now() where id=auth.uid();return nid;end $function$
;

CREATE OR REPLACE FUNCTION public.launch_demo_create_relationship(p_dataset_version text, p_from_entity_id uuid, p_to_entity_id uuid, p_relationship_type text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if not public.is_network_admin(nid) and not public.is_platform_owner() then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Authorized launch dataset required.' using errcode='42501'; end if;
 return public.create_productized_network_relationship(p_from_entity_id,p_to_entity_id,p_relationship_type,coalesce(p_metadata,'{}'::jsonb));
end $function$
;

CREATE OR REPLACE FUNCTION public.launch_demo_open_ballot(p_dataset_version text, p_ballot_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

CREATE OR REPLACE FUNCTION public.launch_demo_upsert_fca_role_catalog(p_dataset_version text, p_role_key text, p_label text, p_role_type text, p_portfolio text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

CREATE OR REPLACE FUNCTION public.leave_current_family()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin perform public.leave_owned_network(nid); return 'left'; end $function$
;

CREATE OR REPLACE FUNCTION public.leave_network_group(p_group_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 delete from public.network_group_memberships where group_id=p_group_id and network_id=public.current_network_id() and user_id=auth.uid();
end $function$
;

CREATE OR REPLACE FUNCTION public.leave_owned_network(p_network_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); actor_role text; owner_count int; next_id uuid;
begin
 if uid is null then raise exception 'Sign in required.' using errcode='42501'; end if;
 select role into actor_role from public.network_memberships where network_id=p_network_id and user_id=uid and status='active';
 if actor_role is null then raise exception 'You are not an active member of this network.' using errcode='42501'; end if;
 if actor_role='owner' then
  select count(*) into owner_count from public.network_memberships where network_id=p_network_id and role='owner' and status='active';
  if owner_count<=1 then raise exception 'The sole owner cannot leave. Add another owner, archive, or permanently delete the network.' using errcode='42501'; end if;
 end if;
 update public.network_memberships set status='left' where network_id=p_network_id and user_id=uid;
 select nm.network_id into next_id from public.network_memberships nm join public.networks n on n.id=nm.network_id and n.status='active'
 where nm.user_id=uid and nm.status='active' and nm.network_id<>p_network_id order by nm.joined_at desc limit 1;
 update public.profiles set active_network_id=next_id,member_id=case when next_id is null then null else member_id end,updated_at=now()
 where id=uid and active_network_id=p_network_id;
 return next_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.leave_productized_network()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$begin return public.leave_owned_network(public.current_network_id());end$function$
;

CREATE OR REPLACE FUNCTION public.log_audit_event(p_action character varying, p_details jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  audit_id uuid;
  nid uuid:=public.current_network_id();
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode='42501';
  end if;
  if nid is null or (not public.is_network_admin(nid) and not public.is_platform_owner()) then
    raise exception 'Family administrator access is required.' using errcode='42501';
  end if;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),left(p_action,80),coalesce(p_details,'{}'::jsonb))
  returning id into audit_id;
  return audit_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.m6b_bridge_capabilities(p_value jsonb)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
 select jsonb_build_object(
  'discovery',coalesce((p_value->>'discovery')::boolean,false),
  'introductions',coalesce((p_value->>'introductions')::boolean,false),
  'pathTraversal',coalesce((p_value->>'pathTraversal')::boolean,false)
 );
$function$
;

CREATE OR REPLACE FUNCTION public.mark_family_digest_opened()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); previous timestamptz;
begin
 if auth.uid() is null or nid is null then return; end if;
 select last_opened_at into previous from public.family_digest_state where network_id=nid and user_id=auth.uid();
 insert into public.family_digest_state(network_id,user_id,last_opened_at,open_count,updated_at)
 values(nid,auth.uid(),now(),1,now())
 on conflict(network_id,user_id) do update set last_opened_at=now(),open_count=family_digest_state.open_count+1,updated_at=now();
 insert into public.family_engagement_events(network_id,user_id,event_type,entity_type,channel)
 values(nid,auth.uid(),case when previous is not null and previous<now()-interval '3 days' then 'digest_return' else 'digest_open' end,'digest','in_app');
end;$function$
;

CREATE OR REPLACE FUNCTION public.mark_family_digest_shared(p_channel text DEFAULT 'copy'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if auth.uid() is null or nid is null then return; end if;
 insert into public.family_digest_state(network_id,user_id,last_shared_at,share_count,updated_at)
 values(nid,auth.uid(),now(),1,now())
 on conflict(network_id,user_id) do update set last_shared_at=now(),share_count=family_digest_state.share_count+1,updated_at=now();
 insert into public.family_engagement_events(network_id,user_id,event_type,entity_type,channel)
 values(nid,auth.uid(),'digest_share','digest',nullif(left(coalesce(p_channel,'copy'),32),''));
end;$function$
;

CREATE OR REPLACE FUNCTION public.mark_feature_announcement_seen(p_feature_key character varying, p_announcement_version integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  insert into public.user_feature_discoveries(user_id,feature_key,announcement_version)
  values(auth.uid(),p_feature_key,p_announcement_version)
  on conflict do nothing;
end $function$
;

CREATE OR REPLACE FUNCTION public.nf8_capture_accepted_trust_receipt()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if new.status='accepted' and (old.status is distinct from new.status or old.responded_at is distinct from new.responded_at) then
  perform public.ensure_federated_trust_receipt(new.id);
 end if;
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.normalize_intake_name(p_name text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select trim(regexp_replace(lower(regexp_replace(coalesce(p_name,''),'[^a-zA-Z0-9 ]','','g')),'\\s+',' ','g'));
$function$
;

CREATE OR REPLACE FUNCTION public.notify_network_roles(p_network_id uuid, p_roles text[], p_type text, p_title text, p_body text DEFAULT NULL::text, p_surface text DEFAULT NULL::text, p_entity_type text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid, p_priority text DEFAULT 'normal'::text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r record; v_count integer:=0;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  if not public.is_network_member(p_network_id) and not public.is_platform_owner() then raise exception 'Not authorized.' using errcode='42501'; end if;
  for r in select distinct nm.user_id from public.network_memberships nm
           where nm.network_id=p_network_id and nm.status='active' and nm.role=any(coalesce(p_roles,array[]::text[])) loop
    perform public.create_network_notification(p_network_id,r.user_id,p_type,p_title,p_body,p_surface,p_entity_type,p_entity_id,p_priority,p_metadata,auth.uid());
    v_count:=v_count+1;
  end loop;
  return v_count;
end $function$
;

CREATE OR REPLACE FUNCTION public.notify_user(p_user_id uuid, p_type character varying, p_title character varying, p_body text DEFAULT NULL::text, p_href text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid;
begin
 if not public.is_admin() and auth.uid()<>p_user_id then raise exception 'Not authorized.' using errcode='42501'; end if;
 insert into public.notifications(user_id,type,title,body,href) values(p_user_id,p_type,p_title,p_body,p_href) returning id into nid; return nid;
end; $function$
;

CREATE OR REPLACE FUNCTION public.open_network_ballot(p_ballot_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();b public.network_ballots%rowtype;r record;cnt int:=0;begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;select * into b from public.network_ballots where id=p_ballot_id and network_id=nid and status='draft';if not found then raise exception 'Draft ballot not found.';end if;
 if (select count(*) from public.network_ballot_options where ballot_id=b.id)<2 then raise exception 'At least two ballot choices are required.';end if;
 delete from public.network_ballot_eligibility where ballot_id=b.id;
 if b.eligibility_mode='members' then
  insert into public.network_ballot_eligibility(network_id,ballot_id,user_id,source) select nid,b.id,nm.user_id,'member' from public.network_memberships nm where nm.network_id=nid and nm.status='active' on conflict do nothing;
 elsif b.eligibility_mode='admins' then
  insert into public.network_ballot_eligibility(network_id,ballot_id,user_id,source) select nid,b.id,nm.user_id,'admin' from public.network_memberships nm where nm.network_id=nid and nm.status='active' and nm.role in ('owner','admin') on conflict do nothing;
 else
  insert into public.network_ballot_eligibility(network_id,ballot_id,user_id,source)
  select distinct nid,b.id,rep.owner_user_id,'family_representative' from public.family_association_family_memberships m join public.family_association_membership_years y on y.id=m.membership_year_id and y.network_id=m.network_id join public.network_entities rep on rep.id=m.representative_entity_id and rep.network_id=m.network_id join public.network_memberships nm on nm.network_id=m.network_id and nm.user_id=rep.owner_user_id and nm.status='active' where m.network_id=nid and m.status in ('active','grace') and y.status='open' and rep.owner_user_id is not null on conflict do nothing;
 end if;
 select count(*) into cnt from public.network_ballot_eligibility where ballot_id=b.id;if cnt=0 then raise exception 'No eligible voters were found for this ballot.';end if;
 update public.network_ballots set status='open',opens_at=now(),updated_at=now() where id=b.id;
 for r in select user_id from public.network_ballot_eligibility where ballot_id=b.id loop perform public.create_network_notification(nid,r.user_id,'ballot_opened',case when b.ballot_type='election' then 'Election voting is open' else 'New poll is open' end,b.title,'elections','ballot',b.id,'high',jsonb_build_object('ballot_type',b.ballot_type),auth.uid());end loop;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_ballot_opened',jsonb_build_object('ballot_id',b.id,'eligible_voters',cnt));return cnt;
end $function$
;

CREATE OR REPLACE FUNCTION public.prepare_network_media_upload(p_network_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid();membership_status text;creator uuid;enabled boolean;max_bytes integer;lim bigint;
begin
  if uid is null then raise exception 'Sign in required before uploading media.' using errcode='42501'; end if;
  select n.created_by,n.photo_upload_enabled,n.photo_max_bytes,n.storage_limit_bytes
    into creator,enabled,max_bytes,lim from public.networks n where n.id=p_network_id and n.status='active';
  if creator is null then raise exception 'Network was not found.' using errcode='P0002'; end if;

  select nm.status into membership_status from public.network_memberships nm
   where nm.network_id=p_network_id and nm.user_id=uid;

  if membership_status is null then
    if creator<>uid then raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501'; end if;
    insert into public.network_memberships(network_id,user_id,role,status)
      values(p_network_id,uid,'owner','active')
      on conflict(network_id,user_id) do nothing;
    membership_status:='active';
  elsif membership_status<>'active' then
    raise exception 'Your membership in this network is not active.' using errcode='42501';
  end if;

  if not public.has_active_network_membership(p_network_id,uid) then
    raise exception 'Media membership authorization could not be verified.' using errcode='42501';
  end if;
  return jsonb_build_object('network_id',p_network_id,'photo_upload_enabled',coalesce(enabled,false),'photo_max_bytes',coalesce(max_bytes,102400),'storage_limit_bytes',coalesce(lim,0));
end $function$
;

CREATE OR REPLACE FUNCTION public.prepare_owned_network_for_purge(p_network_id uuid, p_confirm_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); nname text; nstatus text; owner_status text; next_id uuid;
begin
 if uid is null then raise exception 'Sign in required.' using errcode='42501'; end if;
 select n.name,n.status,nm.status into nname,nstatus,owner_status
 from public.networks n join public.network_memberships nm on nm.network_id=n.id
 where n.id=p_network_id and nm.user_id=uid and nm.role='owner' and nm.status in ('active','suspended');
 if nname is null then raise exception 'Only the network Owner can permanently delete this network.' using errcode='42501'; end if;
 if trim(coalesce(p_confirm_name,''))<>nname then raise exception 'Network name confirmation does not match.' using errcode='22023'; end if;

 if nstatus='active' then
  delete from public.network_archive_membership_state where network_id=p_network_id;
  insert into public.network_archive_membership_state(network_id,user_id,previous_status)
  select network_id,user_id,status from public.network_memberships where network_id=p_network_id;
  update public.networks set status='archived',updated_at=now() where id=p_network_id;
  update public.network_memberships set status='suspended' where network_id=p_network_id and status='active';
 elsif nstatus<>'archived' then
  raise exception 'Network is not in a purgeable lifecycle state.' using errcode='55000';
 end if;

 select nm.network_id into next_id
 from public.network_memberships nm join public.networks n on n.id=nm.network_id and n.status='active'
 where nm.user_id=uid and nm.status='active' and nm.network_id<>p_network_id
 order by nm.joined_at desc limit 1;
 update public.profiles set active_network_id=next_id,member_id=case when next_id is null then null else member_id end,updated_at=now()
 where active_network_id=p_network_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.protect_foundational_family_relationship()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  actor_role varchar;
begin
  -- Service-role/maintenance operations do not carry an authenticated end-user uid.
  if auth.uid() is null then return old; end if;

  actor_role := public.current_family_role(old.network_id);
  if old.relationship_type in ('parent','child') and actor_role is distinct from 'owner' then
    raise exception 'Only the Family Owner can remove a parent-child relationship. Ask the owner to correct this family line.' using errcode='42501';
  end if;
  return old;
end $function$
;

CREATE OR REPLACE FUNCTION public.publish_community_post(p_space_id uuid, p_category text, p_title text, p_body text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_target_member_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); mine uuid; rid uuid;
begin
 if nid is null or not public.community_space_is_allowed(p_space_id,nid) then raise exception 'Your family is not connected to this community.' using errcode='42501'; end if;
 select member_id into mine from public.network_memberships where network_id=nid and user_id=auth.uid() and status='active';
 if length(trim(p_title))<3 then raise exception 'A clear title is required.' using errcode='22023'; end if;
 if p_target_member_id is not null and p_target_member_id<>mine and not public.is_network_admin(nid) then raise exception 'Only a Family Owner/admin can publish for another member.' using errcode='42501'; end if;
 if p_category='marriage' and p_target_member_id is not null and not exists(select 1 from public.community_profile_cards c where c.member_id=p_target_member_id and c.space_id=p_space_id and c.category='marriage' and c.active) then
   raise exception 'The person must first opt in with a marriage community profile.' using errcode='42501';
 end if;
 insert into public.community_posts(space_id,network_id,author_user_id,target_member_id,category,title,body,city)
 values(p_space_id,nid,auth.uid(),p_target_member_id,p_category,trim(p_title),nullif(trim(p_body),''),nullif(trim(p_city),'')) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.publish_my_community_profile(p_member_id uuid, p_space_id uuid, p_category text, p_headline text DEFAULT NULL::text, p_summary text DEFAULT NULL::text, p_contact_mode text DEFAULT 'family_intro'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); mine uuid; m public.family_members%rowtype; rid uuid;
begin
 select member_id into mine from public.network_memberships where network_id=nid and user_id=auth.uid() and status='active';
 if mine is null or mine<>p_member_id then raise exception 'You can publish only your own community profile.' using errcode='42501'; end if;
 if not public.community_space_is_allowed(p_space_id,nid) then raise exception 'Your family is not connected to this community.' using errcode='42501'; end if;
 select * into m from public.family_members where id=p_member_id and network_id=nid;
 if m.id is null then raise exception 'Family profile not found.' using errcode='22023'; end if;
 insert into public.community_profile_cards(space_id,network_id,member_id,owner_user_id,category,display_name,photo_url,profession,city,headline,summary,contact_mode,active,updated_at)
 values(p_space_id,nid,p_member_id,auth.uid(),p_category,m.full_name,m.photo_url,m.profession,m.city,nullif(trim(p_headline),''),nullif(trim(p_summary),''),p_contact_mode,true,now())
 on conflict(space_id,member_id,category) do update set display_name=excluded.display_name,photo_url=excluded.photo_url,profession=excluded.profession,city=excluded.city,headline=excluded.headline,summary=excluded.summary,contact_mode=excluded.contact_mode,active=true,updated_at=now()
 returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.publish_network_ballot_results(p_ballot_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();b public.network_ballots%rowtype;r record;begin if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;update public.network_ballots set status='published',results_published_at=now(),updated_at=now() where id=p_ballot_id and network_id=nid and status in ('closed','published') returning * into b;if not found then raise exception 'Close the ballot before publishing results.';end if;for r in select user_id from public.network_ballot_eligibility where ballot_id=b.id loop perform public.create_network_notification(nid,r.user_id,'ballot_results',case when b.ballot_type='election' then 'Election results published' else 'Poll results published' end,b.title,'elections','ballot',b.id,'normal','{}'::jsonb,auth.uid());end loop;insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_ballot_results_published',jsonb_build_object('ballot_id',b.id));end $function$
;

CREATE OR REPLACE FUNCTION public.record_launch_demo_seed_issue(p_run_id uuid, p_severity text, p_section_key text, p_row_ref text, p_operation text, p_error_code text DEFAULT NULL::text, p_message text DEFAULT ''::text, p_details text DEFAULT NULL::text, p_hint text DEFAULT NULL::text, p_retryable boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); r public.launch_demo_seed_runs%rowtype;
begin
 select * into r from public.launch_demo_seed_runs where id=p_run_id and network_id=nid;
 if not found or (not public.is_network_admin(nid) and not public.is_platform_owner()) then raise exception 'Seed run is not available in the active network.' using errcode='42501'; end if;
 if r.status<>'running' then raise exception 'Seed run is already complete.' using errcode='22023'; end if;
 if p_severity not in ('error','warning') then raise exception 'Invalid seed issue severity.' using errcode='22023'; end if;
 insert into public.launch_demo_seed_issues(run_id,network_id,dataset_version,severity,section_key,row_ref,operation,error_code,message,details,hint,retryable)
 values(r.id,nid,r.dataset_version,p_severity,left(coalesce(nullif(trim(p_section_key),''),'unknown'),140),left(coalesce(nullif(trim(p_row_ref),''),'unknown'),180),left(coalesce(nullif(trim(p_operation),''),'seed-row'),120),nullif(left(trim(coalesce(p_error_code,'')),60),''),coalesce(nullif(trim(p_message),''),'Unknown seed issue'),nullif(p_details,''),nullif(p_hint,''),coalesce(p_retryable,false));
end $function$
;

CREATE OR REPLACE FUNCTION public.record_launch_demo_seed_lineage(p_dataset_version text, p_section_key text, p_row_ref text, p_payload_hash text, p_remote_id text, p_status text DEFAULT 'committed'::text, p_message text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
end $function$
;

CREATE OR REPLACE FUNCTION public.record_my_federated_introduction_outcome(p_introduction_id uuid, p_outcome_code text, p_note text DEFAULT NULL::text, p_close_request boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare i public.federated_introductions%rowtype; rid uuid; role_name varchar(20);
begin
 if p_outcome_code not in ('connected','helpful','resolved','not_resolved','no_follow_up') then raise exception 'Unsupported outcome.' using errcode='22023'; end if;
 if length(trim(coalesce(p_note,'')))>800 then raise exception 'Outcome note is too long.' using errcode='22023'; end if;
 select * into i from public.federated_introductions where id=p_introduction_id and status='accepted' and (requester_user_id=auth.uid() or target_user_id=auth.uid());
 if not found then raise exception 'Accepted introduction not found for this user.' using errcode='42501'; end if;
 role_name:=case when i.requester_user_id=auth.uid() then 'requester' else 'recipient' end;
 rid:=public.ensure_federated_trust_receipt(i.id);
 if rid is null then raise exception 'Trust Receipt could not be established.' using errcode='55000'; end if;
 insert into public.federated_introduction_outcomes(introduction_id,receipt_id,actor_user_id,actor_role,outcome_code,note)
 values(i.id,rid,auth.uid(),role_name,p_outcome_code,left(nullif(trim(coalesce(p_note,'')),''),800))
 on conflict(introduction_id,actor_user_id) do update set outcome_code=excluded.outcome_code,note=excluded.note,updated_at=now();
 if p_close_request and role_name='requester' then
  update public.federated_requests set status='closed',updated_at=now() where id=i.request_id and requester_user_id=auth.uid() and status='open';
 end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.record_network_fund_transaction(p_fund_id uuid, p_transaction_kind text, p_amount numeric, p_source_entity_id uuid DEFAULT NULL::uuid, p_activity_id uuid DEFAULT NULL::uuid, p_membership_year_id uuid DEFAULT NULL::uuid, p_payment_method text DEFAULT NULL::text, p_reference text DEFAULT NULL::text, p_note text DEFAULT NULL::text, p_visibility text DEFAULT 'members'::text, p_occurred_on date DEFAULT CURRENT_DATE)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); rid uuid; fundrow public.network_funds%rowtype; receipt text; recipient uuid; due numeric; paid numeric;
begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501'; end if;
 select * into fundrow from public.network_funds where id=p_fund_id and network_id=nid and status='active'; if not found then raise exception 'Active fund not found.' using errcode='22023'; end if;
 if p_transaction_kind not in ('collection','expense','refund','transfer_in','transfer_out','adjustment') then raise exception 'Invalid transaction kind.' using errcode='22023'; end if;
 if coalesce(p_amount,0)<=0 then raise exception 'Amount must be greater than zero.' using errcode='22023'; end if;
 if p_visibility not in ('admins','members','highlighted') then raise exception 'Invalid transaction visibility.' using errcode='22023'; end if;
 if p_source_entity_id is not null and not exists(select 1 from public.network_entities e where e.id=p_source_entity_id and e.network_id=nid) then raise exception 'Source family/member not found.' using errcode='22023'; end if;
 if p_activity_id is not null and not exists(select 1 from public.network_activities a where a.id=p_activity_id and a.network_id=nid) then raise exception 'Activity not found.' using errcode='22023'; end if;
 receipt:='TW-'||to_char(coalesce(p_occurred_on,current_date),'YYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
 insert into public.network_fund_transactions(network_id,fund_id,transaction_kind,amount,source_entity_id,activity_id,membership_year_id,receipt_no,payment_method,reference,note,visibility,occurred_on,created_by)
 values(nid,p_fund_id,p_transaction_kind,p_amount,p_source_entity_id,p_activity_id,p_membership_year_id,receipt,nullif(trim(coalesce(p_payment_method,'')),''),nullif(trim(coalesce(p_reference,'')),''),nullif(trim(coalesce(p_note,'')),''),p_visibility,coalesce(p_occurred_on,current_date),auth.uid()) returning id into rid;

 -- Keep FCA annual membership status synchronized when a membership fund collection is linked to a family/year.
 if p_transaction_kind='collection' and p_source_entity_id is not null and p_membership_year_id is not null and to_regclass('public.family_association_family_memberships') is not null then
   update public.family_association_family_memberships m
      set amount_paid=m.amount_paid+p_amount,
          payment_status=case when m.amount_paid+p_amount>=m.amount_due then 'paid' when m.amount_paid+p_amount>0 then 'partial' else m.payment_status end,
          renewed_on=current_date,updated_at=now()
    where m.network_id=nid and m.membership_year_id=p_membership_year_id and m.family_entity_id=p_source_entity_id;
 end if;

 -- Notify the member/family representative when a collection or refund is recorded.
 if p_source_entity_id is not null and p_transaction_kind in ('collection','refund') then
   select coalesce(e.owner_user_id,rep.owner_user_id) into recipient
   from public.network_entities e
   left join public.family_association_family_memberships m on m.network_id=nid and m.family_entity_id=e.id and (p_membership_year_id is null or m.membership_year_id=p_membership_year_id)
   left join public.network_entities rep on rep.id=m.representative_entity_id and rep.network_id=nid
   where e.id=p_source_entity_id and e.network_id=nid limit 1;
   if recipient is not null and recipient<>auth.uid() and exists(select 1 from public.network_memberships nm where nm.network_id=nid and nm.user_id=recipient and nm.status='active') then
     perform public.create_network_notification(nid,recipient,'fund_transaction',case when p_transaction_kind='collection' then 'Payment recorded' else 'Refund recorded' end,
       fundrow.name||' · ₹'||to_char(p_amount,'FM999G999G990D00'),'funds','fund_transaction',rid,'normal',jsonb_build_object('fund_id',p_fund_id,'receipt_no',receipt),auth.uid());
   end if;
 end if;

 -- Treasurer/President see meaningful fund movement without relying on someone opening the app.
 if p_transaction_kind in ('expense','collection','refund') then
   perform public.route_network_mentions(array['@treasurer','@president'],
     case when p_transaction_kind='expense' then 'Fund expense recorded' else 'Fund collection updated' end,
     fundrow.name||' · ₹'||to_char(p_amount,'FM999G999G990D00'),'funds','fund_transaction',rid,
     case when p_transaction_kind='expense' and p_amount>=5000 then 'high' else 'normal' end);
 end if;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_fund_transaction_recorded',jsonb_build_object('transaction_id',rid,'fund_id',p_fund_id,'kind',p_transaction_kind,'amount',p_amount,'receipt_no',receipt));
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.record_pilot_product_decision(p_moment_type text, p_disposition text, p_evidence_days integer, p_rationale text, p_next_action text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare rid uuid; snap jsonb; clean_rationale text:=nullif(trim(coalesce(p_rationale,'')),''); clean_next text:=nullif(trim(coalesce(p_next_action,'')),'');
begin
 if auth.uid() is null then raise exception 'Authentication required.' using errcode='42501';end if;
 if not exists(select 1 from public.network_memberships nm join public.networks n on n.id=nm.network_id where nm.user_id=auth.uid() and nm.status='active' and nm.role in('owner','admin') and n.status='active') then raise exception 'Owner or Admin access is required.' using errcode='42501';end if;
 if p_moment_type not in('launch','participation','claim','bridge','discovery','introduction','outcome','general') then raise exception 'Unsupported decision moment.' using errcode='22023';end if;
 if p_disposition not in('invest','fix','hold','stop') then raise exception 'Unsupported decision.' using errcode='22023';end if;
 if p_evidence_days<7 or p_evidence_days>90 then raise exception 'Evidence window must be between 7 and 90 days.' using errcode='22023';end if;
 if clean_rationale is null or length(clean_rationale)<8 then raise exception 'A short rationale is required.' using errcode='22023';end if;
 if length(clean_rationale)>800 or length(coalesce(clean_next,''))>300 then raise exception 'Decision text is too long.' using errcode='22023';end if;
 select jsonb_build_object(
  'days',p_evidence_days,
  'feedback',count(*),
  'helpful',count(*) filter(where outcome='helpful'),
  'partial',count(*) filter(where outcome='partial'),
  'blocked',count(*) filter(where outcome='blocked'),
  'topFriction',(select pf2.friction_code from public.pilot_feedback pf2 join public.network_memberships nm2 on nm2.network_id=pf2.network_id and nm2.user_id=auth.uid() and nm2.status='active' and nm2.role in('owner','admin') where pf2.moment_type=p_moment_type and pf2.friction_code<>'none' and pf2.created_at>=now()-(p_evidence_days||' days')::interval group by pf2.friction_code order by count(*) desc,pf2.friction_code limit 1)
 ) into snap
 from public.pilot_feedback pf join public.network_memberships nm on nm.network_id=pf.network_id and nm.user_id=auth.uid() and nm.status='active' and nm.role in('owner','admin')
 where pf.moment_type=p_moment_type and pf.created_at>=now()-(p_evidence_days||' days')::interval;
 insert into public.pilot_product_decisions(decided_by,moment_type,disposition,evidence_days,evidence_snapshot,rationale,next_action)
 values(auth.uid(),p_moment_type,p_disposition,p_evidence_days,coalesce(snap,'{}'::jsonb),clean_rationale,clean_next) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.refresh_family_intake_matches(p_session_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare p record; c record; sc integer; reason jsonb;
begin
  delete from public.family_intake_match_candidates where session_id=p_session_id and status='open';
  for p in select * from public.family_intake_people where session_id=p_session_id and status in ('staged','new','ambiguous') loop
    for c in select fm.* from public.family_members fm where fm.network_id=p.network_id and public.normalize_intake_name(fm.full_name)=p.normalized_name loop
      sc:=public.score_intake_person(p.full_name,p.date_of_birth,p.birth_year,p.gender,p.city,c.full_name,c.date_of_birth,extract(year from c.date_of_birth)::int,c.gender,c.city);
      -- Relationship context: reported parent/spouse names matching canonical neighbours is stronger than demographics alone.
      if exists(
        select 1 from public.family_intake_relationships ir
        join public.family_intake_people ip on ip.id=case when ir.from_staged_person_id=p.id then ir.to_staged_person_id else ir.from_staged_person_id end
        join public.family_relationships fr on fr.network_id=p.network_id and (fr.person_id=c.id or fr.related_person_id=c.id)
        join public.family_members cm on cm.network_id=p.network_id and cm.id=case when fr.person_id=c.id then fr.related_person_id else fr.person_id end
        where ir.session_id=p_session_id and (ir.from_staged_person_id=p.id or ir.to_staged_person_id=p.id) and public.normalize_intake_name(cm.full_name)=ip.normalized_name
      ) then sc:=least(100,sc+20); end if;
      if sc>=45 and not exists(select 1 from public.family_intake_match_candidates x where x.staged_person_id=p.id and x.candidate_member_id=c.id and x.status<>'open') then
        reason:=jsonb_build_object('name','exact','dob',p.date_of_birth is not null and c.date_of_birth=p.date_of_birth,'birth_year',coalesce(p.birth_year,extract(year from p.date_of_birth)::int)=extract(year from c.date_of_birth)::int,'city',lower(coalesce(p.city,''))=lower(coalesce(c.city,'')));
        insert into public.family_intake_match_candidates(session_id,network_id,staged_person_id,candidate_member_id,score,confidence_band,reasons)
        values(p_session_id,p.network_id,p.id,c.id,sc,case when sc>=90 then 'high' when sc>=65 then 'medium' else 'low' end,reason);
        if sc>=95 and p.matched_member_id is null then
          update public.family_intake_people set matched_member_id=c.id,match_confidence=sc,status='matched' where id=p.id;
          insert into public.family_intake_decisions(session_id,network_id,staged_person_id,decision,decision_source,reason)
          values(p_session_id,p.network_id,p.id,'same','automatic_high_confidence','Deterministic score >= 95');
        elsif sc>=65 and p.status='staged' then update public.family_intake_people set status='ambiguous',match_confidence=sc where id=p.id; end if;
      end if;
    end loop;
    -- Cross-branch exact-name candidates. Never auto-merge these.
    for c in select q.* from public.family_intake_people q where q.session_id=p_session_id and q.id<>p.id and q.access_id<>p.access_id and q.normalized_name=p.normalized_name and q.created_at<p.created_at loop
      sc:=public.score_intake_person(p.full_name,p.date_of_birth,p.birth_year,p.gender,p.city,c.full_name,c.date_of_birth,c.birth_year,c.gender,c.city);
      if sc>=45 and not exists(select 1 from public.family_intake_match_candidates x where x.staged_person_id=p.id and x.candidate_staged_person_id=c.id) then
        insert into public.family_intake_match_candidates(session_id,network_id,staged_person_id,candidate_staged_person_id,score,confidence_band,reasons)
        values(p_session_id,p.network_id,p.id,c.id,sc,case when sc>=90 then 'high' when sc>=65 then 'medium' else 'low' end,jsonb_build_object('name','exact','cross_branch',true));
        if sc>=65 and p.status='staged' then update public.family_intake_people set status='ambiguous',match_confidence=sc where id=p.id; end if;
      end if;
    end loop;
  end loop;
end $function$
;

CREATE OR REPLACE FUNCTION public.refresh_my_federated_request_routes(p_request_id uuid, p_limit integer DEFAULT 20)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare req public.federated_requests%rowtype; inserted_count integer:=0;
begin
 select * into req from public.federated_requests where id=p_request_id and requester_user_id=auth.uid();
 if not found then raise exception 'Request not found or not owned by you.' using errcode='42501'; end if;
 if req.status<>'open' then raise exception 'Only open requests can be routed.' using errcode='22023'; end if;
 if not exists(select 1 from public.network_umbrella_affiliations a join public.federation_umbrellas u on u.id=a.umbrella_id and u.status='active' where a.network_id=req.source_network_id and a.umbrella_id=req.umbrella_id and a.status='approved') then raise exception 'The source federation path is no longer active.' using errcode='42501'; end if;

 delete from public.federated_request_routes where request_id=req.id and status<>'shortlisted';

 insert into public.federated_request_routes(request_id,target_scope_profile_id,score,reasons,trust_path_label,status,generated_at)
 select req.id,c.id,
  least(100,
   least(45,15*coalesce((select count(*) from unnest(c.tags) ct where exists(select 1 from unnest(req.tags) rt where lower(rt)=lower(ct))),0))
   + case when coalesce(trim(req.location_label),'')<>'' and lower(coalesce(c.location_label,'')) like '%'||lower(trim(req.location_label))||'%' then 15 else 0 end
   + case when lower(concat_ws(' ',c.headline,c.summary,array_to_string(c.tags,' '))) like '%'||lower(req.title)||'%' then 20 else 0 end
   + case when c.updated_at>now()-interval '90 days' then 10 else 0 end
   + 10
  )::integer as score,
  array_remove(array[
   case when exists(select 1 from unnest(c.tags) ct where exists(select 1 from unnest(req.tags) rt where lower(rt)=lower(ct))) then 'Purpose tags overlap' end,
   case when coalesce(trim(req.location_label),'')<>'' and lower(coalesce(c.location_label,'')) like '%'||lower(trim(req.location_label))||'%' then 'Location aligns' end,
   case when lower(concat_ws(' ',c.headline,c.summary,array_to_string(c.tags,' '))) like '%'||lower(req.title)||'%' then 'Published profile matches the request wording' end,
   case when c.updated_at>now()-interval '90 days' then 'Purpose profile is recently refreshed' end,
   'Same approved umbrella and purpose'
  ]::text[],null),
  (src.name||' → '||u.name||' → '||target.name)::text,'suggested',now()
 from public.federated_scope_profiles c
 join public.networks target on target.id=c.network_id and target.status='active'
 join public.networks src on src.id=req.source_network_id and src.status='active'
 join public.federation_umbrellas u on u.id=req.umbrella_id and u.status='active'
 join public.network_umbrella_affiliations ta on ta.network_id=c.network_id and ta.umbrella_id=req.umbrella_id and ta.status='approved'
 join public.network_passports np on np.network_id=c.network_id and np.visibility in ('federation','public')
 where c.umbrella_id=req.umbrella_id and c.active and lower(c.scope_key)=lower(req.scope_key) and c.owner_user_id<>auth.uid()
   and exists(select 1 from unnest(np.participation_scopes) x where lower(x)=lower(req.scope_key))
 order by score desc,c.updated_at desc
 limit least(greatest(coalesce(p_limit,20),1),50)
 on conflict(request_id,target_scope_profile_id) do update set score=excluded.score,reasons=excluded.reasons,trust_path_label=excluded.trust_path_label,generated_at=now();
 get diagnostics inserted_count=row_count;
 update public.federated_requests set updated_at=now() where id=req.id;
 return inserted_count;
end $function$
;

CREATE OR REPLACE FUNCTION public.regenerate_family_join_code()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); c text;
begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Family administrator access required.' using errcode='42501'; end if;
 c:=public.generate_family_join_code();
 insert into public.family_join_codes(network_id,code,created_by,updated_at) values(nid,c,auth.uid(),now())
 on conflict(network_id) do update set code=excluded.code,created_by=auth.uid(),updated_at=now();
 return c;
end;$function$
;

CREATE OR REPLACE FUNCTION public.regenerate_network_bridge_code(p_network_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare result text;
begin
 if auth.uid() is null or not public.is_network_admin(p_network_id) then raise exception 'Network administrator access is required.' using errcode='42501'; end if;
 result:=upper(substr(encode(gen_random_bytes(8),'hex'),1,12));
 insert into public.network_bridge_codes(network_id,code,created_by,rotated_at) values(p_network_id,result,auth.uid(),now())
 on conflict(network_id) do update set code=excluded.code,created_by=auth.uid(),rotated_at=now();
 return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.regenerate_network_join_code()
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();c text; begin if not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501'; end if;c:=public.g8_generate_join_code();insert into public.network_join_codes(network_id,code,created_by,updated_at) values(nid,c,auth.uid(),now()) on conflict(network_id) do update set code=excluded.code,created_by=excluded.created_by,updated_at=now();return c;end $function$
;

CREATE OR REPLACE FUNCTION public.register_network_creation(p_network_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_result jsonb;
begin
  v_result:=public.finalize_network_creation(p_network_id,null);
  return coalesce(v_result->>'approval_status','approved');
end $function$
;

CREATE OR REPLACE FUNCTION public.remove_platform_owner(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_count integer;
begin
  if not public.is_platform_owner() then
    raise exception 'Platform owner access is required.' using errcode='42501';
  end if;
  if not exists(select 1 from public.platform_owners where user_id=p_user_id) then
    raise exception 'That account is not a platform owner.' using errcode='P0002';
  end if;
  select count(*) into v_count from public.platform_owners;
  if v_count<=1 then
    raise exception 'At least one platform owner must remain.' using errcode='23514';
  end if;
  delete from public.platform_owners where user_id=p_user_id;
  insert into public.platform_owner_audit(actor_user_id,target_user_id,action) values(auth.uid(),p_user_id,'removed');
end $function$
;

CREATE OR REPLACE FUNCTION public.remove_productized_network_member(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); actor_role text; target_role text;
begin
 if not public.g8_productized_vertical((select vertical_kind from public.networks where id=nid)) then raise exception 'Productized network required.' using errcode='42501'; end if;
 select role into actor_role from public.network_memberships where network_id=nid and user_id=auth.uid() and status='active';
 if actor_role is null or actor_role not in ('owner','admin') then raise exception 'Network admin access required.' using errcode='42501'; end if;
 if p_user_id=auth.uid() then raise exception 'Use the network switcher/lobby to leave your own network.' using errcode='42501'; end if;
 select role into target_role from public.network_memberships where network_id=nid and user_id=p_user_id and status='active';
 if target_role is null or target_role='owner' then raise exception 'The network owner cannot be removed.' using errcode='42501'; end if;
 if target_role='admin' and actor_role<>'owner' then raise exception 'Only the owner can remove an admin.' using errcode='42501'; end if;
 update public.network_memberships set status='left' where network_id=nid and user_id=p_user_id;
 update public.network_entities set owner_user_id=null,updated_at=now() where network_id=nid and owner_user_id=p_user_id;
 update public.profiles set active_network_id=null,updated_at=now() where id=p_user_id and active_network_id=nid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'productized_member_removed',jsonb_build_object('user_id',p_user_id,'previous_role',target_role));
end $function$
;

CREATE OR REPLACE FUNCTION public.request_community_introduction(p_card_id uuid, p_message text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); c public.community_profile_cards%rowtype; rid uuid; path_names text[]; path_ids uuid[]; hop_count integer;
begin
 if nid is null then raise exception 'Choose an active family first.' using errcode='42501'; end if;
 select * into c from public.community_profile_cards where id=p_card_id and active;
 if c.id is null or not public.community_space_is_allowed(c.space_id,nid) then raise exception 'Community profile is not available.' using errcode='42501'; end if;
 if c.network_id=nid then raise exception 'This person is already in your family.' using errcode='22023'; end if;
 select path_network_ids,path_family_names,hops into path_ids,path_names,hop_count from public.get_trusted_connection_path(c.space_id,c.network_id) limit 1;
 insert into public.community_introduction_requests(space_id,requester_network_id,requester_user_id,target_card_id,target_network_id,target_user_id,message,path_snapshot)
 values(c.space_id,nid,auth.uid(),c.id,c.network_id,c.owner_user_id,nullif(trim(p_message),''),
   case when path_names is null then '[]'::jsonb else to_jsonb(path_names) end) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.request_family_community_link(p_space_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); rid uuid;
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family Owner/admin access required.' using errcode='42501'; end if;
  if not exists(select 1 from public.community_spaces where id=p_space_id and status='active') then raise exception 'Community not found.' using errcode='22023'; end if;
  insert into public.community_family_links(space_id,network_id,status,requested_by)
  values(p_space_id,nid,case when public.is_platform_owner() then 'approved' else 'pending' end,auth.uid())
  on conflict(space_id,network_id) do update set status=excluded.status,requested_by=auth.uid(),created_at=now()
  returning id into rid;
  return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.request_family_creation(p_name text, p_description text DEFAULT ''::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); rid uuid;
begin
  if uid is null then raise exception 'Sign in is required.' using errcode='42501'; end if;
  if length(trim(coalesce(p_name,'')))<2 then raise exception 'Please give your family a name.' using errcode='22023'; end if;
  if exists(select 1 from public.family_creation_requests where requester_user_id=uid and status='pending') then
    select id into rid from public.family_creation_requests where requester_user_id=uid and status='pending' order by created_at desc limit 1;
    return rid;
  end if;
  insert into public.family_creation_requests(requester_user_id,name,description,slug)
  values(uid,left(trim(p_name),180),coalesce(p_description,''),left(public.slugify_family_name(p_name),60))
  returning id into rid;
  return rid;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.request_family_trust_connection(p_space_id uuid, p_target_network_id uuid, p_context_label text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); rid uuid;
begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Family Owner/admin access required.' using errcode='42501'; end if;
 if p_target_network_id=nid then raise exception 'Choose another family.' using errcode='22023'; end if;
 if not public.community_space_is_allowed(p_space_id,nid) then raise exception 'Your family is not connected to this community.' using errcode='42501'; end if;
 if not public.community_space_is_allowed(p_space_id,p_target_network_id) then raise exception 'That family is not connected to this community.' using errcode='42501'; end if;
 insert into public.community_trust_edges(space_id,requester_network_id,recipient_network_id,status,context_label,requested_by,updated_at)
 values(p_space_id,nid,p_target_network_id,'pending',nullif(trim(p_context_label),''),auth.uid(),now())
 on conflict(space_id,(least(requester_network_id,recipient_network_id)),(greatest(requester_network_id,recipient_network_id)))
 do update set requester_network_id=nid,recipient_network_id=p_target_network_id,status='pending',context_label=excluded.context_label,requested_by=auth.uid(),reviewed_by=null,reviewed_at=null,updated_at=now()
 returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.request_federated_introduction_v2(p_route_id uuid, p_requester_alias text, p_message text, p_contact_note text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare rr public.federated_request_routes%rowtype; req public.federated_requests%rowtype; sp public.federated_scope_profiles%rowtype; rid uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_requester_alias,'')))<2 then raise exception 'Add the name or alias you want the recipient to see.' using errcode='22023'; end if;
 if length(trim(coalesce(p_message,'')))<3 then raise exception 'Add a short introduction reason.' using errcode='22023'; end if;
 if length(trim(coalesce(p_contact_note,'')))<3 then raise exception 'Add a response channel to reveal only after acceptance.' using errcode='22023'; end if;
 select * into rr from public.federated_request_routes where id=p_route_id and status='shortlisted';
 if not found then raise exception 'Only a shortlisted route can become an introduction.' using errcode='42501'; end if;
 select * into req from public.federated_requests where id=rr.request_id and requester_user_id=auth.uid() and status='open';
 if not found then raise exception 'The source request is not open or not owned by you.' using errcode='42501'; end if;
 select * into sp from public.federated_scope_profiles where id=rr.target_scope_profile_id and active and owner_user_id<>auth.uid();
 if not found then raise exception 'The target purpose opt-in is no longer available.' using errcode='42501'; end if;
 if sp.umbrella_id<>req.umbrella_id or lower(sp.scope_key)<>lower(req.scope_key) then raise exception 'The target no longer matches this request context.' using errcode='42501'; end if;
 if not exists(select 1 from public.federation_umbrellas u where u.id=req.umbrella_id and u.status='active') then raise exception 'The umbrella is no longer active.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_umbrella_affiliations a where a.network_id=req.source_network_id and a.umbrella_id=req.umbrella_id and a.status='approved') then raise exception 'The requester federation path is no longer approved.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_umbrella_affiliations a where a.network_id=sp.network_id and a.umbrella_id=req.umbrella_id and a.status='approved') then raise exception 'The target federation path is no longer approved.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_passports p where p.network_id=sp.network_id and p.visibility in ('federation','public') and exists(select 1 from unnest(p.participation_scopes) x where lower(x)=lower(req.scope_key))) then raise exception 'The target Network Passport no longer permits this purpose.' using errcode='42501'; end if;
 insert into public.federated_introductions(request_id,route_id,target_scope_profile_id,requester_user_id,target_user_id,requester_alias,message,requester_contact_note,trust_path_snapshot)
 values(req.id,rr.id,sp.id,auth.uid(),sp.owner_user_id,trim(p_requester_alias),left(trim(p_message),800),left(trim(p_contact_note),320),rr.trust_path_label)
 returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.request_network_trust_bridge(p_source_network_id uuid, p_target_code text, p_relationship_type text, p_context_label text DEFAULT NULL::text, p_capabilities jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare target_id uuid; existing public.network_trust_bridges%rowtype; rid uuid; caps jsonb;
begin
 if auth.uid() is null or not public.is_network_admin(p_source_network_id) then raise exception 'Network administrator access is required.' using errcode='42501'; end if;
 if p_relationship_type not in ('affiliation','community','partner','parent_child','trusted_peer') then raise exception 'Unsupported network bridge relationship.' using errcode='22023'; end if;
 select c.network_id into target_id from public.network_bridge_codes c join public.networks n on n.id=c.network_id where upper(c.code)=upper(trim(p_target_code)) and n.status='active';
 if target_id is null then raise exception 'Bridge code was not found.' using errcode='P0002'; end if;
 if target_id=p_source_network_id then raise exception 'A network cannot bridge to itself.' using errcode='22023'; end if;
 caps:=public.m6b_bridge_capabilities(coalesce(p_capabilities,'{}'::jsonb));
 select * into existing from public.network_trust_bridges b
  where least(b.requester_network_id,b.recipient_network_id)=least(p_source_network_id,target_id)
    and greatest(b.requester_network_id,b.recipient_network_id)=greatest(p_source_network_id,target_id)
    and b.relationship_type=p_relationship_type order by b.updated_at desc limit 1;
 if existing.id is not null and existing.status='accepted' then raise exception 'These networks already have an accepted bridge of this type.' using errcode='23505'; end if;
 if existing.id is not null then
  update public.network_trust_bridges set requester_network_id=p_source_network_id,recipient_network_id=target_id,status='pending',context_label=nullif(trim(p_context_label),''),capabilities=caps,requested_by=auth.uid(),reviewed_by=null,reviewed_at=null,revoked_by=null,revoked_at=null,updated_at=now() where id=existing.id returning id into rid;
 else
  insert into public.network_trust_bridges(requester_network_id,recipient_network_id,relationship_type,context_label,capabilities,requested_by)
  values(p_source_network_id,target_id,p_relationship_type,nullif(trim(p_context_label),''),caps,auth.uid()) returning id into rid;
 end if;
 insert into public.audit_log(network_id,actor_id,action,details) values(p_source_network_id,auth.uid(),'network_trust_bridge_requested',jsonb_build_object('bridge_id',rid,'target_network_id',target_id,'relationship_type',p_relationship_type,'capabilities',caps));
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.respond_network_event(p_activity_id uuid, p_response text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id();
begin
 if p_response not in ('going','maybe','declined') then raise exception 'Invalid RSVP response.'; end if;
 if not public.is_network_member(v_network) then raise exception 'Membership required.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_activities where id=p_activity_id and network_id=v_network and activity_type='event') then raise exception 'Event not found.'; end if;
 insert into public.network_activity_rsvps(activity_id,network_id,user_id,response) values(p_activity_id,v_network,auth.uid(),p_response)
 on conflict(activity_id,user_id) do update set response=excluded.response,updated_at=now();
end $function$
;

CREATE OR REPLACE FUNCTION public.respond_to_community_event(p_event_id uuid, p_response text, p_guest_count integer DEFAULT 0)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
  if p_response not in ('going','interested','not_going') then raise exception 'Invalid response.' using errcode='22023'; end if;
  if not exists(select 1 from public.community_events where id=p_event_id and status='open') then raise exception 'This event is not accepting responses.' using errcode='22023'; end if;
  insert into public.community_event_responses(event_id,user_id,response,guest_count)
  values(p_event_id,auth.uid(),p_response,greatest(0,least(coalesce(p_guest_count,0),20)))
  on conflict(event_id,user_id) do update set response=excluded.response,guest_count=excluded.guest_count,updated_at=now();
  insert into public.audit_log(actor_id,action,details) values(auth.uid(),'community_event_response',jsonb_build_object('event_id',p_event_id,'response',p_response));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.respond_to_community_introduction(p_request_id uuid, p_accept boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 update public.community_introduction_requests set status=case when p_accept then 'accepted' else 'declined' end,responded_by=auth.uid(),responded_at=now(),updated_at=now()
 where id=p_request_id and target_user_id=auth.uid() and status='pending';
 if not found then raise exception 'Introduction request not found or not yours to review.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.respond_to_federated_introduction_v2(p_introduction_id uuid, p_accept boolean, p_response_note text DEFAULT NULL::text, p_contact_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare i public.federated_introductions%rowtype; req public.federated_requests%rowtype; sp public.federated_scope_profiles%rowtype;
begin
 select * into i from public.federated_introductions where id=p_introduction_id and target_user_id=auth.uid() and status='pending';
 if not found then raise exception 'Pending introduction not found.' using errcode='42501'; end if;
 if p_accept then
  if length(trim(coalesce(p_contact_note,'')))<3 then raise exception 'Add a response channel before accepting.' using errcode='22023'; end if;
  select * into req from public.federated_requests where id=i.request_id;
  select * into sp from public.federated_scope_profiles where id=i.target_scope_profile_id and owner_user_id=auth.uid() and active;
  if not found then raise exception 'Your purpose opt-in is no longer active.' using errcode='42501'; end if;
  if req.status<>'open' then raise exception 'The original request is no longer open.' using errcode='42501'; end if;
  if sp.umbrella_id<>req.umbrella_id or lower(sp.scope_key)<>lower(req.scope_key) then raise exception 'The introduction context is no longer valid.' using errcode='42501'; end if;
  if not exists(select 1 from public.federation_umbrellas u where u.id=req.umbrella_id and u.status='active') then raise exception 'The umbrella is no longer active.' using errcode='42501'; end if;
  if not exists(select 1 from public.network_umbrella_affiliations a where a.network_id=req.source_network_id and a.umbrella_id=req.umbrella_id and a.status='approved') then raise exception 'The requester federation path is no longer approved.' using errcode='42501'; end if;
  if not exists(select 1 from public.network_umbrella_affiliations a where a.network_id=sp.network_id and a.umbrella_id=req.umbrella_id and a.status='approved') then raise exception 'Your federation path is no longer approved.' using errcode='42501'; end if;
  if not exists(select 1 from public.network_passports p where p.network_id=sp.network_id and p.visibility in ('federation','public') and exists(select 1 from unnest(p.participation_scopes) x where lower(x)=lower(req.scope_key))) then raise exception 'Your Network Passport no longer permits this purpose.' using errcode='42501'; end if;
 end if;
 update public.federated_introductions set status=case when p_accept then 'accepted' else 'declined' end,
  target_response_note=left(nullif(trim(coalesce(p_response_note,'')),''),800),
  target_contact_note=case when p_accept then left(trim(p_contact_note),320) else null end,
  responded_at=now(),updated_at=now()
 where id=i.id;
end $function$
;

CREATE OR REPLACE FUNCTION public.restore_owned_network(p_network_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); owner_ok boolean;
begin
 if uid is null then raise exception 'Sign in required.' using errcode='42501'; end if;
 select exists(select 1 from public.network_memberships nm join public.networks n on n.id=nm.network_id
  where n.id=p_network_id and n.status='archived' and nm.user_id=uid and nm.role='owner' and nm.status in ('suspended','active')) into owner_ok;
 if not owner_ok then raise exception 'Only the archived network Owner can restore this network.' using errcode='42501'; end if;
 update public.networks set status='active',updated_at=now() where id=p_network_id;
 if exists(select 1 from public.network_archive_membership_state where network_id=p_network_id) then
  update public.network_memberships nm set status=s.previous_status
  from public.network_archive_membership_state s where s.network_id=p_network_id and s.network_id=nm.network_id and s.user_id=nm.user_id;
 else
  -- Compatibility fallback for networks archived before XP-0 snapshotting existed.
  update public.network_memberships set status='active' where network_id=p_network_id and status='suspended';
 end if;
 delete from public.network_archive_membership_state where network_id=p_network_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_community_link(p_link_id uuid, p_approve boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access required.' using errcode='42501'; end if;
 update public.community_family_links set status=case when p_approve then 'approved' else 'rejected' end,reviewed_by=auth.uid(),reviewed_at=now() where id=p_link_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_family_creation_request(p_request_id uuid, p_action text, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  req public.family_creation_requests%rowtype;
  nid uuid; base_slug text; final_slug text; suffix integer:=1;
begin
  if not public.is_platform_owner() then raise exception 'Platform-owner access required.' using errcode='42501'; end if;
  if p_action not in ('approve','reject') then raise exception 'Action must be approve or reject.' using errcode='22023'; end if;

  select * into req from public.family_creation_requests where id=p_request_id for update;
  if req.id is null then raise exception 'Family creation request not found.' using errcode='P0002'; end if;
  if req.status<>'pending' then raise exception 'This request has already been reviewed.' using errcode='22023'; end if;

  if p_action='reject' then
    update public.family_creation_requests
      set status='rejected',reviewed_by=auth.uid(),reviewed_at=now(),decision_note=nullif(trim(coalesce(p_note,'')),''),updated_at=now()
      where id=req.id;
    return null;
  end if;

  base_slug:=coalesce(nullif(trim(req.slug),''),public.slugify_family_name(req.name));
  if length(base_slug)<2 then base_slug:='family'; end if;
  base_slug:=left(base_slug,60); final_slug:=base_slug;
  while exists(select 1 from public.networks where slug=final_slug) loop
    suffix:=suffix+1; final_slug:=left(base_slug,54)||'-'||suffix::text;
  end loop;

  insert into public.networks(name,slug,created_by,photo_upload_enabled)
  values(req.name,final_slug,req.requester_user_id,false) returning id into nid;

  insert into public.network_memberships(network_id,user_id,role,status)
  values(nid,req.requester_user_id,'owner','active');

  insert into public.network_settings(
    id,network_id,name,description,entity_label,entity_label_plural,level_label,level_label_plural,
    parent_label,child_label,peer_label,network_template,photo_upload_enabled
  ) values(
    'network',nid,req.name,coalesce(req.description,''),'Member','Members','Generation','Generations',
    'Parent','Child','Spouse','family',false
  );

  update public.profiles set active_network_id=nid,member_id=null,updated_at=now() where id=req.requester_user_id;
  update public.family_creation_requests
    set status='approved',reviewed_by=auth.uid(),reviewed_at=now(),network_id=nid,decision_note=nullif(trim(coalesce(p_note,'')),''),updated_at=now()
    where id=req.id;
  return nid;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.review_family_trust_connection(p_edge_id uuid, p_accept boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); edge public.community_trust_edges%rowtype;
begin
 select * into edge from public.community_trust_edges where id=p_edge_id;
 if edge.id is null or edge.recipient_network_id<>nid or not public.is_network_admin(nid) then raise exception 'Only the receiving Family Owner/admin can review this connection.' using errcode='42501'; end if;
 update public.community_trust_edges set status=case when p_accept then 'accepted' else 'declined' end,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=p_edge_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_network_ballot_nomination(p_nomination_id uuid, p_action text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();n public.network_ballot_nominations%rowtype;begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;if p_action not in ('approved','rejected') then raise exception 'Invalid review action.';end if;
 update public.network_ballot_nominations set status=p_action,reviewed_by=auth.uid(),reviewed_at=now() where id=p_nomination_id and network_id=nid returning * into n;if not found then raise exception 'Nomination not found.';end if;
 if p_action='approved' and not exists(select 1 from public.network_ballot_options where ballot_id=n.ballot_id and candidate_entity_id=n.nominee_entity_id) then perform public.add_network_ballot_option(n.ballot_id,n.nominee_label,n.statement,n.nominee_entity_id);end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_network_creation(p_network_id uuid, p_action text, p_note text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_status text; v_creator uuid;
begin
  if not public.is_platform_owner() then raise exception 'Platform-owner access required.' using errcode='42501'; end if;
  if p_action not in ('approve','reject') then raise exception 'Action must be approve or reject.' using errcode='22023'; end if;
  select created_by into v_creator from public.networks where id=p_network_id;
  if v_creator is null then raise exception 'Network not found.' using errcode='P0002'; end if;
  v_status:=case when p_action='approve' then 'approved' else 'rejected' end;

  if v_status='approved' then
    insert into public.profiles(id,full_name)
    select u.id,coalesce(nullif(trim(u.raw_user_meta_data->>'full_name'),''),split_part(coalesce(u.email,''),'@',1),'')
    from auth.users u where u.id=v_creator on conflict(id) do nothing;
    insert into public.network_memberships(network_id,user_id,role,status)
    values(p_network_id,v_creator,'owner','active')
    on conflict(network_id,user_id) do update set status='active';
  end if;

  update public.networks
  set approval_status=v_status,approval_reviewed_at=now(),approval_reviewed_by=auth.uid(),approval_note=nullif(trim(coalesce(p_note,'')),''),updated_at=now()
  where id=p_network_id;
  return v_status;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_network_trust_bridge(p_bridge_id uuid, p_accept boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare b public.network_trust_bridges%rowtype;
begin
 select * into b from public.network_trust_bridges where id=p_bridge_id;
 if b.id is null then raise exception 'Network bridge request not found.' using errcode='P0002'; end if;
 if b.status<>'pending' then raise exception 'Only pending bridge requests can be reviewed.' using errcode='22023'; end if;
 if not public.is_network_admin(b.recipient_network_id) then raise exception 'Only an administrator of the receiving network can review this bridge.' using errcode='42501'; end if;
 update public.network_trust_bridges set status=case when p_accept then 'accepted' else 'declined' end,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=p_bridge_id;
 insert into public.audit_log(network_id,actor_id,action,details) values(b.recipient_network_id,auth.uid(),case when p_accept then 'network_trust_bridge_accepted' else 'network_trust_bridge_declined' end,jsonb_build_object('bridge_id',b.id,'source_network_id',b.requester_network_id,'capabilities',b.capabilities));
end $function$
;

CREATE OR REPLACE FUNCTION public.review_organization_knowledge_candidate(p_assertion_id uuid, p_action text, p_reason text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();a public.network_candidate_assertions%rowtype;sid uuid;oid uuid;committed boolean:=false;
begin
 perform public.g91b_assert_organization_network(nid);if not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;
 if p_action not in ('accept','reject') then raise exception 'Invalid review action.' using errcode='22023';end if;
 select * into a from public.network_candidate_assertions where id=p_assertion_id and network_id=nid for update;if a.id is null then raise exception 'Candidate not found.';end if;if a.status not in ('candidate','conflicted') then raise exception 'Candidate already reviewed.';end if;
 if p_action='reject' then update public.network_candidate_assertions set status='rejected',reviewed_by=auth.uid(),reviewed_at=now() where id=a.id;insert into public.network_assertion_decisions(network_id,assertion_id,action,actor_user_id,reason) values(nid,a.id,'reject',auth.uid(),nullif(trim(p_reason),''));return jsonb_build_object('status','rejected','committed',false);end if;
 sid:=nullif(a.subject->>'entityId','')::uuid;oid:=nullif(a.object->>'entityId','')::uuid;
 if sid is not null and not exists(select 1 from public.network_entities e where e.id=sid and e.network_id=nid) then raise exception 'Subject entity is outside active network.' using errcode='42501';end if;
 if oid is not null and not exists(select 1 from public.network_entities e where e.id=oid and e.network_id=nid) then raise exception 'Object entity is outside active network.' using errcode='42501';end if;
 if a.predicate='skill' then
  if sid is null or nullif(trim(coalesce(a.object->>'value',a.object->>'label','')),'') is null then raise exception 'Expertise candidate requires resolved person and skill value.';end if;
  perform public.g7_set_entity_affiliation(sid,nid,'skill',coalesce(a.object->>'value',a.object->>'label'));committed:=true;
 elsif a.predicate in ('owns','depends_on') then
  if sid is null or oid is null then raise exception 'Relationship candidate requires resolved entities.';end if;
  insert into public.network_entity_relationships(network_id,from_entity_id,to_entity_id,relationship_type,metadata,created_by) values(nid,sid,oid,a.predicate,jsonb_build_object('source','g9.1-b-verified-evidence','assertion_id',a.id,'evidence_ids',a.evidence_ids),auth.uid()) on conflict(network_id,from_entity_id,to_entity_id,relationship_type) do update set metadata=network_entity_relationships.metadata||excluded.metadata;committed:=true;
 elsif a.predicate='architectural_decision' then committed:=false;
 else raise exception 'Unsupported candidate predicate.';end if;
 update public.network_candidate_assertions set status='verified',reviewed_by=auth.uid(),reviewed_at=now() where id=a.id;insert into public.network_assertion_decisions(network_id,assertion_id,action,actor_user_id,reason) values(nid,a.id,'accept',auth.uid(),nullif(trim(p_reason),''));
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'organization_knowledge_candidate_verified',jsonb_build_object('assertion_id',a.id,'predicate',a.predicate,'graph_committed',committed));return jsonb_build_object('status','verified','committed',committed);
end $function$
;

CREATE OR REPLACE FUNCTION public.review_productized_network_contribution(p_contribution_id uuid, p_action text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin if not public.is_network_admin() then raise exception 'Network admin access required.' using errcode='42501';end if;if p_action not in ('accepted','rejected') then raise exception 'Invalid action.';end if;update public.network_contributions set status=p_action,reviewed_by=auth.uid(),reviewed_at=now() where id=p_contribution_id and network_id=public.current_network_id();end $function$
;

CREATE OR REPLACE FUNCTION public.revoke_family_intake_link(p_access_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family admin access is required.' using errcode='42501'; end if;
  update public.family_intake_access set status='revoked' where id=p_access_id and network_id=nid and status='active';
end $function$
;

CREATE OR REPLACE FUNCTION public.revoke_family_trust_connection(p_edge_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); edge public.community_trust_edges%rowtype;
begin
 select * into edge from public.community_trust_edges where id=p_edge_id;
 if edge.id is null or nid not in(edge.requester_network_id,edge.recipient_network_id) or not public.is_network_admin(nid) then raise exception 'Family Owner/admin access required.' using errcode='42501'; end if;
 update public.community_trust_edges set status='revoked',updated_at=now() where id=p_edge_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.revoke_network_trust_bridge(p_bridge_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare b public.network_trust_bridges%rowtype; actor_network uuid;
begin
 select * into b from public.network_trust_bridges where id=p_bridge_id;
 if b.id is null then raise exception 'Network bridge not found.' using errcode='P0002'; end if;
 if b.status<>'accepted' then raise exception 'Only accepted bridges can be revoked.' using errcode='22023'; end if;
 if public.is_network_admin(b.requester_network_id) then actor_network:=b.requester_network_id;
 elsif public.is_network_admin(b.recipient_network_id) then actor_network:=b.recipient_network_id;
 else raise exception 'Administrator access to one of the bridged networks is required.' using errcode='42501'; end if;
 update public.network_trust_bridges set status='revoked',revoked_by=auth.uid(),revoked_at=now(),updated_at=now() where id=p_bridge_id;
 insert into public.audit_log(network_id,actor_id,action,details) values(actor_network,auth.uid(),'network_trust_bridge_revoked',jsonb_build_object('bridge_id',b.id));
end $function$
;

CREATE OR REPLACE FUNCTION public.route_network_mentions(p_mentions text[], p_title text, p_body text, p_surface text, p_entity_type text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid, p_priority text DEFAULT 'normal'::text)
 RETURNS uuid[]
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); token text; key text; target uuid; ids uuid[]:='{}'; nid_out uuid;
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Active network required.' using errcode='42501';end if;
 foreach token in array coalesce(p_mentions,'{}'::text[]) loop
  key:=trim(both '-' from regexp_replace(lower(trim(leading '@' from token)),'[^a-z0-9]+','-','g'));
  if key='' then continue;end if;
  for target in
    select distinct x.user_id from (
      select nm.user_id from public.network_memberships nm where nm.network_id=nid and nm.status='active' and ((key in ('owner','owners') and nm.role='owner') or (key in ('admin','admins','board') and nm.role in ('owner','admin')))
      union all
      select r.user_id from public.network_notification_roles r where r.network_id=nid and r.active and r.role_key=key
      union all
      select nm.user_id from public.network_memberships nm join auth.users u on u.id=nm.user_id left join public.profiles p on p.id=nm.user_id
       where nm.network_id=nid and nm.status='active' and (trim(both '-' from regexp_replace(lower(split_part(coalesce(u.email,''),'@',1)),'[^a-z0-9]+','-','g'))=key or trim(both '-' from regexp_replace(lower(coalesce(p.full_name,'')),'[^a-z0-9]+','-','g'))=key)
    ) x
  loop
    if target=auth.uid() then continue;end if;
    nid_out:=public.create_network_notification(nid,target,'mention',p_title,p_body,p_surface,p_entity_type,p_entity_id,p_priority,jsonb_build_object('mention',key,'surface',p_surface),auth.uid());ids:=array_append(ids,nid_out);
  end loop;
 end loop;
 return (select coalesce(array_agg(distinct i),'{}'::uuid[]) from unnest(ids) i);
end $function$
;

CREATE OR REPLACE FUNCTION public.s3a_intake_enabled(p_network_id uuid, p_allow_creator uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists(
    select 1 from public.platform_feature_flags f
    where f.feature_key='contribute.branch_intake' and (
      f.rollout_state='released'
      or (f.rollout_state='pilot' and p_network_id=any(f.pilot_network_ids))
      or (p_allow_creator is not null and exists(select 1 from public.platform_owners po where po.user_id=p_allow_creator))
    )
  );
$function$
;

CREATE OR REPLACE FUNCTION public.save_my_digest_preferences(p_digest text, p_special_days boolean, p_memories boolean, p_gatherings boolean, p_contributions boolean, p_introductions boolean, p_family_changes boolean, p_preferred_weekday smallint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
 if p_digest not in ('off','weekly','monthly') then raise exception 'Invalid digest preference.' using errcode='22023'; end if;
 if p_preferred_weekday<0 or p_preferred_weekday>6 then raise exception 'Invalid digest day.' using errcode='22023'; end if;
 insert into public.notification_preferences(network_id,user_id,digest,special_days,memories,gatherings,contributions,introductions,family_changes,preferred_weekday)
 values(nid,auth.uid(),p_digest,p_special_days,p_memories,p_gatherings,p_contributions,p_introductions,p_family_changes,p_preferred_weekday)
 on conflict(network_id,user_id) do update set
  digest=excluded.digest,special_days=excluded.special_days,memories=excluded.memories,gatherings=excluded.gatherings,
  contributions=excluded.contributions,introductions=excluded.introductions,family_changes=excluded.family_changes,
  preferred_weekday=excluded.preferred_weekday,updated_at=now();
end;$function$
;

CREATE OR REPLACE FUNCTION public.save_my_federated_scope_profile(p_network_id uuid, p_umbrella_id uuid, p_scope_key text, p_display_name text, p_headline text DEFAULT NULL::text, p_summary text DEFAULT NULL::text, p_location_label text DEFAULT NULL::text, p_tags text[] DEFAULT '{}'::text[], p_contact_mode text DEFAULT 'introduction_only'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare rid uuid; sk text:=lower(trim(p_scope_key));
begin
 if auth.uid() is null or not public.is_network_member(p_network_id) then raise exception 'Active source-network membership required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_display_name,'')))<2 then raise exception 'Display name is required.' using errcode='22023'; end if;
 if coalesce(array_length(p_tags,1),0)>12 then raise exception 'Use at most 12 tags.' using errcode='22023'; end if;
 if p_contact_mode not in ('introduction_only','direct_request') then raise exception 'Unsupported contact mode.' using errcode='22023'; end if;
 if not exists(select 1 from public.network_umbrella_affiliations a join public.federation_umbrellas u on u.id=a.umbrella_id and u.status='active' where a.network_id=p_network_id and a.umbrella_id=p_umbrella_id and a.status='approved') then raise exception 'Approved umbrella affiliation required.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_passports p where p.network_id=p_network_id and p.visibility in ('federation','public') and exists(select 1 from unnest(p.participation_scopes) x where lower(x)=sk)) then raise exception 'The Network Passport must currently declare this purpose for federation/public participation.' using errcode='42501'; end if;
 insert into public.federated_scope_profiles(owner_user_id,network_id,umbrella_id,scope_key,display_name,headline,summary,location_label,tags,contact_mode,active,updated_at)
 values(auth.uid(),p_network_id,p_umbrella_id,sk,trim(p_display_name),nullif(trim(coalesce(p_headline,'')),''),left(nullif(trim(coalesce(p_summary,'')),''),800),nullif(trim(coalesce(p_location_label,'')),''),coalesce(p_tags,'{}'),p_contact_mode,true,now())
 on conflict(owner_user_id,network_id,umbrella_id,scope_key) do update set display_name=excluded.display_name,headline=excluded.headline,summary=excluded.summary,location_label=excluded.location_label,tags=excluded.tags,contact_mode=excluded.contact_mode,active=true,updated_at=now()
 returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.save_network_passport(p_network_id uuid, p_public_slug text, p_tagline text DEFAULT ''::text, p_summary text DEFAULT ''::text, p_location_label text DEFAULT ''::text, p_established_label text DEFAULT ''::text, p_external_url text DEFAULT ''::text, p_capabilities text[] DEFAULT '{}'::text[], p_participation_scopes text[] DEFAULT '{}'::text[], p_visibility text DEFAULT 'private'::text, p_directory_discoverable boolean DEFAULT false)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_slug text:=lower(trim(coalesce(p_public_slug,'')));v_url text:=trim(coalesce(p_external_url,''));
begin
 if not public.is_network_admin(p_network_id) then raise exception 'Network owner/admin access required.' using errcode='42501'; end if;
 if v_slug !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' or length(v_slug)>80 then raise exception 'Passport slug must use lowercase letters, numbers and hyphens.'; end if;
 if length(trim(coalesce(p_tagline,'')))>120 or length(trim(coalesce(p_summary,'')))>800 or length(trim(coalesce(p_location_label,'')))>120 or length(trim(coalesce(p_established_label,'')))>80 then raise exception 'Passport field exceeds its allowed length.'; end if;
 if v_url<>'' and (length(v_url)>300 or v_url !~ '^https://') then raise exception 'External URL must use HTTPS.'; end if;
 if p_visibility not in ('private','federation','public') then raise exception 'Invalid Passport visibility.'; end if;
 if coalesce(array_length(p_capabilities,1),0)>12 or coalesce(array_length(p_participation_scopes,1),0)>12 then raise exception 'Use at most 12 capabilities or participation scopes.'; end if;
 if exists(select 1 from unnest(coalesce(p_capabilities,'{}')) x where length(trim(x))>80) or exists(select 1 from unnest(coalesce(p_participation_scopes,'{}')) x where length(trim(x))>80) then raise exception 'Capability and scope labels must be 80 characters or fewer.'; end if;
 insert into public.network_passports(network_id,public_slug,tagline,summary,location_label,established_label,external_url,capabilities,participation_scopes,visibility,directory_discoverable,verification_state,created_by,updated_by)
 values(p_network_id,v_slug,trim(coalesce(p_tagline,'')),trim(coalesce(p_summary,'')),trim(coalesce(p_location_label,'')),trim(coalesce(p_established_label,'')),v_url,array(select distinct trim(x) from unnest(coalesce(p_capabilities,'{}')) x where trim(x)<>'' limit 12),array(select distinct trim(x) from unnest(coalesce(p_participation_scopes,'{}')) x where trim(x)<>'' limit 12),p_visibility,case when p_visibility='private' then false else coalesce(p_directory_discoverable,false) end,'network_admin_reviewed',auth.uid(),auth.uid())
 on conflict(network_id) do update set public_slug=excluded.public_slug,tagline=excluded.tagline,summary=excluded.summary,location_label=excluded.location_label,established_label=excluded.established_label,external_url=excluded.external_url,capabilities=excluded.capabilities,participation_scopes=excluded.participation_scopes,visibility=excluded.visibility,directory_discoverable=excluded.directory_discoverable,verification_state='network_admin_reviewed',updated_by=auth.uid(),updated_at=now();
 return p_network_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.save_network_quick_start_state(p_network_id uuid, p_dismissed boolean, p_completed_step_ids text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if not exists(select 1 from public.network_memberships m where m.network_id=p_network_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Active network membership required.'; end if;
 insert into public.network_quick_start_state(network_id,user_id,dismissed,completed_step_ids,updated_at)
 values(p_network_id,auth.uid(),coalesce(p_dismissed,false),coalesce(p_completed_step_ids,'{}'),now())
 on conflict(network_id,user_id) do update set dismissed=excluded.dismissed,completed_step_ids=excluded.completed_step_ids,updated_at=now();
end $function$
;

CREATE OR REPLACE FUNCTION public.save_network_settings(p_name text, p_description text DEFAULT ''::text, p_entity_label text DEFAULT 'Member'::text, p_entity_label_plural text DEFAULT 'Members'::text, p_level_label text DEFAULT 'Generation'::text, p_level_label_plural text DEFAULT 'Generations'::text, p_parent_label text DEFAULT 'Parent'::text, p_child_label text DEFAULT 'Child'::text, p_peer_label text DEFAULT 'Spouse'::text, p_network_template text DEFAULT 'family'::text, p_self_edit_mode text DEFAULT 'review'::text, p_family_milestones_enabled boolean DEFAULT true, p_photo_upload_enabled boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if nid is null then raise exception 'No active family selected.' using errcode='42501'; end if;
  if not public.is_network_admin(nid) then raise exception 'Family administrator access required.' using errcode='42501'; end if;

  update public.network_settings
  set name=left(coalesce(nullif(trim(p_name),''),name),180),
      description=coalesce(p_description,''),
      entity_label=coalesce(nullif(trim(p_entity_label),''),'Member'),
      entity_label_plural=coalesce(nullif(trim(p_entity_label_plural),''),'Members'),
      level_label=coalesce(nullif(trim(p_level_label),''),'Generation'),
      level_label_plural=coalesce(nullif(trim(p_level_label_plural),''),'Generations'),
      parent_label=coalesce(nullif(trim(p_parent_label),''),'Parent'),
      child_label=coalesce(nullif(trim(p_child_label),''),'Child'),
      peer_label=coalesce(nullif(trim(p_peer_label),''),'Spouse'),
      network_template=coalesce(nullif(trim(p_network_template),''),'family'),
      self_edit_mode=coalesce(nullif(trim(p_self_edit_mode),''),'review'),
      family_milestones_enabled=coalesce(p_family_milestones_enabled,true),
      photo_upload_enabled=coalesce(p_photo_upload_enabled,false)
  where network_id=nid;

  if not found then
    raise exception 'Family settings were not initialized. Re-run migration 031 or recreate the family.' using errcode='P0002';
  end if;
end;$function$
;

CREATE OR REPLACE FUNCTION public.save_network_settings(p_network_id uuid, p_name text, p_description text DEFAULT ''::text, p_entity_label text DEFAULT 'Member'::text, p_entity_label_plural text DEFAULT 'Members'::text, p_level_label text DEFAULT 'Generation'::text, p_level_label_plural text DEFAULT 'Generations'::text, p_parent_label text DEFAULT 'Parent'::text, p_child_label text DEFAULT 'Child'::text, p_peer_label text DEFAULT 'Spouse'::text, p_network_template text DEFAULT 'family'::text, p_self_edit_mode text DEFAULT 'review'::text, p_family_milestones_enabled boolean DEFAULT true, p_photo_upload_enabled boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  nid uuid:=coalesce(p_network_id,public.current_network_id());
begin
  if nid is null then raise exception 'No family selected.' using errcode='42501'; end if;
  if not exists(
    select 1 from public.network_memberships nm
    where nm.network_id=nid and nm.user_id=auth.uid() and nm.status='active' and nm.role in ('owner','admin')
  ) and not public.is_platform_owner() then
    raise exception 'Family administrator access required.' using errcode='42501';
  end if;

  update public.network_settings
  set name=left(coalesce(nullif(trim(p_name),''),name),180),
      description=coalesce(p_description,''),
      entity_label=coalesce(nullif(trim(p_entity_label),''),'Member'),
      entity_label_plural=coalesce(nullif(trim(p_entity_label_plural),''),'Members'),
      level_label=coalesce(nullif(trim(p_level_label),''),'Generation'),
      level_label_plural=coalesce(nullif(trim(p_level_label_plural),''),'Generations'),
      parent_label=coalesce(nullif(trim(p_parent_label),''),'Parent'),
      child_label=coalesce(nullif(trim(p_child_label),''),'Child'),
      peer_label=coalesce(nullif(trim(p_peer_label),''),'Spouse'),
      network_template=coalesce(nullif(trim(p_network_template),''),'family'),
      self_edit_mode=coalesce(nullif(trim(p_self_edit_mode),''),'review'),
      family_milestones_enabled=coalesce(p_family_milestones_enabled,true),
      photo_upload_enabled=coalesce(p_photo_upload_enabled,false)
  where network_id=nid;

  if not found then
    insert into public.network_settings(
      id,network_id,name,description,entity_label,entity_label_plural,level_label,level_label_plural,
      parent_label,child_label,peer_label,network_template,self_edit_mode,family_milestones_enabled,photo_upload_enabled
    ) values(
      'network',nid,left(trim(coalesce(p_name,'Our Family')),180),coalesce(p_description,''),
      coalesce(nullif(trim(p_entity_label),''),'Member'),coalesce(nullif(trim(p_entity_label_plural),''),'Members'),
      coalesce(nullif(trim(p_level_label),''),'Generation'),coalesce(nullif(trim(p_level_label_plural),''),'Generations'),
      coalesce(nullif(trim(p_parent_label),''),'Parent'),coalesce(nullif(trim(p_child_label),''),'Child'),
      coalesce(nullif(trim(p_peer_label),''),'Spouse'),coalesce(nullif(trim(p_network_template),''),'family'),
      coalesce(nullif(trim(p_self_edit_mode),''),'review'),coalesce(p_family_milestones_enabled,true),coalesce(p_photo_upload_enabled,false)
    );
  end if;

  -- Keep the new family active for the creator even if the previous client session was stale.
  update public.profiles set active_network_id=nid,updated_at=now() where id=auth.uid();
end;$function$
;

CREATE OR REPLACE FUNCTION public.score_intake_person(p_name text, p_dob date, p_year integer, p_gender text, p_city text, p_other_name text, p_other_dob date, p_other_year integer, p_other_gender text, p_other_city text)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select least(100,
    case when public.normalize_intake_name(p_name)=public.normalize_intake_name(p_other_name) and public.normalize_intake_name(p_name)<>'' then 45 else 0 end
    + case when p_dob is not null and p_other_dob is not null and p_dob=p_other_dob then 35 else 0 end
    + case when coalesce(p_year,extract(year from p_dob)::int) is not null and coalesce(p_other_year,extract(year from p_other_dob)::int) is not null and coalesce(p_year,extract(year from p_dob)::int)=coalesce(p_other_year,extract(year from p_other_dob)::int) then 15 else 0 end
    + case when p_gender is not null and p_other_gender is not null and p_gender=p_other_gender then 3 else 0 end
    + case when nullif(lower(trim(p_city)),'') is not null and lower(trim(p_city))=lower(trim(p_other_city)) then 2 else 0 end
  );
$function$
;

CREATE OR REPLACE FUNCTION public.search_community_profiles(p_space_id uuid, p_category text DEFAULT NULL::text, p_query text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, space_id uuid, space_name character varying, network_id uuid, family_name character varying, member_id uuid, category character varying, display_name character varying, photo_url text, profession character varying, city character varying, headline character varying, summary text, contact_mode character varying, featured boolean, featured_label character varying, is_mine boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with recursive scope as (
    select id from public.community_spaces where id=p_space_id
    union all select s.id from public.community_spaces s join scope p on s.parent_id=p.id
  )
  select c.id,c.space_id,s.name,c.network_id,n.name,c.member_id,c.category,c.display_name,c.photo_url,c.profession,c.city,c.headline,c.summary,c.contact_mode,c.featured,c.featured_label,(c.owner_user_id=auth.uid())
  from public.community_profile_cards c join public.community_spaces s on s.id=c.space_id join public.networks n on n.id=c.network_id
  where c.active and c.space_id in(select id from scope)
    and public.community_space_is_allowed(p_space_id,public.current_network_id())
    and (p_category is null or p_category='' or c.category=p_category)
    and (p_query is null or p_query='' or concat_ws(' ',c.display_name,c.profession,c.city,c.headline,c.summary,n.name) ilike '%'||p_query||'%')
  order by c.featured desc,c.updated_at desc limit 200;
$function$
;

CREATE OR REPLACE FUNCTION public.search_family_members(p_query text DEFAULT NULL::text, p_profession text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_generation integer DEFAULT NULL::integer, p_life_status text DEFAULT 'all'::text, p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(id uuid, full_name text, date_of_birth date, date_of_death date, generation_level integer, profession text, city text, country text, photo_url text, bio text, phone text, email text, latitude double precision, longitude double precision, profile_status text, profile_visibility text, contact_visibility text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    m.id,m.full_name,m.date_of_birth,m.date_of_death,m.generation_level,
    m.profession,m.city,m.country,m.photo_url,m.bio,
    case when public.is_admin() or coalesce(m.contact_visibility,'admin') <> 'admin' then m.phone end,
    case when public.is_admin() or coalesce(m.contact_visibility,'admin') <> 'admin' then m.email end,
    m.latitude::double precision,m.longitude::double precision,m.profile_status,
    coalesce(m.profile_visibility,'member'),coalesce(m.contact_visibility,'admin')
  from public.family_members m
  where m.profile_status='approved'
    and (public.is_admin() or coalesce(m.profile_visibility,'member') <> 'admin')
    and (nullif(trim(p_query),'') is null or
         lower(coalesce(m.full_name,'')) like '%'||lower(trim(p_query))||'%' or
         lower(coalesce(m.profession,'')) like '%'||lower(trim(p_query))||'%' or
         lower(coalesce(m.city,'')) like '%'||lower(trim(p_query))||'%' or
         lower(coalesce(m.country,'')) like '%'||lower(trim(p_query))||'%')
    and (nullif(trim(p_profession),'') is null or lower(coalesce(m.profession,''))=lower(trim(p_profession)))
    and (nullif(trim(p_city),'') is null or lower(coalesce(m.city,''))=lower(trim(p_city)))
    and (p_generation is null or m.generation_level=p_generation)
    and (coalesce(p_life_status,'all')='all' or (p_life_status='living' and m.date_of_death is null) or (p_life_status='deceased' and m.date_of_death is not null))
  order by lower(m.full_name),m.id
  limit greatest(1,least(coalesce(p_limit,100),500))
  offset greatest(0,coalesce(p_offset,0));
$function$
;

CREATE OR REPLACE FUNCTION public.search_federated_network_directory(p_query text DEFAULT ''::text, p_purpose text DEFAULT 'all'::text, p_limit integer DEFAULT 40)
 RETURNS TABLE(network_id uuid, network_name character varying, vertical_kind character varying, passport_slug character varying, passport_visibility character varying, tagline character varying, summary character varying, location_label character varying, established_label character varying, external_url character varying, capabilities text[], participation_scopes text[], verification_state character varying, umbrella_id uuid, umbrella_name character varying, umbrella_slug character varying, relationship_type character varying, context_label character varying, source_network_id uuid, source_network_name character varying, matched_purpose character varying, trust_path_label text, passport_updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with requester_networks as (
  select distinct nm.network_id,n.name as network_name
  from public.network_memberships nm
  join public.networks n on n.id=nm.network_id
  where nm.user_id=auth.uid() and nm.status='active'
 ), requester_umbrellas as (
  select distinct rn.network_id as source_network_id,rn.network_name as source_network_name,f.umbrella_id
  from requester_networks rn
  join public.network_umbrella_affiliations f on f.network_id=rn.network_id and f.status='approved'
  join public.federation_umbrellas u on u.id=f.umbrella_id and u.status='active'
 ), candidates as (
  select distinct on (ru.source_network_id,f.network_id,f.umbrella_id)
   n.id network_id,n.name network_name,n.vertical_kind,p.public_slug passport_slug,p.visibility passport_visibility,
   p.tagline,p.summary,p.location_label,p.established_label,p.external_url,p.capabilities,p.participation_scopes,p.verification_state,
   u.id umbrella_id,u.name umbrella_name,u.slug umbrella_slug,f.relationship_type,f.context_label,
   ru.source_network_id,ru.source_network_name,p.updated_at passport_updated_at
  from requester_umbrellas ru
  join public.network_umbrella_affiliations f on f.umbrella_id=ru.umbrella_id and f.status='approved' and f.network_id<>ru.source_network_id
  join public.federation_umbrellas u on u.id=f.umbrella_id and u.status='active'
  join public.networks n on n.id=f.network_id
  join public.network_passports p on p.network_id=n.id
  where p.visibility in ('federation','public') and p.directory_discoverable=true
 ), filtered as (
  select c.*,
   case when coalesce(nullif(trim(p_purpose),''),'all')='all' then ''
        when lower(p_purpose)=any(select lower(x) from unnest(c.participation_scopes) x) then p_purpose
        when lower(p_purpose)=any(select lower(x) from unnest(c.capabilities) x) then p_purpose
        else '' end::varchar as matched_purpose
  from candidates c
  where (
   coalesce(trim(p_query),'')='' or
   lower(c.network_name||' '||coalesce(c.tagline,'')||' '||coalesce(c.summary,'')||' '||coalesce(c.location_label,'')||' '||array_to_string(c.capabilities,' ')||' '||array_to_string(c.participation_scopes,' ')) like '%'||lower(trim(p_query))||'%'
  )
  and (
   coalesce(nullif(trim(p_purpose),''),'all')='all' or
   lower(p_purpose)=any(select lower(x) from unnest(c.participation_scopes) x) or
   lower(p_purpose)=any(select lower(x) from unnest(c.capabilities) x)
  )
 )
 select f.network_id,f.network_name,f.vertical_kind,f.passport_slug,f.passport_visibility,f.tagline,f.summary,f.location_label,f.established_label,f.external_url,
  f.capabilities,f.participation_scopes,f.verification_state,f.umbrella_id,f.umbrella_name,f.umbrella_slug,f.relationship_type,f.context_label,
  f.source_network_id,f.source_network_name,f.matched_purpose,
  (f.source_network_name||' → '||f.umbrella_name||' → '||f.network_name)::text as trust_path_label,
  f.passport_updated_at
 from filtered f
 order by f.network_name,f.umbrella_name
 limit least(greatest(coalesce(p_limit,40),1),100);
$function$
;

CREATE OR REPLACE FUNCTION public.search_federated_scope_profiles(p_scope_key text, p_query text DEFAULT ''::text, p_limit integer DEFAULT 40)
 RETURNS TABLE(id uuid, scope_key character varying, display_name character varying, headline character varying, summary character varying, location_label character varying, tags text[], contact_mode character varying, network_id uuid, network_name character varying, umbrella_id uuid, umbrella_name character varying, source_network_id uuid, source_network_name character varying, trust_path_label text, is_mine boolean, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with requester_paths as (
  select distinct src.id source_network_id,src.name source_network_name,a.umbrella_id
  from public.network_memberships nm join public.networks src on src.id=nm.network_id and src.status='active'
  join public.network_umbrella_affiliations a on a.network_id=src.id and a.status='approved'
  join public.federation_umbrellas u on u.id=a.umbrella_id and u.status='active'
  where nm.user_id=auth.uid() and nm.status='active'
 ), eligible as (
  select distinct on (sp.id) sp.*,n.name network_name,u.name umbrella_name,rp.source_network_id,rp.source_network_name
  from requester_paths rp
  join public.federated_scope_profiles sp on sp.umbrella_id=rp.umbrella_id and sp.active and lower(sp.scope_key)=lower(trim(p_scope_key))
  join public.network_umbrella_affiliations ta on ta.network_id=sp.network_id and ta.umbrella_id=sp.umbrella_id and ta.status='approved'
  join public.federation_umbrellas u on u.id=sp.umbrella_id and u.status='active'
  join public.networks n on n.id=sp.network_id and n.status='active'
  join public.network_passports np on np.network_id=sp.network_id and np.visibility in ('federation','public')
  where exists(select 1 from unnest(np.participation_scopes) x where lower(x)=lower(sp.scope_key))
  order by sp.id,rp.source_network_name
 )
 select e.id,e.scope_key,e.display_name,e.headline,e.summary,e.location_label,e.tags,e.contact_mode,e.network_id,e.network_name,e.umbrella_id,e.umbrella_name,e.source_network_id,e.source_network_name,
  (e.source_network_name||' → '||e.umbrella_name||' → '||e.network_name)::text,(e.owner_user_id=auth.uid()),e.updated_at
 from eligible e
 where coalesce(trim(p_query),'')='' or lower(concat_ws(' ',e.display_name,e.headline,e.summary,e.location_label,array_to_string(e.tags,' '),e.network_name)) like '%'||lower(trim(p_query))||'%'
 order by (e.owner_user_id=auth.uid()) desc,e.updated_at desc
 limit least(greatest(coalesce(p_limit,40),1),100);
$function$
;

CREATE OR REPLACE FUNCTION public.set_active_network(p_network_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  if not public.is_network_member(p_network_id) then raise exception 'You are not an active member of this network.' using errcode='42501'; end if;
  if coalesce((select approval_status from public.networks where id=p_network_id),'pending')<>'approved' and not public.is_platform_owner() then
    raise exception 'This network is waiting for platform approval.' using errcode='42501';
  end if;

  insert into public.profiles(id,full_name,active_network_id,family_lobby_mode,updated_at)
  select u.id,coalesce(nullif(trim(u.raw_user_meta_data->>'full_name'),''),split_part(coalesce(u.email,''),'@',1),''),p_network_id,false,now()
  from auth.users u where u.id=auth.uid()
  on conflict(id) do update
    set active_network_id=excluded.active_network_id,family_lobby_mode=false,updated_at=now();

  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.active_network_id=p_network_id) then
    raise exception 'Network activation could not be persisted.' using errcode='P0001';
  end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_community_profile_featured(p_card_id uuid, p_featured boolean, p_label text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if not public.is_platform_owner() then raise exception 'Platform owner access required.' using errcode='42501'; end if;
 update public.community_profile_cards set featured=p_featured,featured_label=case when p_featured then nullif(trim(p_label),'') else null end,updated_at=now() where id=p_card_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_family_creation_policy(p_approval_required boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  perform public.set_network_creation_policy(p_approval_required);
end $function$
;

CREATE OR REPLACE FUNCTION public.set_family_feature_setting(p_feature_key character varying, p_enabled boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); bundle text;
begin
  if nid is null or not public.is_network_admin(nid) then
    raise exception 'Family admin access is required.' using errcode='42501';
  end if;
  select bundle_key into bundle from public.platform_feature_flags where feature_key=p_feature_key;
  if bundle is null then raise exception 'Unknown feature key: %',p_feature_key using errcode='P0002'; end if;
  if bundle='admin' then raise exception 'Admin capabilities are not member-view controls.' using errcode='22023'; end if;
  insert into public.network_feature_settings(network_id,feature_key,enabled,updated_by,updated_at)
  values(nid,p_feature_key,p_enabled,auth.uid(),now())
  on conflict(network_id,feature_key) do update
    set enabled=excluded.enabled,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_family_member_role(p_user_id uuid, p_role character varying)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); actor_role varchar; target_role varchar;
begin
 if p_role not in ('admin','member') then raise exception 'Role must be admin or member.' using errcode='22023'; end if;
 select role into actor_role from public.network_memberships where network_id=nid and user_id=auth.uid() and status='active';
 if actor_role is null or actor_role not in ('owner','admin') then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
 select role into target_role from public.network_memberships where network_id=nid and user_id=p_user_id and status='active';
 if target_role is null then raise exception 'This account is not an active member of this family.' using errcode='P0002'; end if;
 if target_role='owner' then raise exception 'The family owner role cannot be changed here.' using errcode='42501'; end if;
 if actor_role='admin' and target_role='admin' and p_user_id<>auth.uid() then raise exception 'Only the family owner can change another administrator.' using errcode='42501'; end if;
 if p_user_id=auth.uid() and p_role='member' and actor_role='admin' then raise exception 'Ask the family owner to remove your administrator role.' using errcode='42501'; end if;
 update public.network_memberships set role=p_role where network_id=nid and user_id=p_user_id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'family_role_changed',jsonb_build_object('user_id',p_user_id,'role',p_role));
end $function$
;

CREATE OR REPLACE FUNCTION public.set_fca_family_membership(p_year_id uuid, p_family_entity_id uuid, p_representative_entity_id uuid, p_status text, p_payment_status text, p_amount_paid numeric, p_payment_reference text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id(); fee numeric; rid uuid; begin
 if not public.is_network_admin(nid) then raise exception 'Association admin access required.' using errcode='42501'; end if;
 select family_fee into fee from public.family_association_membership_years where id=p_year_id and network_id=nid; if fee is null then raise exception 'Membership year not found.';end if;
 if not exists(select 1 from public.network_entities where id=p_family_entity_id and network_id=nid and kind='family') then raise exception 'Family not found.';end if;
 insert into public.family_association_family_memberships(network_id,membership_year_id,family_entity_id,representative_entity_id,status,payment_status,amount_due,amount_paid,payment_reference,joined_on,renewed_on)
 values(nid,p_year_id,p_family_entity_id,p_representative_entity_id,p_status,p_payment_status,fee,coalesce(p_amount_paid,0),nullif(trim(coalesce(p_payment_reference,'')),''),current_date,current_date)
 on conflict(network_id,membership_year_id,family_entity_id) do update set representative_entity_id=excluded.representative_entity_id,status=excluded.status,payment_status=excluded.payment_status,amount_due=excluded.amount_due,amount_paid=excluded.amount_paid,payment_reference=excluded.payment_reference,renewed_on=current_date,updated_at=now() returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_my_experience_level(p_level character varying)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if p_level not in ('simple','connected','explorer') then
    raise exception 'Invalid experience level.' using errcode='22023';
  end if;
  update public.profiles set experience_level=p_level,updated_at=now() where id=auth.uid();
end $function$
;

CREATE OR REPLACE FUNCTION public.set_my_federated_request_route_status(p_route_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if p_status not in ('suggested','shortlisted','dismissed') then raise exception 'Unsupported route status.' using errcode='22023'; end if;
 update public.federated_request_routes rr set status=p_status
 from public.federated_requests r where rr.id=p_route_id and r.id=rr.request_id and r.requester_user_id=auth.uid();
 if not found then raise exception 'Route not found or not owned by your request.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_my_federated_request_status(p_request_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if p_status not in ('open','closed','cancelled') then raise exception 'Unsupported request status.' using errcode='22023'; end if;
 update public.federated_requests set status=p_status,updated_at=now() where id=p_request_id and requester_user_id=auth.uid();
 if not found then raise exception 'Request not found or not owned by you.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_my_federated_scope_profile_active(p_profile_id uuid, p_active boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 update public.federated_scope_profiles set active=p_active,updated_at=now() where id=p_profile_id and owner_user_id=auth.uid();
 if not found then raise exception 'Scope profile not found or not owned by you.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_network_activity_pinned(p_activity_id uuid, p_pinned boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501'; end if;
  update public.network_activities
  set metadata=case when p_pinned
      then coalesce(metadata,'{}'::jsonb)||jsonb_build_object('pinned_at',now(),'pinned_by',auth.uid())
      else (coalesce(metadata,'{}'::jsonb)-'pinned_at'-'pinned_by') end,
      updated_at=now()
  where id=p_activity_id and network_id=nid and coalesce(metadata->>'content_kind','')='post';
  if not found then raise exception 'Post not found.' using errcode='P0002'; end if;
  insert into public.audit_log(network_id,actor_id,action,details)
  values(nid,auth.uid(),case when p_pinned then 'network_post_pinned' else 'network_post_unpinned' end,jsonb_build_object('activity_id',p_activity_id));
end $function$
;

CREATE OR REPLACE FUNCTION public.set_network_creation_policy(p_approval_required boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then raise exception 'Platform-owner access required.' using errcode='42501'; end if;
  insert into public.platform_onboarding_settings(id,family_creation_approval_required,network_creation_approval_required,updated_at,updated_by)
  values('default',coalesce(p_approval_required,false),coalesce(p_approval_required,false),now(),auth.uid())
  on conflict(id) do update
    set family_creation_approval_required=excluded.family_creation_approval_required,
        network_creation_approval_required=excluded.network_creation_approval_required,
        updated_at=now(),updated_by=auth.uid();
end $function$
;

CREATE OR REPLACE FUNCTION public.set_platform_bundle_rollout(p_bundle_key character varying, p_rollout_state character varying, p_pilot_network_ids uuid[] DEFAULT '{}'::uuid[], p_announce boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare changed integer;
begin
  if not public.is_platform_owner() then
    raise exception 'Platform owner access is required.' using errcode='42501';
  end if;
  if p_rollout_state not in ('hidden','test','pilot','released') then
    raise exception 'Invalid rollout state.' using errcode='22023';
  end if;
  update public.platform_feature_flags
  set rollout_state=p_rollout_state,
      pilot_network_ids=case when p_rollout_state='pilot' then coalesce(p_pilot_network_ids,'{}') else '{}' end,
      announcement_version=announcement_version + case when p_announce and p_rollout_state in ('pilot','released') then 1 else 0 end,
      updated_by=auth.uid(),updated_at=now()
  where bundle_key=p_bundle_key;
  get diagnostics changed = row_count;
  if changed=0 then raise exception 'Unknown feature bundle: %',p_bundle_key using errcode='P0002'; end if;
  return changed;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_platform_feature_rollout(p_feature_key character varying, p_rollout_state character varying, p_pilot_network_ids uuid[] DEFAULT '{}'::uuid[], p_announce boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then
    raise exception 'Platform owner access is required.' using errcode='42501';
  end if;
  if p_rollout_state not in ('hidden','test','pilot','released') then
    raise exception 'Invalid rollout state.' using errcode='22023';
  end if;
  update public.platform_feature_flags
  set rollout_state=p_rollout_state,
      pilot_network_ids=case when p_rollout_state='pilot' then coalesce(p_pilot_network_ids,'{}') else '{}' end,
      announcement_version=announcement_version + case when p_announce and p_rollout_state in ('pilot','released') then 1 else 0 end,
      updated_by=auth.uid(),
      updated_at=now()
  where feature_key=p_feature_key;
  if not found then raise exception 'Unknown feature key: %',p_feature_key using errcode='P0002'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_platform_showcase_vertical_setting(p_vertical_kind character varying, p_create_enabled boolean, p_playground_enabled boolean, p_featured boolean, p_palette_key character varying)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
  if p_vertical_kind not in ('family','alumni','association','family-association','housing-society','organization','business-trust','franchise','professional') then raise exception 'Unknown vertical.' using errcode='22023'; end if;
  if p_palette_key not in ('signature','warm','modern','classic','minimal') then raise exception 'Unknown palette.' using errcode='22023'; end if;
  insert into public.platform_showcase_verticals(vertical_kind,create_enabled,playground_enabled,featured,palette_key,updated_by,updated_at)
  values(p_vertical_kind,p_create_enabled,p_playground_enabled,p_featured,p_palette_key,auth.uid(),now())
  on conflict(vertical_kind) do update set create_enabled=excluded.create_enabled,playground_enabled=excluded.playground_enabled,featured=excluded.featured,palette_key=excluded.palette_key,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
end $function$
;

CREATE OR REPLACE FUNCTION public.set_platform_vertical_bundle_rollout(p_vertical_kind character varying, p_bundle_key character varying, p_rollout_state character varying, p_pilot_network_ids uuid[] DEFAULT '{}'::uuid[], p_announce boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare v_count integer;begin if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501';end if;if p_vertical_kind not in ('family','alumni','association','family-association','housing-society','organization','business-trust','franchise','professional') then raise exception 'Unknown vertical.' using errcode='22023';end if;if p_rollout_state not in ('hidden','test','pilot','released') then raise exception 'Invalid rollout state.';end if;update public.platform_feature_flags set rollout_state=p_rollout_state,pilot_network_ids=case when p_rollout_state='pilot' then coalesce(p_pilot_network_ids,'{}') else '{}'::uuid[] end,announcement_version=case when p_announce then announcement_version+1 else announcement_version end,updated_by=auth.uid(),updated_at=now() where vertical_kind=p_vertical_kind and bundle_key=p_bundle_key;get diagnostics v_count=row_count;return v_count;end $function$
;

CREATE OR REPLACE FUNCTION public.set_playground_feature_visibility(p_feature_key character varying, p_enabled boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_platform_owner() then raise exception 'Platform owner access is required.' using errcode='42501'; end if;
  if not exists(select 1 from public.platform_feature_flags where feature_key=p_feature_key) then
    raise exception 'Unknown feature key: %',p_feature_key using errcode='P0002';
  end if;
  insert into public.platform_playground_features(feature_key,enabled,updated_by,updated_at)
  values(p_feature_key,coalesce(p_enabled,false),auth.uid(),now())
  on conflict(feature_key) do update set enabled=excluded.enabled,updated_by=auth.uid(),updated_at=now();
end $function$
;

CREATE OR REPLACE FUNCTION public.set_productized_network_member_role(p_user_id uuid, p_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); actor_role text; target_role text;
begin
 if not public.g8_productized_vertical((select vertical_kind from public.networks where id=nid)) then raise exception 'Productized network required.' using errcode='42501'; end if;
 select role into actor_role from public.network_memberships where network_id=nid and user_id=auth.uid() and status='active';
 if actor_role is null or actor_role<>'owner' then raise exception 'Only the network owner can change admin roles.' using errcode='42501'; end if;
 if p_user_id=auth.uid() then raise exception 'The owner role cannot be changed here.' using errcode='42501'; end if;
 if p_role not in ('admin','member') then raise exception 'Invalid member role.' using errcode='22023'; end if;
 select role into target_role from public.network_memberships where network_id=nid and user_id=p_user_id and status='active';
 if target_role is null or target_role='owner' then raise exception 'Target member cannot be changed.' using errcode='22023'; end if;
 update public.network_memberships set role=p_role where network_id=nid and user_id=p_user_id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'productized_member_role_changed',jsonb_build_object('user_id',p_user_id,'role',p_role));
end $function$
;

CREATE OR REPLACE FUNCTION public.slugify_family_name(p_name text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  select trim(both '-' from regexp_replace(lower(coalesce(p_name,'')),'[^a-z0-9]+','-','g'));
$function$
;

CREATE OR REPLACE FUNCTION public.start_launch_demo_seed_run(p_dataset_version text, p_vertical_kind text, p_total_rows integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); rid uuid; actual_kind text;
begin
 if nid is null or (not public.is_network_admin(nid) and not public.is_platform_owner()) then raise exception 'Network admin or platform-owner access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.launch_demo_seed_authorizations a where a.network_id=nid and a.dataset_version=p_dataset_version) then raise exception 'Launch dataset is not authorized for this network.' using errcode='42501'; end if;
 select vertical_kind into actual_kind from public.networks where id=nid;
 if actual_kind is distinct from p_vertical_kind then raise exception 'Launch seed vertical does not match the active network.' using errcode='22023'; end if;
 insert into public.launch_demo_seed_runs(network_id,dataset_version,vertical_kind,total_rows,created_by)
 values(nid,p_dataset_version,p_vertical_kind,greatest(coalesce(p_total_rows,0),0),auth.uid()) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.storage_object_metadata_bytes(p_metadata jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare v text;
begin
 v:=coalesce(p_metadata->>'size',p_metadata->>'contentLength',p_metadata->>'content_length',p_metadata->>'content-length','');
 if v ~ '^\s*[0-9]+\s*$' then return trim(v)::bigint; end if;
 return 0;
end $function$
;

CREATE OR REPLACE FUNCTION public.storage_path_network_id(p_object_name text)
 RETURNS uuid
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
declare v text:=split_part(coalesce(p_object_name,''),'/',1);
begin
 if v='' then return null; end if;
 begin return v::uuid; exception when others then return null; end;
end $function$
;

CREATE OR REPLACE FUNCTION public.storage_path_owner_user_id(p_object_name text)
 RETURNS uuid
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
declare v text:=split_part(coalesce(p_object_name,''),'/',3);
begin
  if v='' then return null; end if;
  begin return v::uuid; exception when others then return null; end;
end $function$
;

CREATE OR REPLACE FUNCTION public.submit_family_intake(p_token text, p_people jsonb, p_relationships jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.family_intake_access%rowtype; s public.family_intake_sessions%rowtype; item jsonb; rid jsonb; person_count int; rel_count int; from_id uuid; to_id uuid;
begin
  select * into a from public.family_intake_access where token_hash=digest(coalesce(p_token,''),'sha256') for update;
  if a.id is null or a.status<>'active' or a.expires_at<=now() or a.submission_count>=a.max_submissions then raise exception 'This contribution link is no longer accepting submissions.' using errcode='42501'; end if;
  if not public.s3a_intake_enabled(a.network_id,a.created_by) then raise exception 'This family intake is not currently available.' using errcode='42501'; end if;
  select * into s from public.family_intake_sessions where id=a.session_id;
  if s.status not in ('collecting','review') then raise exception 'This family intake is not accepting submissions.' using errcode='42501'; end if;
  if jsonb_typeof(p_people)<>'array' or jsonb_typeof(p_relationships)<>'array' then raise exception 'Invalid intake payload.' using errcode='22023'; end if;
  person_count:=jsonb_array_length(p_people); rel_count:=jsonb_array_length(p_relationships);
  if person_count<1 or person_count>60 or rel_count>100 then raise exception 'This branch is too large for the guided intake.' using errcode='22023'; end if;
  for item in select * from jsonb_array_elements(p_people) loop
    if length(trim(coalesce(item->>'full_name','')))<2 or length(trim(item->>'full_name'))>150 then raise exception 'Every person needs a valid name.' using errcode='22023'; end if;
    insert into public.family_intake_people(session_id,access_id,network_id,client_ref,full_name,normalized_name,date_of_birth,birth_year,gender,city,role_from_anchor,generation_offset)
    values(a.session_id,a.id,a.network_id,left(item->>'client_ref',80),left(trim(item->>'full_name'),150),public.normalize_intake_name(item->>'full_name'),nullif(item->>'date_of_birth','')::date,nullif(item->>'birth_year','')::int,nullif(item->>'gender',''),left(nullif(trim(item->>'city'),''),100),left(nullif(item->>'role_from_anchor',''),60),coalesce((item->>'generation_offset')::int,0));
  end loop;
  for rid in select * from jsonb_array_elements(p_relationships) loop
    select id into from_id from public.family_intake_people where access_id=a.id and client_ref=rid->>'from_ref';
    select id into to_id from public.family_intake_people where access_id=a.id and client_ref=rid->>'to_ref';
    if from_id is null or to_id is null or rid->>'relationship_type' not in ('parent','child','spouse') then raise exception 'Invalid relationship in intake payload.' using errcode='22023'; end if;
    insert into public.family_intake_relationships(session_id,access_id,network_id,from_staged_person_id,to_staged_person_id,relationship_type,reported_relationship)
    values(a.session_id,a.id,a.network_id,from_id,to_id,rid->>'relationship_type',left(nullif(rid->>'reported_relationship',''),80));
  end loop;
  update public.family_intake_access set status='submitted',submission_count=submission_count+1,submitted_at=now() where id=a.id;
  update public.family_intake_sessions set status='review',updated_at=now() where id=a.session_id and status='collecting';
  perform public.refresh_family_intake_matches(a.session_id);
  insert into public.family_intake_events(network_id,session_id,access_id,event_name,properties)
  values(a.network_id,a.session_id,a.id,'intake_submitted',jsonb_build_object('people_reported',person_count,'relationships_reported',rel_count));
  return jsonb_build_object('people_reported',person_count,'relationships_reported',rel_count,'message','Thank you — your family branch has been sent for review.');
end $function$
;

CREATE OR REPLACE FUNCTION public.submit_network_ballot_nomination(p_ballot_id uuid, p_nominee_entity_id uuid, p_statement text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();rid uuid;lbl text;begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501';end if;
 if not exists(select 1 from public.network_ballots where id=p_ballot_id and network_id=nid and ballot_type='election' and allow_nominations and status='draft') then raise exception 'Nominations are not open for this election.';end if;
 select label into lbl from public.network_entities where id=p_nominee_entity_id and network_id=nid and kind='person';if lbl is null then raise exception 'Nominee is not a person in this network.';end if;
 insert into public.network_ballot_nominations(network_id,ballot_id,nominee_entity_id,nominee_label,statement,nominated_by) values(nid,p_ballot_id,p_nominee_entity_id,lbl,nullif(trim(coalesce(p_statement,'')),''),auth.uid()) on conflict(ballot_id,nominee_entity_id) do update set statement=excluded.statement,nominated_by=auth.uid(),status='pending',reviewed_by=null,reviewed_at=null returning id into rid;
 perform public.route_network_mentions(array['@president','@election-officer','@admin'],'Election nomination submitted',lbl||' was nominated.','elections','ballot_nomination',rid,'normal');return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.submit_organization_candidate_assertions(p_assertions jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();r jsonb;c int:=0;pred text;kind text;eids uuid[];
begin
 perform public.g91b_assert_organization_network(nid);if not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;
 for r in select * from jsonb_array_elements(coalesce(p_assertions,'[]'::jsonb)) loop
  pred:=r->>'predicate';kind:=r->>'kind';
  if kind not in ('expertise','ownership','dependency','decision') then continue;end if;
  if pred not in ('skill','owns','depends_on','architectural_decision') then continue;end if;
  eids:=coalesce(array(select value::uuid from jsonb_array_elements_text(coalesce(r->'evidenceIds','[]'::jsonb)) x(value) where exists(select 1 from public.network_evidence_records e where e.id=value::uuid and e.network_id=nid)),'{}');
  if cardinality(eids)=0 then continue;end if;
  insert into public.network_candidate_assertions(network_id,subject,predicate,object,evidence_ids,confidence,extraction_method,extractor_version,status,metadata)
  values(nid,coalesce(r->'subject','{}'),pred,coalesce(r->'object','{}'),eids,greatest(0,least(1,coalesce((r->>'confidence')::numeric,0))),coalesce(nullif(r->>'extractionMethod',''),'organization-targeted-extractor'),nullif(r->>'extractorVersion',''),'candidate',coalesce(r->'metadata','{}')||jsonb_build_object('kind',kind));c:=c+1;
 end loop;return c;
end $function$
;

CREATE OR REPLACE FUNCTION public.submit_organization_knowledge_evidence(p_source jsonb, p_records jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();sid uuid;r jsonb;inserted_count int:=0;existing_source uuid;
begin
 perform public.g91b_assert_organization_network(nid);if not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;
 select id into existing_source from public.network_knowledge_sources where network_id=nid and external_id=nullif(p_source->>'externalId','') order by created_at desc limit 1;
 if existing_source is null then
  insert into public.network_knowledge_sources(network_id,source_type,external_id,title,uri,connector_id,visibility,authorization_refs,content_hash,source_updated_at,last_observed_at,metadata)
  values(nid,coalesce(nullif(p_source->>'type',''),'other'),nullif(p_source->>'externalId',''),coalesce(nullif(p_source->>'title',''),'Knowledge source'),nullif(p_source->>'uri',''),nullif(p_source->>'connectorId',''),case when p_source->>'visibility'='restricted' then 'restricted' else 'network' end,coalesce(array(select jsonb_array_elements_text(coalesce(p_source->'authorizationRefs','[]'::jsonb))),'{}'),nullif(p_source->>'contentHash',''),nullif(p_source->>'sourceUpdatedAt','')::timestamptz,now(),coalesce(p_source->'metadata','{}')) returning id into sid;
 else sid:=existing_source;update public.network_knowledge_sources set last_observed_at=now(),content_hash=coalesce(nullif(p_source->>'contentHash',''),content_hash),source_updated_at=coalesce(nullif(p_source->>'sourceUpdatedAt','')::timestamptz,source_updated_at) where id=sid;end if;
 for r in select * from jsonb_array_elements(coalesce(p_records,'[]'::jsonb)) loop
  insert into public.network_evidence_records(network_id,source_id,document_external_id,chunk_id,title,uri,section,breadcrumb,content_hash,excerpt,source_updated_at,visibility,authorization_refs,extraction_version,metadata)
  values(nid,sid,nullif(r->>'documentExternalId',''),coalesce(nullif(r->>'chunkId',''),md5(coalesce(r->>'excerpt',''))),nullif(r->>'title',''),nullif(r->>'uri',''),nullif(r->>'section',''),coalesce(r->'breadcrumb','[]'),coalesce(nullif(r->>'contentHash',''),md5(coalesce(r->>'excerpt',''))),nullif(r->>'excerpt',''),nullif(r->>'sourceUpdatedAt','')::timestamptz,case when r->>'visibility'='restricted' then 'restricted' else 'network' end,coalesce(array(select jsonb_array_elements_text(coalesce(r->'authorizationRefs',p_source->'authorizationRefs','[]'::jsonb))),'{}'),nullif(r->>'extractionVersion',''),coalesce(r->'metadata','{}')) on conflict(network_id,source_id,chunk_id,content_hash) do nothing;
  if found then inserted_count:=inserted_count+1;end if;
 end loop;
 return jsonb_build_object('sourceId',sid,'insertedEvidence',inserted_count);
end $function$
;

CREATE OR REPLACE FUNCTION public.submit_pilot_feedback(p_network_id uuid, p_moment_type text, p_outcome text, p_friction_code text DEFAULT 'none'::text, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare rid uuid;clean_note text:=nullif(trim(coalesce(p_note,'')),'');
begin
 if auth.uid() is null or not public.is_network_member(p_network_id) then raise exception 'Active network membership is required.' using errcode='42501';end if;
 if p_moment_type not in('launch','participation','claim','bridge','discovery','introduction','outcome','general') then raise exception 'Unsupported feedback moment.' using errcode='22023';end if;
 if p_outcome not in('helpful','partial','blocked') then raise exception 'Choose whether the experience helped, partly helped, or blocked you.' using errcode='22023';end if;
 if p_friction_code not in('none','next_step','setup','data','permission','discovery','consent','technical','other') then raise exception 'Unsupported friction category.' using errcode='22023';end if;
 if p_outcome<>'helpful' and p_friction_code='none' then raise exception 'Choose the main friction when the experience did not fully help.' using errcode='22023';end if;
 if length(coalesce(clean_note,''))>600 then raise exception 'Keep feedback notes under 600 characters.' using errcode='22023';end if;
 if (select count(*) from public.pilot_feedback f where f.user_id=auth.uid() and f.created_at>=now()-interval '1 day')>=20 then raise exception 'Feedback limit reached for today.' using errcode='42901';end if;
 insert into public.pilot_feedback(user_id,network_id,moment_type,outcome,friction_code,note)
 values(auth.uid(),p_network_id,p_moment_type,p_outcome,case when p_outcome='helpful' then 'none' else p_friction_code end,clean_note)
 returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.submit_productized_network_contribution(p_entity_id uuid, p_message text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id();v_id uuid; begin if not public.is_network_member(nid) then raise exception 'Membership required.' using errcode='42501';end if;if length(trim(coalesce(p_message,'')))<3 then raise exception 'Please add a useful note.';end if;if p_entity_id is not null and not exists(select 1 from public.network_entities where id=p_entity_id and network_id=nid) then raise exception 'Entity not found.';end if;insert into public.network_contributions(network_id,entity_id,message,payload,created_by) values(nid,p_entity_id,trim(p_message),coalesce(p_payload,'{}'),auth.uid()) returning id into v_id;return v_id;end $function$
;

CREATE OR REPLACE FUNCTION public.submit_profile_change(p_submission_id uuid, p_member_id uuid DEFAULT NULL::uuid, p_full_name character varying DEFAULT ''::character varying, p_profession character varying DEFAULT NULL::character varying, p_city character varying DEFAULT NULL::character varying, p_country character varying DEFAULT NULL::character varying, p_bio text DEFAULT NULL::text, p_phone character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_photo_url text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare request_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode = '42501';
  end if;
  if nullif(trim(p_full_name),'') is null then
    raise exception 'Full name is required.' using errcode = '22023';
  end if;

  insert into public.profile_submissions(
    id,member_id,full_name,profession,city,country,bio,phone,email,photo_url,status,submitted_by
  ) values (
    p_submission_id,p_member_id,trim(p_full_name),p_profession,p_city,p_country,p_bio,p_phone,p_email,p_photo_url,'pending',auth.uid()
  );

  insert into public.change_requests(action,target_member_id,submitted_by,payload)
  values (
    case when p_member_id is null then 'create_member' else 'update_member' end,
    p_member_id,
    auth.uid(),
    jsonb_build_object('submission_id',p_submission_id,'full_name',p_full_name,'profession',p_profession,'city',p_city,'country',p_country,'bio',p_bio,'phone',p_phone,'email',p_email,'photo_url',p_photo_url)
  ) returning id into request_id;

  insert into public.audit_log(actor_id,action,details)
  values(auth.uid(),'profile_change_submitted',jsonb_build_object('submission_id',p_submission_id,'member_id',p_member_id));

  return request_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.submit_profile_change(p_submission_id uuid, p_member_id uuid DEFAULT NULL::uuid, p_full_name character varying DEFAULT ''::character varying, p_profession character varying DEFAULT NULL::character varying, p_city character varying DEFAULT NULL::character varying, p_country character varying DEFAULT NULL::character varying, p_bio text DEFAULT NULL::text, p_phone character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_photo_url text DEFAULT NULL::text, p_profile_visibility character varying DEFAULT 'member'::character varying, p_contact_visibility character varying DEFAULT 'admin'::character varying, p_avatar_style character varying DEFAULT 'initials'::character varying, p_facebook_url text DEFAULT NULL::text, p_facebook_public boolean DEFAULT false, p_instagram_url text DEFAULT NULL::text, p_instagram_public boolean DEFAULT false, p_other_social_url text DEFAULT NULL::text, p_other_social_label character varying DEFAULT NULL::character varying, p_other_social_public boolean DEFAULT false)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare request_id uuid;
begin
 if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
 if nullif(trim(p_full_name),'') is null then raise exception 'Full name is required.' using errcode='22023'; end if;
 if p_profile_visibility not in ('public','member','admin') or p_contact_visibility not in ('member','admin') then raise exception 'Invalid visibility setting.' using errcode='22023'; end if;
 if p_avatar_style not in ('initials','leaf','sun','sparkles','heart','person') then raise exception 'Invalid avatar choice.' using errcode='22023'; end if;
 if not public.a4_safe_external_url(p_facebook_url,'facebook') or not public.a4_safe_external_url(p_instagram_url,'instagram') or not public.a4_safe_external_url(p_other_social_url,'other') then raise exception 'Enter valid HTTPS social profile links.' using errcode='22023'; end if;
 if not public.is_network_admin() and p_member_id is not null and not exists(select 1 from public.profiles where id=auth.uid() and member_id=p_member_id) then raise exception 'You can only submit changes for your own profile.' using errcode='42501'; end if;
 insert into public.profile_submissions(id,member_id,full_name,profession,city,country,bio,phone,email,photo_url,status,submitted_by,profile_visibility,contact_visibility,avatar_style,facebook_url,facebook_public,instagram_url,instagram_public,other_social_url,other_social_label,other_social_public)
 values(p_submission_id,p_member_id,trim(p_full_name),p_profession,p_city,p_country,p_bio,p_phone,p_email,p_photo_url,'pending',auth.uid(),p_profile_visibility,p_contact_visibility,p_avatar_style,nullif(trim(p_facebook_url),''),(p_facebook_public and nullif(trim(p_facebook_url),'') is not null),nullif(trim(p_instagram_url),''),(p_instagram_public and nullif(trim(p_instagram_url),'') is not null),nullif(trim(p_other_social_url),''),left(coalesce(nullif(trim(p_other_social_label),''),'Website'),40),(p_other_social_public and nullif(trim(p_other_social_url),'') is not null));
 insert into public.change_requests(action,target_member_id,submitted_by,payload) values(case when p_member_id is null then 'create_member' else 'update_member' end,p_member_id,auth.uid(),jsonb_build_object('submission_id',p_submission_id,'full_name',p_full_name,'profile_visibility',p_profile_visibility,'contact_visibility',p_contact_visibility,'avatar_style',p_avatar_style)) returning id into request_id;
 return request_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.toggle_network_activity_like(p_activity_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id(); liked boolean; begin
 if not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501';end if;
 if not exists(select 1 from public.network_activities where id=p_activity_id and network_id=nid) then raise exception 'Activity not found.';end if;
 if exists(select 1 from public.network_activity_reactions where activity_id=p_activity_id and user_id=auth.uid()) then delete from public.network_activity_reactions where activity_id=p_activity_id and user_id=auth.uid();liked:=false;else insert into public.network_activity_reactions(activity_id,network_id,user_id) values(p_activity_id,nid,auth.uid());liked:=true;end if;return liked;
end $function$
;

CREATE OR REPLACE FUNCTION public.track_family_engagement(p_event_type text, p_entity_type text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid, p_channel text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if auth.uid() is null or nid is null then return; end if;
  if length(coalesce(p_event_type,''))<2 or length(p_event_type)>48 then raise exception 'Invalid event type.' using errcode='22023'; end if;
  insert into public.family_engagement_events(network_id,user_id,event_type,entity_type,entity_id,channel)
  values(nid,auth.uid(),p_event_type,nullif(left(coalesce(p_entity_type,''),32),''),p_entity_id,nullif(left(coalesce(p_channel,''),32),''));
end $function$
;

CREATE OR REPLACE FUNCTION public.unpublish_my_community_profile(p_card_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 update public.community_profile_cards set active=false,updated_at=now() where id=p_card_id and owner_user_id=auth.uid();
 if not found then raise exception 'Profile card not found or not owned by you.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.update_fca_settings(p_dependent_age_limit integer, p_grace_period_days integer, p_max_auto_children integer, p_onboarding_policy text, p_finance_visibility text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id(); begin
 if not public.is_network_admin(nid) then raise exception 'Association admin access required.' using errcode='42501'; end if;
 insert into public.family_association_settings(network_id,dependent_age_limit,grace_period_days,max_auto_children,onboarding_policy,finance_visibility) values(nid,p_dependent_age_limit,p_grace_period_days,p_max_auto_children,p_onboarding_policy,p_finance_visibility)
 on conflict(network_id) do update set dependent_age_limit=excluded.dependent_age_limit,grace_period_days=excluded.grace_period_days,max_auto_children=excluded.max_auto_children,onboarding_policy=excluded.onboarding_policy,finance_visibility=excluded.finance_visibility,updated_at=now();
end $function$
;

CREATE OR REPLACE FUNCTION public.update_own_profile_safe_fields(p_profession character varying DEFAULT NULL::character varying, p_city character varying DEFAULT NULL::character varying, p_country character varying DEFAULT NULL::character varying, p_bio text DEFAULT NULL::text, p_phone character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_photo_url text DEFAULT NULL::text, p_avatar_style character varying DEFAULT 'initials'::character varying, p_facebook_url text DEFAULT NULL::text, p_facebook_public boolean DEFAULT false, p_instagram_url text DEFAULT NULL::text, p_instagram_public boolean DEFAULT false, p_other_social_url text DEFAULT NULL::text, p_other_social_label character varying DEFAULT NULL::character varying, p_other_social_public boolean DEFAULT false)
 RETURNS family_members
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare target_member uuid; result public.family_members; mode varchar;
begin
  if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
  select p.member_id into target_member from public.profiles p where p.id=auth.uid();
  if target_member is null then raise exception 'Your account is not linked to a member profile.' using errcode='42501'; end if;
  select coalesce(ns.self_edit_mode,'review') into mode from public.network_settings ns where ns.network_id=public.current_network_id() limit 1;
  if coalesce(mode,'review') <> 'safe_fields_direct' then raise exception 'This family requires administrator review for profile changes.' using errcode='42501'; end if;
  if p_email is not null and p_email<>'' and position('@' in p_email)=0 then raise exception 'Enter a valid email address.' using errcode='22023'; end if;
  if p_avatar_style not in ('initials','leaf','sun','sparkles','heart','person') then raise exception 'Invalid avatar choice.' using errcode='22023'; end if;
  if not public.a4_safe_external_url(p_facebook_url,'facebook') or not public.a4_safe_external_url(p_instagram_url,'instagram') or not public.a4_safe_external_url(p_other_social_url,'other') then raise exception 'Enter valid HTTPS social profile links.' using errcode='22023'; end if;
  update public.family_members set profession=nullif(trim(p_profession),''),city=nullif(trim(p_city),''),country=coalesce(nullif(trim(p_country),''),'India'),bio=nullif(p_bio,''),phone=nullif(trim(p_phone),''),email=nullif(trim(p_email),''),photo_url=coalesce(nullif(p_photo_url,''),photo_url),avatar_style=p_avatar_style,facebook_url=nullif(trim(p_facebook_url),''),facebook_public=(p_facebook_public and nullif(trim(p_facebook_url),'') is not null),instagram_url=nullif(trim(p_instagram_url),''),instagram_public=(p_instagram_public and nullif(trim(p_instagram_url),'') is not null),other_social_url=nullif(trim(p_other_social_url),''),other_social_label=left(coalesce(nullif(trim(p_other_social_label),''),'Website'),40),other_social_public=(p_other_social_public and nullif(trim(p_other_social_url),'') is not null),updated_at=now()
  where id=target_member and network_id=public.current_network_id() returning * into result;
  if result.id is null then raise exception 'Linked member profile was not found in this family.' using errcode='P0002'; end if;
  insert into public.audit_log(actor_id,action,details) values(auth.uid(),'own_profile_identity_links_updated',jsonb_build_object('member_id',target_member));
  return result;
end $function$
;

CREATE OR REPLACE FUNCTION public.upsert_fca_membership_year(p_id uuid, p_label text, p_start_date date, p_end_date date, p_family_fee numeric, p_grace_period_days integer, p_status text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare nid uuid:=public.current_network_id(); rid uuid; begin
 if not public.is_network_admin(nid) then raise exception 'Association admin access required.' using errcode='42501'; end if;
 if p_id is null then insert into public.family_association_membership_years(network_id,label,start_date,end_date,family_fee,grace_period_days,status,created_by) values(nid,trim(p_label),p_start_date,p_end_date,p_family_fee,p_grace_period_days,p_status,auth.uid()) returning id into rid;
 else update public.family_association_membership_years set label=trim(p_label),start_date=p_start_date,end_date=p_end_date,family_fee=p_family_fee,grace_period_days=p_grace_period_days,status=p_status where id=p_id and network_id=nid returning id into rid; end if;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.upsert_my_push_subscription(p_endpoint text, p_p256dh text, p_auth text, p_user_agent text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; nid uuid:=public.current_network_id();
begin
 if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501';end if;
 if length(coalesce(p_endpoint,''))<20 or length(coalesce(p_p256dh,''))<20 or length(coalesce(p_auth,''))<8 then raise exception 'Invalid push subscription.' using errcode='22023';end if;
 insert into public.push_subscriptions(user_id,endpoint,p256dh,auth_key,user_agent,active,last_seen_at,updated_at)
 values(auth.uid(),p_endpoint,p_p256dh,p_auth,left(p_user_agent,500),true,now(),now())
 on conflict(user_id,endpoint) do update set p256dh=excluded.p256dh,auth_key=excluded.auth_key,user_agent=excluded.user_agent,active=true,last_seen_at=now(),updated_at=now()
 returning id into v_id;
 if nid is not null then
   insert into public.notification_preferences(network_id,user_id,push_enabled)
   values(nid,auth.uid(),true)
   on conflict(network_id,user_id) do update set push_enabled=true,updated_at=now();
 end if;
 return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.upsert_network_ballot(p_id uuid, p_ballot_type text, p_title text, p_description text, p_eligibility_mode text, p_max_choices integer, p_secret_ballot boolean, p_allow_nominations boolean, p_opens_at timestamp with time zone, p_closes_at timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); rid uuid;
begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;
 if p_ballot_type not in ('poll','election') or p_eligibility_mode not in ('members','admins','family_representatives') then raise exception 'Invalid ballot configuration.' using errcode='22023';end if;
 if length(trim(coalesce(p_title,'')))<3 then raise exception 'Ballot title is required.';end if;
 if p_id is null then insert into public.network_ballots(network_id,ballot_type,title,description,eligibility_mode,max_choices,secret_ballot,allow_nominations,opens_at,closes_at,created_by)
 values(nid,p_ballot_type,left(trim(p_title),180),nullif(trim(coalesce(p_description,'')),''),p_eligibility_mode,greatest(1,least(coalesce(p_max_choices,1),10)),coalesce(p_secret_ballot,true),coalesce(p_allow_nominations,false),p_opens_at,p_closes_at,auth.uid()) returning id into rid;
 else update public.network_ballots set ballot_type=p_ballot_type,title=left(trim(p_title),180),description=nullif(trim(coalesce(p_description,'')),''),eligibility_mode=p_eligibility_mode,max_choices=greatest(1,least(coalesce(p_max_choices,1),10)),secret_ballot=coalesce(p_secret_ballot,true),allow_nominations=coalesce(p_allow_nominations,false),opens_at=p_opens_at,closes_at=p_closes_at,updated_at=now() where id=p_id and network_id=nid and status='draft' returning id into rid;end if;
 if rid is null then raise exception 'Only draft ballots can be edited.';end if;return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.upsert_productized_network_entity(p_entity_id uuid, p_kind text, p_label text, p_metadata jsonb DEFAULT '{}'::jsonb, p_affiliations jsonb DEFAULT '{}'::jsonb, p_visibility text DEFAULT 'members'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id();v_kind text;v_id uuid;pair record;v_family uuid;v_allowed boolean:=false;
begin
 select vertical_kind into v_kind from public.networks where id=v_network;
 if not public.g8_productized_vertical(v_kind) then raise exception 'Active network does not use the productized entity runtime.';end if;
 if p_entity_id is null then
  if not public.is_network_admin(v_network) then raise exception 'Network admin access required.' using errcode='42501';end if;
 else
  v_allowed:=public.is_network_admin(v_network) or exists(select 1 from public.network_entities own where own.id=p_entity_id and own.network_id=v_network and own.owner_user_id=auth.uid());
  if not v_allowed and v_kind in ('association','family-association') then
   select case when e.kind in ('household','family') then e.id else (select r.to_entity_id from public.network_entity_relationships r where r.network_id=v_network and r.from_entity_id=e.id and r.relationship_type in ('member_of_household','member_of_family') limit 1) end into v_family from public.network_entities e where e.id=p_entity_id and e.network_id=v_network;
   v_allowed:=v_family is not null and public.can_manage_association_household(v_family,auth.uid());
  end if;
  if not v_allowed then raise exception 'You can edit only your claimed profile or a family you are allowed to maintain.' using errcode='42501';end if;
 end if;
 if not public.g8_allowed_entity_kind(v_kind,p_kind) then raise exception 'Entity kind is not allowed for this network.' using errcode='22023';end if;
 if length(trim(coalesce(p_label,'')))<2 then raise exception 'Entity name is required.';end if;
 if p_visibility not in ('members','private') then raise exception 'Invalid visibility.';end if;
 if p_entity_id is null then insert into public.network_entities(network_id,kind,label,metadata,visibility,owner_user_id) values(v_network,p_kind,trim(p_label),coalesce(p_metadata,'{}'),p_visibility,null) returning id into v_id;
 else update public.network_entities set kind=p_kind,label=trim(p_label),metadata=coalesce(p_metadata,'{}'),visibility=p_visibility,updated_at=now() where id=p_entity_id and network_id=v_network returning id into v_id;if v_id is null then raise exception 'Entity not found.';end if;end if;
 for pair in select key,value from jsonb_each(coalesce(p_affiliations,'{}'::jsonb)) loop perform public.g8_set_entity_affiliations(v_id,v_network,pair.key,pair.value);end loop;
 return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.validate_family_relationship()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  parent_id uuid;
  child_id uuid;
  parent_generation integer;
  child_generation integer;
begin
  if new.person_id = new.related_person_id then
    raise exception 'A member cannot be related to themselves.' using errcode = '23514';
  end if;

  -- Spouse relationships are symmetric. Generation equality is intentionally
  -- not enforced because the existing P3 data contains legitimate mixed-level
  -- spouse examples; the UI validator reports these as warnings.
  if new.relationship_type = 'spouse' then
    return new;
  end if;

  if new.relationship_type = 'parent' then
    parent_id := new.person_id;
    child_id := new.related_person_id;
  else
    parent_id := new.related_person_id;
    child_id := new.person_id;
  end if;

  select generation_level into parent_generation
  from public.family_members where id = parent_id;
  select generation_level into child_generation
  from public.family_members where id = child_id;

  if parent_generation is null or child_generation is null then
    raise exception 'Both members must exist before creating a relationship.' using errcode = '23503';
  end if;

  if parent_generation >= child_generation then
    raise exception 'Parent generation must be earlier than child generation.' using errcode = '23514';
  end if;

  -- Follow existing parent/child edges downward. If the proposed parent is
  -- already reachable from the proposed child, the new edge would create a cycle.
  if exists (
    with recursive descendants(id) as (
      select child_id
      union
      select case
               when r.relationship_type = 'parent' then r.related_person_id
               else r.person_id
             end
      from public.family_relationships r
      join descendants d on (
        case
          when r.relationship_type = 'parent' then r.person_id
          else r.related_person_id
        end
      ) = d.id
      where r.relationship_type in ('parent','child')
    )
    select 1 from descendants where id = parent_id
  ) then
    raise exception 'The relationship would create a parent/child cycle.' using errcode = '23514';
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.xp0_network_residue_report(p_network_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'storage'
AS $function$
declare r record; c bigint; relational_total bigint:=0; storage_total bigint:=0; details jsonb:='[]'::jsonb;
begin
 for r in
  select ns.nspname schema_name,cl.relname table_name,a.attname column_name
  from pg_constraint con
  join pg_class cl on cl.oid=con.conrelid
  join pg_namespace ns on ns.oid=cl.relnamespace
  join pg_class refcl on refcl.oid=con.confrelid
  join pg_namespace refns on refns.oid=refcl.relnamespace
  join unnest(con.conkey) with ordinality ck(attnum,ord) on true
  join unnest(con.confkey) with ordinality fk(attnum,ord) on fk.ord=ck.ord
  join pg_attribute a on a.attrelid=cl.oid and a.attnum=ck.attnum
  join pg_attribute ra on ra.attrelid=refcl.oid and ra.attnum=fk.attnum
  where con.contype='f' and ns.nspname='public' and refns.nspname='public'
    and refcl.relname='networks' and ra.attname='id'
    and array_length(con.conkey,1)=1
 loop
  execute format('select count(*) from %I.%I where %I=$1',r.schema_name,r.table_name,r.column_name) into c using p_network_id;
  if c>0 then
   relational_total:=relational_total+c;
   details:=details||jsonb_build_array(jsonb_build_object('table',r.table_name,'column',r.column_name,'count',c));
  end if;
 end loop;
 if to_regclass('storage.objects') is not null then
  select count(*) into storage_total from storage.objects where split_part(name,'/',1)=p_network_id::text;
 end if;
 return jsonb_build_object('networkId',p_network_id,'relationalResidue',relational_total,'storageResidue',storage_total,'details',details,'clean',relational_total=0 and storage_total=0);
end $function$
;

CREATE OR REPLACE FUNCTION public.xp6_log_contribution_review()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$begin
 if old.status is distinct from new.status then insert into public.network_contribution_audit(network_id,contribution_id,from_status,to_status,actor_user_id) values(new.network_id,new.id,old.status,new.status,auth.uid());end if;return new;end $function$
;

SET check_function_bodies = on;
