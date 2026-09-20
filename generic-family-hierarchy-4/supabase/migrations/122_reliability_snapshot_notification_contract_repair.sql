-- Reliability repair: restore the complete Housing operations snapshot after
-- migration 121 narrowed it to complaints, and restore the notification-role
-- read contract observed missing from the connected staging schema cache.

create or replace function public.get_network_notification_roles()
returns table(role_key varchar,label varchar,user_id uuid,email text,member_label text,active boolean,updated_at timestamptz)
language sql security definer stable set search_path=public as $$
 select r.role_key,r.label,r.user_id,u.email::text,coalesce(p.full_name,u.raw_user_meta_data->>'full_name',split_part(coalesce(u.email,''),'@',1))::text,r.active,r.updated_at
 from public.network_notification_roles r
 join auth.users u on u.id=r.user_id
 left join public.profiles p on p.id=r.user_id
 where r.network_id=public.current_network_id() and public.is_network_member(r.network_id)
 order by r.role_key,member_label;
$$;
revoke all on function public.get_network_notification_roles() from public;
grant execute on function public.get_network_notification_roles() to authenticated;

create or replace function public.hs4_get_operations_snapshot() returns jsonb
language plpgsql security definer stable set search_path=public as $$
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
end $$;
revoke all on function public.hs4_get_operations_snapshot() from public;
grant execute on function public.hs4_get_operations_snapshot() to authenticated;

do $$
begin
 if to_regprocedure('public.get_network_notification_roles()') is null then raise exception 'Reliability repair failed: notification-role RPC missing.'; end if;
 if to_regprocedure('public.hs4_get_operations_snapshot()') is null then raise exception 'Reliability repair failed: Housing snapshot RPC missing.'; end if;
end $$;

notify pgrst, 'reload schema';
