-- E10 — Engagement Control Center
-- Per-user, per-network notification delivery preferences.
-- Persisted in-app notifications remain the source of truth. Preferences control default inbox emphasis and push delivery only.

alter table public.notification_preferences add column if not exists engagement_categories jsonb not null default jsonb_build_object(
  'posts',jsonb_build_object('inbox',true,'push',true),
  'mentions',jsonb_build_object('inbox',true,'push',true),
  'complaints',jsonb_build_object('inbox',true,'push',true),
  'funds',jsonb_build_object('inbox',true,'push',true),
  'elections',jsonb_build_object('inbox',true,'push',true),
  'events_membership',jsonb_build_object('inbox',true,'push',true),
  'general',jsonb_build_object('inbox',true,'push',true)
);

create or replace function public.notification_engagement_category(p_type text,p_metadata jsonb default '{}'::jsonb)
returns text language sql immutable as $$
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
$$;

create or replace function public.get_my_engagement_notification_preferences()
returns jsonb language plpgsql security definer stable set search_path=public as $$
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
end $$;
revoke all on function public.get_my_engagement_notification_preferences() from public;
grant execute on function public.get_my_engagement_notification_preferences() to authenticated;

create or replace function public.save_my_engagement_notification_preferences(
 p_push_enabled boolean,
 p_quiet_start time default null,
 p_quiet_end time default null,
 p_timezone text default 'Asia/Kolkata',
 p_urgent_bypass_quiet boolean default true,
 p_categories jsonb default '{}'::jsonb
) returns void
language plpgsql security definer set search_path=public as $$
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
end $$;
revoke all on function public.save_my_engagement_notification_preferences(boolean,time,time,text,boolean,jsonb) from public;
grant execute on function public.save_my_engagement_notification_preferences(boolean,time,time,text,boolean,jsonb) to authenticated;

-- E2 originally updated an existing preference row after subscribing. Make this robust for a new network/user with no row yet.
create or replace function public.upsert_my_push_subscription(p_endpoint text,p_p256dh text,p_auth text,p_user_agent text default null) returns uuid
language plpgsql security definer set search_path=public as $$
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
end $$;
revoke all on function public.upsert_my_push_subscription(text,text,text,text) from public;
grant execute on function public.upsert_my_push_subscription(text,text,text,text) to authenticated;
