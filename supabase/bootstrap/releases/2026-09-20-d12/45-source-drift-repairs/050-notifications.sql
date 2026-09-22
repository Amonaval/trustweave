-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

-- Explicit D12 source-drift repairs proven on the fresh candidate.
CREATE OR REPLACE FUNCTION public.set_network_notification_role(p_role_key text, p_label text, p_user_id uuid, p_active boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id(); v_key text;
begin
 if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;
 if not exists(select 1 from public.network_memberships nm where nm.network_id=nid and nm.user_id=p_user_id and nm.status='active') then raise exception 'Role assignee must be an active network member.' using errcode='22023';end if;
 v_key:=trim(both '-' from regexp_replace(lower(trim(p_role_key)),'[^a-z0-9]+','-','g'));if length(v_key)<2 then raise exception 'Invalid responsibility role.' using errcode='22023';end if;
 insert into public.network_notification_roles(network_id,role_key,user_id,label,active,set_by,updated_at) values(nid,v_key,p_user_id,left(coalesce(nullif(trim(p_label),''),initcap(replace(v_key,'-',' '))),100),p_active,auth.uid(),now())
 on conflict(network_id,role_key,user_id) do update set label=excluded.label,active=excluded.active,set_by=auth.uid(),updated_at=now();
end $function$;
CREATE OR REPLACE FUNCTION public.remove_network_notification_role(p_role_key text, p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare nid uuid:=public.current_network_id();
begin if nid is null or not public.is_network_admin(nid) then raise exception 'Network admin access required.' using errcode='42501';end if;delete from public.network_notification_roles where network_id=nid and role_key=trim(both '-' from regexp_replace(lower(trim(p_role_key)),'[^a-z0-9]+','-','g')) and user_id=p_user_id;end $function$;
REVOKE ALL ON FUNCTION public.set_network_notification_role(text,text,uuid,boolean) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.set_network_notification_role(text,text,uuid,boolean) TO postgres, authenticated, service_role;
REVOKE ALL ON FUNCTION public.remove_network_notification_role(text,uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.remove_network_notification_role(text,uuid) TO postgres, authenticated, service_role;
