-- Final launch runtime contract repair.
-- Repairs live-schema drift and launch blockers found during real seeded-network rehearsal.
-- Additive/idempotent: safe to apply after 113.

-- 1) Restore the E3 mention-routing contract if an earlier migration was skipped or schema cache drifted.
create or replace function public.route_network_mentions(
 p_mentions text[],p_title text,p_body text,p_surface text,p_entity_type text default null,p_entity_id uuid default null,p_priority text default 'normal'
) returns uuid[]
language plpgsql security definer set search_path=public as $$
declare nid uuid:=public.current_network_id(); token text; key text; target uuid; ids uuid[]:='{}'; nid_out uuid;
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Active network required.' using errcode='42501';end if;
 foreach token in array coalesce(p_mentions,'{}'::text[]) loop
  key:=trim(both '-' from regexp_replace(lower(trim(leading '@' from token)),'[^a-z0-9]+','-','g'));
  if key='' then continue;end if;
  for target in
    select distinct x.user_id from (
      select nm.user_id from public.network_memberships nm where nm.network_id=nid and nm.status='active' and ((key in ('owner','owners') and nm.role='owner') or (key in ('admin','admins','board') and nm.role in ('owner','admin')))
      union all
      select r.user_id from public.network_notification_roles r where r.network_id=nid and r.active and r.role_key=key
      union all
      select nm.user_id from public.network_memberships nm join auth.users u on u.id=nm.user_id left join public.profiles p on p.id=nm.user_id
       where nm.network_id=nid and nm.status='active' and (trim(both '-' from regexp_replace(lower(split_part(coalesce(u.email,''),'@',1)),'[^a-z0-9]+','-','g'))=key or trim(both '-' from regexp_replace(lower(coalesce(p.full_name,'')),'[^a-z0-9]+','-','g'))=key)
    ) x
  loop
    if target=auth.uid() then continue;end if;
    nid_out:=public.create_network_notification(nid,target,'mention',p_title,p_body,p_surface,p_entity_type,p_entity_id,p_priority,jsonb_build_object('mention',key,'surface',p_surface),auth.uid());ids:=array_append(ids,nid_out);
  end loop;
 end loop;
 return (select coalesce(array_agg(distinct i),'{}'::uuid[]) from unnest(ids) i);
end $$;
revoke all on function public.route_network_mentions(text[],text,text,text,text,uuid,text) from public;grant execute on function public.route_network_mentions(text[],text,text,text,text,uuid,text) to authenticated;

-- 2) Restore the Residential operations snapshot contract used by the live Housing UI.
create or replace function public.hs4_get_operations_snapshot() returns jsonb language plpgsql security definer stable set search_path=public as $$
declare nid uuid:=public.hs2_assert_network(); isadm boolean:=public.is_network_admin(nid);
begin
 return jsonb_build_object(
  'notices',coalesce((select jsonb_agg(jsonb_build_object('id',n.id,'title',n.title,'body',n.body,'noticeType',n.notice_type,'pinned',n.pinned,'expiresAt',n.expires_at,'createdAt',n.created_at,'createdBy',n.created_by) order by n.pinned desc,n.created_at desc) from public.hs_notices n where n.network_id=nid and (n.expires_at is null or n.expires_at>now())),'[]'::jsonb),
  'complaints',coalesce((select jsonb_agg(jsonb_build_object('id',c.id,'unitEntityId',c.unit_entity_id,'unitLabel',u.label,'category',c.category,'title',c.title,'description',c.description,'attachments',c.attachments,'priority',c.priority,'status',c.status,'slaDueAt',c.sla_due_at,'assignedTo',c.assigned_to,'assignedToLabel',coalesce(ae.label,au.email),'assignedVendorId',c.assigned_vendor_id,'resolutionNote',c.resolution_note,'createdAt',c.created_at,'updatedAt',c.updated_at,'createdBy',c.created_by,'comments',coalesce((select jsonb_agg(jsonb_build_object('id',cc.id,'body',cc.body,'createdAt',cc.created_at,'authorLabel',coalesce(ne.label,cu.email,'Member')) order by cc.created_at) from public.hs_complaint_comments cc left join auth.users cu on cu.id=cc.created_by left join public.network_entities ne on ne.network_id=nid and ne.owner_user_id=cc.created_by where cc.complaint_id=c.id),'[]'::jsonb)) order by c.created_at desc)
    from public.hs_complaints c left join public.network_entities u on u.id=c.unit_entity_id and u.network_id=nid left join auth.users au on au.id=c.assigned_to left join public.network_entities ae on ae.network_id=nid and ae.owner_user_id=c.assigned_to
    where c.network_id=nid and (isadm or c.created_by=auth.uid() or c.assigned_to=auth.uid())),'[]'::jsonb),
  'vendors',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'name',v.name,'category',v.category,'contactName',v.contact_name,'phone',case when isadm then v.phone else null end,'email',case when isadm then v.email else null end,'status',v.status,'contractCount',(select count(*) from public.hs_vendor_contracts vc where vc.vendor_id=v.id)) order by v.name) from public.hs_vendors v where v.network_id=nid and (isadm or v.status='active')),'[]'::jsonb),
  'amenities',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'name',a.name,'description',a.description,'location',a.location,'capacity',a.capacity,'bookingMode',a.booking_mode,'status',a.status) order by a.name) from public.hs_amenities a where a.network_id=nid),'[]'::jsonb),
  'bookings',coalesce((select jsonb_agg(jsonb_build_object('id',b.id,'amenityId',b.amenity_id,'amenityName',a.name,'unitEntityId',b.unit_entity_id,'startsAt',b.starts_at,'endsAt',b.ends_at,'status',b.status,'purpose',b.purpose,'createdBy',b.created_by) order by b.starts_at desc) from public.hs_amenity_bookings b join public.hs_amenities a on a.id=b.amenity_id where b.network_id=nid and (isadm or b.created_by=auth.uid()) and b.starts_at>now()-interval '30 days'),'[]'::jsonb)
 );
