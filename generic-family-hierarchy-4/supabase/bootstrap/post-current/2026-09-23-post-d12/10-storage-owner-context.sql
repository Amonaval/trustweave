-- TrustWeave post-D12 hosted Storage owner-context tail.
-- Apply after 00-database.sql through Supabase dashboard/platform owner context.
-- This is the runtime-proven final Platform Design Studio Storage policy contract.

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
