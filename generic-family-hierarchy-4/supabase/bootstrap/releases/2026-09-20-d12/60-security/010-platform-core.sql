-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."audit_log" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."launch_demo_seed_authorizations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."launch_demo_seed_issues" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."launch_demo_seed_lineage" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."launch_demo_seed_runs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_archive_membership_state" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_assertion_decisions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_bridge_codes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_candidate_assertions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_contribution_audit" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_contributions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_dimension_values" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_dimensions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_entities" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_entity_affiliations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_entity_relationships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_evidence_records" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_feature_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_group_memberships" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_groups" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_join_codes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_knowledge_sources" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_projections" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_purge_receipts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_quick_start_state" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."network_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."networks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."pilot_feedback" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."pilot_product_decisions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."platform_feature_flags" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."platform_feature_rollout_audit" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."platform_onboarding_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."platform_owner_audit" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."platform_owners" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."platform_playground_features" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."platform_showcase_verticals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."productized_network_settings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."user_feature_discoveries" ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admins can read audit log" ON "public"."audit_log" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());
CREATE POLICY "admins can write audit log" ON "public"."audit_log" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (is_admin());
CREATE POLICY "tenant isolation audit_log" ON "public"."audit_log" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((network_id = current_network_id())) WITH CHECK ((network_id = current_network_id()));
CREATE POLICY "g91a assertion decisions network members" ON "public"."network_assertion_decisions" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1
   FROM network_memberships nm
  WHERE ((nm.network_id = network_assertion_decisions.network_id) AND (nm.user_id = auth.uid()) AND ((nm.status)::text = 'active'::text)))));
CREATE POLICY "g91a candidate assertions network members" ON "public"."network_candidate_assertions" AS PERMISSIVE FOR SELECT TO PUBLIC USING ((EXISTS ( SELECT 1
   FROM network_memberships nm
  WHERE ((nm.network_id = network_candidate_assertions.network_id) AND (nm.user_id = auth.uid()) AND ((nm.status)::text = 'active'::text)))));
CREATE POLICY "g91a evidence network members" ON "public"."network_evidence_records" AS PERMISSIVE FOR SELECT TO PUBLIC USING (((EXISTS ( SELECT 1
   FROM network_memberships nm
  WHERE ((nm.network_id = network_evidence_records.network_id) AND (nm.user_id = auth.uid()) AND ((nm.status)::text = 'active'::text)))) AND (visibility = 'network'::text)));
CREATE POLICY "family members read feature settings" ON "public"."network_feature_settings" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_network_member(network_id) OR is_platform_owner()));
CREATE POLICY "g91a knowledge sources network members" ON "public"."network_knowledge_sources" AS PERMISSIVE FOR SELECT TO PUBLIC USING (((EXISTS ( SELECT 1
   FROM network_memberships nm
  WHERE ((nm.network_id = network_knowledge_sources.network_id) AND (nm.user_id = auth.uid()) AND ((nm.status)::text = 'active'::text)))) AND (visibility = 'network'::text)));
CREATE POLICY "network_quick_start_state_self" ON "public"."network_quick_start_state" AS PERMISSIVE FOR ALL TO PUBLIC USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));
CREATE POLICY "family admins manage network settings" ON "public"."network_settings" AS PERMISSIVE FOR ALL TO "authenticated" USING (((network_id = current_network_id()) AND is_network_admin(network_id))) WITH CHECK (((network_id = current_network_id()) AND is_network_admin(network_id)));
CREATE POLICY "members read network settings" ON "public"."network_settings" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((network_id = current_network_id()) AND is_network_member(network_id)));
CREATE POLICY "admins update their network" ON "public"."networks" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (is_network_admin(id)) WITH CHECK (is_network_admin(id));
CREATE POLICY "members read their networks" ON "public"."networks" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_network_member(id));
CREATE POLICY "platform owner can read own ownership" ON "public"."platform_owners" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));
CREATE POLICY "users read own feature discoveries" ON "public"."user_feature_discoveries" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));