end $$;
revoke all on function public.hs4_get_operations_snapshot() from public;grant execute on function public.hs4_get_operations_snapshot() to authenticated;

-- 3) Fix funds snapshot against the actual network_activities schema (`activity_type`, not `type`).
create or replace function public.get_network_funds_snapshot()
returns jsonb
language plpgsql security definer stable set search_path=public as $$
declare nid uuid:=public.current_network_id(); admin boolean; mode text:='admins'; result jsonb;
begin
 if nid is null or not public.is_network_member(nid) then raise exception 'Network membership required.' using errcode='42501'; end if;
 admin:=public.is_network_admin(nid);
 if exists(select 1 from public.networks where id=nid and vertical_kind='family-association') then
   select coalesce(s.finance_visibility,'admins') into mode from public.family_association_settings s where s.network_id=nid;
 end if;
 result:=jsonb_build_object(
  'is_admin',admin,'visibility_mode',mode,
  'funds',coalesce((select jsonb_agg(jsonb_build_object(
    'id',f.id,'name',f.name,'fund_kind',f.fund_kind,'purpose',f.purpose,'target_amount',f.target_amount,'opening_balance',f.opening_balance,
    'visibility',f.visibility,'status',f.status,'membership_year_id',f.membership_year_id,'activity_id',f.activity_id,
    'activity_title',a.title,'year_label',y.label,
    'collected',coalesce((select sum(t.amount) from public.network_fund_transactions t where t.fund_id=f.id and t.transaction_kind in ('collection','transfer_in')),0),
    'spent',coalesce((select sum(t.amount) from public.network_fund_transactions t where t.fund_id=f.id and t.transaction_kind in ('expense','refund','transfer_out')),0),
    'balance',f.opening_balance+coalesce((select sum(public.e6_fund_signed_amount(t.transaction_kind,t.amount)) from public.network_fund_transactions t where t.fund_id=f.id),0)
   ) order by f.status,f.created_at desc)
   from public.network_funds f left join public.network_activities a on a.id=f.activity_id and a.network_id=f.network_id
   left join public.family_association_membership_years y on y.id=f.membership_year_id and y.network_id=f.network_id
   where f.network_id=nid and (admin or (mode<>'admins' and f.visibility<>'admins'))),'[]'::jsonb),
  'transactions',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'fund_id',t.fund_id,'fund_name',f.name,'transaction_kind',t.transaction_kind,'amount',t.amount,'signed_amount',public.e6_fund_signed_amount(t.transaction_kind,t.amount),'source_entity_id',t.source_entity_id,'source_label',e.label,'receipt_no',t.receipt_no,'payment_method',t.payment_method,'reference',t.reference,'note',t.note,'visibility',t.visibility,'occurred_on',t.occurred_on,'created_at',t.created_at) order by t.occurred_on desc,t.created_at desc)
   from public.network_fund_transactions t join public.network_funds f on f.id=t.fund_id left join public.network_entities e on e.id=t.source_entity_id and e.network_id=t.network_id
   where t.network_id=nid and (admin or (mode='members' and t.visibility<>'admins') or (mode='highlighted' and t.visibility='highlighted'))),'[]'::jsonb),
  'membership_dues',case when admin then coalesce((select jsonb_agg(jsonb_build_object('membership_id',m.id,'membership_year_id',m.membership_year_id,'year_label',y.label,'family_entity_id',m.family_entity_id,'family_label',f.label,'representative_label',r.label,'amount_due',m.amount_due,'amount_paid',m.amount_paid,'outstanding',greatest(m.amount_due-m.amount_paid,0),'payment_status',m.payment_status,'status',m.status) order by y.start_date desc,f.label)
    from public.family_association_family_memberships m join public.family_association_membership_years y on y.id=m.membership_year_id join public.network_entities f on f.id=m.family_entity_id left join public.network_entities r on r.id=m.representative_entity_id where m.network_id=nid and m.status in ('active','grace','pending')),'[]'::jsonb) else '[]'::jsonb end,
  'events',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'title',a.title,'starts_at',a.starts_at) order by a.starts_at desc nulls last) from public.network_activities a where a.network_id=nid and a.activity_type='event'),'[]'::jsonb)
 );
 return result;
