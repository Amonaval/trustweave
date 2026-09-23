-- VIS3 media core repair.
-- SOURCE ONLY. Apply explicitly after 128 (and the existing media migrations) when activating this runtime.
-- Restores the stronger network-media guard from migration 116 while adding the
-- platform/<owner-id>/... exception required by Design Studio.

create or replace function public.a5_storage_guard() returns trigger
language plpgsql security definer set search_path=public,storage as $$
declare
  nid uuid; actor uuid; request_uid uuid:=auth.uid(); bytes bigint; old_bytes bigint:=0;
  lim bigint; max_file integer; current_usage bigint; mime text;
begin
  if new.bucket_id not in ('profile-photos','community-media') then return new; end if;
  bytes:=public.storage_object_metadata_bytes(new.metadata);
  mime:=lower(coalesce(new.metadata->>'mimetype',new.metadata->>'contentType',new.metadata->>'content_type',''));

  if new.bucket_id='community-media' and new.name like 'platform/%' then
    if request_uid is null or not public.is_platform_owner() then
      raise exception 'Platform-owner access is required for platform visuals.' using errcode='42501';
    end if;
    if new.name not like 'platform/'||request_uid::text||'/%' then
      raise exception 'Platform visual path must be owned by the signed-in platform owner.' using errcode='42501';
    end if;
    if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then
      raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023';
    end if;
    if bytes>2097152 then raise exception 'Platform image exceeds the 2 MB storage guard.' using errcode='22023'; end if;
    return new;
  end if;

  nid:=public.storage_path_network_id(new.name);
  actor:=public.storage_path_owner_user_id(new.name);
  if nid is null then raise exception 'Network media path must begin with the network id.' using errcode='22023'; end if;
  if actor is null then raise exception 'Network media path must include the uploading user id.' using errcode='22023'; end if;
  if request_uid is not null and actor<>request_uid then raise exception 'Media path does not belong to the signed-in user.' using errcode='42501'; end if;
  if not public.has_active_network_membership(nid,actor) then raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501'; end if;
  if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023'; end if;

  select storage_limit_bytes,photo_max_bytes,media_usage_bytes into lim,max_file,current_usage
    from public.networks where id=nid for update;
  if lim is null then raise exception 'Network was not found.' using errcode='P0002'; end if;
  current_usage:=greatest(coalesce(current_usage,0),coalesce((select sum(m.bytes+m.thumbnail_bytes) from public.network_media_assets m where m.network_id=nid),0));
  if bytes>0 and bytes>max_file then raise exception 'Image exceeds this network''s % KB upload limit.',ceil(max_file/1024.0) using errcode='22023'; end if;
  if tg_op='UPDATE' then old_bytes:=public.storage_object_metadata_bytes(old.metadata); end if;
  if bytes>0 and current_usage-old_bytes+bytes>lim then raise exception 'Network storage limit reached. Remove older photos or use a smaller image.' using errcode='22023'; end if;
  return new;
end $$;

notify pgrst, 'reload schema';
