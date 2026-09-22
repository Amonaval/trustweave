-- Mission 2 runtime repair — deterministic network media membership authorization.
-- Keeps tenant/user path isolation while avoiding implicit auth.uid() resolution inside Storage triggers.

create or replace function public.has_active_network_membership(p_network_id uuid,p_user_id uuid)
returns boolean
language sql security definer stable set search_path=public as $$
  select p_network_id is not null and p_user_id is not null and exists(
    select 1 from public.network_memberships nm
    join public.networks n on n.id=nm.network_id and n.status='active'
    where nm.network_id=p_network_id and nm.user_id=p_user_id and nm.status='active'
  );
$$;
revoke all on function public.has_active_network_membership(uuid,uuid) from public;
grant execute on function public.has_active_network_membership(uuid,uuid) to authenticated;

create or replace function public.storage_path_owner_user_id(p_object_name text)
returns uuid
language plpgsql immutable set search_path=public as $$
declare v text:=split_part(coalesce(p_object_name,''),'/',3);
begin
  if v='' then return null; end if;
  begin return v::uuid; exception when others then return null; end;
end $$;
revoke all on function public.storage_path_owner_user_id(text) from public;
grant execute on function public.storage_path_owner_user_id(text) to authenticated;

-- Preflight used by the browser immediately before Storage upload.
-- It may heal only a missing creator membership. A left/suspended membership is never reactivated here.
create or replace function public.prepare_network_media_upload(p_network_id uuid)
returns jsonb
language plpgsql security definer set search_path=public as $$
declare uid uuid:=auth.uid();membership_status text;creator uuid;enabled boolean;max_bytes integer;lim bigint;
begin
  if uid is null then raise exception 'Sign in required before uploading media.' using errcode='42501'; end if;
  select n.created_by,n.photo_upload_enabled,n.photo_max_bytes,n.storage_limit_bytes
    into creator,enabled,max_bytes,lim from public.networks n where n.id=p_network_id and n.status='active';
  if creator is null then raise exception 'Network was not found.' using errcode='P0002'; end if;

  select nm.status into membership_status from public.network_memberships nm
   where nm.network_id=p_network_id and nm.user_id=uid;

  if membership_status is null then
    if creator<>uid then raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501'; end if;
    insert into public.network_memberships(network_id,user_id,role,status)
      values(p_network_id,uid,'owner','active')
      on conflict(network_id,user_id) do nothing;
    membership_status:='active';
  elsif membership_status<>'active' then
    raise exception 'Your membership in this network is not active.' using errcode='42501';
  end if;

  if not public.has_active_network_membership(p_network_id,uid) then
    raise exception 'Media membership authorization could not be verified.' using errcode='42501';
  end if;
  return jsonb_build_object('network_id',p_network_id,'photo_upload_enabled',coalesce(enabled,false),'photo_max_bytes',coalesce(max_bytes,102400),'storage_limit_bytes',coalesce(lim,0));
end $$;
revoke all on function public.prepare_network_media_upload(uuid) from public;
grant execute on function public.prepare_network_media_upload(uuid) to authenticated;

create or replace function public.a5_storage_guard() returns trigger
language plpgsql security definer set search_path=public,storage as $$
declare nid uuid;actor uuid;request_uid uuid:=auth.uid();bytes bigint;old_bytes bigint:=0;lim bigint;max_file integer;current_usage bigint;mime text;
begin
  if new.bucket_id not in ('profile-photos','community-media') then return new; end if;
  nid:=public.storage_path_network_id(new.name);actor:=public.storage_path_owner_user_id(new.name);
  if nid is null then raise exception 'Network media path must begin with the network id.' using errcode='22023'; end if;
  if actor is null then raise exception 'Network media path must include the uploading user id.' using errcode='22023'; end if;
  if request_uid is not null and actor<>request_uid then raise exception 'Media path does not belong to the signed-in user.' using errcode='42501'; end if;
  if not public.has_active_network_membership(nid,actor) then raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501'; end if;

  bytes:=public.storage_object_metadata_bytes(new.metadata);
  mime:=lower(coalesce(new.metadata->>'mimetype',new.metadata->>'contentType',new.metadata->>'content_type',''));
  if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023'; end if;
  select storage_limit_bytes,photo_max_bytes,media_usage_bytes into lim,max_file,current_usage from public.networks where id=nid for update;
  if lim is null then raise exception 'Network was not found.' using errcode='P0002'; end if;
  current_usage:=greatest(coalesce(current_usage,0),coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid),0));
  if bytes>0 and bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
  if tg_op='UPDATE' then old_bytes:=public.storage_object_metadata_bytes(old.metadata); end if;
  if bytes>0 and current_usage-old_bytes+bytes>lim then raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023'; end if;
  return new;
end $$;

-- RLS independently proves that the user encoded in the object path is the authenticated user.
drop policy if exists "authenticated can upload profile photos" on storage.objects;
create policy "authenticated can upload profile photos" on storage.objects for insert to authenticated with check (
 bucket_id='profile-photos'
 and public.storage_path_owner_user_id(name)=auth.uid()
 and public.has_active_network_membership(public.storage_path_network_id(name),auth.uid())
 and (storage.foldername(name))[2]='profiles'
);
drop policy if exists "authenticated can update own profile photos" on storage.objects;
create policy "authenticated can update own profile photos" on storage.objects for update to authenticated using (
 bucket_id='profile-photos' and public.storage_path_owner_user_id(name)=auth.uid()
 and public.has_active_network_membership(public.storage_path_network_id(name),auth.uid())
) with check (
 bucket_id='profile-photos' and public.storage_path_owner_user_id(name)=auth.uid()
 and public.has_active_network_membership(public.storage_path_network_id(name),auth.uid())
);
drop policy if exists "authenticated can delete own profile photos" on storage.objects;
create policy "authenticated can delete own profile photos" on storage.objects for delete to authenticated using (
 bucket_id='profile-photos'
 and public.has_active_network_membership(public.storage_path_network_id(name),auth.uid())
 and (public.storage_path_owner_user_id(name)=auth.uid() or public.is_network_admin(public.storage_path_network_id(name)))
);

