-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

GRANT USAGE ON SEQUENCE "public"."family_engagement_events_id_seq" TO "anon";
GRANT USAGE ON SEQUENCE "public"."family_engagement_events_id_seq" TO "authenticated";
GRANT USAGE ON SEQUENCE "public"."family_engagement_events_id_seq" TO "postgres";
GRANT USAGE ON SEQUENCE "public"."family_engagement_events_id_seq" TO "service_role";
GRANT USAGE ON SEQUENCE "public"."family_intake_events_id_seq" TO "anon";
GRANT USAGE ON SEQUENCE "public"."family_intake_events_id_seq" TO "authenticated";
GRANT USAGE ON SEQUENCE "public"."family_intake_events_id_seq" TO "postgres";
GRANT USAGE ON SEQUENCE "public"."family_intake_events_id_seq" TO "service_role";
GRANT USAGE ON SEQUENCE "public"."hs_pilot_usage_events_id_seq" TO "anon";
GRANT USAGE ON SEQUENCE "public"."hs_pilot_usage_events_id_seq" TO "authenticated";
GRANT USAGE ON SEQUENCE "public"."hs_pilot_usage_events_id_seq" TO "postgres";
GRANT USAGE ON SEQUENCE "public"."hs_pilot_usage_events_id_seq" TO "service_role";
GRANT USAGE ON SEQUENCE "public"."network_effect_events_id_seq" TO "anon";
GRANT USAGE ON SEQUENCE "public"."network_effect_events_id_seq" TO "authenticated";
GRANT USAGE ON SEQUENCE "public"."network_effect_events_id_seq" TO "postgres";
GRANT USAGE ON SEQUENCE "public"."network_effect_events_id_seq" TO "service_role";
GRANT USAGE ON SEQUENCE "public"."participation_events_id_seq" TO "anon";
GRANT USAGE ON SEQUENCE "public"."participation_events_id_seq" TO "authenticated";
GRANT USAGE ON SEQUENCE "public"."participation_events_id_seq" TO "postgres";
GRANT USAGE ON SEQUENCE "public"."participation_events_id_seq" TO "service_role";
GRANT USAGE ON SEQUENCE "public"."platform_feature_rollout_audit_id_seq" TO "anon";
GRANT USAGE ON SEQUENCE "public"."platform_feature_rollout_audit_id_seq" TO "authenticated";
GRANT USAGE ON SEQUENCE "public"."platform_feature_rollout_audit_id_seq" TO "postgres";
GRANT USAGE ON SEQUENCE "public"."platform_feature_rollout_audit_id_seq" TO "service_role";
