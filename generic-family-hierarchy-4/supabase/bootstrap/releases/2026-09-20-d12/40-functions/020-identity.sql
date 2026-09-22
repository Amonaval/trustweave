-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.accept_member_invitation(p_token text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare invite public.member_invitations; uid uuid:=auth.uid(); active_nid uuid; existing_claim uuid;
begin
  if uid is null then raise exception 'Sign in is required to accept this invitation.' using errcode='42501'; end if;
  select * into invite from public.member_invitations
   where token_hash=encode(digest(p_token,'sha256'),'hex') and used_at is null
     and revoked_at is null and expires_at>now() for update;
  if invite.id is null then raise exception 'This invitation is invalid, expired, revoked or already used.' using errcode='22023'; end if;
  if not exists(select 1 from public.family_members fm where fm.id=invite.member_id and fm.network_id=invite.network_id) then
    raise exception 'The invited family profile no longer exists.' using errcode='P0002'; end if;

  select nm.user_id into existing_claim from public.network_memberships nm
    where nm.network_id=invite.network_id and nm.member_id=invite.member_id and nm.status='active' and nm.user_id<>uid limit 1;
  if existing_claim is not null then raise exception 'This family profile is already claimed.' using errcode='23505'; end if;

  insert into public.network_memberships(network_id,user_id,role,status,member_id)
  values(invite.network_id,uid,'member','active',invite.member_id)
  on conflict(network_id,user_id) do update set status='active',member_id=excluded.member_id;

  select active_network_id into active_nid from public.profiles where id=uid for update;
  update public.profiles
     set active_network_id=invite.network_id,member_id=invite.member_id,updated_at=now()
   where id=uid;
  if not found then raise exception 'User profile was not initialized.' using errcode='P0002'; end if;

  update public.member_invitations set used_at=now(),accepted_by=uid where id=invite.id;
  insert into public.audit_log(network_id,actor_id,action,details)
    values(invite.network_id,uid,'member_invitation_accepted',jsonb_build_object('invitation_id',invite.id,'member_id',invite.member_id));
  if invite.created_by is not null and invite.created_by<>uid then
    insert into public.notifications(network_id,user_id,type,title,body)
      values(invite.network_id,invite.created_by,'invitation_accepted','Invitation accepted','A relative joined and claimed their profile.');
  end if;
  return invite.member_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_bulk_member_invitations(p_items jsonb, p_expires_days integer DEFAULT 7)
 RETURNS TABLE(invitation_id uuid, member_id uuid, token text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare item jsonb; raw_token text; target uuid; created uuid; channel text; hint text; nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
  if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>200 then
    raise exception 'Provide between 1 and 200 invitation items.' using errcode='22023';
  end if;
  for item in select value from jsonb_array_elements(p_items) loop
    begin target := (item->>'member_id')::uuid; exception when others then
      raise exception 'Every invitation needs a valid member ID.' using errcode='22023'; end;
    raw_token:=item->>'token'; channel:=coalesce(nullif(item->>'channel',''),'link');
    hint:=nullif(left(trim(item->>'recipient_hint'),160),'');
    if length(coalesce(raw_token,''))<32 then raise exception 'Every invitation needs a strong token.' using errcode='22023'; end if;
    if channel not in ('link','email','whatsapp','sms','print','other') then raise exception 'Invalid delivery channel.' using errcode='22023'; end if;
    if not exists(select 1 from public.family_members fm where fm.id=target and fm.network_id=nid and fm.profile_status='approved') then
      raise exception 'Approved family member not found.' using errcode='P0002'; end if;
    if exists(select 1 from public.network_memberships nm where nm.network_id=nid and nm.member_id=target and nm.status='active') then
      raise exception 'A selected member profile is already claimed.' using errcode='23505'; end if;
    update public.member_invitations mi set revoked_at=now(),revoked_by=auth.uid()
      where mi.network_id=nid and mi.member_id=target and mi.used_at is null and mi.revoked_at is null and mi.expires_at>now();
    insert into public.member_invitations(network_id,member_id,token_hash,created_by,expires_at,last_sent_at,delivery_channel,recipient_hint)
    values(nid,target,encode(digest(raw_token,'sha256'),'hex'),auth.uid(),
      now()+make_interval(days=>greatest(1,least(coalesce(p_expires_days,7),30))),now(),channel,hint)
    returning id into created;
    insert into public.audit_log(network_id,actor_id,action,details)
      values(nid,auth.uid(),'member_invitation_created',jsonb_build_object('invitation_id',created,'member_id',target,'channel',channel));
    invitation_id:=created; member_id:=target; token:=raw_token; return next;
  end loop;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.create_member_invitation(p_member_id uuid, p_token text, p_expires_days integer DEFAULT 7)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_admin() then raise exception 'Administrator access is required.' using errcode='42501'; end if;
  if not exists(select 1 from public.family_members where id=p_member_id and profile_status='approved') then raise exception 'Approved member not found.' using errcode='P0002'; end if;
  if exists(select 1 from public.profiles where member_id=p_member_id) then raise exception 'This member profile is already claimed.' using errcode='23505'; end if;
  if p_token is null or length(p_token) < 24 then raise exception 'Invalid invitation token.' using errcode='22023'; end if;
  insert into public.member_invitations(member_id,token_hash,created_by,expires_at)
  values(p_member_id,encode(digest(p_token,'sha256'),'hex'),auth.uid(),now()+make_interval(days=>greatest(1,least(p_expires_days,30))));
  insert into public.audit_log(actor_id,action,details) values(auth.uid(),'member_invitation_created',jsonb_build_object('member_id',p_member_id,'expires_days',p_expires_days));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_member_invitations()
 RETURNS TABLE(id uuid, member_id uuid, member_name text, status text, expires_at timestamp with time zone, created_at timestamp with time zone, first_opened_at timestamp with time zone, last_sent_at timestamp with time zone, delivery_channel text, recipient_hint text, resend_of uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
  return query select i.id,i.member_id,fm.full_name::text,public.invitation_status(i.used_at,i.revoked_at,i.expires_at),
    i.expires_at,i.created_at,i.first_opened_at,i.last_sent_at,i.delivery_channel::text,i.recipient_hint::text,i.resend_of
  from public.member_invitations i join public.family_members fm on fm.id=i.member_id and fm.network_id=nid
  where i.network_id=nid order by i.created_at desc limit 1000;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_productized_network_memberships()
 RETURNS TABLE(user_id uuid, email text, role character varying, status character varying, entity_label character varying, joined_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select m.user_id,u.email::text,m.role,m.status,e.label,m.joined_at
 from public.network_memberships m
 left join auth.users u on u.id=m.user_id
 left join public.network_entities e on e.network_id=m.network_id and e.owner_user_id=m.user_id
 where m.network_id=public.current_network_id() and public.is_network_admin(m.network_id)
   and public.g8_productized_vertical((select n.vertical_kind from public.networks n where n.id=m.network_id))
 order by case m.role when 'owner' then 0 when 'admin' then 1 else 2 end,coalesce(e.label,u.email::text);
$function$
;

CREATE OR REPLACE FUNCTION public.get_productized_network_memberships_page(p_after_joined_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_after_user_id uuid DEFAULT NULL::uuid, p_limit integer DEFAULT 100)
 RETURNS TABLE(user_id uuid, email text, role character varying, status character varying, entity_label character varying, joined_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select m.user_id,u.email::text,m.role,m.status,e.label,m.joined_at
 from public.network_memberships m
 left join auth.users u on u.id=m.user_id
 left join public.network_entities e on e.network_id=m.network_id and e.owner_user_id=m.user_id
 where m.network_id=public.current_network_id()
   and public.is_network_admin(m.network_id)
   and (p_after_joined_at is null or p_after_user_id is null or (m.joined_at,m.user_id)<(p_after_joined_at,p_after_user_id))
 order by m.joined_at desc,m.user_id desc
 limit least(greatest(coalesce(p_limit,100),1),200);
$function$
;

CREATE OR REPLACE FUNCTION public.has_active_network_membership(p_network_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select p_network_id is not null and p_user_id is not null and exists(
    select 1 from public.network_memberships nm
    join public.networks n on n.id=nm.network_id and n.status='active'
    where nm.network_id=p_network_id and nm.user_id=p_user_id and nm.status='active'
  );
$function$
;

CREATE OR REPLACE FUNCTION public.resend_member_invitation(p_invitation_id uuid, p_token text, p_expires_days integer DEFAULT 7)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare old_invite public.member_invitations; new_id uuid; nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
  if length(coalesce(p_token,''))<32 then raise exception 'A strong token is required.' using errcode='22023'; end if;
  select * into old_invite from public.member_invitations where id=p_invitation_id and network_id=nid for update;
  if old_invite.id is null or old_invite.used_at is not null then raise exception 'Invitation cannot be resent.' using errcode='22023'; end if;
  if exists(select 1 from public.network_memberships nm where nm.network_id=nid and nm.member_id=old_invite.member_id and nm.status='active') then
    raise exception 'This profile is already claimed.' using errcode='23505'; end if;
  update public.member_invitations set revoked_at=coalesce(revoked_at,now()),revoked_by=coalesce(revoked_by,auth.uid()) where id=old_invite.id;
  insert into public.member_invitations(network_id,member_id,token_hash,created_by,expires_at,last_sent_at,delivery_channel,recipient_hint,resend_of)
  values(nid,old_invite.member_id,encode(digest(p_token,'sha256'),'hex'),auth.uid(),
    now()+make_interval(days=>greatest(1,least(coalesce(p_expires_days,7),30))),now(),
    old_invite.delivery_channel,old_invite.recipient_hint,old_invite.id)
  returning id into new_id;
  insert into public.audit_log(network_id,actor_id,action,details)
    values(nid,auth.uid(),'member_invitation_resent',jsonb_build_object('invitation_id',new_id,'resend_of',old_invite.id,'member_id',old_invite.member_id));
  return new_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.revoke_member_invitation(p_invitation_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
  if nid is null or not public.is_network_admin(nid) then raise exception 'Family administrator access is required.' using errcode='42501'; end if;
  update public.member_invitations set revoked_at=now(),revoked_by=auth.uid()
   where id=p_invitation_id and network_id=nid and used_at is null and revoked_at is null;
  if not found then raise exception 'Active invitation not found in this family.' using errcode='P0002'; end if;
  insert into public.audit_log(network_id,actor_id,action,details)
    values(nid,auth.uid(),'member_invitation_revoked',jsonb_build_object('invitation_id',p_invitation_id));
end;
$function$
;

SET check_function_bodies = on;