drop policy if exists "authenticated can upload community media" on storage.objects;
create policy "authenticated can upload community media" on storage.objects for insert to authenticated with check (
 bucket_id='community-media'
 and public.storage_path_owner_user_id(name)=auth.uid()
 and public.has_active_network_membership(public.storage_path_network_id(name),auth.uid())
 and (storage.foldername(name))[2]='community'
);
drop policy if exists "authenticated can delete community media" on storage.objects;
create policy "authenticated can delete community media" on storage.objects for delete to authenticated using (
 bucket_id='community-media'
 and public.has_active_network_membership(public.storage_path_network_id(name),auth.uid())
 and (public.storage_path_owner_user_id(name)=auth.uid() or public.is_network_admin(public.storage_path_network_id(name)))
);

-- Re-assert registry authorization using the explicit actor/path contract too.
create or replace function public.register_network_media_asset(
  p_bucket text,p_object_path text,p_thumbnail_path text default null,p_media_kind text default 'other',p_entity_type text default null,p_entity_id text default null,
  p_mime_type text default 'image/webp',p_bytes bigint default 0,p_thumbnail_bytes bigint default 0,p_width integer default null,p_height integer default null
) returns uuid
language plpgsql security definer set search_path=public,storage as $$
declare nid uuid:=public.storage_path_network_id(p_object_path);uid uuid:=auth.uid();rid uuid;expected_scope text;max_file integer;lim bigint;object_bytes bigint;thumb_bytes bigint;
begin
 if uid is null or nid is null or not public.has_active_network_membership(nid,uid) then raise exception 'Network membership required for the media path.' using errcode='42501'; end if;
 if public.storage_path_owner_user_id(p_object_path)<>uid then raise exception 'Media path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 if p_bucket not in ('profile-photos','community-media') then raise exception 'Unsupported media bucket.' using errcode='22023'; end if;
 if p_media_kind not in ('profile','memory','event','announcement','complaint','post','other') then raise exception 'Unsupported media kind.' using errcode='22023'; end if;
 expected_scope:=case when p_bucket='profile-photos' then 'profiles' else 'community' end;
 if coalesce(p_object_path,'') not like nid::text||'/'||expected_scope||'/'||uid::text||'/%' then raise exception 'Media path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 if nullif(p_thumbnail_path,'') is not null and (public.storage_path_owner_user_id(p_thumbnail_path)<>uid or p_thumbnail_path not like nid::text||'/'||expected_scope||'/'||uid::text||'/%') then raise exception 'Thumbnail path is not owned by the signed-in member in this network.' using errcode='42501'; end if;
 select photo_max_bytes,storage_limit_bytes into max_file,lim from public.networks where id=nid;
 select public.storage_object_metadata_bytes(o.metadata) into object_bytes from storage.objects o where o.bucket_id=p_bucket and o.name=p_object_path;
 if not found then raise exception 'Uploaded media object was not found.' using errcode='P0002'; end if;
 if nullif(p_thumbnail_path,'') is not null then select public.storage_object_metadata_bytes(o.metadata) into thumb_bytes from storage.objects o where o.bucket_id=p_bucket and o.name=p_thumbnail_path; end if;
 object_bytes:=greatest(coalesce(nullif(object_bytes,0),p_bytes,0),0);thumb_bytes:=greatest(coalesce(nullif(thumb_bytes,0),p_thumbnail_bytes,0),0);
 if object_bytes<=0 then raise exception 'Uploaded image size could not be verified after upload.' using errcode='22023'; end if;
 if object_bytes>max_file or thumb_bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
 if coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid and not (m.bucket=p_bucket and m.object_path=p_object_path)),0)+object_bytes+thumb_bytes>lim then raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023'; end if;
 insert into public.network_media_assets(network_id,owner_user_id,bucket,object_path,thumbnail_path,media_kind,entity_type,entity_id,mime_type,bytes,thumbnail_bytes,width,height)
 values(nid,uid,p_bucket,p_object_path,nullif(p_thumbnail_path,''),p_media_kind,nullif(trim(p_entity_type),''),nullif(trim(p_entity_id),''),coalesce(nullif(p_mime_type,''),'image/webp'),object_bytes,thumb_bytes,p_width,p_height)
 on conflict(bucket,object_path) do update set thumbnail_path=excluded.thumbnail_path,media_kind=excluded.media_kind,entity_type=coalesce(excluded.entity_type,network_media_assets.entity_type),entity_id=coalesce(excluded.entity_id,network_media_assets.entity_id),mime_type=excluded.mime_type,bytes=excluded.bytes,thumbnail_bytes=excluded.thumbnail_bytes,width=excluded.width,height=excluded.height,updated_at=now()
 returning id into rid;
 update public.networks n set media_usage_bytes=greatest(n.media_usage_bytes,coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid),0)),updated_at=now() where n.id=nid;
 return rid;
end $$;
revoke all on function public.register_network_media_asset(text,text,text,text,text,text,text,bigint,bigint,integer,integer) from public;
grant execute on function public.register_network_media_asset(text,text,text,text,text,text,text,bigint,bigint,integer,integer) to authenticated;

notify pgrst, 'reload schema';
