-- Mission 2 paused follow-up: restore Housing Society complaint category helper
-- required by hs4_create_complaint() and complaint route management.
-- Safe to apply after migration 119.

begin;

create or replace function public.hs4_category_key(p_category text)
returns text
language sql
immutable
as $$
  select trim(
    both '-' from regexp_replace(
      lower(trim(coalesce(p_category,'other'))),
      '[^a-z0-9]+',
      '-',
      'g'
    )
  );
$$;

revoke all on function public.hs4_category_key(text) from public;
grant execute on function public.hs4_category_key(text) to authenticated;

notify pgrst, 'reload schema';

commit;
