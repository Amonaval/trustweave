-- Mission 2 final runtime cleanup before pausing regression work.
-- Reasserts two contracts observed drifting in the live QA database.

alter table public.notification_preferences add column if not exists digest varchar(12) not null default 'weekly';
alter table public.notification_preferences add column if not exists special_days boolean not null default true;
alter table public.notification_preferences add column if not exists memories boolean not null default false;
alter table public.notification_preferences add column if not exists gatherings boolean not null default true;
alter table public.notification_preferences add column if not exists contributions boolean not null default true;
alter table public.notification_preferences add column if not exists introductions boolean not null default true;
alter table public.notification_preferences add column if not exists family_changes boolean not null default true;
alter table public.notification_preferences add column if not exists preferred_weekday smallint not null default 0;

create or replace function public.get_my_notification_preferences() returns jsonb
language plpgsql security definer stable set search_path=public as $$
declare nid uuid:=public.current_network_id(); result jsonb;
begin
 if auth.uid() is null or nid is null then raise exception 'Active family is required.' using errcode='42501'; end if;
 select jsonb_build_object(
   'digest',coalesce(np.digest,'weekly'),'special_days',coalesce(np.special_days,true),'memories',coalesce(np.memories,false),'gatherings',coalesce(np.gatherings,true),
   'contributions',coalesce(np.contributions,true),'introductions',coalesce(np.introductions,true),'family_changes',coalesce(np.family_changes,true),
   'preferred_weekday',coalesce(np.preferred_weekday,0)
 ) into result
 from public.notification_preferences np
 where np.network_id=nid and np.user_id=auth.uid();
 return coalesce(result,jsonb_build_object(
   'digest','weekly','special_days',true,'memories',false,'gatherings',true,
   'contributions',true,'introductions',true,'family_changes',true,'preferred_weekday',0
 ));
end;$$;
revoke all on function public.get_my_notification_preferences() from public;
grant execute on function public.get_my_notification_preferences() to authenticated;

create or replace function public.hs4_get_complaint_routes()
returns table(category_key varchar,role_key varchar,role_label text,assignee_count bigint)
language sql security definer stable set search_path=public as $$
 select r.category_key,
        r.role_key,
        initcap(replace(r.role_key,'-',' '))::text,
        (select count(*)
           from public.network_notification_roles nr
          where nr.network_id=r.network_id
            and nr.role_key=r.role_key
            and nr.active)
   from public.hs_complaint_routes r
  where r.network_id=public.hs2_assert_network()
  order by r.category_key;
$$;
revoke all on function public.hs4_get_complaint_routes() from public;
grant execute on function public.hs4_get_complaint_routes() to authenticated;

notify pgrst, 'reload schema';
