-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

REVOKE ALL ON FUNCTION "public"."accept_member_invitation"(p_token text) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."accept_member_invitation"(p_token text) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."accept_member_invitation"(p_token text) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."accept_member_invitation"(p_token text) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."accept_member_invitation"(p_token text) TO "service_role";
REVOKE ALL ON FUNCTION "public"."create_bulk_member_invitations"(p_items jsonb, p_expires_days integer) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."create_bulk_member_invitations"(p_items jsonb, p_expires_days integer) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."create_bulk_member_invitations"(p_items jsonb, p_expires_days integer) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."create_bulk_member_invitations"(p_items jsonb, p_expires_days integer) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."create_bulk_member_invitations"(p_items jsonb, p_expires_days integer) TO "service_role";
REVOKE ALL ON FUNCTION "public"."create_member_invitation"(p_member_id uuid, p_token text, p_expires_days integer) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."create_member_invitation"(p_member_id uuid, p_token text, p_expires_days integer) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."create_member_invitation"(p_member_id uuid, p_token text, p_expires_days integer) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."create_member_invitation"(p_member_id uuid, p_token text, p_expires_days integer) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."create_member_invitation"(p_member_id uuid, p_token text, p_expires_days integer) TO "service_role";
REVOKE ALL ON FUNCTION "public"."get_member_invitations"() FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."get_member_invitations"() TO "anon";
GRANT EXECUTE ON FUNCTION "public"."get_member_invitations"() TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."get_member_invitations"() TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."get_member_invitations"() TO "service_role";
REVOKE ALL ON FUNCTION "public"."get_productized_network_memberships"() FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships"() TO "anon";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships"() TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships"() TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships"() TO "service_role";
REVOKE ALL ON FUNCTION "public"."get_productized_network_memberships_page"(p_after_joined_at timestamp with time zone, p_after_user_id uuid, p_limit integer) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships_page"(p_after_joined_at timestamp with time zone, p_after_user_id uuid, p_limit integer) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships_page"(p_after_joined_at timestamp with time zone, p_after_user_id uuid, p_limit integer) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships_page"(p_after_joined_at timestamp with time zone, p_after_user_id uuid, p_limit integer) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."get_productized_network_memberships_page"(p_after_joined_at timestamp with time zone, p_after_user_id uuid, p_limit integer) TO "service_role";
REVOKE ALL ON FUNCTION "public"."has_active_network_membership"(p_network_id uuid, p_user_id uuid) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."has_active_network_membership"(p_network_id uuid, p_user_id uuid) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."has_active_network_membership"(p_network_id uuid, p_user_id uuid) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."has_active_network_membership"(p_network_id uuid, p_user_id uuid) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."has_active_network_membership"(p_network_id uuid, p_user_id uuid) TO "service_role";
REVOKE ALL ON FUNCTION "public"."resend_member_invitation"(p_invitation_id uuid, p_token text, p_expires_days integer) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."resend_member_invitation"(p_invitation_id uuid, p_token text, p_expires_days integer) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."resend_member_invitation"(p_invitation_id uuid, p_token text, p_expires_days integer) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."resend_member_invitation"(p_invitation_id uuid, p_token text, p_expires_days integer) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."resend_member_invitation"(p_invitation_id uuid, p_token text, p_expires_days integer) TO "service_role";
REVOKE ALL ON FUNCTION "public"."revoke_member_invitation"(p_invitation_id uuid) FROM PUBLIC, "anon", "authenticated", "service_role";
GRANT EXECUTE ON FUNCTION "public"."revoke_member_invitation"(p_invitation_id uuid) TO "anon";
GRANT EXECUTE ON FUNCTION "public"."revoke_member_invitation"(p_invitation_id uuid) TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."revoke_member_invitation"(p_invitation_id uuid) TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."revoke_member_invitation"(p_invitation_id uuid) TO "service_role";
