-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

SET check_function_bodies = off;
CREATE OR REPLACE FUNCTION public.a4_safe_external_url(p_url text, p_kind text DEFAULT 'other'::text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
declare u text:=lower(trim(coalesce(p_url,'')));
begin
  if u='' then return true; end if;
  if u !~ '^https://[^[:space:]]+$' then return false; end if;
  if p_kind='facebook' then return u ~ '^https://(www\.|m\.)?facebook\.com/'; end if;
  if p_kind='instagram' then return u ~ '^https://(www\.)?instagram\.com/'; end if;
  return true;
end $function$
;

CREATE OR REPLACE FUNCTION public.current_network_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select case when coalesce(p.family_lobby_mode,false) then null else coalesce(
    (
      select p.active_network_id
      from public.network_memberships active_nm
      where active_nm.network_id=p.active_network_id
        and active_nm.user_id=p.id
        and active_nm.status='active'
      limit 1
    ),
    (
      select nm.network_id
      from public.network_memberships nm
      join public.networks n on n.id=nm.network_id and n.status='active'
      where nm.user_id=p.id and nm.status='active'
      order by nm.joined_at desc
      limit 1
    )
  ) end
  from public.profiles p
  where p.id=auth.uid()
  limit 1;
$function$
;

SET check_function_bodies = on;
