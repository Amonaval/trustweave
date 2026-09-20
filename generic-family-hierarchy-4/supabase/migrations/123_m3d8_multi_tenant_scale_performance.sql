-- M3-D8 — Multi-tenant scale & performance foundations.
-- Additive only. Establishes network-first indexes and bounded keyset read contracts.
-- Does not partition, shard or change existing eager RPC behavior.

create index if not exists idx_network_entities_network_label_id
 on public.network_entities(network_id,label,id);

create index if not exists idx_network_activities_network_sort_id
 on public.network_activities(network_id,(coalesce(starts_at,created_at)) desc,id desc);

create index if not exists idx_network_relationships_network_id
 on public.network_entity_relationships(network_id,id);

create index if not exists idx_network_memberships_network_status_joined
 on public.network_memberships(network_id,status,joined_at desc,user_id);

create index if not exists idx_network_activity_comments_network_activity_created
 on public.network_activity_comments(network_id,activity_id,created_at,id);

create index if not exists idx_fca_finance_network_created
 on public.family_association_finance_ledger(network_id,created_at desc,id);

create index if not exists idx_fca_role_history_network_start
 on public.family_association_role_history(network_id,starts_on desc,id);

-- Keyset directory page. Existing get_network_affiliated_entities() stays compatible.
create or replace function public.get_network_affiliated_entities_page(
 p_after_label text default null,
 p_after_id uuid default null,
 p_limit integer default 50
)
returns table(
 entity_id uuid,
 external_ref uuid,
 entity_kind varchar,
 entity_label varchar,
 owner_user_id uuid,
 metadata jsonb,
 visibility varchar,
 affiliations jsonb
)
language sql security definer stable set search_path=public as $$
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
$$;
revoke all on function public.get_network_affiliated_entities_page(text,uuid,integer) from public;
grant execute on function public.get_network_affiliated_entities_page(text,uuid,integer) to authenticated;

-- Keyset relationship page. UUID cursor is deterministic and network-first indexed.
create or replace function public.get_productized_network_relationships_page(
 p_after_id uuid default null,
 p_limit integer default 100
)
returns table(
 id uuid,
 from_entity_id uuid,
 to_entity_id uuid,
 from_label varchar,
 to_label varchar,
 relationship_type varchar,
 relationship_label text,
 metadata jsonb
)
language sql security definer stable set search_path=public as $$
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
$$;
revoke all on function public.get_productized_network_relationships_page(uuid,integer) from public;
grant execute on function public.get_productized_network_relationships_page(uuid,integer) to authenticated;

-- Admin membership page. Existing full-list RPC remains for compatibility while large surfaces migrate.
create or replace function public.get_productized_network_memberships_page(
 p_after_joined_at timestamptz default null,
 p_after_user_id uuid default null,
 p_limit integer default 100
)
returns table(user_id uuid,email text,role varchar,status varchar,entity_label varchar,joined_at timestamptz)
language sql security definer stable set search_path=public as $$
 select m.user_id,u.email::text,m.role,m.status,e.label,m.joined_at
 from public.network_memberships m
 left join auth.users u on u.id=m.user_id
 left join public.network_entities e on e.network_id=m.network_id and e.owner_user_id=m.user_id
 where m.network_id=public.current_network_id()
   and public.is_network_admin(m.network_id)
   and (p_after_joined_at is null or p_after_user_id is null or (m.joined_at,m.user_id)<(p_after_joined_at,p_after_user_id))
 order by m.joined_at desc,m.user_id desc
 limit least(greatest(coalesce(p_limit,100),1),200);
$$;
revoke all on function public.get_productized_network_memberships_page(timestamptz,uuid,integer) from public;
grant execute on function public.get_productized_network_memberships_page(timestamptz,uuid,integer) to authenticated;
