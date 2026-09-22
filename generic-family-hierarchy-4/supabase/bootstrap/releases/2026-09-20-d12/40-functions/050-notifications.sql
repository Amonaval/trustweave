-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.create_network_notification(p_network_id uuid, p_user_id uuid, p_type text, p_title text, p_body text DEFAULT NULL::text, p_surface text DEFAULT NULL::text, p_entity_type text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid, p_priority text DEFAULT 'normal'::text, p_metadata jsonb DEFAULT '{}'::jsonb, p_actor_id uuid DEFAULT auth.uid())
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_href text;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  if p_priority not in ('low','normal','high','urgent') then raise exception 'Invalid notification priority.' using errcode='22023'; end if;
  if not public.is_network_member(p_network_id) and not public.is_platform_owner() then
    raise exception 'Not authorized for this network.' using errcode='42501';
  end if;
  if not exists(select 1 from public.network_memberships nm where nm.network_id=p_network_id and nm.user_id=p_user_id and nm.status='active') then
    raise exception 'Notification recipient is not an active network member.' using errcode='22023';
  end if;
  v_href := case when nullif(trim(coalesce(p_surface,'')),'') is null then null
    else '/?twNetwork='||p_network_id::text||'&twSurface='||replace(trim(p_surface),' ','%20')||
      case when p_entity_id is null then '' else '&twItem='||p_entity_id::text end
    end;
  insert into public.notifications(user_id,network_id,actor_id,type,title,body,href,entity_type,entity_id,priority,metadata)
  values(p_user_id,p_network_id,p_actor_id,left(p_type,50),left(p_title,180),p_body,v_href,nullif(p_entity_type,''),p_entity_id,p_priority,coalesce(p_metadata,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_my_engagement_notification_preferences()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); r public.notification_preferences%rowtype;
begin
 if auth.uid() is null or nid is null then raise exception 'Active network is required.' using errcode='42501'; end if;
 select * into r from public.notification_preferences where network_id=nid and user_id=auth.uid();
 return jsonb_build_object(
  'push_enabled',coalesce(r.push_enabled,false),
  'quiet_start',case when r.quiet_start is null then null else to_char(r.quiet_start,'HH24:MI') end,
  'quiet_end',case when r.quiet_end is null then null else to_char(r.quiet_end,'HH24:MI') end,
  'timezone',coalesce(r.timezone,'Asia/Kolkata'),
  'urgent_bypass_quiet',coalesce(r.urgent_bypass_quiet,true),
  'categories',coalesce(r.engagement_categories,jsonb_build_object(
    'posts',jsonb_build_object('inbox',true,'push',true),'mentions',jsonb_build_object('inbox',true,'push',true),
    'complaints',jsonb_build_object('inbox',true,'push',true),'funds',jsonb_build_object('inbox',true,'push',true),
    'elections',jsonb_build_object('inbox',true,'push',true),'events_membership',jsonb_build_object('inbox',true,'push',true),
    'general',jsonb_build_object('inbox',true,'push',true)
  ))
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.get_my_notification_preferences()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); result jsonb;
begin
 if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
 select jsonb_build_object(
   'digest',np.digest,'special_days',np.special_days,'memories',np.memories,'gatherings',np.gatherings,
   'contributions',np.contributions,'introductions',np.introductions,'family_changes',np.family_changes,
   'preferred_weekday',np.preferred_weekday
 ) into result
 from public.notification_preferences np
 where np.network_id=nid and np.user_id=auth.uid();
 return coalesce(result,jsonb_build_object(
   'digest','weekly','special_days',true,'memories',false,'gatherings',true,
   'contributions',true,'introductions',true,'family_changes',true,'preferred_weekday',0
 ));
end;$function$
;

CREATE OR REPLACE FUNCTION public.get_my_notification_unread_count()
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select count(*)::integer from public.notifications n
 where n.user_id=auth.uid() and n.read_at is null and n.archived_at is null
   and (n.network_id is null or exists(select 1 from public.network_memberships nm where nm.network_id=n.network_id and nm.user_id=auth.uid() and nm.status='active'));
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_notifications()
 RETURNS TABLE(id uuid, user_id uuid, network_id uuid, network_name text, type character varying, title character varying, body text, href text, entity_type character varying, entity_id uuid, priority character varying, metadata jsonb, read_at timestamp with time zone, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select * from public.get_my_notifications(80,false);
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_notifications(p_limit integer DEFAULT 80, p_unread_only boolean DEFAULT false)
 RETURNS TABLE(id uuid, user_id uuid, network_id uuid, network_name text, type character varying, title character varying, body text, href text, entity_type character varying, entity_id uuid, priority character varying, metadata jsonb, read_at timestamp with time zone, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select n.id,n.user_id,n.network_id,coalesce(net.name,'TrustWeave')::text,n.type,n.title,n.body,n.href,
        n.entity_type,n.entity_id,n.priority,n.metadata,n.read_at,n.created_at
 from public.notifications n
 left join public.networks net on net.id=n.network_id
 where n.user_id=auth.uid() and n.archived_at is null
   and (n.network_id is null or exists(select 1 from public.network_memberships nm where nm.network_id=n.network_id and nm.user_id=auth.uid() and nm.status='active'))
   and (not p_unread_only or n.read_at is null)
 order by case n.priority when 'urgent' then 0 when 'high' then 1 when 'normal' then 2 else 3 end,n.created_at desc
 limit greatest(1,least(coalesce(p_limit,80),200));
$function$
;

CREATE OR REPLACE FUNCTION public.get_network_notification_roles()
 RETURNS TABLE(role_key character varying, label character varying, user_id uuid, email text, member_label text, active boolean, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    r.role_key,
    r.label,
    r.user_id,
    u.email::text,
    coalesce(
      p.full_name,
      u.raw_user_meta_data->>'full_name',
      split_part(coalesce(u.email,''),'@',1)
    )::text as member_label,
    r.active,
    r.updated_at
  from public.network_notification_roles r
  join auth.users u on u.id = r.user_id
  left join public.profiles p on p.id = r.user_id
  where r.network_id = public.current_network_id()
    and public.is_network_member(r.network_id)
  order by
    r.role_key,
    coalesce(
      p.full_name,
      u.raw_user_meta_data->>'full_name',
      split_part(coalesce(u.email,''),'@',1)
    );
$function$
;

CREATE OR REPLACE FUNCTION public.get_notification_preferences()
 RETURNS notification_preferences
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare r public.notification_preferences; begin
 if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
 select * into r from public.notification_preferences where user_id=auth.uid();
 if r.user_id is null then r.user_id:=auth.uid(); r.birthdays:=true;r.anniversaries:=true;r.invitations:=true;r.memories:=false;r.gatherings:=true;r.contributions:=false;r.updated_at:=now(); end if;
 return r;
end $function$
;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(p_network_id uuid DEFAULT NULL::uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_count integer;
begin
  update public.notifications n set read_at=coalesce(n.read_at,now())
  where n.user_id=auth.uid() and n.archived_at is null and n.read_at is null
    and (p_network_id is null or n.network_id=p_network_id)
    and (n.network_id is null or exists(select 1 from public.network_memberships nm where nm.network_id=n.network_id and nm.user_id=auth.uid() and nm.status='active'));
  get diagnostics v_count=row_count; return v_count;
end $function$
;

CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id uuid)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 update public.notifications set read_at=coalesce(read_at,now()) where id=p_notification_id and user_id=auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.notification_engagement_category(p_type text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
 select case
  when coalesce(p_metadata->>'category','') in ('posts','mentions','complaints','funds','elections','events_membership','general') then p_metadata->>'category'
  when coalesce(p_type,'') in ('mention','role_mention') then 'mentions'
  when coalesce(p_type,'') like 'complaint%' then 'complaints'
  when coalesce(p_type,'') like 'fund_%' or coalesce(p_type,'') in ('payment_recorded','collection_due') then 'funds'
  when coalesce(p_type,'') like 'ballot_%' or coalesce(p_type,'') like 'election%' or coalesce(p_type,'') like 'poll%' then 'elections'
  when coalesce(p_type,'') in ('community_post','community_broadcast','post_mention','post_comment') then 'posts'
  when coalesce(p_type,'') like 'event%' or coalesce(p_type,'') like 'membership%' or coalesce(p_type,'') like 'renewal%' then 'events_membership'
  else 'general'
 end;
$function$
;

CREATE OR REPLACE FUNCTION public.save_my_engagement_notification_preferences(p_push_enabled boolean, p_quiet_start time without time zone DEFAULT NULL::time without time zone, p_quiet_end time without time zone DEFAULT NULL::time without time zone, p_timezone text DEFAULT 'Asia/Kolkata'::text, p_urgent_bypass_quiet boolean DEFAULT true, p_categories jsonb DEFAULT '{}'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); k text; v jsonb; normalized jsonb:='{}'::jsonb;
begin
 if auth.uid() is null or nid is null or not public.is_network_member(nid) then raise exception 'Active network membership is required.' using errcode='42501'; end if;
 if length(trim(coalesce(p_timezone,'')))<3 or length(p_timezone)>80 then raise exception 'Invalid timezone.' using errcode='22023'; end if;
 for k,v in select * from jsonb_each(coalesce(p_categories,'{}'::jsonb)) loop
   if k not in ('posts','mentions','complaints','funds','elections','events_membership','general') then continue; end if;
   normalized:=normalized||jsonb_build_object(k,jsonb_build_object('inbox',coalesce((v->>'inbox')::boolean,true),'push',coalesce((v->>'push')::boolean,true)));
 end loop;
 for k in select unnest(array['posts','mentions','complaints','funds','elections','events_membership','general']) loop
   if not normalized?k then normalized:=normalized||jsonb_build_object(k,jsonb_build_object('inbox',true,'push',true)); end if;
 end loop;
 insert into public.notification_preferences(network_id,user_id,push_enabled,quiet_start,quiet_end,timezone,urgent_bypass_quiet,engagement_categories)
 values(nid,auth.uid(),coalesce(p_push_enabled,false),p_quiet_start,p_quiet_end,left(trim(p_timezone),80),coalesce(p_urgent_bypass_quiet,true),normalized)
 on conflict(network_id,user_id) do update set
  push_enabled=excluded.push_enabled,quiet_start=excluded.quiet_start,quiet_end=excluded.quiet_end,timezone=excluded.timezone,
  urgent_bypass_quiet=excluded.urgent_bypass_quiet,engagement_categories=excluded.engagement_categories,updated_at=now();
end $function$
;

CREATE OR REPLACE FUNCTION public.save_my_notification_preferences(p_digest text, p_special_days boolean, p_memories boolean, p_gatherings boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
 if p_digest not in ('off','weekly','monthly') then raise exception 'Invalid digest preference.' using errcode='22023'; end if;
 insert into public.notification_preferences(network_id,user_id,digest,special_days,memories,gatherings)
 values(nid,auth.uid(),p_digest,p_special_days,p_memories,p_gatherings)
 on conflict(network_id,user_id) do update set digest=excluded.digest,special_days=excluded.special_days,memories=excluded.memories,gatherings=excluded.gatherings,updated_at=now();
end;$function$
;

CREATE OR REPLACE FUNCTION public.save_notification_preferences(p_birthdays boolean, p_anniversaries boolean, p_invitations boolean, p_memories boolean, p_gatherings boolean, p_contributions boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin
 if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
 insert into public.notification_preferences(user_id,birthdays,anniversaries,invitations,memories,gatherings,contributions,updated_at)
 values(auth.uid(),p_birthdays,p_anniversaries,p_invitations,p_memories,p_gatherings,p_contributions,now())
 on conflict(user_id) do update set birthdays=excluded.birthdays,anniversaries=excluded.anniversaries,invitations=excluded.invitations,memories=excluded.memories,gatherings=excluded.gatherings,contributions=excluded.contributions,updated_at=now();
end $function$
;

SET check_function_bodies = on;
