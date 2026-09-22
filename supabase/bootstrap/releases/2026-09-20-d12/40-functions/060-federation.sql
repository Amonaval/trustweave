-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.create_federation_umbrella(p_name text, p_slug text, p_umbrella_type text DEFAULT 'community'::text, p_summary text DEFAULT ''::text, p_location_label text DEFAULT ''::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); rid uuid; v_slug text:=lower(trim(coalesce(p_slug,'')));
begin
 if uid is null then raise exception 'Authentication required.' using errcode='42501'; end if;
 if not exists(select 1 from public.network_memberships nm where nm.user_id=uid and nm.status='active' and nm.role in ('owner','admin')) then raise exception 'Administer at least one active network before creating an umbrella.' using errcode='42501'; end if;
 if length(trim(coalesce(p_name,'')))<2 or length(trim(p_name))>160 then raise exception 'Umbrella name must be 2-160 characters.'; end if;
 if v_slug !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$' or length(v_slug)>180 then raise exception 'Umbrella slug must use lowercase letters, numbers and hyphens.'; end if;
 if p_umbrella_type not in ('community','association','federation','institution','ecosystem','other') then raise exception 'Unsupported umbrella type.'; end if;
 if length(trim(coalesce(p_summary,'')))>600 or length(trim(coalesce(p_location_label,'')))>120 then raise exception 'Umbrella field exceeds its allowed length.'; end if;
 insert into public.federation_umbrellas(name,slug,umbrella_type,summary,location_label,created_by)
 values(trim(p_name),v_slug,p_umbrella_type,trim(coalesce(p_summary,'')),trim(coalesce(p_location_label,'')),uid) returning id into rid;
 insert into public.federation_umbrella_admins(umbrella_id,user_id,role) values(rid,uid,'owner');
 insert into public.audit_log(actor_id,action,details) values(uid,'federation_umbrella_created',jsonb_build_object('umbrella_id',rid,'slug',v_slug,'umbrella_type',p_umbrella_type));
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.get_my_federation_umbrellas()
 RETURNS TABLE(id uuid, name character varying, slug character varying, umbrella_type character varying, summary character varying, location_label character varying, status character varying, role character varying, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select u.id,u.name,u.slug,u.umbrella_type,u.summary,u.location_label,u.status,a.role,u.created_at
 from public.federation_umbrella_admins a join public.federation_umbrellas u on u.id=a.umbrella_id
 where a.user_id=auth.uid() and a.status='active'
 order by u.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_network_effect_pulse(p_days integer DEFAULT 30)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
with cfg as(select greatest(7,least(coalesce(p_days,30),90)) d),
mine as(select network_id from public.network_memberships where user_id=auth.uid() and status='active'),
bridges as(select b.* from public.network_trust_bridges b where b.status='accepted' and exists(select 1 from mine m where m.network_id in(b.requester_network_id,b.recipient_network_id))),
events as(select e.* from public.network_effect_events e,cfg where e.actor_user_id=auth.uid() and e.created_at>=now()-(cfg.d||' days')::interval),
intros as(select i.* from public.trusted_introduction_requests i,cfg where auth.uid() in(i.requester_user_id,i.target_user_id) and i.created_at>=now()-(cfg.d||' days')::interval),
vals as(select
 (select count(*) from mine)::int active_networks,(select count(*) from bridges)::int accepted_bridges,
 coalesce((select sum(event_count) from events where event_type='discovery_search'),0)::int discovery_searches,
 coalesce((select sum(event_count) from events where event_type='discovery_opportunity'),0)::int opportunities_found,
 coalesce((select sum(event_count) from events where event_type='trusted_path_opportunity'),0)::int multi_hop_opportunities,
 (select count(*) from intros where requester_user_id=auth.uid())::int introductions_requested,
 (select count(*) from intros where requester_user_id=auth.uid() and status='accepted')::int introductions_accepted,
 (select count(*) from intros where target_user_id=auth.uid() and status='pending')::int introductions_waiting,
 (select count(*) from intros where status='declined')::int introductions_declined)
select jsonb_build_object('days',(select d from cfg),'activeNetworks',active_networks,'acceptedBridges',accepted_bridges,'discoverySearches',discovery_searches,'opportunitiesFound',opportunities_found,'multiHopOpportunities',multi_hop_opportunities,'introductionsRequested',introductions_requested,'introductionsAccepted',introductions_accepted,'introductionsWaiting',introductions_waiting,'introductionsDeclined',introductions_declined,'acceptanceRate',case when introductions_requested>0 then round((introductions_accepted::numeric/introductions_requested)*100) else 0 end,'activationStage',case when active_networks<2 then 'multi_network' when accepted_bridges=0 then 'bridge' when discovery_searches=0 then 'discover' when introductions_requested=0 then 'introduce' when introductions_accepted=0 then 'consent' else 'proven' end) from vals;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_network_umbrella_affiliations()
 RETURNS TABLE(id uuid, network_id uuid, network_name character varying, vertical_kind character varying, umbrella_id uuid, umbrella_name character varying, umbrella_slug character varying, relationship_type character varying, status character varying, context_label character varying, direction character varying, can_review boolean, can_suspend boolean, can_revoke boolean, passport_slug character varying, passport_tagline character varying, passport_summary character varying, passport_location character varying, passport_verification character varying, requested_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with visible as (
  select a.*,
   public.is_network_admin(a.network_id) as network_admin,
   public.is_federation_umbrella_admin(a.umbrella_id) as umbrella_admin
  from public.network_umbrella_affiliations a
  where public.is_network_admin(a.network_id) or public.is_federation_umbrella_admin(a.umbrella_id)
 )
 select a.id,a.network_id,n.name,n.vertical_kind,a.umbrella_id,u.name,u.slug,a.relationship_type,a.status,a.context_label,
  case when a.network_admin and a.umbrella_admin then 'both' when a.umbrella_admin then 'umbrella' else 'network' end::varchar,
  (a.umbrella_admin and a.status='requested'),(a.umbrella_admin and a.status='approved'),((a.network_admin or a.umbrella_admin) and a.status in ('requested','approved','suspended')),
  case when p.visibility in ('federation','public') then p.public_slug else '' end::varchar,
  case when p.visibility in ('federation','public') then p.tagline else '' end::varchar,
  case when p.visibility in ('federation','public') then p.summary else '' end::varchar,
  case when p.visibility in ('federation','public') then p.location_label else '' end::varchar,
  case when p.visibility in ('federation','public') then p.verification_state else 'self_declared' end::varchar,a.created_at,a.updated_at
 from visible a
 join public.networks n on n.id=a.network_id
 join public.federation_umbrellas u on u.id=a.umbrella_id
 join public.network_passports p on p.network_id=a.network_id
 order by case a.status when 'requested' then 0 when 'approved' then 1 when 'suspended' then 2 else 3 end,a.updated_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_trusted_introductions()
 RETURNS TABLE(id uuid, direction character varying, source_network_name character varying, target_network_name character varying, other_name character varying, message character varying, status character varying, created_at timestamp with time zone, updated_at timestamp with time zone, can_review boolean, path_depth smallint, path_summary character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select i.id,
  case when i.target_user_id=auth.uid() then 'incoming'::varchar else 'outgoing'::varchar end,
  sn.name,tn.name,
  case
   when i.target_user_id=auth.uid() then coalesce(nullif(p.full_name,''),'A member of '||sn.name)
   when i.requester_user_id=auth.uid() and i.status='accepted' then
    case i.target_subject_kind
     when 'family' then fm.full_name
     when 'alumni' then ap.full_name
     else ne.label
    end
   else null
  end::varchar,
  i.message,i.status,i.created_at,i.updated_at,(i.target_user_id=auth.uid() and i.status='pending'),i.path_depth,i.path_summary
 from public.trusted_introduction_requests i
 join public.networks sn on sn.id=i.source_network_id
 join public.networks tn on tn.id=i.target_network_id
 left join public.profiles p on p.id=i.requester_user_id
 left join public.network_entities ne on i.target_subject_kind='entity' and ne.id=i.target_ref_id
 left join public.alumni_profiles ap on i.target_subject_kind='alumni' and ap.id=i.target_ref_id
 left join public.family_members fm on i.target_subject_kind='family' and fm.id=i.target_ref_id
 where auth.uid() in(i.requester_user_id,i.target_user_id)
 order by i.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_umbrella_runtime_summaries()
 RETURNS TABLE(umbrella_id uuid, name character varying, slug character varying, umbrella_type character varying, summary character varying, location_label character varying, role character varying, approved_networks bigint, requested_networks bigint, suspended_networks bigint, visible_passport_networks bigint, public_passport_networks bigint, vertical_count bigint, capability_count bigint, scope_count bigint, profile_freshness_pct integer, health_score integer, health character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with mine as (
  select u.*,a.role
  from public.federation_umbrellas u
  join public.federation_umbrella_admins a on a.umbrella_id=u.id
  where a.user_id=auth.uid() and a.status='active' and u.status='active'
 ), agg as (
  select m.id as umbrella_id,
   count(distinct f.id) filter(where f.status='approved') as approved_networks,
   count(distinct f.id) filter(where f.status='requested') as requested_networks,
   count(distinct f.id) filter(where f.status='suspended') as suspended_networks,
   count(distinct f.id) filter(where f.status='approved' and p.visibility in ('federation','public')) as visible_passport_networks,
   count(distinct f.id) filter(where f.status='approved' and p.visibility='public') as public_passport_networks,
   count(distinct n.vertical_kind) filter(where f.status='approved') as vertical_count,
   count(distinct cap.value) filter(where f.status='approved' and p.visibility in ('federation','public')) as capability_count,
   count(distinct scp.value) filter(where f.status='approved' and p.visibility in ('federation','public')) as scope_count,
   count(distinct f.id) filter(where f.status='approved' and p.visibility in ('federation','public') and p.updated_at>=now()-interval '180 days') as fresh_passports
  from mine m
  left join public.network_umbrella_affiliations f on f.umbrella_id=m.id
  left join public.networks n on n.id=f.network_id
  left join public.network_passports p on p.network_id=f.network_id
  left join lateral unnest(case when p.visibility in ('federation','public') then p.capabilities else '{}'::text[] end) cap(value) on true
  left join lateral unnest(case when p.visibility in ('federation','public') then p.participation_scopes else '{}'::text[] end) scp(value) on true
  group by m.id
 ), normalized as (
  select m.*,coalesce(a.approved_networks,0) approved_networks,coalesce(a.requested_networks,0) requested_networks,coalesce(a.suspended_networks,0) suspended_networks,
   coalesce(a.visible_passport_networks,0) visible_passport_networks,coalesce(a.public_passport_networks,0) public_passport_networks,
   coalesce(a.vertical_count,0) vertical_count,coalesce(a.capability_count,0) capability_count,coalesce(a.scope_count,0) scope_count,
   case when coalesce(a.approved_networks,0)=0 then 0 else round(100.0*coalesce(a.fresh_passports,0)/a.approved_networks)::int end as profile_freshness_pct
  from mine m left join agg a on a.umbrella_id=m.id
 ), scored as (
  select n.*,
   least(100,greatest(0,round(
    (case when n.approved_networks=0 then 0 else least(100,n.approved_networks*12) end)*0.30 +
    (case when n.approved_networks=0 then 0 else 100.0*n.visible_passport_networks/n.approved_networks end)*0.30 +
    least(100,n.vertical_count*22)*0.15 +
    n.profile_freshness_pct*0.15 +
    (case when n.requested_networks=0 then 100 else greatest(0,100-n.requested_networks*15) end)*0.10
   )::int)) as health_score
  from normalized n
 )
 select s.id,s.name,s.slug,s.umbrella_type,s.summary,s.location_label,s.role,
  s.approved_networks,s.requested_networks,s.suspended_networks,s.visible_passport_networks,s.public_passport_networks,
  s.vertical_count,s.capability_count,s.scope_count,s.profile_freshness_pct,s.health_score,
  (case when s.health_score>=75 then 'ready' when s.health_score>=45 then 'watch' else 'setup' end)::varchar
 from scored s order by s.name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_umbrella_network_participants(p_umbrella_id uuid)
 RETURNS TABLE(affiliation_id uuid, network_id uuid, network_name character varying, vertical_kind character varying, relationship_type character varying, context_label character varying, passport_visible boolean, passport_slug character varying, passport_visibility character varying, passport_tagline character varying, passport_summary character varying, passport_location character varying, passport_established character varying, passport_external_url character varying, passport_capabilities text[], passport_scopes text[], passport_verification character varying, directory_discoverable boolean, passport_updated_at timestamp with time zone, affiliation_updated_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if not public.is_federation_umbrella_admin(p_umbrella_id) then raise exception 'Umbrella administrator access required.' using errcode='42501'; end if;
 return query
 select f.id,n.id,n.name,n.vertical_kind,f.relationship_type,f.context_label,
  (p.visibility in ('federation','public')),
  case when p.visibility in ('federation','public') then p.public_slug else '' end::varchar,
  case when p.visibility in ('federation','public') then p.visibility else 'private' end::varchar,
  case when p.visibility in ('federation','public') then p.tagline else '' end::varchar,
  case when p.visibility in ('federation','public') then p.summary else '' end::varchar,
  case when p.visibility in ('federation','public') then p.location_label else '' end::varchar,
  case when p.visibility in ('federation','public') then p.established_label else '' end::varchar,
  case when p.visibility in ('federation','public') then p.external_url else '' end::varchar,
  case when p.visibility in ('federation','public') then p.capabilities else '{}'::text[] end,
  case when p.visibility in ('federation','public') then p.participation_scopes else '{}'::text[] end,
  case when p.visibility in ('federation','public') then p.verification_state else 'self_declared' end::varchar,
  case when p.visibility in ('federation','public') then p.directory_discoverable else false end,
  case when p.visibility in ('federation','public') then p.updated_at else null end,
  f.updated_at
 from public.network_umbrella_affiliations f
 join public.networks n on n.id=f.network_id
 left join public.network_passports p on p.network_id=f.network_id
 where f.umbrella_id=p_umbrella_id and f.status='approved'
 order by n.name;
end $function$
;

CREATE OR REPLACE FUNCTION public.is_federation_umbrella_admin(p_umbrella_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select auth.uid() is not null and exists(
  select 1 from public.federation_umbrella_admins a
  where a.umbrella_id=p_umbrella_id and a.user_id=auth.uid() and a.status='active'
 );
$function$
;

CREATE OR REPLACE FUNCTION public.record_network_effect_event(p_source_network_id uuid, p_bridge_id uuid, p_event_type text, p_event_count integer DEFAULT 1)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if auth.uid() is null then raise exception 'Authentication is required.' using errcode='42501'; end if;
 if p_source_network_id is not null and not public.is_network_member(p_source_network_id) then raise exception 'Source network membership is required.' using errcode='42501'; end if;
 if p_event_type not in('discovery_search','discovery_opportunity','introduction_requested','introduction_accepted','introduction_declined') then raise exception 'Unsupported network effect event.' using errcode='22023'; end if;
 insert into public.network_effect_events(actor_user_id,source_network_id,bridge_id,event_type,event_count)
 values(auth.uid(),p_source_network_id,p_bridge_id,p_event_type,greatest(1,least(coalesce(p_event_count,1),1000)));
end $function$
;

CREATE OR REPLACE FUNCTION public.request_network_umbrella_affiliation(p_network_id uuid, p_umbrella_slug text, p_relationship_type text DEFAULT 'member'::text, p_context_label text DEFAULT ''::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid:=auth.uid(); u public.federation_umbrellas%rowtype; p public.network_passports%rowtype; existing public.network_umbrella_affiliations%rowtype; rid uuid;
begin
 if uid is null or not public.is_network_admin(p_network_id) then raise exception 'Network owner/admin access required.' using errcode='42501'; end if;
 if p_relationship_type not in ('member','chapter','affiliate','constituent','franchisee','partner','other') then raise exception 'Unsupported affiliation relationship.'; end if;
 if length(trim(coalesce(p_context_label,'')))>160 then raise exception 'Affiliation context is too long.'; end if;
 select * into u from public.federation_umbrellas where slug=lower(trim(p_umbrella_slug)) and status='active';
 if u.id is null then raise exception 'Umbrella not found.' using errcode='P0002'; end if;
 select * into p from public.network_passports where network_id=p_network_id;
 if p.network_id is null or p.visibility not in ('federation','public') then raise exception 'Set the Network Passport visibility to Federation or Public before requesting affiliation.' using errcode='22023'; end if;
 select * into existing from public.network_umbrella_affiliations where network_id=p_network_id and umbrella_id=u.id and relationship_type=p_relationship_type;
 if existing.id is not null and existing.status='approved' then raise exception 'This affiliation is already approved.' using errcode='23505'; end if;
 if existing.id is null then
  insert into public.network_umbrella_affiliations(network_id,umbrella_id,relationship_type,status,context_label,requested_by)
  values(p_network_id,u.id,p_relationship_type,'requested',trim(coalesce(p_context_label,'')),uid) returning id into rid;
 else
  update public.network_umbrella_affiliations set status='requested',context_label=trim(coalesce(p_context_label,'')),requested_by=uid,reviewed_by=null,reviewed_at=null,suspended_by=null,suspended_at=null,revoked_by=null,revoked_at=null,updated_at=now() where id=existing.id returning id into rid;
 end if;
 insert into public.audit_log(actor_id,action,details) values(uid,'network_umbrella_affiliation_requested',jsonb_build_object('affiliation_id',rid,'network_id',p_network_id,'umbrella_id',u.id,'relationship_type',p_relationship_type));
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.request_trusted_introduction(p_candidate_id uuid, p_message text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare c public.cross_network_discovery_candidates%rowtype;rid uuid;msg text:=trim(coalesce(p_message,''));valid_edges integer;
begin
 select * into c from public.cross_network_discovery_candidates where id=p_candidate_id and requester_user_id=auth.uid() and expires_at>now();
 if c.id is null then raise exception 'Discovery result expired or is unavailable.' using errcode='P0002';end if;
 if length(msg)<3 then raise exception 'Add a short reason for the introduction.' using errcode='22023';end if;
 select count(*) into valid_edges from public.network_trust_bridges b
 where b.id=any(c.path_bridge_ids) and b.status='accepted'
  and coalesce((b.capabilities->>'introductions')::boolean,false)
  and (c.path_depth=1 or coalesce((b.capabilities->>'pathTraversal')::boolean,false));
 if valid_edges<>cardinality(c.path_bridge_ids) then raise exception 'This trusted path no longer permits introductions.' using errcode='42501';end if;
 insert into public.trusted_introduction_requests(candidate_id,bridge_id,source_network_id,target_network_id,requester_user_id,target_user_id,target_entity_id,message,path_depth,path_bridge_ids,path_summary,target_subject_kind,target_ref_id)
 values(c.id,c.bridge_id,c.source_network_id,c.target_network_id,auth.uid(),c.target_user_id,c.target_entity_id,msg,c.path_depth,c.path_bridge_ids,c.path_summary,c.target_subject_kind,c.target_ref_id)
 returning id into rid;
 insert into public.network_effect_events(actor_user_id,source_network_id,bridge_id,event_type) values(auth.uid(),c.source_network_id,c.bridge_id,'introduction_requested');
 insert into public.audit_log(network_id,actor_id,action,details) values(c.source_network_id,auth.uid(),'cross_network_introduction_requested',jsonb_build_object('introduction_id',rid,'bridge_id',c.bridge_id,'target_network_id',c.target_network_id,'path_depth',c.path_depth,'target_subject_kind',c.target_subject_kind));
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.review_network_umbrella_affiliation(p_affiliation_id uuid, p_approve boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.network_umbrella_affiliations%rowtype;
begin
 select * into a from public.network_umbrella_affiliations where id=p_affiliation_id;
 if a.id is null then raise exception 'Affiliation request not found.' using errcode='P0002'; end if;
 if a.status<>'requested' then raise exception 'Only requested affiliations can be reviewed.'; end if;
 if not public.is_federation_umbrella_admin(a.umbrella_id) then raise exception 'Umbrella administrator access required.' using errcode='42501'; end if;
 update public.network_umbrella_affiliations set status=case when p_approve then 'approved' else 'declined' end,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=a.id;
 insert into public.audit_log(actor_id,action,details) values(auth.uid(),case when p_approve then 'network_umbrella_affiliation_approved' else 'network_umbrella_affiliation_declined' end,jsonb_build_object('affiliation_id',a.id,'network_id',a.network_id,'umbrella_id',a.umbrella_id));
end $function$
;

CREATE OR REPLACE FUNCTION public.review_trusted_introduction(p_introduction_id uuid, p_accept boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare x public.trusted_introduction_requests%rowtype;
begin
 select * into x from public.trusted_introduction_requests where id=p_introduction_id;
 if x.id is null then raise exception 'Introduction request not found.' using errcode='P0002';end if;
 if x.target_user_id<>auth.uid() then raise exception 'Only the requested person can review this introduction.' using errcode='42501';end if;
 if x.status<>'pending' then raise exception 'Only pending introduction requests can be reviewed.' using errcode='22023';end if;
 update public.trusted_introduction_requests set status=case when p_accept then 'accepted' else 'declined' end,reviewed_at=now(),updated_at=now() where id=x.id;
 insert into public.network_effect_events(actor_user_id,source_network_id,bridge_id,event_type) values(auth.uid(),x.source_network_id,x.bridge_id,case when p_accept then 'introduction_accepted' else 'introduction_declined' end);
 insert into public.audit_log(network_id,actor_id,action,details) values(x.target_network_id,auth.uid(),case when p_accept then 'cross_network_introduction_accepted' else 'cross_network_introduction_declined' end,jsonb_build_object('introduction_id',x.id,'bridge_id',x.bridge_id));
end $function$
;

CREATE OR REPLACE FUNCTION public.revoke_network_umbrella_affiliation(p_affiliation_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.network_umbrella_affiliations%rowtype;
begin
 select * into a from public.network_umbrella_affiliations where id=p_affiliation_id;
 if a.id is null then raise exception 'Affiliation not found.' using errcode='P0002'; end if;
 if a.status not in ('requested','approved','suspended') then raise exception 'This affiliation cannot be revoked.'; end if;
 if not public.is_network_admin(a.network_id) and not public.is_federation_umbrella_admin(a.umbrella_id) then raise exception 'Network or umbrella administrator access required.' using errcode='42501'; end if;
 update public.network_umbrella_affiliations set status='revoked',revoked_by=auth.uid(),revoked_at=now(),updated_at=now() where id=a.id;
 insert into public.audit_log(actor_id,action,details) values(auth.uid(),'network_umbrella_affiliation_revoked',jsonb_build_object('affiliation_id',a.id,'network_id',a.network_id,'umbrella_id',a.umbrella_id));
end $function$
;

CREATE OR REPLACE FUNCTION public.search_federation_umbrellas(p_query text DEFAULT ''::text)
 RETURNS TABLE(id uuid, name character varying, slug character varying, umbrella_type character varying, summary character varying, location_label character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select u.id,u.name,u.slug,u.umbrella_type,u.summary,u.location_label
 from public.federation_umbrellas u
 where auth.uid() is not null and u.status='active'
   and (trim(coalesce(p_query,''))='' or u.name ilike '%'||trim(p_query)||'%' or u.slug ilike '%'||trim(p_query)||'%')
 order by case when lower(u.slug)=lower(trim(coalesce(p_query,''))) then 0 else 1 end,u.name
 limit 20;
$function$
;

CREATE OR REPLACE FUNCTION public.suspend_network_umbrella_affiliation(p_affiliation_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare a public.network_umbrella_affiliations%rowtype;
begin
 select * into a from public.network_umbrella_affiliations where id=p_affiliation_id;
 if a.id is null then raise exception 'Affiliation not found.' using errcode='P0002'; end if;
 if a.status<>'approved' then raise exception 'Only approved affiliations can be suspended.'; end if;
 if not public.is_federation_umbrella_admin(a.umbrella_id) then raise exception 'Umbrella administrator access required.' using errcode='42501'; end if;
 update public.network_umbrella_affiliations set status='suspended',suspended_by=auth.uid(),suspended_at=now(),updated_at=now() where id=a.id;
 insert into public.audit_log(actor_id,action,details) values(auth.uid(),'network_umbrella_affiliation_suspended',jsonb_build_object('affiliation_id',a.id));
end $function$
;

SET check_function_bodies = on;
