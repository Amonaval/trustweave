-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.hs1_accept_resident_invitation(p_token uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare inv public.hs_resident_invitations%rowtype;mail text;nid uuid;begin
 if auth.uid() is null then raise exception 'Sign in required.' using errcode='42501';end if;
 select * into inv from public.hs_resident_invitations where token=p_token for update;if not found then raise exception 'Invitation not found.' using errcode='22023';end if;
 if inv.status<>'pending' or inv.expires_at<now() then raise exception 'Invitation is no longer active.' using errcode='22023';end if;
 mail:=lower(trim(coalesce(auth.jwt()->>'email','')));if mail='' or mail<>lower(trim(inv.email)) then raise exception 'Sign in with the invited email address.' using errcode='42501';end if;nid:=inv.network_id;
 if exists(select 1 from public.network_entities e where e.network_id=nid and e.owner_user_id=auth.uid() and e.id<>inv.person_entity_id) then raise exception 'Your account is already linked to another resident profile in this society.' using errcode='23505';end if;
 update public.network_entities set owner_user_id=auth.uid(),updated_at=now() where id=inv.person_entity_id and network_id=nid and (owner_user_id is null or owner_user_id=auth.uid());if not found then raise exception 'Resident profile is already claimed.' using errcode='23505';end if;
 insert into public.network_memberships(network_id,user_id,role,status) values(nid,auth.uid(),'member','active') on conflict(network_id,user_id) do update set status='active';
 update public.profiles set active_network_id=nid,updated_at=now() where id=auth.uid();update public.hs_resident_invitations set status='claimed',claimed_at=now() where id=inv.id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs1_resident_invitation_claimed',jsonb_build_object('invitation_id',inv.id,'person_entity_id',inv.person_entity_id));return nid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_allocate_parking(p_slot_id uuid, p_unit_id uuid, p_vehicle_id uuid DEFAULT NULL::uuid, p_starts_on date DEFAULT CURRENT_DATE, p_ends_on date DEFAULT NULL::date, p_allocation_type text DEFAULT 'assigned'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();rid uuid;begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;if p_ends_on is null then update public.hs_parking_allocations set ends_on=greatest(starts_on,p_starts_on-1) where network_id=nid and parking_slot_id=p_slot_id and ends_on is null;end if;insert into public.hs_parking_allocations(network_id,parking_slot_id,vehicle_id,unit_entity_id,starts_on,ends_on,allocation_type,created_by) values(nid,p_slot_id,p_vehicle_id,p_unit_id,coalesce(p_starts_on,current_date),p_ends_on,p_allocation_type,auth.uid()) returning id into rid;update public.hs_parking_slots set status=case when p_ends_on is null then 'allocated' else status end,updated_at=now() where id=p_slot_id and network_id=nid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_assert_network()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();begin if nid is null or not public.is_network_member(nid) then raise exception 'Housing society membership required.' using errcode='42501';end if;if coalesce((select vertical_kind from public.networks where id=nid),'')<>'housing-society' then raise exception 'Active network is not a housing society.' using errcode='22023';end if;return nid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_create_resident_invitation(p_person_entity_id uuid, p_unit_entity_id uuid DEFAULT NULL::uuid, p_email text DEFAULT NULL::text, p_expires_days integer DEFAULT 14)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();rid uuid;mail text;begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;select coalesce(nullif(trim(p_email),''),nullif(trim(metadata->>'email'),'')) into mail from public.network_entities where id=p_person_entity_id and network_id=nid and kind='person';if mail is null then raise exception 'Resident email required for claiming.';end if;update public.network_entities set metadata=jsonb_set(metadata,'{email}',to_jsonb(lower(mail)),true),updated_at=now() where id=p_person_entity_id and network_id=nid;insert into public.hs_resident_invitations(network_id,person_entity_id,unit_entity_id,email,status,expires_at,created_by) values(nid,p_person_entity_id,p_unit_entity_id,lower(mail),'pending',now()+make_interval(days=>greatest(1,least(coalesce(p_expires_days,14),90))),auth.uid()) on conflict(network_id,person_entity_id) do update set unit_entity_id=excluded.unit_entity_id,email=excluded.email,token=gen_random_uuid(),status='pending',expires_at=excluded.expires_at,created_by=auth.uid(),created_at=now(),claimed_at=null returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_get_import_template()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ begin perform public.hs1_assert_network();return jsonb_build_object('required',jsonb_build_array('unit','resident_name'),'recommended',jsonb_build_array('building','wing','floor','unit_type','occupancy_role','resident_email','phone','household','vehicle_registration','vehicle_type','parking_slot'),'aliases',jsonb_build_object('flat','unit','flat_no','unit','name','resident_name','email','resident_email','tower','building','parking','parking_slot'));end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_get_my_flat()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();pid uuid;begin
 select id into pid from public.network_entities where network_id=nid and owner_user_id=auth.uid() and kind='person' order by updated_at desc limit 1;
 if pid is null then return jsonb_build_object('claimed',false);end if;
 return jsonb_build_object('claimed',true,'personId',pid,'personLabel',(select label from public.network_entities where id=pid),
 'units',coalesce((select jsonb_agg(distinct jsonb_build_object('unitId',h.unit_entity_id,'unitLabel',u.label,'role',h.occupancy_role,'startsOn',h.starts_on,'endsOn',h.ends_on,'metadata',u.metadata)) from public.hs_unit_occupancy_history h join public.network_entities u on u.id=h.unit_entity_id where h.network_id=nid and h.subject_entity_id=pid and (h.ends_on is null or h.ends_on>=current_date)),'[]'::jsonb),
 'households',coalesce((select jsonb_agg(distinct jsonb_build_object('householdId',r.to_entity_id,'householdLabel',hh.label)) from public.network_entity_relationships r join public.network_entities hh on hh.id=r.to_entity_id where r.network_id=nid and r.from_entity_id=pid and r.relationship_type='member_of_household'),'[]'::jsonb),
 'vehicles',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'registrationNo',v.registration_no,'vehicleType',v.vehicle_type,'makeModel',v.make_model,'isEv',v.is_ev,'unitId',v.unit_entity_id)) from public.hs_vehicles v where v.network_id=nid and (v.owner_entity_id=pid or v.unit_entity_id in (select h.unit_entity_id from public.hs_unit_occupancy_history h where h.network_id=nid and h.subject_entity_id=pid and (h.ends_on is null or h.ends_on>=current_date)))),'[]'::jsonb)
 );end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_get_property_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();begin return jsonb_build_object(
 'occupancy',coalesce((select jsonb_agg(jsonb_build_object('id',h.id,'unitId',h.unit_entity_id,'unitLabel',u.label,'subjectId',h.subject_entity_id,'subjectLabel',s.label,'subjectKind',s.kind,'role',h.occupancy_role,'startsOn',h.starts_on,'endsOn',h.ends_on,'isPrimary',h.is_primary) order by u.label,h.starts_on desc) from public.hs_unit_occupancy_history h join public.network_entities u on u.id=h.unit_entity_id join public.network_entities s on s.id=h.subject_entity_id where h.network_id=nid),'[]'::jsonb),
 'parkingSlots',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'slotCode',p.slot_code,'zone',p.zone,'slotType',p.slot_type,'status',p.status) order by p.slot_code) from public.hs_parking_slots p where p.network_id=nid),'[]'::jsonb),
 'vehicles',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'unitId',v.unit_entity_id,'unitLabel',u.label,'ownerEntityId',v.owner_entity_id,'registrationNo',v.registration_no,'vehicleType',v.vehicle_type,'makeModel',v.make_model,'isEv',v.is_ev,'status',v.status) order by v.registration_no) from public.hs_vehicles v join public.network_entities u on u.id=v.unit_entity_id where v.network_id=nid),'[]'::jsonb),
 'parkingAllocations',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'slotId',a.parking_slot_id,'slotCode',p.slot_code,'vehicleId',a.vehicle_id,'registrationNo',v.registration_no,'unitId',a.unit_entity_id,'unitLabel',u.label,'startsOn',a.starts_on,'endsOn',a.ends_on,'allocationType',a.allocation_type) order by p.slot_code,a.starts_on desc) from public.hs_parking_allocations a join public.hs_parking_slots p on p.id=a.parking_slot_id join public.network_entities u on u.id=a.unit_entity_id left join public.hs_vehicles v on v.id=a.vehicle_id where a.network_id=nid),'[]'::jsonb),
 'invitations',case when public.is_network_admin(nid) then coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'personEntityId',i.person_entity_id,'personLabel',e.label,'unitEntityId',i.unit_entity_id,'email',i.email,'token',i.token,'status',case when i.status='pending' and i.expires_at<now() then 'expired' else i.status end,'expiresAt',i.expires_at) order by i.created_at desc) from public.hs_resident_invitations i join public.network_entities e on e.id=i.person_entity_id where i.network_id=nid),'[]'::jsonb) else '[]'::jsonb end
 );end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_get_resident_invitation_preview(p_token uuid)
 RETURNS TABLE(status text, society_name character varying, resident_name character varying, email text, unit_label character varying, expires_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select case when i.status<>'pending' then i.status when i.expires_at<now() then 'expired' else 'active' end,n.name,e.label,i.email,u.label,i.expires_at
 from public.hs_resident_invitations i join public.networks n on n.id=i.network_id join public.network_entities e on e.id=i.person_entity_id left join public.network_entities u on u.id=i.unit_entity_id
 where i.token=p_token and n.vertical_kind='housing-society';
$function$
;

CREATE OR REPLACE FUNCTION public.hs1_import_resident_rows(p_rows jsonb, p_file_name text DEFAULT NULL::text, p_column_mapping jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();r jsonb;unit_id uuid;person_id uuid;house_id uuid;slot_id uuid;vehicle_id uuid;batch_id uuid;i int:=0;u int:=0;sk int:=0;unit_label text;person_label text;mail text;house_label text;role text;reg text;slot text;existing boolean;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;
 if jsonb_typeof(p_rows)<>'array' then raise exception 'Rows must be an array.' using errcode='22023';end if;
 insert into public.hs_import_batches(network_id,file_name,column_mapping,row_count,status,created_by) values(nid,p_file_name,coalesce(p_column_mapping,'{}'),jsonb_array_length(p_rows),'preview',auth.uid()) returning id into batch_id;
 for r in select value from jsonb_array_elements(p_rows) loop
  unit_label:=trim(coalesce(r->>'unit',''));person_label:=trim(coalesce(r->>'resident_name',''));mail:=lower(trim(coalesce(r->>'resident_email','')));house_label:=trim(coalesce(r->>'household',''));role:=lower(trim(coalesce(r->>'occupancy_role','occupant')));reg:=upper(replace(trim(coalesce(r->>'vehicle_registration','')),' ',''));slot:=upper(trim(coalesce(r->>'parking_slot','')));
  if length(unit_label)<1 or length(person_label)<2 then sk:=sk+1;continue;end if;
  select id into unit_id from public.network_entities where network_id=nid and kind='unit' and lower(label)=lower(unit_label) order by created_at limit 1;existing:=unit_id is not null;
  if unit_id is null then insert into public.network_entities(network_id,kind,label,metadata,visibility) values(nid,'unit',unit_label,jsonb_strip_nulls(jsonb_build_object('area',nullif(r->>'area',''))),'members') returning id into unit_id;i:=i+1;else u:=u+1;end if;
  perform public.g8_set_entity_affiliations(unit_id,nid,'building',to_jsonb(coalesce(nullif(r->>'building',''),'Main Building')));if nullif(r->>'wing','') is not null then perform public.g8_set_entity_affiliations(unit_id,nid,'wing',to_jsonb(r->>'wing'));end if;if nullif(r->>'floor','') is not null then perform public.g8_set_entity_affiliations(unit_id,nid,'floor',to_jsonb(r->>'floor'));end if;if nullif(r->>'unit_type','') is not null then perform public.g8_set_entity_affiliations(unit_id,nid,'unit_type',to_jsonb(r->>'unit_type'));end if;
  select id into person_id from public.network_entities where network_id=nid and kind='person' and ((mail<>'' and lower(coalesce(metadata->>'email',''))=mail) or lower(label)=lower(person_label)) order by created_at limit 1;
  if person_id is null then insert into public.network_entities(network_id,kind,label,metadata,visibility) values(nid,'person',person_label,jsonb_strip_nulls(jsonb_build_object('email',nullif(mail,''),'phone',nullif(r->>'phone',''),'profession',nullif(r->>'profession',''),'photo_url',nullif(r->>'photo_url',''),'contact_visibility','members','profile_visibility','members')),'members') returning id into person_id;i:=i+1;else update public.network_entities set metadata=metadata||jsonb_strip_nulls(jsonb_build_object('email',nullif(mail,''),'phone',nullif(r->>'phone',''),'profession',nullif(r->>'profession',''),'photo_url',nullif(r->>'photo_url',''))),updated_at=now() where id=person_id;u:=u+1;end if;
  if house_label<>'' then select id into house_id from public.network_entities where network_id=nid and kind='household' and lower(label)=lower(house_label) order by created_at limit 1;if house_id is null then insert into public.network_entities(network_id,kind,label,metadata,visibility) values(nid,'household',house_label,'{}','members') returning id into house_id;i:=i+1;end if;insert into public.network_entity_relationships(network_id,from_entity_id,to_entity_id,relationship_type,metadata,created_by) values(nid,person_id,house_id,'member_of_household','{}',auth.uid()) on conflict(network_id,from_entity_id,to_entity_id,relationship_type) do nothing;end if;
  insert into public.network_entity_relationships(network_id,from_entity_id,to_entity_id,relationship_type,metadata,created_by) values(nid,person_id,unit_id,'resident_of','{}',auth.uid()) on conflict(network_id,from_entity_id,to_entity_id,relationship_type) do nothing;
  if role not in ('owner','co-owner','tenant','occupant') then role:='occupant';end if;perform public.g8_set_entity_affiliations(person_id,nid,'resident_type',to_jsonb(initcap(role)));perform public.g8_set_entity_affiliations(unit_id,nid,'occupancy_status',to_jsonb(case when role in ('tenant','occupant') then 'Occupied' else 'Owner Occupied' end));
  if not exists(select 1 from public.hs_unit_occupancy_history where network_id=nid and unit_entity_id=unit_id and subject_entity_id=person_id and occupancy_role=role and ends_on is null) then insert into public.hs_unit_occupancy_history(network_id,unit_entity_id,subject_entity_id,occupancy_role,starts_on,is_primary,created_by) values(nid,unit_id,person_id,role,coalesce(nullif(r->>'starts_on','')::date,current_date),role in ('owner','tenant'),auth.uid());end if;
  if role='owner' then insert into public.network_entity_relationships(network_id,from_entity_id,to_entity_id,relationship_type,metadata,created_by) values(nid,unit_id,person_id,'owned_by','{}',auth.uid()) on conflict(network_id,from_entity_id,to_entity_id,relationship_type) do nothing;elsif role='co-owner' then insert into public.network_entity_relationships(network_id,from_entity_id,to_entity_id,relationship_type,metadata,created_by) values(nid,unit_id,person_id,'co_owned_by','{}',auth.uid()) on conflict(network_id,from_entity_id,to_entity_id,relationship_type) do nothing;end if;
  if mail<>'' then perform public.hs1_create_resident_invitation(person_id,unit_id,mail,14);end if;
  if reg<>'' then select id into vehicle_id from public.hs_vehicles where network_id=nid and registration_no=reg;if vehicle_id is null then insert into public.hs_vehicles(network_id,unit_entity_id,owner_entity_id,registration_no,vehicle_type,make_model,is_ev,created_by) values(nid,unit_id,person_id,reg,coalesce(nullif(lower(r->>'vehicle_type'),''),'car'),nullif(r->>'vehicle_model',''),case when lower(coalesce(r->>'is_ev','')) in ('true','1','yes','y') then true else false end,auth.uid()) returning id into vehicle_id;end if;end if;
  if slot<>'' then insert into public.hs_parking_slots(network_id,slot_code,zone,slot_type,status) values(nid,slot,nullif(r->>'parking_zone',''),coalesce(nullif(lower(r->>'vehicle_type'),''),'car'),'allocated') on conflict(network_id,slot_code) do update set status='allocated',updated_at=now() returning id into slot_id;if not exists(select 1 from public.hs_parking_allocations where network_id=nid and parking_slot_id=slot_id and ends_on is null) then insert into public.hs_parking_allocations(network_id,parking_slot_id,vehicle_id,unit_entity_id,created_by) values(nid,slot_id,vehicle_id,unit_id,auth.uid());end if;end if;
 end loop;
 update public.hs_import_batches set inserted_count=i,updated_count=u,skipped_count=sk,status='committed',committed_at=now() where id=batch_id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs1_bulk_import_committed',jsonb_build_object('batch_id',batch_id,'inserted',i,'updated',u,'skipped',sk));
 return jsonb_build_object('batchId',batch_id,'inserted',i,'updated',u,'skipped',sk);
exception when others then update public.hs_import_batches set status='failed' where id=batch_id;raise;end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_set_occupancy(p_unit_id uuid, p_subject_id uuid, p_role text, p_starts_on date DEFAULT CURRENT_DATE, p_ends_on date DEFAULT NULL::date, p_is_primary boolean DEFAULT false, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();rid uuid;subject_kind text;begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;
 if p_role not in ('owner','co-owner','tenant','occupant') then raise exception 'Invalid occupancy role.' using errcode='22023';end if;
 if not exists(select 1 from public.network_entities where id=p_unit_id and network_id=nid and kind='unit') then raise exception 'Unit not found.' using errcode='22023';end if;
 select kind into subject_kind from public.network_entities where id=p_subject_id and network_id=nid;if subject_kind is null or (p_role in ('owner','co-owner') and subject_kind<>'person') or (p_role in ('tenant','occupant') and subject_kind not in ('person','household')) then raise exception 'Subject kind is incompatible with role.' using errcode='22023';end if;
 if p_ends_on is null then update public.hs_unit_occupancy_history set ends_on=greatest(starts_on,p_starts_on-1) where network_id=nid and unit_entity_id=p_unit_id and subject_entity_id=p_subject_id and occupancy_role=p_role and ends_on is null;end if;
 insert into public.hs_unit_occupancy_history(network_id,unit_entity_id,subject_entity_id,occupancy_role,starts_on,ends_on,is_primary,notes,created_by) values(nid,p_unit_id,p_subject_id,p_role,coalesce(p_starts_on,current_date),p_ends_on,p_is_primary,nullif(trim(coalesce(p_notes,'')),''),auth.uid()) returning id into rid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs1_occupancy_recorded',jsonb_build_object('unit_id',p_unit_id,'subject_id',p_subject_id,'role',p_role,'history_id',rid));return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_upsert_parking_slot(p_id uuid, p_slot_code text, p_zone text DEFAULT NULL::text, p_slot_type text DEFAULT 'car'::text, p_status text DEFAULT 'available'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();rid uuid;begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;if length(trim(coalesce(p_slot_code,'')))<1 then raise exception 'Parking slot code required.';end if;insert into public.hs_parking_slots(id,network_id,slot_code,zone,slot_type,status) values(coalesce(p_id,gen_random_uuid()),nid,upper(trim(p_slot_code)),nullif(trim(coalesce(p_zone,'')),''),p_slot_type,p_status) on conflict(network_id,slot_code) do update set zone=excluded.zone,slot_type=excluded.slot_type,status=excluded.status,updated_at=now() returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs1_upsert_vehicle(p_id uuid, p_unit_id uuid, p_owner_entity_id uuid, p_registration_no text, p_vehicle_type text DEFAULT 'car'::text, p_make_model text DEFAULT NULL::text, p_color text DEFAULT NULL::text, p_is_ev boolean DEFAULT false)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs1_assert_network();rid uuid;mine boolean:=false;begin
 if not exists(select 1 from public.network_entities where id=p_unit_id and network_id=nid and kind='unit') then raise exception 'Unit not found.' using errcode='22023';end if;
 mine:=exists(select 1 from public.hs_unit_occupancy_history h join public.network_entities p on p.id=h.subject_entity_id where h.network_id=nid and h.unit_entity_id=p_unit_id and p.owner_user_id=auth.uid() and (h.ends_on is null or h.ends_on>=current_date));
 if not public.is_network_admin(nid) and not mine then raise exception 'You can add vehicles only for your current flat.' using errcode='42501';end if;
 insert into public.hs_vehicles(id,network_id,unit_entity_id,owner_entity_id,registration_no,vehicle_type,make_model,color,is_ev,created_by) values(coalesce(p_id,gen_random_uuid()),nid,p_unit_id,p_owner_entity_id,upper(replace(trim(p_registration_no),' ','')),p_vehicle_type,nullif(trim(coalesce(p_make_model,'')),''),nullif(trim(coalesce(p_color,'')),''),p_is_ev,auth.uid()) on conflict(network_id,registration_no) do update set unit_entity_id=excluded.unit_entity_id,owner_entity_id=excluded.owner_entity_id,vehicle_type=excluded.vehicle_type,make_model=excluded.make_model,color=excluded.color,is_ev=excluded.is_ev,status='active',updated_at=now() returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_add_complaint_comment(p_complaint_id uuid, p_body text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); rid uuid; owner_id uuid;
begin
 select created_by into owner_id from public.hs_complaints where id=p_complaint_id and network_id=nid;
 if owner_id is null and not exists(select 1 from public.hs_complaints where id=p_complaint_id and network_id=nid) then raise exception 'Complaint not found.'; end if;
 if not public.is_network_admin(nid) and owner_id is distinct from auth.uid() then raise exception 'You can comment only on your complaint.' using errcode='42501'; end if;
 if length(trim(coalesce(p_body,'')))<2 then raise exception 'Comment is required.'; end if;
 insert into public.hs_complaint_comments(network_id,complaint_id,body,created_by) values(nid,p_complaint_id,trim(p_body),auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_assert_network()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Housing Society membership required.' using errcode='42501'; end if;
 if coalesce((select vertical_kind from public.networks where id=nid),'')<>'housing-society' then raise exception 'HS-2 is available only for housing-society networks.' using errcode='22023'; end if;
 return nid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_create_amenity_booking(p_amenity_id uuid, p_unit_entity_id uuid, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_purpose text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); rid uuid; mode text; st text; resolved_unit uuid:=p_unit_entity_id; person_id uuid;
begin
 if resolved_unit is null then select id into person_id from public.network_entities where network_id=nid and kind='person' and owner_user_id=auth.uid() order by updated_at desc limit 1; if person_id is not null then select unit_entity_id into resolved_unit from public.hs_unit_occupancy_history where network_id=nid and subject_entity_id=person_id and ends_on is null order by is_primary desc,starts_on desc limit 1; end if; end if;
 select booking_mode,status into mode,st from public.hs_amenities where id=p_amenity_id and network_id=nid;
 if mode is null or st<>'active' or mode='disabled' then raise exception 'Amenity is not bookable.'; end if;
 if p_ends_at<=p_starts_at then raise exception 'Booking end must be after start.'; end if;
 if exists(select 1 from public.hs_amenity_bookings where network_id=nid and amenity_id=p_amenity_id and status in ('pending','approved') and tstzrange(starts_at,ends_at,'[)') && tstzrange(p_starts_at,p_ends_at,'[)')) then raise exception 'This amenity already has an overlapping booking.' using errcode='23505'; end if;
 insert into public.hs_amenity_bookings(network_id,amenity_id,unit_entity_id,starts_at,ends_at,purpose,status,created_by) values(nid,p_amenity_id,resolved_unit,p_starts_at,p_ends_at,nullif(trim(p_purpose),''),case when mode='instant' then 'approved' else 'pending' end,auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_create_complaint(p_unit_entity_id uuid, p_category text, p_title text, p_description text DEFAULT NULL::text, p_priority text DEFAULT 'normal'::text, p_photo_url text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); rid uuid; resolved_unit uuid:=p_unit_entity_id; person_id uuid;
begin
 if resolved_unit is null then select id into person_id from public.network_entities where network_id=nid and kind='person' and owner_user_id=auth.uid() order by updated_at desc limit 1; if person_id is not null then select unit_entity_id into resolved_unit from public.hs_unit_occupancy_history where network_id=nid and subject_entity_id=person_id and ends_on is null order by is_primary desc,starts_on desc limit 1; end if; end if;
 if p_priority not in ('low','normal','high','urgent') then raise exception 'Invalid priority.'; end if;
 if resolved_unit is not null and not exists(select 1 from public.network_entities where id=resolved_unit and network_id=nid and kind='unit') then raise exception 'Unit not found in this society.'; end if;
 insert into public.hs_complaints(network_id,unit_entity_id,category,title,description,attachments,priority,created_by) values(nid,resolved_unit,coalesce(nullif(trim(p_category),''),'Other'),trim(p_title),nullif(trim(p_description),''),case when nullif(trim(p_photo_url),'') is null then '[]'::jsonb else jsonb_build_array(jsonb_build_object('kind','photo','url',trim(p_photo_url))) end,p_priority,auth.uid()) returning id into rid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs2_complaint_created',jsonb_build_object('complaint_id',rid,'priority',p_priority)); return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_create_notice(p_title text, p_body text DEFAULT NULL::text, p_notice_type text DEFAULT 'general'::text, p_pinned boolean DEFAULT false, p_expires_at timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_notice_type not in ('general','urgent','targeted') then raise exception 'Invalid notice type.'; end if;
 if length(trim(coalesce(p_title,'')))<2 then raise exception 'Notice title is required.'; end if;
 insert into public.hs_notices(network_id,title,body,notice_type,pinned,expires_at,created_by) values(nid,trim(p_title),nullif(trim(p_body),''),p_notice_type,p_pinned,p_expires_at,auth.uid()) returning id into rid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs2_notice_published',jsonb_build_object('notice_id',rid,'type',p_notice_type)); return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_create_vendor_contract(p_vendor_id uuid, p_title text, p_starts_on date DEFAULT NULL::date, p_ends_on date DEFAULT NULL::date, p_sla text DEFAULT NULL::text, p_amount numeric DEFAULT NULL::numeric)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.hs_vendors where id=p_vendor_id and network_id=nid) then raise exception 'Vendor not found.'; end if;
 insert into public.hs_vendor_contracts(network_id,vendor_id,title,starts_on,ends_on,sla,amount,status,created_by) values(nid,p_vendor_id,trim(p_title),p_starts_on,p_ends_on,nullif(trim(p_sla),''),p_amount,case when p_starts_on is null or p_starts_on<=current_date then 'active' else 'draft' end,auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_get_operations_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); isadm boolean:=public.is_network_admin(nid);
begin
 return jsonb_build_object(
  'notices',coalesce((select jsonb_agg(jsonb_build_object('id',n.id,'title',n.title,'body',n.body,'noticeType',n.notice_type,'pinned',n.pinned,'expiresAt',n.expires_at,'createdAt',n.created_at,'createdBy',n.created_by) order by n.pinned desc,n.created_at desc) from public.hs_notices n where n.network_id=nid and (n.expires_at is null or n.expires_at>now())),'[]'::jsonb),
  'complaints',coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'unitEntityId',c.unit_entity_id,'unitLabel',u.label,'category',c.category,'title',c.title,'description',c.description,'priority',c.priority,'status',c.status,'slaDueAt',c.sla_due_at,'assignedTo',c.assigned_to,'assignedVendorId',c.assigned_vendor_id,'resolutionNote',c.resolution_note,'createdAt',c.created_at,'updatedAt',c.updated_at,'createdBy',c.created_by,'comments',coalesce((select jsonb_agg(jsonb_build_object('id',cc.id,'body',cc.body,'createdAt',cc.created_at,'authorLabel',coalesce(ne.label,au.email,'Member')) order by cc.created_at) from public.hs_complaint_comments cc left join auth.users au on au.id=cc.created_by left join public.network_entities ne on ne.network_id=nid and ne.owner_user_id=cc.created_by where cc.complaint_id=c.id),'[]'::jsonb)) order by c.created_at desc) from public.hs_complaints c left join public.network_entities u on u.id=c.unit_entity_id and u.network_id=nid where c.network_id=nid and (isadm or c.created_by=auth.uid())),'[]'::jsonb),
  'vendors',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'name',v.name,'category',v.category,'contactName',v.contact_name,'phone',case when isadm then v.phone else null end,'email',case when isadm then v.email else null end,'status',v.status,'contractCount',(select count(*) from public.hs_vendor_contracts vc where vc.vendor_id=v.id)) order by v.name) from public.hs_vendors v where v.network_id=nid and (isadm or v.status='active')),'[]'::jsonb),
  'amenities',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'description',a.description,'location',a.location,'capacity',a.capacity,'bookingMode',a.booking_mode,'status',a.status) order by a.name) from public.hs_amenities a where a.network_id=nid),'[]'::jsonb),
  'bookings',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'amenityId',b.amenity_id,'amenityName',a.name,'unitEntityId',b.unit_entity_id,'startsAt',b.starts_at,'endsAt',b.ends_at,'status',b.status,'purpose',b.purpose,'createdBy',b.created_by) order by b.starts_at desc) from public.hs_amenity_bookings b join public.hs_amenities a on a.id=b.amenity_id where b.network_id=nid and (isadm or b.created_by=auth.uid()) and b.starts_at>now()-interval '30 days'),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_review_amenity_booking(p_booking_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); own uuid;
