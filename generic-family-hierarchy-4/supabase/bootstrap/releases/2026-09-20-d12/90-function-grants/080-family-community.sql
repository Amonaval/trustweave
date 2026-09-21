-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

REVOKE ALL ON FUNCTION "public"."can_manage_association_household"(p_household_id uuid, p_user_id uuid) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."can_manage_association_household"(p_household_id uuid, p_user_id uuid) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."can_manage_association_household"(p_household_id uuid, p_user_id uuid) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."can_manage_association_household"(p_household_id uuid, p_user_id uuid) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."can_manage_association_household"(p_household_id uuid, p_user_id uuid) TO "service_role";
REVOKE ALL ON FUNCTION "public"."fca_seed_defaults"(p_network uuid) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_defaults"(p_network uuid) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_defaults"(p_network uuid) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_defaults"(p_network uuid) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_defaults"(p_network uuid) TO "service_role";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_defaults"(p_network uuid) TO PUBLIC;
REVOKE ALL ON FUNCTION "public"."fca_seed_network_defaults_trigger"() FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_network_defaults_trigger"() TO "anon";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_network_defaults_trigger"() TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_network_defaults_trigger"() TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_network_defaults_trigger"() TO "service_role";
GRANT EXECUTE ON FUNCTION "public"."fca_seed_network_defaults_trigger"() TO PUBLIC;
REVOKE ALL ON FUNCTION "public"."get_my_association_household_admin_context"() FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."get_my_association_household_admin_context"() TO "anon";
GRANT EXECUTE ON FUNCTION "public"."get_my_association_household_admin_context"() TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."get_my_association_household_admin_context"() TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."get_my_association_household_admin_context"() TO "service_role";
REVOKE ALL ON FUNCTION "public"."set_association_household_admin"(p_household_id uuid, p_user_id uuid, p_enabled boolean) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."set_association_household_admin"(p_household_id uuid, p_user_id uuid, p_enabled boolean) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."set_association_household_admin"(p_household_id uuid, p_user_id uuid, p_enabled boolean) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."set_association_household_admin"(p_household_id uuid, p_user_id uuid, p_enabled boolean) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."set_association_household_admin"(p_household_id uuid, p_user_id uuid, p_enabled boolean) TO "service_role";
