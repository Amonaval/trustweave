-- VIS3 final platform-media repair.
-- Runtime-proven on the active Supabase project before promotion to source.
--
-- Design principle:
--   * platform/<owner-id>/... objects are authorized by explicit Storage RLS;
--   * the shared BEFORE trigger validates media shape/size when available but does not
--     duplicate platform-owner authorization;
--   * ordinary network media keeps the strong Mission-2 membership/user/path/quota guard.
--
-- This supersedes the platform branch introduced by 128 and refined by 129.

create or replace function public.a5_storage_guard()
returns trigger
language plpgsql
security definer
set search_path=public,storage
as $$
declare
  nid uuid;
  actor uuid;
  request_uid uuid:=auth.uid();
  bytes bigint:=0;
  old_bytes bigint:=0;
  lim bigint;
  max_file integer;
  current_usage bigint;
  mime text;
begin
  if new.bucket_id not in ('profile-photos','community-media') then
    return new;
  end if;

  -- Platform visuals are not tenant-network media. Storage RLS below is the
  -- authorization boundary for the platform/<signed-in-owner>/... namespace.
  if new.bucket_id='community-media' and new.name like 'platform/%' then
    bytes:=public.storage_object_metadata_bytes(new.metadata);
    mime:=lower(coalesce(
      new.metadata->>'mimetype',
      new.metadata->>'contentType',
      new.metadata->>'content_type',
      ''
    ));

    if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then
      raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023';
    end if;

    -- Storage BEFORE triggers do not expose byte metadata consistently across
    -- storage-api versions. Enforce the limit here only when bytes are known;
    -- the client already compresses Design Studio assets before upload.
    if bytes>2097152 then
      raise exception 'Platform image exceeds the 2 MB storage guard.' using errcode='22023';
    end if;

    return new;
  end if;

  -- Normal network media retains explicit tenant + uploader ownership checks.
  nid:=public.storage_path_network_id(new.name);
  actor:=public.storage_path_owner_user_id(new.name);

  if nid is null then
    raise exception 'Network media path must begin with the network id.' using errcode='22023';
  end if;
  if actor is null then
    raise exception 'Network media path must include the uploading user id.' using errcode='22023';
  end if;
  if request_uid is not null and actor<>request_uid then
    raise exception 'Media path does not belong to the signed-in user.' using errcode='42501';
  end if;
  if not public.has_active_network_membership(nid,actor) then
    raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501';
  end if;

  bytes:=public.storage_object_metadata_bytes(new.metadata);
  mime:=lower(coalesce(
    new.metadata->>'mimetype',
    new.metadata->>'contentType',
    new.metadata->>'content_type',
    ''
  ));

  if mime<>'' and mime not in ('image/jpeg','image/png','image/webp') then
    raise exception 'Only JPG, PNG or WebP images are supported.' using errcode='22023';
  end if;

  select storage_limit_bytes,photo_max_bytes,media_usage_bytes
    into lim,max_file,current_usage
    from public.networks
   where id=nid
   for update;

  if lim is null then
    raise exception 'Network was not found.' using errcode='P0002';
  end if;

  current_usage:=greatest(
    coalesce(current_usage,0),
    coalesce((
      select sum(m.bytes+m.thumbnail_bytes)
        from public.network_media_assets m
       where m.network_id=nid
    ),0)
  );

  if bytes>0 and bytes>max_file then
    raise exception 'Image exceeds this network''s % KB upload limit.',
      ceil(max_file/1024.0) using errcode='22023';
  end if;

  if tg_op='UPDATE' then
    old_bytes:=public.storage_object_metadata_bytes(old.metadata);
  end if;

  if bytes>0 and current_usage-old_bytes+bytes>lim then
    raise exception 'Network storage limit reached. Remove older photos or use a smaller image.'
      using errcode='22023';
  end if;

  return new;
end
$$;

-- Explicit platform namespace authorization. These policies are the sole
-- authorization boundary for platform Design Studio Storage objects.
drop policy if exists platform_visuals_read on storage.objects;
create policy platform_visuals_read
on storage.objects
for select
to anon,authenticated
using (
  bucket_id='community-media'
  and (storage.foldername(name))[1]='platform'
);

drop policy if exists platform_visuals_insert on storage.objects;
create policy platform_visuals_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id='community-media'
  and (storage.foldername(name))[1]='platform'
  and (storage.foldername(name))[2]=auth.uid()::text
  and public.is_platform_owner()
);

drop policy if exists platform_visuals_update on storage.objects;
create policy platform_visuals_update
on storage.objects
for update
to authenticated
using (
  bucket_id='community-media'
  and (storage.foldername(name))[1]='platform'
  and (storage.foldername(name))[2]=auth.uid()::text
  and public.is_platform_owner()
)
with check (
  bucket_id='community-media'
  and (storage.foldername(name))[1]='platform'
  and (storage.foldername(name))[2]=auth.uid()::text
  and public.is_platform_owner()
);

drop policy if exists platform_visuals_delete on storage.objects;
create policy platform_visuals_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id='community-media'
  and (storage.foldername(name))[1]='platform'
  and (storage.foldername(name))[2]=auth.uid()::text
  and public.is_platform_owner()
);

notify pgrst, 'reload schema';