begin
 if p_status not in ('approved','rejected','cancelled') then raise exception 'Invalid booking review.'; end if;
 select created_by into own from public.hs_amenity_bookings where id=p_booking_id and network_id=nid;
 if own is null and not exists(select 1 from public.hs_amenity_bookings where id=p_booking_id and network_id=nid) then raise exception 'Booking not found.'; end if;
 if p_status in ('approved','rejected') and not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_status='cancelled' and not public.is_network_admin(nid) and own is distinct from auth.uid() then raise exception 'You can cancel only your booking.' using errcode='42501'; end if;
 update public.hs_amenity_bookings set status=p_status,reviewed_by=case when public.is_network_admin(nid) then auth.uid() else reviewed_by end,reviewed_at=case when public.is_network_admin(nid) then now() else reviewed_at end,updated_at=now() where id=p_booking_id and network_id=nid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_update_complaint(p_complaint_id uuid, p_status text DEFAULT NULL::text, p_assigned_to uuid DEFAULT NULL::uuid, p_assigned_vendor_id uuid DEFAULT NULL::uuid, p_sla_due_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_resolution_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network();
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_status is not null and p_status not in ('open','in_progress','resolved','closed','reopened') then raise exception 'Invalid complaint status.'; end if;
 if p_assigned_vendor_id is not null and not exists(select 1 from public.hs_vendors where id=p_assigned_vendor_id and network_id=nid) then raise exception 'Vendor not found.'; end if;
 update public.hs_complaints set status=coalesce(p_status,status),assigned_to=coalesce(p_assigned_to,assigned_to),assigned_vendor_id=coalesce(p_assigned_vendor_id,assigned_vendor_id),sla_due_at=coalesce(p_sla_due_at,sla_due_at),resolution_note=coalesce(nullif(trim(p_resolution_note),''),resolution_note),resolved_at=case when coalesce(p_status,status) in ('resolved','closed') then coalesce(resolved_at,now()) when p_status='reopened' then null else resolved_at end,updated_at=now() where id=p_complaint_id and network_id=nid;
 if not found then raise exception 'Complaint not found.'; end if;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs2_complaint_updated',jsonb_build_object('complaint_id',p_complaint_id,'status',p_status));
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_upsert_amenity(p_id uuid, p_name text, p_description text DEFAULT NULL::text, p_location text DEFAULT NULL::text, p_capacity integer DEFAULT NULL::integer, p_booking_mode text DEFAULT 'approval'::text, p_status text DEFAULT 'active'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_booking_mode not in ('approval','instant','disabled') or p_status not in ('active','maintenance','inactive') then raise exception 'Invalid amenity configuration.'; end if;
 if p_id is null then insert into public.hs_amenities(network_id,name,description,location,capacity,booking_mode,status,created_by) values(nid,trim(p_name),nullif(trim(p_description),''),nullif(trim(p_location),''),p_capacity,p_booking_mode,p_status,auth.uid()) on conflict(network_id,name) do update set description=excluded.description,location=excluded.location,capacity=excluded.capacity,booking_mode=excluded.booking_mode,status=excluded.status,updated_at=now() returning id into rid;
 else update public.hs_amenities set name=trim(p_name),description=nullif(trim(p_description),''),location=nullif(trim(p_location),''),capacity=p_capacity,booking_mode=p_booking_mode,status=p_status,updated_at=now() where id=p_id and network_id=nid returning id into rid; end if; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs2_upsert_vendor(p_id uuid, p_name text, p_category text, p_contact_name text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_status text DEFAULT 'active'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_status not in ('active','inactive','blocked') then raise exception 'Invalid vendor status.'; end if;
 if p_id is null then insert into public.hs_vendors(network_id,name,category,contact_name,phone,email,status,created_by) values(nid,trim(p_name),trim(p_category),nullif(trim(p_contact_name),''),nullif(trim(p_phone),''),nullif(lower(trim(p_email)),''),p_status,auth.uid()) on conflict(network_id,name,category) do update set contact_name=excluded.contact_name,phone=excluded.phone,email=excluded.email,status=excluded.status,updated_at=now() returning id into rid;
 else update public.hs_vendors set name=trim(p_name),category=trim(p_category),contact_name=nullif(trim(p_contact_name),''),phone=nullif(trim(p_phone),''),email=nullif(lower(trim(p_email)),''),status=p_status,updated_at=now() where id=p_id and network_id=nid returning id into rid; end if;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_add_bill_adjustment(p_bill_id uuid, p_type text, p_amount numeric, p_reason text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_type not in ('credit','debit','waiver','penalty') or p_amount<0 then raise exception 'Invalid adjustment.'; end if;
 if not exists(select 1 from public.hs_unit_bills where id=p_bill_id and network_id=nid) then raise exception 'Bill not found.'; end if;
 insert into public.hs_bill_adjustments(network_id,bill_id,adjustment_type,amount,reason,created_by) values(nid,p_bill_id,p_type,p_amount,trim(p_reason),auth.uid()) returning id into rid;
 perform public.hs3_recalculate_bill(p_bill_id); return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_assert_network()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Housing Society membership required.' using errcode='42501'; end if;
 if coalesce((select vertical_kind from public.networks where id=nid),'')<>'housing-society' then raise exception 'HS-3 is available only for housing-society networks.' using errcode='22023'; end if;
 return nid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_create_billing_cycle(p_label text, p_period_start date, p_period_end date, p_due_on date, p_grace_days integer DEFAULT 0, p_penalty_rate_monthly numeric DEFAULT 0)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_period_end<p_period_start or p_due_on<p_period_start then raise exception 'Invalid billing dates.'; end if;
 insert into public.hs_billing_cycles(network_id,label,period_start,period_end,due_on,grace_days,penalty_rate_monthly,created_by) values(nid,trim(p_label),p_period_start,p_period_end,p_due_on,greatest(coalesce(p_grace_days,0),0),greatest(coalesce(p_penalty_rate_monthly,0),0),auth.uid()) on conflict(network_id,period_start,period_end) do update set label=excluded.label,due_on=excluded.due_on,grace_days=excluded.grace_days,penalty_rate_monthly=excluded.penalty_rate_monthly,updated_at=now() returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_generate_cycle_bills(p_cycle_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); cyc public.hs_billing_cycles%rowtype; u record; h record; bid uuid; created_count int:=0; head_count int:=0;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 select * into cyc from public.hs_billing_cycles where id=p_cycle_id and network_id=nid;
 if cyc.id is null then raise exception 'Billing cycle not found.'; end if;
 if cyc.status='cancelled' then raise exception 'Cancelled cycle cannot be generated.'; end if;
 select count(*) into head_count from public.hs_charge_heads where network_id=nid and active and calculation_mode='fixed_per_unit';
 if head_count=0 then raise exception 'Create at least one active fixed charge head before generating bills.'; end if;
 for u in select id,label from public.network_entities where network_id=nid and kind='unit' loop
  insert into public.hs_unit_bills(network_id,billing_cycle_id,unit_entity_id,due_on,issued_at,created_by) values(nid,p_cycle_id,u.id,cyc.due_on,now(),auth.uid()) on conflict(network_id,billing_cycle_id,unit_entity_id) do update set due_on=excluded.due_on,issued_at=coalesce(public.hs_unit_bills.issued_at,excluded.issued_at),updated_at=now() returning id into bid;
  delete from public.hs_bill_line_items where bill_id=bid and network_id=nid;
  for h in select id,label,default_amount,category from public.hs_charge_heads where network_id=nid and active and calculation_mode='fixed_per_unit' order by label loop
   insert into public.hs_bill_line_items(network_id,bill_id,charge_head_id,label,amount,metadata) values(nid,bid,h.id,h.label,h.default_amount,jsonb_build_object('category',h.category));
  end loop;
  perform public.hs3_recalculate_bill(bid); created_count:=created_count+1;
 end loop;
 update public.hs_billing_cycles set status='issued',issued_at=coalesce(issued_at,now()),updated_at=now() where id=p_cycle_id;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs3_billing_cycle_issued',jsonb_build_object('cycle_id',p_cycle_id,'unit_count',created_count,'charge_head_count',head_count));
 return jsonb_build_object('cycleId',p_cycle_id,'unitCount',created_count,'chargeHeadCount',head_count);
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_get_finance_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); isadm boolean:=public.is_network_admin(nid);
begin
 return jsonb_build_object(
  'chargeHeads',case when isadm then coalesce((select jsonb_agg(jsonb_build_object('id',h.id,'code',h.code,'label',h.label,'category',h.category,'amount',h.default_amount,'active',h.active) order by h.label) from public.hs_charge_heads h where h.network_id=nid),'[]'::jsonb) else '[]'::jsonb end,
  'cycles',coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'label',c.label,'periodStart',c.period_start,'periodEnd',c.period_end,'dueOn',c.due_on,'status',c.status,'graceDays',c.grace_days,'penaltyRateMonthly',c.penalty_rate_monthly) order by c.period_start desc) from public.hs_billing_cycles c where c.network_id=nid),'[]'::jsonb),
  'bills',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'cycleId',b.billing_cycle_id,'cycleLabel',c.label,'unitEntityId',b.unit_entity_id,'unitLabel',u.label,'dueOn',b.due_on,'subtotal',b.subtotal,'adjustmentAmount',b.adjustment_amount,'totalAmount',b.total_amount,'paidAmount',b.paid_amount,'balanceAmount',b.balance_amount,'status',b.status,'lineItems',coalesce((select jsonb_agg(jsonb_build_object('id',li.id,'label',li.label,'amount',li.amount) order by li.created_at) from public.hs_bill_line_items li where li.bill_id=b.id),'[]'::jsonb),'payments',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'amount',p.amount,'paidOn',p.paid_on,'paymentMode',p.payment_mode,'paymentReference',p.payment_reference,'receiptNumber',p.receipt_number,'status',p.status) order by p.paid_on desc,p.created_at desc) from public.hs_payments p where p.bill_id=b.id),'[]'::jsonb)) order by b.due_on desc,u.label) from public.hs_unit_bills b join public.hs_billing_cycles c on c.id=b.billing_cycle_id join public.network_entities u on u.id=b.unit_entity_id where b.network_id=nid and (isadm or exists(select 1 from public.hs_unit_occupancy_history o join public.network_entities p on p.id=o.subject_entity_id where o.network_id=nid and o.unit_entity_id=b.unit_entity_id and o.ends_on is null and p.owner_user_id=auth.uid()))),'[]'::jsonb),
  'funds',coalesce((select jsonb_agg(jsonb_build_object('id',f.id,'code',f.code,'label',f.label,'openingBalance',f.opening_balance,'currentBalance',f.current_balance,'visibility',f.visibility) order by f.label) from public.hs_funds f where f.network_id=nid and (isadm or f.visibility='members')),'[]'::jsonb),
  'budget',coalesce((select jsonb_agg(jsonb_build_object('id',bl.id,'financialYear',bl.financial_year,'category',bl.category,'label',bl.label,'budgetAmount',bl.budget_amount,'actualAmount',coalesce((select sum(e.amount) from public.hs_expenses e where e.network_id=nid and e.category=bl.category and e.visibility=case when isadm then e.visibility else 'members' end),0),'visibility',bl.visibility) order by bl.financial_year desc,bl.category,bl.label) from public.hs_budget_lines bl where bl.network_id=nid and (isadm or bl.visibility='members')),'[]'::jsonb),
  'summary',jsonb_build_object('totalBilled',coalesce((select sum(total_amount) from public.hs_unit_bills where network_id=nid),0),'totalCollected',coalesce((select sum(amount) from public.hs_payments where network_id=nid and status='recorded'),0),'totalOutstanding',coalesce((select sum(balance_amount) from public.hs_unit_bills where network_id=nid and status not in ('paid','waived','void')),0),'overdueBills',coalesce((select count(*) from public.hs_unit_bills where network_id=nid and balance_amount>0 and due_on<current_date),0))
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_recalculate_bill(p_bill_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid; sub numeric; adj numeric; paid numeric; total numeric; bal numeric; st text;
begin
 select network_id into nid from public.hs_unit_bills where id=p_bill_id;
 if nid is null then raise exception 'Bill not found.'; end if;
 sub:=coalesce((select sum(amount) from public.hs_bill_line_items where bill_id=p_bill_id and network_id=nid),0);
 adj:=coalesce((select sum(case when adjustment_type in ('credit','waiver') then -amount else amount end) from public.hs_bill_adjustments where bill_id=p_bill_id and network_id=nid),0);
 paid:=coalesce((select sum(case when status='recorded' then amount else 0 end) from public.hs_payments where bill_id=p_bill_id and network_id=nid),0);
 total:=greatest(sub+adj,0); bal:=greatest(total-paid,0);
 st:=case when total=0 and exists(select 1 from public.hs_bill_adjustments where bill_id=p_bill_id and adjustment_type='waiver') then 'waived' when bal=0 then 'paid' when paid>0 then 'partial' else 'unpaid' end;
 update public.hs_unit_bills set subtotal=sub,adjustment_amount=adj,total_amount=total,paid_amount=paid,balance_amount=bal,status=st,updated_at=now() where id=p_bill_id;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_record_expense(p_category text, p_description text, p_amount numeric, p_incurred_on date DEFAULT CURRENT_DATE, p_fund_id uuid DEFAULT NULL::uuid, p_vendor_id uuid DEFAULT NULL::uuid, p_payment_reference text DEFAULT NULL::text, p_visibility text DEFAULT 'members'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 insert into public.hs_expenses(network_id,fund_id,vendor_id,category,description,amount,incurred_on,payment_reference,visibility,created_by) values(nid,p_fund_id,p_vendor_id,trim(p_category),trim(p_description),p_amount,coalesce(p_incurred_on,current_date),nullif(trim(p_payment_reference),''),p_visibility,auth.uid()) returning id into rid;
 if p_fund_id is not null then update public.hs_funds set current_balance=current_balance-p_amount,updated_at=now() where id=p_fund_id and network_id=nid; end if;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_record_payment(p_bill_id uuid, p_amount numeric, p_paid_on date DEFAULT CURRENT_DATE, p_payment_mode text DEFAULT 'manual'::text, p_payment_reference text DEFAULT NULL::text, p_receipt_number text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); rid uuid; uid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_amount<=0 then raise exception 'Payment amount must be positive.'; end if;
 select unit_entity_id into uid from public.hs_unit_bills where id=p_bill_id and network_id=nid;
 if uid is null then raise exception 'Bill not found.'; end if;
 insert into public.hs_payments(network_id,bill_id,unit_entity_id,amount,paid_on,payment_mode,payment_reference,receipt_number,notes,created_by) values(nid,p_bill_id,uid,p_amount,coalesce(p_paid_on,current_date),p_payment_mode,nullif(trim(p_payment_reference),''),nullif(trim(p_receipt_number),''),nullif(trim(p_notes),''),auth.uid()) returning id into rid;
 perform public.hs3_recalculate_bill(p_bill_id);
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs3_payment_recorded',jsonb_build_object('payment_id',rid,'bill_id',p_bill_id,'amount',p_amount)); return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_upsert_budget_line(p_financial_year text, p_category text, p_label text, p_budget_amount numeric, p_visibility text DEFAULT 'members'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 insert into public.hs_budget_lines(network_id,financial_year,category,label,budget_amount,visibility,created_by) values(nid,trim(p_financial_year),trim(p_category),trim(p_label),p_budget_amount,p_visibility,auth.uid()) on conflict(network_id,financial_year,category,label) do update set budget_amount=excluded.budget_amount,visibility=excluded.visibility,updated_at=now() returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_upsert_charge_head(p_id uuid, p_code text, p_label text, p_category text, p_default_amount numeric, p_active boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_default_amount<0 then raise exception 'Charge amount cannot be negative.'; end if;
 if p_id is null then insert into public.hs_charge_heads(network_id,code,label,category,default_amount,active,created_by) values(nid,upper(trim(p_code)),trim(p_label),p_category,p_default_amount,p_active,auth.uid()) on conflict(network_id,code) do update set label=excluded.label,category=excluded.category,default_amount=excluded.default_amount,active=excluded.active,updated_at=now() returning id into rid;
 else update public.hs_charge_heads set code=upper(trim(p_code)),label=trim(p_label),category=p_category,default_amount=p_default_amount,active=p_active,updated_at=now() where id=p_id and network_id=nid returning id into rid; end if;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs3_upsert_fund(p_id uuid, p_code text, p_label text, p_opening_balance numeric DEFAULT 0, p_visibility text DEFAULT 'members'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs3_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_visibility not in ('admin','members') then raise exception 'Invalid visibility.'; end if;
 if p_id is null then insert into public.hs_funds(network_id,code,label,opening_balance,current_balance,visibility,created_by) values(nid,upper(trim(p_code)),trim(p_label),p_opening_balance,p_opening_balance,p_visibility,auth.uid()) on conflict(network_id,code) do update set label=excluded.label,visibility=excluded.visibility,updated_at=now() returning id into rid;
 else update public.hs_funds set code=upper(trim(p_code)),label=trim(p_label),visibility=p_visibility,updated_at=now() where id=p_id and network_id=nid returning id into rid; end if; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_add_agenda_item(p_meeting_id uuid, p_title text, p_description text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid; ord integer;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if not exists(select 1 from public.hs_governance_meetings where id=p_meeting_id and network_id=nid) then raise exception 'Meeting not found.'; end if;
 select coalesce(max(item_order),0)+1 into ord from public.hs_meeting_agenda_items where meeting_id=p_meeting_id;
 insert into public.hs_meeting_agenda_items(network_id,meeting_id,item_order,title,description,created_by) values(nid,p_meeting_id,ord,trim(p_title),nullif(trim(p_description),''),auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_add_complaint_comment(p_complaint_id uuid, p_body text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); c public.hs_complaints; rid uuid;
begin
 select * into c from public.hs_complaints where id=p_complaint_id and network_id=nid;
 if c.id is null then raise exception 'Complaint not found.'; end if;
 if not public.is_network_admin(nid) and c.created_by is distinct from auth.uid() and c.assigned_to is distinct from auth.uid() then raise exception 'You are not part of this complaint workflow.' using errcode='42501'; end if;
 if length(trim(coalesce(p_body,'')))<2 then raise exception 'Comment is required.'; end if;
 insert into public.hs_complaint_comments(network_id,complaint_id,body,created_by) values(nid,p_complaint_id,trim(p_body),auth.uid()) returning id into rid;
 return jsonb_build_object('comment_id',rid,'notification_ids','[]'::jsonb);
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_add_governance_document(p_meeting_id uuid, p_resolution_id uuid, p_document_type text, p_title text, p_version_label text DEFAULT NULL::text, p_document_url text DEFAULT NULL::text, p_visibility text DEFAULT 'members'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_document_type not in ('agenda','minutes','resolution','notice','supporting','other') or p_visibility not in ('admin','members') then raise exception 'Invalid document settings.'; end if;
 insert into public.hs_governance_documents(network_id,meeting_id,resolution_id,document_type,title,version_label,document_url,visibility,created_by) values(nid,p_meeting_id,p_resolution_id,p_document_type,trim(p_title),nullif(trim(p_version_label),''),nullif(trim(p_document_url),''),p_visibility,auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_assert_network()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Housing Society membership required.' using errcode='42501'; end if;
 if coalesce((select vertical_kind from public.networks where id=nid),'')<>'housing-society' then raise exception 'HS-4 is available only for housing-society networks.' using errcode='22023'; end if;
 return nid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_assign_committee_role(p_term_id uuid, p_person_entity_id uuid, p_role_key text, p_role_label text DEFAULT NULL::text, p_starts_on date DEFAULT CURRENT_DATE, p_ends_on date DEFAULT NULL::date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_role_key not in ('chairperson','secretary','treasurer','committee_member','manager','auditor','other') then raise exception 'Invalid committee role.'; end if;
 if not exists(select 1 from public.hs_committee_terms where id=p_term_id and network_id=nid) then raise exception 'Committee term not found.'; end if;
 if not exists(select 1 from public.network_entities where id=p_person_entity_id and network_id=nid and kind='person') then raise exception 'Resident person not found.'; end if;
 insert into public.hs_committee_assignments(network_id,term_id,person_entity_id,role_key,role_label,starts_on,ends_on,created_by) values(nid,p_term_id,p_person_entity_id,p_role_key,nullif(trim(p_role_label),''),p_starts_on,p_ends_on,auth.uid()) returning id into rid;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'hs4_committee_role_assigned',jsonb_build_object('assignment_id',rid,'role',p_role_key,'person_entity_id',p_person_entity_id)); return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_cast_resolution_vote(p_resolution_id uuid, p_choice text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid; r public.hs_resolutions%rowtype;
begin
 if p_choice not in ('yes','no','abstain') then raise exception 'Invalid vote choice.'; end if;
 select * into r from public.hs_resolutions where id=p_resolution_id and network_id=nid;
 if r.id is null then raise exception 'Resolution not found.'; end if;
 if r.status<>'open' or (r.opens_at is not null and r.opens_at>now()) or (r.closes_at is not null and r.closes_at<=now()) then raise exception 'Voting is not open.'; end if;
 insert into public.hs_resolution_votes(network_id,resolution_id,voter_user_id,choice) values(nid,p_resolution_id,auth.uid(),p_choice) on conflict(resolution_id,voter_user_id) do update set choice=excluded.choice,cast_at=now() returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_category_key(p_category text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
 select trim(both '-' from regexp_replace(lower(trim(coalesce(p_category,'other'))),'[^a-z0-9]+','-','g'));
$function$
;

CREATE OR REPLACE FUNCTION public.hs4_close_resolution(p_resolution_id uuid, p_result_status text, p_result_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network();
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_result_status not in ('approved','rejected','closed','withdrawn') then raise exception 'Invalid resolution result.'; end if;
 update public.hs_resolutions set status=p_result_status,result_note=nullif(trim(p_result_note),''),closed_at=now(),updated_at=now() where id=p_resolution_id and network_id=nid;
 if not found then raise exception 'Resolution not found.'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_create_action_item(p_meeting_id uuid, p_title text, p_owner_label text DEFAULT NULL::text, p_due_on date DEFAULT NULL::date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_meeting_id is not null and not exists(select 1 from public.hs_governance_meetings where id=p_meeting_id and network_id=nid) then raise exception 'Meeting not found.'; end if;
 insert into public.hs_governance_action_items(network_id,meeting_id,title,owner_label,due_on,created_by) values(nid,p_meeting_id,trim(p_title),nullif(trim(p_owner_label),''),p_due_on,auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_create_committee_term(p_label text, p_starts_on date, p_ends_on date DEFAULT NULL::date, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 insert into public.hs_committee_terms(network_id,label,starts_on,ends_on,status,notes,created_by) values(nid,trim(p_label),p_starts_on,p_ends_on,case when p_starts_on<=current_date and (p_ends_on is null or p_ends_on>=current_date) then 'active' else 'planned' end,nullif(trim(p_notes),''),auth.uid()) on conflict(network_id,label,starts_on) do update set ends_on=excluded.ends_on,notes=excluded.notes,updated_at=now() returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_create_complaint(p_unit_entity_id uuid, p_category text, p_title text, p_description text DEFAULT NULL::text, p_priority text DEFAULT 'normal'::text, p_photo_path text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 nid uuid:=public.hs2_assert_network(); rid uuid; resolved_unit uuid:=p_unit_entity_id; person_id uuid;
 ckey text; rkey text; assignee uuid; target uuid; notification_ids uuid[]:='{}'; notification_id uuid;
begin
 if length(trim(coalesce(p_title,'')))<2 then raise exception 'Complaint title is required.' using errcode='22023'; end if;
 if p_priority not in ('low','normal','high','urgent') then raise exception 'Invalid priority.' using errcode='22023'; end if;

 if resolved_unit is null and to_regclass('public.hs_unit_occupancy_history') is not null then
   select id into person_id from public.network_entities where network_id=nid and kind='person' and owner_user_id=auth.uid() order by updated_at desc limit 1;
   if person_id is not null then
     execute 'select unit_entity_id from public.hs_unit_occupancy_history where network_id=$1 and subject_entity_id=$2 and ends_on is null order by is_primary desc,starts_on desc limit 1'
       into resolved_unit using nid,person_id;
   end if;
 end if;

 if resolved_unit is not null and not exists(select 1 from public.network_entities where id=resolved_unit and network_id=nid and kind='unit') then
   raise exception 'Unit not found in this society.' using errcode='22023';
 end if;
 if nullif(trim(coalesce(p_photo_path,'')),'') is not null and p_photo_path not like nid::text||'/community/'||auth.uid()::text||'/%' then
   raise exception 'Complaint photo must be uploaded by the signed-in resident.' using errcode='42501';
 end if;

 ckey:=public.hs4_category_key(p_category);
 select role_key into rkey from public.hs_complaint_routes where network_id=nid and category_key=ckey;

 if to_regclass('public.network_notification_roles') is not null then
   execute 'select nr.user_id from public.network_notification_roles nr where nr.network_id=$1 and nr.active and nr.role_key=$2 order by nr.updated_at desc limit 1'
     into assignee using nid,coalesce(rkey,'complaint-resolver');
 end if;

 insert into public.hs_complaints(network_id,unit_entity_id,category,title,description,attachments,priority,assigned_to,created_by)
 values(nid,resolved_unit,coalesce(nullif(trim(p_category),''),'Other'),trim(p_title),nullif(trim(coalesce(p_description,'')),''),
   case when nullif(trim(coalesce(p_photo_path,'')),'') is null then '[]'::jsonb else jsonb_build_array(jsonb_build_object('kind','photo','path',trim(p_photo_path))) end,
   p_priority,assignee,auth.uid()) returning id into rid;

 -- Notifications are useful but must not roll back a valid complaint if engagement objects drift.
 begin
   if to_regclass('public.network_notification_roles') is not null and to_regprocedure('public.create_network_notification(uuid,uuid,text,text,text,text,text,uuid,text,jsonb,uuid)') is not null then
     for target in execute
       'select distinct x.user_id from ('||
       'select nr.user_id from public.network_notification_roles nr where nr.network_id=$1 and nr.active and nr.role_key=$2 '||
       'union all select nm.user_id from public.network_memberships nm where nm.network_id=$1 and nm.status=''active'' and nm.role in (''owner'',''admin'') and $3 is null) x'
       using nid,coalesce(rkey,'complaint-resolver'),assignee
     loop
       if target=auth.uid() then continue; end if;
       notification_id:=public.create_network_notification(nid,target,'complaint-created','New complaint · '||trim(p_title),nullif(trim(coalesce(p_description,'')),''),'complaints','hs_complaint',rid,case when p_priority in ('urgent','high') then p_priority else 'normal' end,jsonb_build_object('surface','complaints','category',p_category),auth.uid());
       notification_ids:=array_append(notification_ids,notification_id);
     end loop;
   end if;
 exception when others then
   -- Do not lose the complaint because notification routing is temporarily degraded.
   null;
 end;

 if to_regclass('public.audit_log') is not null then
   insert into public.audit_log(network_id,actor_id,action,details)
   values(nid,auth.uid(),'hs4_complaint_created',jsonb_build_object('complaint_id',rid,'priority',p_priority,'route',rkey,'assignee',assignee));
 end if;
 return jsonb_build_object('complaint_id',rid,'assigned_to',assignee,'notification_ids',notification_ids);
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_create_meeting(p_meeting_type text, p_title text, p_scheduled_at timestamp with time zone, p_location text DEFAULT NULL::text, p_quorum_required integer DEFAULT NULL::integer)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_meeting_type not in ('committee','agm','sgm','general','other') then raise exception 'Invalid meeting type.'; end if;
 insert into public.hs_governance_meetings(network_id,meeting_type,title,scheduled_at,location,quorum_required,status,created_by) values(nid,p_meeting_type,trim(p_title),p_scheduled_at,nullif(trim(p_location),''),p_quorum_required,'scheduled',auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_create_resolution(p_meeting_id uuid, p_resolution_number text, p_title text, p_body text, p_vote_mode text DEFAULT 'approval'::text, p_opens_at timestamp with time zone DEFAULT now(), p_closes_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_quorum_percent numeric DEFAULT 0)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network(); rid uuid;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_vote_mode not in ('advisory','approval') then raise exception 'Invalid vote mode.'; end if;
 insert into public.hs_resolutions(network_id,meeting_id,resolution_number,title,body,vote_mode,status,opens_at,closes_at,quorum_percent,created_by) values(nid,p_meeting_id,nullif(trim(p_resolution_number),''),trim(p_title),trim(p_body),p_vote_mode,'open',coalesce(p_opens_at,now()),p_closes_at,coalesce(p_quorum_percent,0),auth.uid()) returning id into rid; return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_get_complaint_routes()
 RETURNS TABLE(category_key character varying, role_key character varying, role_label text, assignee_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select r.category_key,r.role_key,initcap(replace(r.role_key,'-',' '))::text,
        case when to_regclass('public.network_notification_roles') is null then 0::bigint else
          (select count(*) from public.network_notification_roles nr where nr.network_id=r.network_id and nr.role_key=r.role_key and nr.active)
        end
 from public.hs_complaint_routes r
 where r.network_id=public.hs2_assert_network()
 order by r.category_key;
$function$
;

CREATE OR REPLACE FUNCTION public.hs4_get_governance_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network();
begin
 return jsonb_build_object(
  'terms',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'label',t.label,'startsOn',t.starts_on,'endsOn',t.ends_on,'status',t.status,'notes',t.notes,'assignments',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'personEntityId',a.person_entity_id,'personLabel',p.label,'roleKey',a.role_key,'roleLabel',a.role_label,'startsOn',a.starts_on,'endsOn',a.ends_on) order by a.starts_on desc,p.label) from public.hs_committee_assignments a join public.network_entities p on p.id=a.person_entity_id where a.term_id=t.id),'[]'::jsonb)) order by t.starts_on desc) from public.hs_committee_terms t where t.network_id=nid),'[]'::jsonb),
  'meetings',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'meetingType',m.meeting_type,'title',m.title,'scheduledAt',m.scheduled_at,'location',m.location,'status',m.status,'quorumRequired',m.quorum_required,'attendeeCount',m.attendee_count,'minutesText',m.minutes_text,'minutesPublishedAt',m.minutes_published_at,'agenda',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'itemOrder',a.item_order,'title',a.title,'description',a.description,'outcomeText',a.outcome_text) order by a.item_order) from public.hs_meeting_agenda_items a where a.meeting_id=m.id),'[]'::jsonb)) order by m.scheduled_at desc) from public.hs_governance_meetings m where m.network_id=nid),'[]'::jsonb),
  'actions',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'meetingId',a.meeting_id,'title',a.title,'ownerLabel',a.owner_label,'dueOn',a.due_on,'status',a.status,'completionNote',a.completion_note) order by case when a.status='done' then 1 else 0 end,a.due_on nulls last,a.created_at desc) from public.hs_governance_action_items a where a.network_id=nid),'[]'::jsonb),
  'resolutions',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'meetingId',r.meeting_id,'resolutionNumber',r.resolution_number,'title',r.title,'body',r.body,'voteMode',r.vote_mode,'status',r.status,'opensAt',r.opens_at,'closesAt',r.closes_at,'quorumPercent',r.quorum_percent,'resultNote',r.result_note,'yesCount',(select count(*) from public.hs_resolution_votes v where v.resolution_id=r.id and v.choice='yes'),'noCount',(select count(*) from public.hs_resolution_votes v where v.resolution_id=r.id and v.choice='no'),'abstainCount',(select count(*) from public.hs_resolution_votes v where v.resolution_id=r.id and v.choice='abstain'),'myVote',(select v.choice from public.hs_resolution_votes v where v.resolution_id=r.id and v.voter_user_id=auth.uid())) order by r.created_at desc) from public.hs_resolutions r where r.network_id=nid),'[]'::jsonb),
  'documents',coalesce((select jsonb_agg(jsonb_build_object('id',d.id,'meetingId',d.meeting_id,'resolutionId',d.resolution_id,'documentType',d.document_type,'title',d.title,'versionLabel',d.version_label,'documentUrl',d.document_url,'visibility',d.visibility,'createdAt',d.created_at) order by d.created_at desc) from public.hs_governance_documents d where d.network_id=nid and (public.is_network_admin(nid) or d.visibility='members')),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_get_operations_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); isadm boolean:=public.is_network_admin(nid);
