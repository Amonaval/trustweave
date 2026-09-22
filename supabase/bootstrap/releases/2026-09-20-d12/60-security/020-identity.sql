-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."family_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."member_invitations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_memberships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_participation_invitations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_role_capabilities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admins can directly read family members" ON "public"."family_members" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());
CREATE POLICY "admins can manage family members" ON "public"."family_members" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "tenant isolation family_members" ON "public"."family_members" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "tenant isolation member_invitations" ON "public"."member_invitations" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "owners manage memberships" ON "public"."network_memberships" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_network_admin(network_id)) WITH CHECK (is_network_admin(network_id));
CREATE POLICY "users read their memberships" ON "public"."network_memberships" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((user_id = auth.uid()) OR is_network_admin(network_id)));
CREATE POLICY "admins can update roles" ON "public"."profiles" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "users can read own profile" ON "public"."profiles" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM (network_memberships mine
     JOIN network_memberships theirs ON ((theirs.network_id = mine.network_id)))
  WHERE ((mine.user_id = auth.uid()) AND ((mine.status)::text = 'active'::text) AND (theirs.user_id = profiles.id) AND ((theirs.status)::text = 'active'::text))))));