end $$;
revoke all on function public.get_network_funds_snapshot() from public;
grant execute on function public.get_network_funds_snapshot() to authenticated;

-- 4) Explicit Open Voting means open immediately. A future opens_at is a schedule, not an opened ballot.
create or replace function public.open_network_ballot(p_ballot_id uuid) returns integer
language plpgsql security definer set search_path=public as $$ declare nid uuid:=public.current_network_id();b public.network_ballots%rowtype;r record;cnt int:=0;begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;select * into b from public.network_ballots where id=p_ballot_id and network_id=nid and status='draft';if not found then raise exception 'Draft ballot not found.';end if;
 if (select count(*) from public.network_ballot_options where ballot_id=b.id)<2 then raise exception 'At least two ballot choices are required.';end if;
 delete from public.network_ballot_eligibility where ballot_id=b.id;
 if b.eligibility_mode='members' then
  insert into public.network_ballot_eligibility(network_id,ballot_id,user_id,source) select nid,b.id,nm.user_id,'member' from public.network_memberships nm where nm.network_id=nid and nm.status='active' on conflict do nothing;
 elsif b.eligibility_mode='admins' then
  insert into public.network_ballot_eligibility(network_id,ballot_id,user_id,source) select nid,b.id,nm.user_id,'admin' from public.network_memberships nm where nm.network_id=nid and nm.status='active' and nm.role in ('owner','admin') on conflict do nothing;
 else
  insert into public.network_ballot_eligibility(network_id,ballot_id,user_id,source)
  select distinct nid,b.id,rep.owner_user_id,'family_representative' from public.family_association_family_memberships m join public.family_association_membership_years y on y.id=m.membership_year_id and y.network_id=m.network_id join public.network_entities rep on rep.id=m.representative_entity_id and rep.network_id=m.network_id join public.network_memberships nm on nm.network_id=m.network_id and nm.user_id=rep.owner_user_id and nm.status='active' where m.network_id=nid and m.status in ('active','grace') and y.status='open' and rep.owner_user_id is not null on conflict do nothing;
 end if;
 select count(*) into cnt from public.network_ballot_eligibility where ballot_id=b.id;if cnt=0 then raise exception 'No eligible voters were found for this ballot.';end if;
 update public.network_ballots set status='open',opens_at=now(),updated_at=now() where id=b.id;
 for r in select user_id from public.network_ballot_eligibility where ballot_id=b.id loop perform public.create_network_notification(nid,r.user_id,'ballot_opened',case when b.ballot_type='election' then 'Election voting is open' else 'New poll is open' end,b.title,'elections','ballot',b.id,'high',jsonb_build_object('ballot_type',b.ballot_type),auth.uid());end loop;
 insert into public.audit_log(network_id,actor_id,action,details) values(nid,auth.uid(),'network_ballot_opened',jsonb_build_object('ballot_id',b.id,'eligible_voters',cnt));return cnt;
