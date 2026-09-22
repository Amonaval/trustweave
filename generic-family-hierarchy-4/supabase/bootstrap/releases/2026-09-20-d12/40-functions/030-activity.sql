-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.accept_network_participation_invitation(p_token uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare v public.network_participation_invitations%rowtype; uid uuid:=auth.uid();begin
 if uid is null then raise exception 'Sign in required.' using errcode='42501';end if;
 select * into v from public.network_participation_invitations where token=p_token for update;if not found then raise exception 'Invitation not found.' using errcode='P0002';end if;
 if v.status<>'pending' then raise exception 'Invitation is no longer active.' using errcode='22023';end if;if v.expires_at<=now() then update public.network_participation_invitations set status='expired',updated_at=now() where id=v.id;raise exception 'Invitation expired.' using errcode='22023';end if;
 insert into public.network_memberships(network_id,user_id,role,status,joined_at) values(v.network_id,uid,v.invited_role,'active',now()) on conflict(network_id,user_id) do update set status='active',role=case when network_memberships.role='owner' then 'owner' else excluded.role end;
 if v.target_ref is not null and v.target_kind='network_entity' then
  if exists(select 1 from public.network_entities where network_id=v.network_id and owner_user_id=uid and id<>v.target_ref) then raise exception 'This account already claims another identity in this network.' using errcode='23505';end if;
  update public.network_entities set owner_user_id=uid where id=v.target_ref and network_id=v.network_id and owner_user_id is null;
 end if;
 update public.profiles set active_network_id=v.network_id,updated_at=now() where id=uid;
 update public.network_participation_invitations set status='accepted',accepted_by=uid,accepted_at=now(),updated_at=now() where id=v.id;
 return v.network_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.bind_network_media_asset(p_asset_id uuid, p_entity_type text, p_entity_id text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501'; end if;
  update public.network_media_assets
  set entity_type=nullif(trim(p_entity_type),''),entity_id=nullif(trim(p_entity_id),''),updated_at=now()
  where id=p_asset_id and network_id=nid and (owner_user_id=auth.uid() or public.is_network_admin(nid));
  if not found then raise exception 'Media asset not found or not editable.' using errcode='42501'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.cancel_network_media_asset_delete(p_asset_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();a public.network_media_assets%rowtype;
begin
 select * into a from public.network_media_assets where id=p_asset_id and network_id=nid for update;
 if not found or a.lifecycle_state<>'delete_pending' or not (a.delete_requested_by=auth.uid() or public.is_network_admin(nid)) then raise exception 'No authorized deletion is pending.' using errcode='42501';end if;
 update public.network_media_assets set lifecycle_state='archived',delete_requested_at=null,delete_requested_by=null,updated_at=now() where id=a.id;
end $function$
;

CREATE OR REPLACE FUNCTION public.community_space_is_allowed(p_space_id uuid, p_network_id uuid DEFAULT current_network_id())
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with recursive ancestors as (
    select s.id,s.parent_id from public.community_spaces s where s.id=p_space_id
    union all select p.id,p.parent_id from public.community_spaces p join ancestors a on a.parent_id=p.id
  )
  select exists(
    select 1 from public.community_family_links l
    where l.network_id=p_network_id and l.status='approved' and l.space_id in (select id from ancestors)
  ) or exists(
    with recursive linked_ancestors as (
      select s.id,s.parent_id from public.community_spaces s
      join public.community_family_links l on l.space_id=s.id
      where l.network_id=p_network_id and l.status='approved'
      union all select p.id,p.parent_id from public.community_spaces p join linked_ancestors a on a.parent_id=p.id
    ) select 1 from linked_ancestors where id=p_space_id
  );
$function$
;

CREATE OR REPLACE FUNCTION public.create_network_participation_invitation(p_network_id uuid, p_email text, p_target_ref uuid DEFAULT NULL::uuid, p_target_kind text DEFAULT NULL::text, p_invited_role text DEFAULT 'member'::text, p_expires_days integer DEFAULT 14)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare actor text; v public.network_participation_invitations%rowtype;
begin
 select role into actor from public.network_memberships where network_id=p_network_id and user_id=auth.uid() and status='active';
 if actor is null or actor not in ('owner','admin') then raise exception 'Network admin access required.' using errcode='42501';end if;
 if position('@' in trim(coalesce(p_email,'')))<2 then raise exception 'Valid email required.' using errcode='22023';end if;
 if p_invited_role='admin' and actor<>'owner' then raise exception 'Only owner can invite an admin.' using errcode='42501';end if;
 update public.network_participation_invitations set status='expired',updated_at=now() where network_id=p_network_id and status='pending' and expires_at<=now();
 select * into v from public.network_participation_invitations where network_id=p_network_id and lower(email)=lower(trim(p_email)) and status='pending' order by created_at desc limit 1;
 if found then return jsonb_build_object('id',v.id,'token',v.token,'email',v.email,'expiresAt',v.expires_at,'status',v.status);end if;
 insert into public.network_participation_invitations(network_id,email,target_ref,target_kind,invited_role,expires_at,created_by)
 values(p_network_id,lower(trim(p_email)),p_target_ref,nullif(trim(coalesce(p_target_kind,'')),''),case when p_invited_role='admin' then 'admin' else 'member' end,now()+make_interval(days=>greatest(1,least(30,coalesce(p_expires_days,14)))),auth.uid()) returning * into v;
 return jsonb_build_object('id',v.id,'token',v.token,'email',v.email,'expiresAt',v.expires_at,'status',v.status);
end $function$
;

CREATE OR REPLACE FUNCTION public.finalize_network_media_asset_delete(p_asset_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();a public.network_media_assets%rowtype;
begin
 select * into a from public.network_media_assets where id=p_asset_id and network_id=nid for update;
 if not found or a.lifecycle_state<>'delete_pending' or not (a.delete_requested_by=auth.uid() or public.is_network_admin(nid)) then raise exception 'No authorized deletion is pending.' using errcode='42501';end if;
 update public.network_media_assets set lifecycle_state='deleted',deleted_at=now(),deleted_by=auth.uid(),updated_at=now() where id=a.id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_media_deleted',jsonb_build_object('asset_id',a.id,'bucket',a.bucket,'media_kind',a.media_kind,'bytes',a.bytes,'thumbnail_bytes',a.thumbnail_bytes));
end $function$
;

CREATE OR REPLACE FUNCTION public.forget_network_media_asset_by_path(p_bucket text, p_object_path text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();a public.network_media_assets%rowtype;
begin
 select * into a from public.network_media_assets where network_id=nid and bucket=p_bucket and object_path=p_object_path;
 if not found then return;end if;
 if not (a.owner_user_id=auth.uid() or public.is_network_admin(nid)) then raise exception 'Media asset not editable.' using errcode='42501';end if;
 update public.network_media_assets set lifecycle_state='deleted',deleted_at=coalesce(deleted_at,now()),deleted_by=coalesce(deleted_by,auth.uid()),delete_reason=coalesce(delete_reason,'Removed from content'),updated_at=now() where id=a.id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_media_deleted',jsonb_build_object('asset_id',a.id,'bucket',a.bucket,'media_kind',a.media_kind,'source','legacy_remove_helper'));
end $function$
;

CREATE OR REPLACE FUNCTION public.get_network_media_assets(p_entity_type text, p_entity_ids text[] DEFAULT NULL::text[])
 RETURNS TABLE(id uuid, bucket character varying, object_path text, thumbnail_path text, media_kind character varying, entity_type character varying, entity_id text, mime_type character varying, bytes bigint, thumbnail_bytes bigint, width integer, height integer, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select m.id,m.bucket,m.object_path,m.thumbnail_path,m.media_kind,m.entity_type,m.entity_id,m.mime_type,m.bytes,m.thumbnail_bytes,m.width,m.height,m.created_at
 from public.network_media_assets m
 where m.network_id=public.current_network_id() and public.is_network_member(m.network_id) and m.lifecycle_state='active'
   and (nullif(trim(coalesce(p_entity_type,'')),'') is null or m.entity_type=p_entity_type)
   and (p_entity_ids is null or cardinality(p_entity_ids)=0 or m.entity_id=any(p_entity_ids))
 order by m.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_participation_metrics()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare result jsonb;
begin
  if not public.is_admin() then raise exception 'Administrator access is required.' using errcode='42501'; end if;
  select jsonb_build_object(
    'invitations_created',(select count(*) from public.member_invitations),
    'invitations_opened',(select count(*) from public.member_invitations where first_opened_at is not null),
    'invitations_accepted',(select count(*) from public.member_invitations where used_at is not null),
    'claimed_profiles',(select count(*) from public.profiles where member_id is not null),
    'claimable_profiles',(select count(*) from public.family_members where profile_status='approved'),
    'contributions',(select count(*) from public.audit_log where action in ('own_profile_safe_fields_updated','profile_submission_approved','contribution_suggestion_resolved')),
    'activated_members',(select count(distinct actor_id) from public.audit_log where actor_id is not null and action in ('member_invitation_accepted','own_profile_safe_fields_updated','memory_created','community_event_response')),
    'public_views',(select count(*) from public.participation_events where event_type in ('public_view','profile_view','qr_view','embed_view')),
    'shares',(select count(*) from public.participation_events where event_type='share'),
    'returning_members',(select count(*) from (select actor_id from public.audit_log where actor_id is not null group by actor_id having count(distinct created_at::date)>1) x),
    'open_suggestions',(select count(*) from public.contribution_suggestions where status='open'),
    'resolved_suggestions',(select count(*) from public.contribution_suggestions where status='resolved'),
    'event_responses',(select count(*) from public.community_event_responses),
    'admin_actions',(select count(*) from public.audit_log a join public.profiles p on p.id=a.actor_id where p.role='admin')
  ) into result;
  return result;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.list_network_participation_invitations(p_network_id uuid)
 RETURNS TABLE(id uuid, email text, target_ref uuid, target_kind character varying, invited_role character varying, status character varying, expires_at timestamp with time zone, created_at timestamp with time zone, resend_count integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if not exists(
  select 1
  from public.network_memberships nm
  where nm.network_id=p_network_id
    and nm.user_id=auth.uid()
    and nm.status='active'
    and nm.role in ('owner','admin')
 ) then
  raise exception 'Network admin access required.' using errcode='42501';
 end if;
 return query
 select i.id,i.email,i.target_ref,i.target_kind,i.invited_role,
        case when i.status='pending' and i.expires_at<=now() then 'expired'::varchar else i.status end,
        i.expires_at,i.created_at,i.resend_count
 from public.network_participation_invitations i
 where i.network_id=p_network_id
 order by i.created_at desc;
end $function$
;

CREATE OR REPLACE FUNCTION public.reconcile_network_media_usage(p_network_id uuid DEFAULT current_network_id())
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'storage'
AS $function$
declare total bigint;
begin
  if p_network_id is null or not public.is_network_admin(p_network_id) then
    raise exception 'Family administrator access is required.' using errcode='42501';
  end if;
  select coalesce(sum(coalesce(nullif(o.metadata->>'size','')::bigint,0)),0)
    into total
    from storage.objects o
   where o.bucket_id in ('profile-photos','community-media')
     and split_part(o.name,'/',1)=p_network_id::text;
  update public.networks set media_usage_bytes=total,updated_at=now() where id=p_network_id;
  return total;
end $function$
;

CREATE OR REPLACE FUNCTION public.register_network_media_asset(p_bucket text, p_object_path text, p_thumbnail_path text DEFAULT NULL::text, p_media_kind text DEFAULT 'other'::text, p_entity_type text DEFAULT NULL::text, p_entity_id text DEFAULT NULL::text, p_mime_type text DEFAULT 'image/webp'::text, p_bytes bigint DEFAULT 0, p_thumbnail_bytes bigint DEFAULT 0, p_width integer DEFAULT NULL::integer, p_height integer DEFAULT NULL::integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'storage'
AS $function$
declare nid uuid:=public.storage_path_network_id(p_object_path);uid uuid:=auth.uid();rid uuid;expected_scope text;max_file integer;lim bigint;object_bytes bigint;thumb_bytes bigint;
begin
 if uid is null or nid is null or not public.has_active_network_membership(nid,uid) then raise exception 'Network membership required for the media path.' using errcode='42501'; end if;
 if public.storage_path_owner_user_id(p_object_path)<>uid then raise exception 'Media path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 if p_bucket not in ('profile-photos','community-media') then raise exception 'Unsupported media bucket.' using errcode='22023'; end if;
 if p_media_kind not in ('profile','memory','event','announcement','complaint','post','other') then raise exception 'Unsupported media kind.' using errcode='22023'; end if;
 expected_scope:=case when p_bucket='profile-photos' then 'profiles' else 'community' end;
 if coalesce(p_object_path,'') not like nid::text||'/'||expected_scope||'/'||uid::text||'/%' then raise exception 'Media path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 if nullif(p_thumbnail_path,'') is not null and (public.storage_path_owner_user_id(p_thumbnail_path)<>uid or p_thumbnail_path not like nid::text||'/'||expected_scope||'/'||uid::text||'/%') then raise exception 'Thumbnail path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 select photo_max_bytes,storage_limit_bytes into max_file,lim from public.networks where id=nid;
 select public.storage_object_metadata_bytes(o.metadata) into object_bytes from storage.objects o where o.bucket_id=p_bucket and o.name=p_object_path;
 if not found then raise exception 'Uploaded media object was not found.' using errcode='P0002'; end if;
 if nullif(p_thumbnail_path,'') is not null then select public.storage_object_metadata_bytes(o.metadata) into thumb_bytes from storage.objects o where o.bucket_id=p_bucket and o.name=p_thumbnail_path; end if;
 object_bytes:=greatest(coalesce(nullif(object_bytes,0),p_bytes,0),0);thumb_bytes:=greatest(coalesce(nullif(thumb_bytes,0),p_thumbnail_bytes,0),0);
 if object_bytes<=0 then raise exception 'Uploaded image size could not be verified after upload.' using errcode='22023'; end if;
 if object_bytes>max_file or thumb_bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
 if coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid and not (m.bucket=p_bucket and m.object_path=p_object_path)),0)+object_bytes+thumb_bytes>lim then raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023'; end if;
 insert into public.network_media_assets(network_id,owner_user_id,bucket,object_path,thumbnail_path,media_kind,entity_type,entity_id,mime_type,bytes,thumbnail_bytes,width,height)
 values(nid,uid,p_bucket,p_object_path,nullif(p_thumbnail_path,''),p_media_kind,nullif(trim(p_entity_type),''),nullif(trim(p_entity_id),''),coalesce(nullif(p_mime_type,''),'image/webp'),object_bytes,thumb_bytes,p_width,p_height)
 on conflict(bucket,object_path) do update set thumbnail_path=excluded.thumbnail_path,media_kind=excluded.media_kind,entity_type=coalesce(excluded.entity_type,network_media_assets.entity_type),entity_id=coalesce(excluded.entity_id,network_media_assets.entity_id),mime_type=excluded.mime_type,bytes=excluded.bytes,thumbnail_bytes=excluded.thumbnail_bytes,width=excluded.width,height=excluded.height,updated_at=now()
 returning id into rid;
 update public.networks n set media_usage_bytes=greatest(n.media_usage_bytes,coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid),0)),updated_at=now() where n.id=nid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.request_network_media_asset_delete(p_asset_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();a public.network_media_assets%rowtype;
begin
 if nid is null then raise exception 'Choose an active network.';end if;
 select * into a from public.network_media_assets where id=p_asset_id and network_id=nid for update;
 if not found or not (a.owner_user_id=auth.uid() or public.is_network_admin(nid)) then raise exception 'Media asset not found or not editable.' using errcode='42501';end if;
 if a.lifecycle_state='deleted' then raise exception 'Media has already been deleted.';end if;
 -- Bound historical content must be archived before deletion. This prevents accidental one-click destruction.
 if a.entity_id is not null and a.lifecycle_state<>'archived' then raise exception 'Archive linked media before permanently deleting it.';end if;
 update public.network_media_assets set lifecycle_state='delete_pending',delete_requested_at=now(),delete_requested_by=auth.uid(),delete_reason=nullif(trim(coalesce(p_reason,'')),''),updated_at=now() where id=a.id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_media_delete_requested',jsonb_build_object('asset_id',a.id,'bucket',a.bucket,'media_kind',a.media_kind,'entity_type',a.entity_type,'entity_id',a.entity_id));
 return jsonb_build_object('asset_id',a.id,'bucket',a.bucket,'object_path',a.object_path,'thumbnail_path',a.thumbnail_path);
end $function$
;

CREATE OR REPLACE FUNCTION public.resend_network_participation_invitation(p_network_id uuid, p_invitation_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare v public.network_participation_invitations%rowtype;begin
 if not exists(select 1 from public.network_memberships where network_id=p_network_id and user_id=auth.uid() and status='active' and role in ('owner','admin')) then raise exception 'Network admin access required.' using errcode='42501';end if;
 update public.network_participation_invitations set token=gen_random_uuid(),status='pending',expires_at=now()+interval '14 days',resend_count=resend_count+1,updated_at=now() where id=p_invitation_id and network_id=p_network_id and status<>'accepted' returning * into v;
 if not found then raise exception 'Invitation not found or already accepted.' using errcode='P0002';end if;
 return jsonb_build_object('id',v.id,'token',v.token,'email',v.email,'expiresAt',v.expires_at,'status',v.status);
end $function$
;

CREATE OR REPLACE FUNCTION public.revoke_network_participation_invitation(p_network_id uuid, p_invitation_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$begin
 if not exists(select 1 from public.network_memberships where network_id=p_network_id and user_id=auth.uid() and status='active' and role in ('owner','admin')) then raise exception 'Network admin access required.' using errcode='42501';end if;
 update public.network_participation_invitations set status='revoked',updated_at=now() where id=p_invitation_id and network_id=p_network_id and status='pending';
end $function$
;

CREATE OR REPLACE FUNCTION public.set_network_media_asset_archived(p_asset_id uuid, p_archived boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();a public.network_media_assets%rowtype;
begin
 if nid is null then raise exception 'Choose an active network.';end if;
 select * into a from public.network_media_assets where id=p_asset_id and network_id=nid;
 if not found or not (a.owner_user_id=auth.uid() or public.is_network_admin(nid)) then raise exception 'Media asset not found or not editable.' using errcode='42501';end if;
 if a.lifecycle_state in ('delete_pending','deleted') then raise exception 'Deleted media cannot be archived or restored.';end if;
 update public.network_media_assets set lifecycle_state=case when p_archived then 'archived' else 'active' end,archived_at=case when p_archived then now() else null end,archived_by=case when p_archived then auth.uid() else null end,updated_at=now() where id=a.id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),case when p_archived then 'network_media_archived' else 'network_media_restored' end,jsonb_build_object('asset_id',a.id,'media_kind',a.media_kind,'entity_type',a.entity_type,'entity_id',a.entity_id));
end $function$
;

CREATE OR REPLACE FUNCTION public.track_public_participation(p_event_type text, p_public_member_id uuid DEFAULT NULL::uuid, p_channel text DEFAULT NULL::text, p_session_token text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare visitor text;
begin
  if p_event_type not in ('public_view','profile_view','share','qr_view','embed_view') then raise exception 'Invalid event type.' using errcode='22023'; end if;
  if p_public_member_id is not null and not exists(select 1 from public.family_members where id=p_public_member_id and profile_status='approved' and profile_visibility='public') then
    raise exception 'Public profile not found.' using errcode='P0002';
  end if;
  visitor:=case when length(coalesce(p_session_token,''))>=16 then encode(digest(p_session_token,'sha256'),'hex') else null end;
  if visitor is null or not exists(select 1 from public.participation_events where event_type=p_event_type and session_hash=visitor
      and public_member_id is not distinct from p_public_member_id and created_at>now()-interval '5 minutes') then
    insert into public.participation_events(event_type,public_member_id,channel,session_hash)
    values(p_event_type,p_public_member_id,left(p_channel,30),visitor);
  end if;
end;
$function$
;

SET check_function_bodies = on;
