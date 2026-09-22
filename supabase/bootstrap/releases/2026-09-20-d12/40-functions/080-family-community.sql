-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.can_manage_association_household(p_household_id uuid, p_user_id uuid DEFAULT auth.uid())
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select exists(select 1 from public.network_entities h join public.networks n on n.id=h.network_id where h.id=p_household_id and ((n.vertical_kind='association' and h.kind='household') or (n.vertical_kind='family-association' and h.kind='family')) and h.network_id=public.current_network_id() and public.is_network_member(h.network_id) and (public.is_network_admin(h.network_id) or exists(select 1 from public.association_household_admins a where a.network_id=h.network_id and a.household_entity_id=h.id and a.user_id=p_user_id) or exists(select 1 from public.network_entity_relationships r join public.network_entities person on person.id=r.to_entity_id and person.network_id=r.network_id where r.network_id=h.network_id and r.from_entity_id=h.id and r.relationship_type='represented_by' and person.owner_user_id=p_user_id)));
$function$
;

CREATE OR REPLACE FUNCTION public.fca_seed_defaults(p_network uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 insert into public.family_association_settings(network_id) values(p_network) on conflict(network_id) do nothing;
 insert into public.family_association_role_catalog(network_id,role_key,label,role_type,sort_order) values
  (p_network,'president','President','office_bearer',10),(p_network,'president-elect','President Elect','office_bearer',20),(p_network,'past-president','Past President','office_bearer',30),(p_network,'secretary','Secretary','office_bearer',40),(p_network,'treasurer','Treasurer','office_bearer',50),(p_network,'director','Director','director',60),(p_network,'chairperson','Chairperson','chairperson',70),(p_network,'committee-member','Committee Member','committee',80),(p_network,'volunteer','Volunteer','volunteer',90),(p_network,'mentor','Mentor','mentor',100)
 on conflict(network_id,role_key) do nothing;
end $function$
;

CREATE OR REPLACE FUNCTION public.fca_seed_network_defaults_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin if new.vertical_kind='family-association' then perform public.fca_seed_defaults(new.id);end if;return new;end $function$
;

CREATE OR REPLACE FUNCTION public.get_my_association_household_admin_context()
 RETURNS TABLE(household_id uuid, household_label character varying, can_manage boolean, user_id uuid, entity_label character varying, is_household_admin boolean, is_representative boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with me as (select e.id person_id,e.network_id from public.network_entities e where e.network_id=public.current_network_id() and e.owner_user_id=auth.uid() and e.kind='person' limit 1),
 household as (select h.id,h.label,h.network_id from me join public.network_entity_relationships r on r.network_id=me.network_id and r.from_entity_id=me.person_id and r.relationship_type in ('member_of_household','member_of_family') join public.network_entities h on h.id=r.to_entity_id and h.network_id=r.network_id and h.kind in ('household','family') limit 1),
 people as (select p.id,p.label,p.owner_user_id from household h join public.network_entity_relationships r on r.network_id=h.network_id and r.to_entity_id=h.id and r.relationship_type in ('member_of_household','member_of_family') join public.network_entities p on p.id=r.from_entity_id and p.network_id=r.network_id and p.kind='person')
 select h.id,h.label,public.can_manage_association_household(h.id,auth.uid()),p.owner_user_id,p.label,exists(select 1 from public.association_household_admins a where a.network_id=h.network_id and a.household_entity_id=h.id and a.user_id=p.owner_user_id),exists(select 1 from public.network_entity_relationships rr where rr.network_id=h.network_id and rr.from_entity_id=h.id and rr.to_entity_id=p.id and rr.relationship_type='represented_by') from household h join people p on p.owner_user_id is not null where public.is_network_member(h.network_id) order by 7 desc,p.label;
$function$
;

CREATE OR REPLACE FUNCTION public.set_association_household_admin(p_household_id uuid, p_user_id uuid, p_enabled boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if not public.can_manage_association_household(p_household_id,auth.uid()) then raise exception 'Family manager access required.' using errcode='42501';end if;
 if not exists(select 1 from public.network_entities p join public.network_entity_relationships r on r.network_id=p.network_id and r.from_entity_id=p.id and r.to_entity_id=p_household_id and r.relationship_type in ('member_of_household','member_of_family') where p.network_id=nid and p.owner_user_id=p_user_id and p.kind='person') then raise exception 'Co-admin must be a claimed member of this family.' using errcode='22023';end if;
 if p_enabled then insert into public.association_household_admins(network_id,household_entity_id,user_id,granted_by) values(nid,p_household_id,p_user_id,auth.uid()) on conflict do nothing;else delete from public.association_household_admins where network_id=nid and household_entity_id=p_household_id and user_id=p_user_id;end if;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'family_association_coadmin_changed',jsonb_build_object('family_id',p_household_id,'user_id',p_user_id,'enabled',p_enabled));
end $function$
;

SET check_function_bodies = on;
