-- VIS3 runtime repairs: platform visual uploads + unambiguous notification inbox.
-- SOURCE ONLY. Apply explicitly after review. No deployment or runtime mutation is performed by this commit.

-- The shared media guard added in migration 114 correctly requires normal network media
-- paths to begin with a network UUID. Platform-owner visual assets are deliberately
-- outside a tenant network, so allow only the dedicated platform/<owner-id>/... scope.
create or replace function public.a5_storage_guard() returns trigger
language plpgsql security definer set search_path=public,storage as $$
declare
  nid uuid; bytes bigint; old_bytes bigint:=0; lim bigint; max_file integer; current_usage bigint;
begin
  if new.bucket_id not in ('profile-photos','community-media') then return new; end if;

  bytes:=coalesce((new.metadata->>'size')::bigint,0);

  if new.bucket_id='community-media' and new.name like 'platform/%' then
    if auth.uid() is null or not public.is_platform_owner() then
      raise exception 'Platform-owner access is required for platform visuals.' using errcode='42501';
    end if;
    if new.name not like 'platform/'||auth.uid()::text||'/%' then
      raise exception 'Platform visual path must be owned by the signed-in platform owner.' using errcode='42501';
    end if;
    if bytes<=0 then
      raise exception 'Uploaded platform image size could not be verified.' using errcode='22023';
    end if;
    if bytes>2097152 then
      raise exception 'Platform image exceeds the 2 MB storage guard.' using errcode='22023';
    end if;
    return new;
  end if;

  nid:=public.storage_path_network_id(new.name);
  if nid is null then
    raise exception 'Network media path must begin with the network id.' using errcode='22023';
  end if;
  if not public.is_network_member(nid) then
    raise exception 'Media can only be uploaded to a network you belong to.' using errcode='42501';
  end if;
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

-- Migration 103 left both a no-arg wrapper and a defaulted two-argument overload.
-- PostgREST cannot choose between them for an empty RPC body.
drop function if exists public.get_my_notifications();

notify pgrst, 'reload schema';
