-- FCA-L1 field feedback — expose event RSVP identities to members of the same network.
-- Additive/read-only. Existing RSVP writes and counts remain unchanged.

create or replace function public.get_network_event_rsvps(p_activity_id uuid)
returns table(user_id uuid,member_label text,response varchar,updated_at timestamptz)
language sql security definer stable set search_path=public as $$
 select r.user_id,
        coalesce(
          (select e.label
             from public.network_entities e
            where e.network_id=r.network_id
              and e.owner_user_id=r.user_id
              and e.kind='person'
            order by e.updated_at desc
            limit 1),
          'Member'
        )::text as member_label,
        r.response,
        r.updated_at
   from public.network_activity_rsvps r
  where r.network_id=public.current_network_id()
    and r.activity_id=p_activity_id
    and public.is_network_member(r.network_id)
  order by case r.response when 'going' then 0 when 'maybe' then 1 else 2 end,
           member_label;
$$;

revoke all on function public.get_network_event_rsvps(uuid) from public;
grant execute on function public.get_network_event_rsvps(uuid) to authenticated;