begin
 return jsonb_build_object(
  'notices',coalesce((select jsonb_agg(jsonb_build_object('id',n.id,'title',n.title,'body',n.body,'noticeType',n.notice_type,'pinned',n.pinned,'expiresAt',n.expires_at,'createdAt',n.created_at,'createdBy',n.created_by) order by n.pinned desc,n.created_at desc) from public.hs_notices n where n.network_id=nid and (n.expires_at is null or n.expires_at>now())),'[]'::jsonb),
  'complaints',coalesce((select jsonb_agg(jsonb_build_object(
    'id',c.id,'unitEntityId',c.unit_entity_id,'unitLabel',u.label,'category',c.category,'title',c.title,'description',c.description,
    'attachments',c.attachments,'priority',c.priority,'status',c.status,'slaDueAt',c.sla_due_at,'assignedTo',c.assigned_to,
    'assignedToLabel',coalesce(ae.label,au.email),'assignedVendorId',c.assigned_vendor_id,'resolutionNote',c.resolution_note,
    'createdAt',c.created_at,'updatedAt',c.updated_at,'createdBy',c.created_by,
    'comments',coalesce((select jsonb_agg(jsonb_build_object('id',cc.id,'body',cc.body,'createdAt',cc.created_at,'authorLabel',coalesce(ne.label,cu.email,'Member')) order by cc.created_at)
      from public.hs_complaint_comments cc left join auth.users cu on cu.id=cc.created_by left join public.network_entities ne on ne.network_id=nid and ne.owner_user_id=cc.created_by where cc.complaint_id=c.id),'[]'::jsonb)
   ) order by c.created_at desc)
   from public.hs_complaints c left join public.network_entities u on u.id=c.unit_entity_id and u.network_id=nid
   left join auth.users au on au.id=c.assigned_to left join public.network_entities ae on ae.network_id=nid and ae.owner_user_id=c.assigned_to
   where c.network_id=nid and (isadm or c.created_by=auth.uid() or c.assigned_to=auth.uid())),'[]'::jsonb),
  'vendors',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'name',v.name,'category',v.category,'contactName',v.contact_name,'phone',case when isadm then v.phone else null end,'email',case when isadm then v.email else null end,'status',v.status,'contractCount',(select count(*) from public.hs_vendor_contracts vc where vc.vendor_id=v.id)) order by v.name) from public.hs_vendors v where v.network_id=nid and (isadm or v.status='active')),'[]'::jsonb),
  'amenities',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'description',a.description,'location',a.location,'capacity',a.capacity,'bookingMode',a.booking_mode,'status',a.status) order by a.name) from public.hs_amenities a where a.network_id=nid),'[]'::jsonb),
  'bookings',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'amenityId',b.amenity_id,'amenityName',a.name,'unitEntityId',b.unit_entity_id,'unitLabel',u.label,'startsAt',b.starts_at,'endsAt',b.ends_at,'status',b.status,'purpose',b.purpose,'createdBy',b.created_by) order by b.starts_at desc) from public.hs_amenity_bookings b join public.hs_amenities a on a.id=b.amenity_id left join public.network_entities u on u.id=b.unit_entity_id and u.network_id=nid where b.network_id=nid and (isadm or b.created_by=auth.uid()) and b.starts_at>now()-interval '30 days'),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_publish_minutes(p_meeting_id uuid, p_minutes text, p_attendee_count integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network();
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 update public.hs_governance_meetings set minutes_text=trim(p_minutes),attendee_count=p_attendee_count,status='completed',minutes_published_at=now(),updated_at=now() where id=p_meeting_id and network_id=nid;
 if not found then raise exception 'Meeting not found.'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_set_complaint_route(p_category text, p_role_key text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); ckey text:=public.hs4_category_key(p_category); rkey text:=trim(both '-' from regexp_replace(lower(trim(p_role_key)),'[^a-z0-9]+','-','g'));
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if length(rkey)<2 then raise exception 'Responsibility role is required.' using errcode='22023'; end if;
 insert into public.hs_complaint_routes(network_id,category_key,role_key,updated_by,updated_at)
 values(nid,ckey,rkey,auth.uid(),now())
 on conflict(network_id,category_key) do update set role_key=excluded.role_key,updated_by=auth.uid(),updated_at=now();
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_update_action_item(p_action_id uuid, p_status text, p_completion_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs4_assert_network();
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 if p_status not in ('open','in_progress','done','cancelled') then raise exception 'Invalid action status.'; end if;
 update public.hs_governance_action_items set status=p_status,completion_note=nullif(trim(p_completion_note),''),completed_at=case when p_status='done' then now() else null end,updated_at=now() where id=p_action_id and network_id=nid;
 if not found then raise exception 'Action item not found.'; end if;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs4_update_complaint(p_complaint_id uuid, p_status text DEFAULT NULL::text, p_assigned_to uuid DEFAULT NULL::uuid, p_assigned_vendor_id uuid DEFAULT NULL::uuid, p_sla_due_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_resolution_note text DEFAULT NULL::text)
 RETURNS uuid[]
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs2_assert_network(); oldrow public.hs_complaints; notification_ids uuid[]:='{}'; newstatus text;
begin
 if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501'; end if;
 select * into oldrow from public.hs_complaints where id=p_complaint_id and network_id=nid;
 if oldrow.id is null then raise exception 'Complaint not found.'; end if;
 if p_status is not null and p_status not in ('open','in_progress','resolved','closed','reopened') then raise exception 'Invalid complaint status.' using errcode='22023'; end if;
 if p_assigned_to is not null and not exists(select 1 from public.network_memberships nm where nm.network_id=nid and nm.user_id=p_assigned_to and nm.status='active') then raise exception 'Assignee must be an active society member.' using errcode='22023'; end if;
 if p_assigned_vendor_id is not null and not exists(select 1 from public.hs_vendors where id=p_assigned_vendor_id and network_id=nid) then raise exception 'Vendor not found.'; end if;
 newstatus:=coalesce(p_status,oldrow.status);
 update public.hs_complaints set status=newstatus,assigned_to=coalesce(p_assigned_to,assigned_to),assigned_vendor_id=coalesce(p_assigned_vendor_id,assigned_vendor_id),sla_due_at=coalesce(p_sla_due_at,sla_due_at),resolution_note=coalesce(nullif(trim(coalesce(p_resolution_note,'')),''),resolution_note),resolved_at=case when newstatus in ('resolved','closed') then coalesce(resolved_at,now()) when p_status='reopened' then null else resolved_at end,updated_at=now() where id=p_complaint_id and network_id=nid;
 return notification_ids;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_add_asset_service(p_asset_id uuid, p_service_type text, p_serviced_on date DEFAULT CURRENT_DATE, p_next_due_on date DEFAULT NULL::date, p_notes text DEFAULT NULL::text, p_cost numeric DEFAULT NULL::numeric)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not(public.is_network_admin(nid) or public.hs5_is_operator(nid,'facility')) then raise exception 'Facility operator access required.' using errcode='42501';end if;insert into public.hs_asset_service_records(network_id,asset_id,service_type,serviced_on,next_due_on,notes,cost,created_by) values(nid,p_asset_id,trim(p_service_type),coalesce(p_serviced_on,current_date),p_next_due_on,nullif(trim(p_notes),''),p_cost,auth.uid()) returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_assert_network()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.current_network_id();begin if nid is null or not public.is_network_member(nid) then raise exception 'Housing Society membership required.' using errcode='42501';end if;if coalesce((select vertical_kind from public.networks where id=nid),'')<>'housing-society' then raise exception 'HS-5 is available only for housing-society networks.' using errcode='22023';end if;return nid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_authorize_staff_unit(p_staff_id uuid, p_unit_entity_id uuid, p_starts_on date DEFAULT CURRENT_DATE, p_ends_on date DEFAULT NULL::date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not public.hs5_is_operator(nid,'security') then raise exception 'Security operator access required.' using errcode='42501';end if;insert into public.hs_staff_unit_permissions(network_id,staff_id,unit_entity_id,starts_on,ends_on,created_by) values(nid,p_staff_id,p_unit_entity_id,coalesce(p_starts_on,current_date),p_ends_on,auth.uid()) returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_create_move_request(p_unit_entity_id uuid, p_move_type text, p_scheduled_on date, p_contact_name text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not(public.is_network_admin(nid) or exists(select 1 from public.hs_unit_occupancy_history o join public.network_entities p on p.id=o.subject_entity_id where o.network_id=nid and o.unit_entity_id=p_unit_entity_id and o.ends_on is null and p.owner_user_id=auth.uid())) then raise exception 'Current-flat resident or admin required.' using errcode='42501';end if;insert into public.hs_move_requests(network_id,unit_entity_id,move_type,scheduled_on,contact_name,notes,created_by) values(nid,p_unit_entity_id,p_move_type,p_scheduled_on,nullif(trim(p_contact_name),''),nullif(trim(p_notes),''),auth.uid()) returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_create_renovation_request(p_unit_entity_id uuid, p_title text, p_description text DEFAULT NULL::text, p_contractor_name text DEFAULT NULL::text, p_starts_on date DEFAULT NULL::date, p_ends_on date DEFAULT NULL::date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not(public.is_network_admin(nid) or exists(select 1 from public.hs_unit_occupancy_history o join public.network_entities p on p.id=o.subject_entity_id where o.network_id=nid and o.unit_entity_id=p_unit_entity_id and o.ends_on is null and p.owner_user_id=auth.uid())) then raise exception 'Current-flat resident or admin required.' using errcode='42501';end if;insert into public.hs_renovation_requests(network_id,unit_entity_id,title,description,contractor_name,starts_on,ends_on,created_by) values(nid,p_unit_entity_id,trim(p_title),nullif(trim(p_description),''),nullif(trim(p_contractor_name),''),p_starts_on,p_ends_on,auth.uid()) returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_create_visitor(p_unit_entity_id uuid, p_visitor_name text, p_visit_type text DEFAULT 'guest'::text, p_expected_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_purpose text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_vehicle_number text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;allowed boolean;begin
 allowed:=public.hs5_is_operator(nid,'security') or exists(select 1 from public.hs_unit_occupancy_history o join public.network_entities p on p.id=o.subject_entity_id where o.network_id=nid and o.unit_entity_id=p_unit_entity_id and o.ends_on is null and p.owner_user_id=auth.uid());if not allowed then raise exception 'Current-flat resident or security access required.' using errcode='42501';end if;
 insert into public.hs_visitors(network_id,unit_entity_id,visitor_name,visit_type,expected_at,purpose,phone,vehicle_number,created_by) values(nid,p_unit_entity_id,trim(p_visitor_name),p_visit_type,p_expected_at,nullif(trim(p_purpose),''),nullif(trim(p_phone),''),nullif(upper(trim(p_vehicle_number)),'') ,auth.uid()) returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_get_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs5_assert_network(); isadm boolean:=public.is_network_admin(nid); issec boolean:=public.hs5_is_operator(nid,'security');
begin return jsonb_build_object(
 'isSecurityOperator',issec,
 'visitors',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'unitEntityId',v.unit_entity_id,'unitLabel',u.label,'visitorName',v.visitor_name,'phone',case when issec then v.phone else null end,'visitType',v.visit_type,'purpose',v.purpose,'vehicleNumber',v.vehicle_number,'expectedAt',v.expected_at,'enteredAt',v.entered_at,'exitedAt',v.exited_at,'status',v.status) order by coalesce(v.expected_at,v.created_at) desc) from public.hs_visitors v join public.network_entities u on u.id=v.unit_entity_id where v.network_id=nid and (issec or exists(select 1 from public.hs_unit_occupancy_history o join public.network_entities p on p.id=o.subject_entity_id where o.network_id=nid and o.unit_entity_id=v.unit_entity_id and o.ends_on is null and p.owner_user_id=auth.uid())) and v.created_at>now()-interval '30 days'),'[]'::jsonb),
 'staff',case when issec then coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'name',s.name,'staffType',s.staff_type,'phone',s.phone,'identityLast4',s.identity_last4,'verificationStatus',s.verification_status,'active',s.active,'units',coalesce((select jsonb_agg(jsonb_build_object('permissionId',p.id,'unitEntityId',p.unit_entity_id,'unitLabel',u.label,'startsOn',p.starts_on,'endsOn',p.ends_on,'status',p.status)) from public.hs_staff_unit_permissions p join public.network_entities u on u.id=p.unit_entity_id where p.staff_id=s.id and p.status='active'),'[]'::jsonb)) order by s.name) from public.hs_domestic_staff s where s.network_id=nid),'[]'::jsonb) else '[]'::jsonb end,
 'moveRequests',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'unitEntityId',r.unit_entity_id,'unitLabel',u.label,'moveType',r.move_type,'scheduledOn',r.scheduled_on,'contactName',r.contact_name,'notes',r.notes,'status',r.status,'reviewNote',r.review_note) order by r.scheduled_on desc) from public.hs_move_requests r join public.network_entities u on u.id=r.unit_entity_id where r.network_id=nid and (isadm or r.created_by=auth.uid())),'[]'::jsonb),
 'renovations',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'unitEntityId',r.unit_entity_id,'unitLabel',u.label,'title',r.title,'description',r.description,'contractorName',r.contractor_name,'startsOn',r.starts_on,'endsOn',r.ends_on,'status',r.status,'nocReference',r.noc_reference,'conditions',r.conditions) order by r.created_at desc) from public.hs_renovation_requests r join public.network_entities u on u.id=r.unit_entity_id where r.network_id=nid and (isadm or r.created_by=auth.uid())),'[]'::jsonb),
 'assets',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'assetCode',a.asset_code,'name',a.name,'category',a.category,'location',a.location,'status',a.status,'commissionedOn',a.commissioned_on,'warrantyUntil',a.warranty_until,'nextServiceOn',(select min(s.next_due_on) from public.hs_asset_service_records s where s.asset_id=a.id and s.next_due_on>=current_date)) order by a.category,a.name) from public.hs_assets a where a.network_id=nid),'[]'::jsonb),
 'compliance',coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'category',c.category,'title',c.title,'dueOn',c.due_on,'status',c.status,'ownerLabel',c.owner_label,'documentUrl',c.document_url,'visibility',c.visibility,'notes',c.notes) order by c.due_on nulls last,c.title) from public.hs_compliance_items c where c.network_id=nid and (isadm or c.visibility='members')),'[]'::jsonb),
 'emergencyContacts',coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'category',e.category,'label',e.label,'phone',e.phone,'notes',e.notes,'priority',e.priority) order by e.priority,e.label) from public.hs_emergency_contacts e where e.network_id=nid and e.active),'[]'::jsonb)
 );end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_grant_operator(p_user_id uuid, p_scope text DEFAULT 'security'::text, p_active boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;insert into public.hs_security_operator_grants(network_id,user_id,scope,active,created_by) values(nid,p_user_id,p_scope,p_active,auth.uid()) on conflict(network_id,user_id,scope) do update set active=excluded.active,updated_at=now() returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_is_operator(p_network_id uuid, p_scope text DEFAULT 'security'::text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$select public.is_network_admin(p_network_id) or exists(select 1 from public.hs_security_operator_grants g where g.network_id=p_network_id and g.user_id=auth.uid() and g.active and (g.scope=p_scope or (p_scope='security' and g.scope='facility')))$function$
;

CREATE OR REPLACE FUNCTION public.hs5_review_request(p_kind text, p_id uuid, p_status text, p_note text DEFAULT NULL::text, p_noc_reference text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;if p_kind='move' then update public.hs_move_requests set status=p_status,review_note=nullif(trim(p_note),''),reviewed_by=auth.uid(),updated_at=now() where id=p_id and network_id=nid;elsif p_kind='renovation' then update public.hs_renovation_requests set status=p_status,conditions=nullif(trim(p_note),''),noc_reference=nullif(trim(p_noc_reference),''),reviewed_by=auth.uid(),updated_at=now() where id=p_id and network_id=nid;else raise exception 'Invalid request kind.';end if;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_update_visitor_status(p_visitor_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();begin if not public.hs5_is_operator(nid,'security') then raise exception 'Security operator access required.' using errcode='42501';end if;if p_status not in ('inside','exited','cancelled','denied') then raise exception 'Invalid visitor status.';end if;update public.hs_visitors set status=p_status,entered_at=case when p_status='inside' then coalesce(entered_at,now()) else entered_at end,exited_at=case when p_status='exited' then now() else exited_at end,checked_by=auth.uid(),updated_at=now() where id=p_visitor_id and network_id=nid;if not found then raise exception 'Visitor not found.';end if;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_upsert_asset(p_id uuid, p_asset_code text, p_name text, p_category text, p_location text DEFAULT NULL::text, p_warranty_until date DEFAULT NULL::date)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;if p_id is null then insert into public.hs_assets(network_id,asset_code,name,category,location,warranty_until,created_by) values(nid,upper(trim(p_asset_code)),trim(p_name),trim(p_category),nullif(trim(p_location),''),p_warranty_until,auth.uid()) on conflict(network_id,asset_code) do update set name=excluded.name,category=excluded.category,location=excluded.location,warranty_until=excluded.warranty_until,updated_at=now() returning id into rid;else update public.hs_assets set asset_code=upper(trim(p_asset_code)),name=trim(p_name),category=trim(p_category),location=nullif(trim(p_location),''),warranty_until=p_warranty_until,updated_at=now() where id=p_id and network_id=nid returning id into rid;end if;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_upsert_compliance(p_id uuid, p_category text, p_title text, p_due_on date, p_owner_label text DEFAULT NULL::text, p_document_url text DEFAULT NULL::text, p_visibility text DEFAULT 'members'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not(public.is_network_admin(nid) or public.hs5_is_operator(nid,'compliance')) then raise exception 'Compliance operator access required.' using errcode='42501';end if;if p_id is null then insert into public.hs_compliance_items(network_id,category,title,due_on,owner_label,document_url,visibility,created_by) values(nid,trim(p_category),trim(p_title),p_due_on,nullif(trim(p_owner_label),''),nullif(trim(p_document_url),''),p_visibility,auth.uid()) returning id into rid;else update public.hs_compliance_items set category=trim(p_category),title=trim(p_title),due_on=p_due_on,owner_label=nullif(trim(p_owner_label),''),document_url=nullif(trim(p_document_url),''),visibility=p_visibility,updated_at=now() where id=p_id and network_id=nid returning id into rid;end if;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_upsert_emergency_contact(p_category text, p_label text, p_phone text, p_notes text DEFAULT NULL::text, p_priority integer DEFAULT 100)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;insert into public.hs_emergency_contacts(network_id,category,label,phone,notes,priority,created_by) values(nid,trim(p_category),trim(p_label),trim(p_phone),nullif(trim(p_notes),''),coalesce(p_priority,100),auth.uid()) on conflict(network_id,category,label) do update set phone=excluded.phone,notes=excluded.notes,priority=excluded.priority,active=true,updated_at=now() returning id into rid;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs5_upsert_staff(p_id uuid, p_name text, p_staff_type text, p_phone text DEFAULT NULL::text, p_identity_last4 text DEFAULT NULL::text, p_verification_status text DEFAULT 'pending'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare nid uuid:=public.hs5_assert_network();rid uuid;begin if not public.hs5_is_operator(nid,'security') then raise exception 'Security operator access required.' using errcode='42501';end if;if p_id is null then insert into public.hs_domestic_staff(network_id,name,staff_type,phone,identity_last4,verification_status,created_by) values(nid,trim(p_name),p_staff_type,nullif(trim(p_phone),''),nullif(trim(p_identity_last4),''),p_verification_status,auth.uid()) returning id into rid;else update public.hs_domestic_staff set name=trim(p_name),staff_type=p_staff_type,phone=nullif(trim(p_phone),''),identity_last4=nullif(trim(p_identity_last4),''),verification_status=p_verification_status,updated_at=now() where id=p_id and network_id=nid returning id into rid;end if;return rid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_assert_admin_network()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs6_assert_network();begin if not public.is_network_admin(nid) then raise exception 'Society admin access required.' using errcode='42501';end if;return nid;end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_assert_network()
 RETURNS uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Housing Society membership required.' using errcode='42501';end if;
 if coalesce((select vertical_kind from public.networks where id=nid),'')<>'housing-society' then raise exception 'HS-6 is available only for housing-society networks.' using errcode='22023';end if;
 return nid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_get_pilot_snapshot()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
 nid uuid:=public.hs6_assert_admin_network();run_row public.hs_pilot_runs%rowtype;latest_cp jsonb;units integer;occupied integer;claimed integer;active_units integer;members integer;notices30 integer;notice_readers integer;complaints30 integer;resolved30 integer;median_hours numeric;maintenance_views integer;billing_cycles integer;payments integer;meetings integer;security_cycles integer;imports integer;readiness integer;signals jsonb;
begin
 select * into run_row from public.hs_pilot_runs where network_id=nid order by (status='active') desc,created_at desc limit 1;
 select count(*) into units from public.network_entities where network_id=nid and kind='unit';
 select count(distinct unit_entity_id) into occupied from public.hs_unit_occupancy_history where network_id=nid and ends_on is null;
 select count(distinct o.unit_entity_id) into claimed from public.hs_unit_occupancy_history o join public.network_entities p on p.id=o.subject_entity_id where o.network_id=nid and o.ends_on is null and p.owner_user_id is not null;
 select count(distinct unit_entity_id) into active_units from public.hs_pilot_usage_events where network_id=nid and created_at>=now()-interval '7 days' and unit_entity_id is not null;
 select count(*) into members from public.network_memberships where network_id=nid and status='active';
 select count(*) into notices30 from public.hs_notices where network_id=nid and created_at>=now()-interval '30 days';
 select count(distinct user_id) into notice_readers from public.hs_notice_reads where network_id=nid and read_at>=now()-interval '30 days';
 select count(*) into complaints30 from public.hs_complaints where network_id=nid and created_at>=now()-interval '30 days';
 select count(*) into resolved30 from public.hs_complaints where network_id=nid and resolved_at is not null and resolved_at>=now()-interval '30 days';
 select round((percentile_cont(0.5) within group(order by extract(epoch from (resolved_at-created_at))/3600.0))::numeric,1) into median_hours from public.hs_complaints where network_id=nid and resolved_at is not null and resolved_at>=now()-interval '30 days';
 select count(*) into maintenance_views from public.hs_pilot_usage_events where network_id=nid and event_key='maintenance_view' and created_at>=now()-interval '30 days';
 select count(*) into billing_cycles from public.hs_billing_cycles where network_id=nid and status in ('issued','closed');
 select count(*) into payments from public.hs_payments where network_id=nid and status='recorded';
 select count(*) into meetings from public.hs_governance_meetings where network_id=nid and status='completed';
 select (select count(*) from public.hs_visitors where network_id=nid and status='exited')+(select count(*) from public.hs_asset_service_records where network_id=nid)+(select count(*) from public.hs_compliance_items where network_id=nid and status in ('compliant','completed')) into security_cycles;
 select count(*) into imports from public.hs_import_batches where network_id=nid and status='committed';
 select to_jsonb(c) into latest_cp from public.hs_pilot_checkpoints c where c.network_id=nid order by checkpoint_on desc,created_at desc limit 1;
 signals:=jsonb_build_array(
  jsonb_build_object('key','mapped_import','label','Mapped import completed','passed',imports>0),
  jsonb_build_object('key','target_units','label','Pilot unit target represented','passed',run_row.id is not null and units>=run_row.target_units),
  jsonb_build_object('key','claimed_units','label','Residents claimed real unit profiles','passed',claimed>0),
  jsonb_build_object('key','weekly_usage','label','Weekly active occupied units observed','passed',active_units>0),
  jsonb_build_object('key','notice_reach','label','Resident notice readership observed','passed',notice_readers>0),
  jsonb_build_object('key','complaint_loop','label','Complaint resolved end-to-end','passed',resolved30>0),
  jsonb_build_object('key','maintenance_cycle','label','Maintenance bill cycle represented','passed',billing_cycles>0),
  jsonb_build_object('key','governance_cycle','label','Committee/AGM meeting completed','passed',meetings>0),
  jsonb_build_object('key','operations_cycle','label','Security/compliance/asset operation completed','passed',security_cycles>0),
  jsonb_build_object('key','repeatable_onboarding','label','Second-society onboarding confirmed without founder-specific code','passed',coalesce((latest_cp->>'repeatable_onboarding_confirmed')::boolean,false) and not coalesce((latest_cp->>'founder_specific_code_required')::boolean,false))
 );
 select round(100.0*count(*) filter(where (x->>'passed')::boolean)/greatest(count(*),1))::integer into readiness from jsonb_array_elements(signals) x;
 return jsonb_build_object(
  'run',case when run_row.id is null then null else jsonb_build_object('id',run_row.id,'phase',run_row.phase,'status',run_row.status,'cohortLabel',run_row.cohort_label,'targetUnits',run_row.target_units,'startedOn',run_row.started_on,'endedOn',run_row.ended_on,'notes',run_row.notes) end,
  'readiness',coalesce(readiness,0),'signals',signals,
  'metrics',jsonb_build_object('totalUnits',units,'occupiedUnits',occupied,'claimedUnits',claimed,'claimRate',case when units=0 then 0 else round(100.0*claimed/units)::integer end,'weeklyActiveUnits',active_units,'activeMembers',members,'notices30d',notices30,'noticeReaders30d',notice_readers,'noticeReadReach',case when members=0 then 0 else least(100,round(100.0*notice_readers/members)::integer) end,'complaints30d',complaints30,'resolvedComplaints30d',resolved30,'medianResolutionHours',coalesce(median_hours,0),'maintenanceViews30d',maintenance_views,'billingCycles',billing_cycles,'paymentsRecorded',payments,'completedMeetings',meetings,'securityComplianceCycles',security_cycles,'committedImports',imports),
  'latestCheckpoint',latest_cp,
  'checkpoints',coalesce((select jsonb_agg(to_jsonb(c) order by c.checkpoint_on desc,c.created_at desc) from (select * from public.hs_pilot_checkpoints where network_id=nid order by checkpoint_on desc,created_at desc limit 12)c),'[]'::jsonb),
  'pricingExperiments',coalesce((select jsonb_agg(to_jsonb(p) order by p.tested_on desc,p.created_at desc) from (select * from public.hs_pilot_pricing_experiments where network_id=nid order by tested_on desc,created_at desc limit 12)p),'[]'::jsonb)
 );
end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_mark_notice_reads(p_notice_ids uuid[])
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs6_assert_network();n integer:=0;begin
 insert into public.hs_notice_reads(network_id,notice_id,user_id)
 select nid,n.id,auth.uid() from public.hs_notices n where n.network_id=nid and n.id=any(coalesce(p_notice_ids,'{}'::uuid[]))
 on conflict(network_id,notice_id,user_id) do update set read_at=greatest(public.hs_notice_reads.read_at,excluded.read_at);
 get diagnostics n=row_count;return n;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_record_checkpoint(p_run_id uuid, p_admin_hours_saved numeric DEFAULT NULL::numeric, p_offline_operations_remaining integer DEFAULT NULL::integer, p_willingness_to_pay text DEFAULT 'unknown'::text, p_renewal_intent text DEFAULT 'unknown'::text, p_repeatable_onboarding_confirmed boolean DEFAULT false, p_founder_specific_code_required boolean DEFAULT false, p_committee_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs6_assert_admin_network();rid uuid;begin
 if not exists(select 1 from public.hs_pilot_runs where id=p_run_id and network_id=nid) then raise exception 'Pilot run not found.';end if;
 insert into public.hs_pilot_checkpoints(network_id,pilot_run_id,admin_hours_saved,offline_operations_remaining,willingness_to_pay,renewal_intent,repeatable_onboarding_confirmed,founder_specific_code_required,committee_note,created_by)
 values(nid,p_run_id,p_admin_hours_saved,p_offline_operations_remaining,p_willingness_to_pay,p_renewal_intent,coalesce(p_repeatable_onboarding_confirmed,false),coalesce(p_founder_specific_code_required,false),nullif(trim(coalesce(p_committee_note,'')),''),auth.uid()) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_record_pricing_experiment(p_run_id uuid, p_pricing_model text, p_amount numeric DEFAULT NULL::numeric, p_currency text DEFAULT 'INR'::text, p_response text DEFAULT 'untested'::text, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs6_assert_admin_network();rid uuid;begin
 if p_run_id is not null and not exists(select 1 from public.hs_pilot_runs where id=p_run_id and network_id=nid) then raise exception 'Pilot run not found.';end if;
 insert into public.hs_pilot_pricing_experiments(network_id,pilot_run_id,pricing_model,amount,currency,response,notes,created_by)
 values(nid,p_run_id,p_pricing_model,p_amount,upper(coalesce(nullif(trim(p_currency),''),'INR')),p_response,nullif(trim(coalesce(p_notes,'')),''),auth.uid()) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_record_usage_event(p_event_key text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs6_assert_network();uid uuid;begin
 select o.unit_entity_id into uid from public.hs_unit_occupancy_history o join public.network_entities p on p.id=o.subject_entity_id where o.network_id=nid and o.ends_on is null and p.owner_user_id=auth.uid() order by o.is_primary desc,o.starts_on desc limit 1;
 insert into public.hs_pilot_usage_events(network_id,user_id,unit_entity_id,event_key,metadata) values(nid,auth.uid(),uid,p_event_key,coalesce(p_metadata,'{}'::jsonb));
end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_start_pilot(p_phase text DEFAULT 'B'::text, p_target_units integer DEFAULT 20, p_cohort_label text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs6_assert_admin_network();rid uuid;begin
 if p_phase not in ('A','B','C','D') then raise exception 'Invalid pilot phase.' using errcode='22023';end if;
 if coalesce(p_target_units,0)<1 or p_target_units>5000 then raise exception 'Pilot target must be between 1 and 5000 units.' using errcode='22023';end if;
 update public.hs_pilot_runs set status='paused',updated_at=now() where network_id=nid and status='active';
 insert into public.hs_pilot_runs(network_id,phase,status,cohort_label,target_units,started_on,notes,created_by)
 values(nid,p_phase,'active',nullif(trim(coalesce(p_cohort_label,'')),''),p_target_units,current_date,nullif(trim(coalesce(p_notes,'')),''),auth.uid()) returning id into rid;
 return rid;
end $function$
;

CREATE OR REPLACE FUNCTION public.hs6_update_pilot_status(p_run_id uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.hs6_assert_admin_network();begin
 if p_status not in ('planning','active','paused','completed','stopped') then raise exception 'Invalid pilot status.' using errcode='22023';end if;
 if p_status='active' then update public.hs_pilot_runs set status='paused',updated_at=now() where network_id=nid and status='active' and id<>p_run_id;end if;
 update public.hs_pilot_runs set status=p_status,started_on=case when p_status='active' then coalesce(started_on,current_date) else started_on end,ended_on=case when p_status in ('completed','stopped') then coalesce(ended_on,current_date) else null end,updated_at=now() where id=p_run_id and network_id=nid;
 if not found then raise exception 'Pilot run not found.';end if;
end $function$
;

SET check_function_bodies = on;
