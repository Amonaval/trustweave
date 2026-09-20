-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.accept_alumni_invitation(p_token text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid; v_profile uuid; v_existing uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
 select network_id,profile_id into v_network,v_profile from public.alumni_invitations where token::text=p_token and status='active' and expires_at>now() for update;
 if v_network is null then raise exception 'Invitation is invalid or expired.'; end if;
 select id into v_existing from public.alumni_profiles where network_id=v_network and claimed_by=auth.uid();
 if v_existing is not null and v_existing<>v_profile then raise exception 'Your account is already linked to another alumni profile in this network.'; end if;
 if exists(select 1 from public.alumni_profiles where id=v_profile and claimed_by is not null and claimed_by<>auth.uid()) then raise exception 'This profile has already been claimed.'; end if;
 update public.alumni_profiles set claimed_by=auth.uid(),updated_at=now() where id=v_profile;
 insert into public.network_memberships(network_id,user_id,role,status) values(v_network,auth.uid(),'member','active') on conflict(network_id,user_id) do update set status='active';
 update public.profiles set active_network_id=v_network,updated_at=now() where id=auth.uid();
 update public.alumni_invitations set status='accepted',accepted_at=now() where token::text=p_token;
 return v_network;
end $function$
;

CREATE OR REPLACE FUNCTION public.admin_upsert_alumni_profile(p_full_name text, p_email text DEFAULT NULL::text, p_graduation_year integer DEFAULT NULL::integer, p_program text DEFAULT NULL::text, p_department text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_job_title text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_id uuid;
begin
 if not public.is_network_admin(v_network) or (select vertical_kind from public.networks where id=v_network)<>'alumni' then raise exception 'Alumni admin access required.' using errcode='42501'; end if;
 if p_email is not null and trim(p_email)<>'' then select id into v_id from public.alumni_profiles where network_id=v_network and lower(email)=lower(trim(p_email)); end if;
 if v_id is null then
  insert into public.alumni_profiles(network_id,full_name,email,graduation_year,program,department,city,company,job_title) values(v_network,trim(p_full_name),nullif(lower(trim(p_email)),''),p_graduation_year,nullif(trim(p_program),''),nullif(trim(p_department),''),nullif(trim(p_city),''),nullif(trim(p_company),''),nullif(trim(p_job_title),'')) returning id into v_id;
 else
  update public.alumni_profiles set full_name=trim(p_full_name),graduation_year=coalesce(p_graduation_year,graduation_year),program=coalesce(nullif(trim(p_program),''),program),department=coalesce(nullif(trim(p_department),''),department),city=coalesce(nullif(trim(p_city),''),city),company=coalesce(nullif(trim(p_company),''),company),job_title=coalesce(nullif(trim(p_job_title),''),job_title),updated_at=now() where id=v_id;
 end if;
 return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.claim_alumni_profile_by_verified_email(p_profile_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid; v_email text; v_existing uuid;
begin
 select ap.network_id,lower(ap.email) into v_network,v_email from public.alumni_profiles ap where ap.id=p_profile_id and ap.claimed_by is null;
 if v_network is null then raise exception 'Profile is not available to claim.'; end if;
 if v_email is distinct from (select lower(email) from auth.users where id=auth.uid()) then raise exception 'Verified email does not match.' using errcode='42501'; end if;
 select id into v_existing from public.alumni_profiles where network_id=v_network and claimed_by=auth.uid();
 if v_existing is not null and v_existing<>p_profile_id then raise exception 'Your account is already linked to another alumni profile in this network.'; end if;
 update public.alumni_profiles set claimed_by=auth.uid(),updated_at=now() where id=p_profile_id;
 insert into public.network_memberships(network_id,user_id,role,status) values(v_network,auth.uid(),'member','active') on conflict(network_id,user_id) do update set status='active';
 update public.profiles set active_network_id=v_network,updated_at=now() where id=auth.uid();
 return v_network;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_alumni_connection(p_related_profile_id uuid, p_relation_kind character varying DEFAULT 'professional_connection'::character varying)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_me uuid; v_id uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
 if (select vertical_kind from public.networks where id=v_network)<>'alumni' then raise exception 'Active network is not Alumni.'; end if;
 select id into v_me from public.alumni_profiles where network_id=v_network and claimed_by=auth.uid();
 if v_me is null then raise exception 'Complete or claim your Alumni profile first.' using errcode='42501'; end if;
 if p_related_profile_id=v_me then raise exception 'You cannot connect to your own profile.' using errcode='22023'; end if;
 if p_relation_kind not in ('batchmate','classmate','mentor','mentee','professional_connection') then raise exception 'Invalid Alumni relationship.' using errcode='22023'; end if;
 if not exists(select 1 from public.alumni_profiles where id=p_related_profile_id and network_id=v_network and visibility='members') then raise exception 'Alumni profile is unavailable.'; end if;
 insert into public.alumni_connections(network_id,person_id,related_person_id,relation_kind,created_by)
 values(v_network,v_me,p_related_profile_id,p_relation_kind,auth.uid())
 on conflict(network_id,person_id,related_person_id,relation_kind) do update set created_by=excluded.created_by
 returning id into v_id;
 return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_alumni_invitation(p_profile_id uuid, p_recipient_hint text DEFAULT NULL::text, p_expires_days integer DEFAULT 30)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_token uuid;
begin
 if not public.is_network_admin(v_network) then raise exception 'Admin access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.alumni_profiles where id=p_profile_id and network_id=v_network) then raise exception 'Profile not found.'; end if;
 insert into public.alumni_invitations(network_id,profile_id,recipient_hint,expires_at,created_by) values(v_network,p_profile_id,p_recipient_hint,now()+(greatest(1,least(coalesce(p_expires_days,30),90))||' days')::interval,auth.uid()) returning token into v_token;
 return v_token::text;
end $function$
;

CREATE OR REPLACE FUNCTION public.create_alumni_network(p_name text, p_institution text, p_description text DEFAULT ''::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid; v_slug text; v_base text;
begin
  if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501'; end if;
  if length(trim(coalesce(p_name,'')))<2 then raise exception 'Network name is required.'; end if;
  if length(trim(coalesce(p_institution,'')))<2 then raise exception 'Institution name is required.'; end if;
  v_base:=lower(regexp_replace(trim(p_name),'[^a-zA-Z0-9]+','-','g')); v_base:=trim(both '-' from v_base);
  if v_base='' then v_base:='alumni-network'; end if;
  v_slug:=v_base;
  while exists(select 1 from public.networks where slug=v_slug) loop v_slug:=v_base||'-'||substr(gen_random_uuid()::text,1,6); end loop;
  insert into public.networks(name,slug,created_by,vertical_kind) values(trim(p_name),v_slug,auth.uid(),'alumni') returning id into v_id;
  insert into public.network_memberships(network_id,user_id,role,status) values(v_id,auth.uid(),'owner','active');
  insert into public.network_settings(network_id,id,name,description,entity_label,entity_label_plural,level_label,level_label_plural,parent_label,child_label,peer_label,network_template,vertical_kind)
  values(v_id,'network',trim(p_name),coalesce(p_description,''),'Alumni','Alumni','Batch Year','Batch Years','Senior','Junior','Classmate','alumni','alumni');
  insert into public.alumni_network_settings(network_id,institution_name) values(v_id,trim(p_institution));
  update public.profiles set active_network_id=v_id,updated_at=now() where id=auth.uid();
  insert into public.audit_log(network_id,actor_id,action,details) values(v_id,auth.uid(),'alumni_network_created',jsonb_build_object('institution',trim(p_institution)));
  insert into public.alumni_profiles(network_id,full_name,email,claimed_by)
  select v_id,coalesce(nullif(trim(p.full_name),''),split_part(coalesce(u.email,'Alumni'),'@',1)),lower(u.email),auth.uid()
  from public.profiles p join auth.users u on u.id=p.id where p.id=auth.uid();
  return v_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.g7_sync_alumni_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_entity uuid; v_institution text;
begin
 if TG_OP='DELETE' then
   delete from public.network_entities where network_id=old.network_id and kind='person' and external_ref=old.id;
   return old;
 end if;
 insert into public.network_entities(network_id,kind,external_ref,owner_user_id,label,metadata,visibility)
 values(new.network_id,'person',new.id,new.claimed_by,new.full_name,jsonb_build_object('vertical','alumni'),new.visibility)
 on conflict(network_id,kind,external_ref) where external_ref is not null do update set owner_user_id=excluded.owner_user_id,label=excluded.label,visibility=excluded.visibility,updated_at=now()
 returning id into v_entity;
 select coalesce(ans.institution_name,n.name) into v_institution from public.networks n left join public.alumni_network_settings ans on ans.network_id=n.id where n.id=new.network_id;
 perform public.g7_set_entity_affiliation(v_entity,new.network_id,'institution',v_institution);
 perform public.g7_set_entity_affiliation(v_entity,new.network_id,'department',new.department);
 perform public.g7_set_entity_affiliation(v_entity,new.network_id,'batch',case when new.graduation_year is null then null else new.graduation_year::text end);
 perform public.g7_set_entity_affiliation(v_entity,new.network_id,'program',new.program);
 perform public.g7_set_entity_affiliation(v_entity,new.network_id,'city',new.city);
 perform public.g7_set_entity_affiliation(v_entity,new.network_id,'company',new.company);
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.g7_sync_alumni_profile_row(p_profile uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.alumni_profiles%rowtype; v_entity uuid; v_institution text;
begin
 select * into r from public.alumni_profiles where id=p_profile; if not found then return; end if;
 insert into public.network_entities(network_id,kind,external_ref,owner_user_id,label,metadata,visibility)
 values(r.network_id,'person',r.id,r.claimed_by,r.full_name,jsonb_build_object('vertical','alumni'),r.visibility)
 on conflict(network_id,kind,external_ref) where external_ref is not null do update set owner_user_id=excluded.owner_user_id,label=excluded.label,visibility=excluded.visibility,updated_at=now()
 returning id into v_entity;
 select coalesce(ans.institution_name,n.name) into v_institution from public.networks n left join public.alumni_network_settings ans on ans.network_id=n.id where n.id=r.network_id;
 perform public.g7_set_entity_affiliation(v_entity,r.network_id,'institution',v_institution);
 perform public.g7_set_entity_affiliation(v_entity,r.network_id,'department',r.department);
 perform public.g7_set_entity_affiliation(v_entity,r.network_id,'batch',case when r.graduation_year is null then null else r.graduation_year::text end);
 perform public.g7_set_entity_affiliation(v_entity,r.network_id,'program',r.program);
 perform public.g7_set_entity_affiliation(v_entity,r.network_id,'city',r.city);
 perform public.g7_set_entity_affiliation(v_entity,r.network_id,'company',r.company);
end $function$
;

CREATE OR REPLACE FUNCTION public.get_alumni_directory(p_query text DEFAULT NULL::text, p_year integer DEFAULT NULL::integer, p_program text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, full_name character varying, email text, graduation_year integer, program character varying, department character varying, city character varying, company character varying, job_title character varying, bio text, visibility character varying, claimed boolean, is_me boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select ap.id,ap.full_name,
    case when ap.claimed_by=auth.uid() or public.is_network_admin(ap.network_id) then ap.email else null end,
    ap.graduation_year,ap.program,ap.department,ap.city,ap.company,ap.job_title,ap.bio,ap.visibility,
    ap.claimed_by is not null,ap.claimed_by=auth.uid()
  from public.alumni_profiles ap
  where ap.network_id=public.current_network_id()
    and public.is_network_member(ap.network_id)
    and (ap.visibility='members' or ap.claimed_by=auth.uid() or public.is_network_admin(ap.network_id))
    and (p_query is null or trim(p_query)='' or ap.full_name ilike '%'||trim(p_query)||'%' or coalesce(ap.city,'') ilike '%'||trim(p_query)||'%' or coalesce(ap.company,'') ilike '%'||trim(p_query)||'%')
    and (p_year is null or ap.graduation_year=p_year)
    and (p_program is null or trim(p_program)='' or ap.program=p_program)
  order by ap.graduation_year nulls last,ap.full_name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_alumni_network_overview()
 RETURNS TABLE(institution_name character varying, profile_count bigint, claimed_count bigint, batch_count bigint, program_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select coalesce(ans.institution_name,n.name),
   (select count(*) from public.alumni_profiles ap where ap.network_id=n.id),
   (select count(*) from public.alumni_profiles ap where ap.network_id=n.id and ap.claimed_by is not null),
   (select count(distinct ap.graduation_year) from public.alumni_profiles ap where ap.network_id=n.id and ap.graduation_year is not null),
   (select count(distinct ap.program) from public.alumni_profiles ap where ap.network_id=n.id and nullif(trim(ap.program),'') is not null)
 from public.networks n left join public.alumni_network_settings ans on ans.network_id=n.id
 where n.id=public.current_network_id() and n.vertical_kind='alumni' and public.is_network_member(n.id);
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_alumni_connections()
 RETURNS TABLE(connection_id uuid, related_profile_id uuid, full_name character varying, graduation_year integer, program character varying, city character varying, company character varying, job_title character varying, relation_kind character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 with mine as (select id,network_id from public.alumni_profiles where network_id=public.current_network_id() and claimed_by=auth.uid() limit 1), links as (
  select ac.id,case when ac.person_id=m.id then ac.related_person_id else ac.person_id end related_id,ac.relation_kind,m.network_id
  from public.alumni_connections ac join mine m on m.network_id=ac.network_id where ac.person_id=m.id or ac.related_person_id=m.id
 )
 select l.id,ap.id,ap.full_name,ap.graduation_year,ap.program,ap.city,ap.company,ap.job_title,l.relation_kind
 from links l join public.alumni_profiles ap on ap.id=l.related_id and ap.network_id=l.network_id
 where ap.visibility='members' or ap.claimed_by=auth.uid() or public.is_network_admin(ap.network_id)
 order by ap.full_name;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_claimable_alumni_profiles()
 RETURNS TABLE(profile_id uuid, network_id uuid, network_name character varying, full_name character varying, graduation_year integer, program character varying)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select ap.id,ap.network_id,n.name,ap.full_name,ap.graduation_year,ap.program
 from public.alumni_profiles ap join public.networks n on n.id=ap.network_id join auth.users u on u.id=auth.uid()
 where ap.claimed_by is null and ap.email is not null and lower(ap.email)=lower(u.email) and n.vertical_kind='alumni' and n.status='active';
$function$
;

CREATE OR REPLACE FUNCTION public.import_alumni_profiles(p_rows jsonb)
 RETURNS TABLE(inserted integer, updated integer, skipped integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); r jsonb; v_id uuid; v_inserted int:=0; v_updated int:=0; v_skipped int:=0;
begin
 if not public.is_network_admin(v_network) or (select vertical_kind from public.networks where id=v_network)<>'alumni' then raise exception 'Alumni admin access required.' using errcode='42501'; end if;
 if jsonb_typeof(p_rows)<>'array' or jsonb_array_length(p_rows)>1000 then raise exception 'Import must contain 1–1000 rows.'; end if;
 for r in select value from jsonb_array_elements(p_rows) loop
  if length(trim(coalesce(r->>'full_name','')))<2 then v_skipped:=v_skipped+1; continue; end if;
  v_id:=null;
  if nullif(trim(r->>'email'),'') is not null then select id into v_id from public.alumni_profiles where network_id=v_network and lower(email)=lower(trim(r->>'email')); end if;
  if v_id is null then
   insert into public.alumni_profiles(network_id,full_name,email,graduation_year,program,department,city,company,job_title)
   values(v_network,trim(r->>'full_name'),nullif(lower(trim(r->>'email')),''),nullif(r->>'graduation_year','')::integer,nullif(trim(r->>'program'),''),nullif(trim(r->>'department'),''),nullif(trim(r->>'city'),''),nullif(trim(r->>'company'),''),nullif(trim(r->>'job_title'),'')); v_inserted:=v_inserted+1;
  else
   update public.alumni_profiles set full_name=trim(r->>'full_name'),graduation_year=coalesce(nullif(r->>'graduation_year','')::integer,graduation_year),program=coalesce(nullif(trim(r->>'program'),''),program),department=coalesce(nullif(trim(r->>'department'),''),department),city=coalesce(nullif(trim(r->>'city'),''),city),company=coalesce(nullif(trim(r->>'company'),''),company),job_title=coalesce(nullif(trim(r->>'job_title'),''),job_title),updated_at=now() where id=v_id; v_updated:=v_updated+1;
  end if;
 end loop;
 return query select v_inserted,v_updated,v_skipped;
end $function$
;

CREATE OR REPLACE FUNCTION public.preview_alumni_invitation(p_token text)
 RETURNS TABLE(full_name character varying, network_name character varying, status character varying, expires_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select ap.full_name,n.name,ai.status,ai.expires_at from public.alumni_invitations ai join public.alumni_profiles ap on ap.id=ai.profile_id join public.networks n on n.id=ai.network_id where ai.token::text=p_token limit 1;
$function$
;

CREATE OR REPLACE FUNCTION public.record_organization_intelligence_query(p_question text, p_intent text, p_confidence text, p_evidence_count integer DEFAULT 0, p_matched_entity_ids text[] DEFAULT '{}'::text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();ids uuid[];
begin
 perform public.g91b_assert_organization_network(nid);
 if not exists(select 1 from public.network_memberships m where m.network_id=nid and m.user_id=auth.uid() and m.status='active') then raise exception 'Active membership required.' using errcode='42501';end if;
 if trim(coalesce(p_question,''))='' then return;end if;
 ids:=coalesce(array(select x::uuid from unnest(coalesce(p_matched_entity_ids,'{}')) x where x~*'^[0-9a-f-]{36}$' and exists(select 1 from public.network_entities e where e.id=x::uuid and e.network_id=nid)),'{}');
 insert into public.organization_intelligence_query_signals(network_id,user_id,question,intent,confidence,evidence_count,matched_entity_ids)
 values(nid,auth.uid(),left(trim(p_question),500),coalesce(nullif(trim(p_intent),''),'general'),case when p_confidence in ('high','medium','low') then p_confidence else 'low' end,greatest(0,coalesce(p_evidence_count,0)),ids);
end $function$
;

CREATE OR REPLACE FUNCTION public.upsert_my_alumni_profile(p_full_name text, p_graduation_year integer DEFAULT NULL::integer, p_program text DEFAULT NULL::text, p_department text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_job_title text DEFAULT NULL::text, p_bio text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_network uuid:=public.current_network_id(); v_id uuid;
begin
 if (select vertical_kind from public.networks where id=v_network)<>'alumni' then raise exception 'Active network is not Alumni.'; end if;
 select id into v_id from public.alumni_profiles where network_id=v_network and claimed_by=auth.uid();
 if v_id is null then
   insert into public.alumni_profiles(network_id,full_name,email,graduation_year,program,department,city,company,job_title,bio,claimed_by)
   select v_network,trim(p_full_name),lower(u.email),p_graduation_year,nullif(trim(p_program),''),nullif(trim(p_department),''),nullif(trim(p_city),''),nullif(trim(p_company),''),nullif(trim(p_job_title),''),nullif(trim(p_bio),''),auth.uid() from auth.users u where u.id=auth.uid() returning id into v_id;
 else
   update public.alumni_profiles set full_name=trim(p_full_name),graduation_year=p_graduation_year,program=nullif(trim(p_program),''),department=nullif(trim(p_department),''),city=nullif(trim(p_city),''),company=nullif(trim(p_company),''),job_title=nullif(trim(p_job_title),''),bio=nullif(trim(p_bio),''),updated_at=now() where id=v_id;
 end if;
 return v_id;
end $function$
;

SET check_function_bodies = on;
