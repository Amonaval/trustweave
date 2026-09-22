-- Mission 2 runtime repair: restore the HS4 complaint-routing read contract on databases
-- where historical migration drift left PostgREST without the zero-argument RPC.

create or replace function public.hs4_get_complaint_routes()
returns table(category_key varchar,role_key varchar,role_label text,assignee_count bigint)
language sql
security definer
stable
set search_path=public
as $$
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

-- Ask PostgREST to refresh its function signature cache after the additive repair.
notify pgrst, 'reload schema';
