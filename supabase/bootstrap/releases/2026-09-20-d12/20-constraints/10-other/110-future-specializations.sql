-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_check" CHECK (person_id <> related_person_id);
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_person_id_fkey" FOREIGN KEY (person_id) REFERENCES alumni_profiles(id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_related_person_id_fkey" FOREIGN KEY (related_person_id) REFERENCES alumni_profiles(id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_relation_kind_check" CHECK (relation_kind::text = ANY (ARRAY['batchmate'::character varying, 'classmate'::character varying, 'mentor'::character varying, 'mentee'::character varying, 'professional_connection'::character varying]::text[]));
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "fk_alumni_connections_person_network" FOREIGN KEY (person_id, network_id) REFERENCES alumni_profiles(id, network_id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "fk_alumni_connections_related_network" FOREIGN KEY (related_person_id, network_id) REFERENCES alumni_profiles(id, network_id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_invitations" ADD CONSTRAINT "alumni_invitations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."alumni_invitations" ADD CONSTRAINT "alumni_invitations_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_invitations" ADD CONSTRAINT "alumni_invitations_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES alumni_profiles(id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_invitations" ADD CONSTRAINT "alumni_invitations_status_check" CHECK (status::text = ANY (ARRAY['active'::character varying, 'accepted'::character varying, 'expired'::character varying, 'revoked'::character varying]::text[]));
ALTER TABLE "public"."alumni_invitations" ADD CONSTRAINT "fk_alumni_invitation_profile_network" FOREIGN KEY (profile_id, network_id) REFERENCES alumni_profiles(id, network_id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_network_settings" ADD CONSTRAINT "alumni_network_settings_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_profiles" ADD CONSTRAINT "alumni_profiles_claimed_by_fkey" FOREIGN KEY (claimed_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."alumni_profiles" ADD CONSTRAINT "alumni_profiles_graduation_year_check" CHECK (graduation_year IS NULL OR graduation_year >= 1900 AND graduation_year <= 2200);
ALTER TABLE "public"."alumni_profiles" ADD CONSTRAINT "alumni_profiles_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."alumni_profiles" ADD CONSTRAINT "alumni_profiles_visibility_check" CHECK (visibility::text = ANY (ARRAY['members'::character varying, 'private'::character varying]::text[]));
ALTER TABLE "public"."organization_intelligence_query_signals" ADD CONSTRAINT "organization_intelligence_query_signals_confidence_check" CHECK (confidence = ANY (ARRAY['high'::text, 'medium'::text, 'low'::text]));
ALTER TABLE "public"."organization_intelligence_query_signals" ADD CONSTRAINT "organization_intelligence_query_signals_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