end $$;
revoke all on function public.open_network_ballot(uuid) from public;grant execute on function public.open_network_ballot(uuid) to authenticated;

-- 5) Storage authorization must be based on the network encoded in the object path + active membership.
--    Do not couple Storage inserts to whichever network happens to be active in a profile row.
create or replace function public.storage_path_network_id(p_object_name text) returns uuid
language plpgsql immutable set search_path=public as $$
declare v text:=split_part(coalesce(p_object_name,''),'/',1);
begin
 if v='' then return null; end if;
 begin return v::uuid; exception when others then return null; end;
end $$;
revoke all on function public.storage_path_network_id(text) from public;
grant execute on function public.storage_path_network_id(text) to authenticated;

create or replace function public.a5_storage_guard() returns trigger
language plpgsql security definer set search_path=public,storage as $$
declare
  nid uuid; bytes bigint; old_bytes bigint:=0; lim bigint; max_file integer; current_usage bigint;
begin
  if new.bucket_id not in ('profile-photos','community-media') then return new; end if;
  nid:=public.storage_path_network_id(new.name);
  if nid is null then
    raise exception 'Network media path must begin with the network id.' using errcode='22023';
  end if;
  if not public.is_network_member(nid) then
    raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501';
  end if;
  bytes:=coalesce((new.metadata->>'size')::bigint,0);
  select storage_limit_bytes,photo_max_bytes,media_usage_bytes into lim,max_file,current_usage
  from public.networks where id=nid for update;
  if lim is null then raise exception 'Network was not found.' using errcode='P0002'; end if;
  if bytes<=0 then raise exception 'Uploaded image size could not be verified.' using errcode='22023'; end if;
  if bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
  if tg_op='UPDATE' then old_bytes:=coalesce((old.metadata->>'size')::bigint,0); end if;
  if current_usage-old_bytes+bytes>lim then
    raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023';
  end if;
  return new;
end $$;

-- Keep uploads tenant-prefixed and user-owned, but allow any active member of that encoded network.
drop policy if exists "authenticated can upload profile photos" on storage.objects;
create policy "authenticated can upload profile photos" on storage.objects for insert to authenticated with check (
 bucket_id='profile-photos'
 and public.is_network_member(public.storage_path_network_id(name))
 and (storage.foldername(name))[2]='profiles'
 and (storage.foldername(name))[3]=auth.uid()::text
);
drop policy if exists "authenticated can update own profile photos" on storage.objects;
create policy "authenticated can update own profile photos" on storage.objects for update to authenticated using (
 bucket_id='profile-photos'
 and public.is_network_member(public.storage_path_network_id(name))
 and (storage.foldername(name))[2]='profiles'
 and (storage.foldername(name))[3]=auth.uid()::text
) with check (
 bucket_id='profile-photos'
 and public.is_network_member(public.storage_path_network_id(name))
 and (storage.foldername(name))[2]='profiles'
 and (storage.foldername(name))[3]=auth.uid()::text
);
drop policy if exists "authenticated can delete own profile photos" on storage.objects;
create policy "authenticated can delete own profile photos" on storage.objects for delete to authenticated using (
 bucket_id='profile-photos'
 and public.is_network_member(public.storage_path_network_id(name))
 and ((storage.foldername(name))[2]='profiles' and (storage.foldername(name))[3]=auth.uid()::text or public.is_network_admin(public.storage_path_network_id(name)))
);

drop policy if exists "authenticated can upload community media" on storage.objects;
create policy "authenticated can upload community media" on storage.objects for insert to authenticated with check (
 bucket_id='community-media'
 and public.is_network_member(public.storage_path_network_id(name))
 and (storage.foldername(name))[2]='community'
 and (storage.foldername(name))[3]=auth.uid()::text
);
drop policy if exists "authenticated can delete community media" on storage.objects;
create policy "authenticated can delete community media" on storage.objects for delete to authenticated using (
 bucket_id='community-media'
 and public.is_network_member(public.storage_path_network_id(name))
 and ((storage.foldername(name))[2]='community' and (storage.foldername(name))[3]=auth.uid()::text or public.is_network_admin(public.storage_path_network_id(name)))
);

-- Ask PostgREST to refresh immediately after the repaired RPC contracts are installed.
notify pgrst, 'reload schema';
