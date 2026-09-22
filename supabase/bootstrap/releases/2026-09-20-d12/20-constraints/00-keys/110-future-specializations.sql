-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_network_id_person_id_related_person_id_r_key" UNIQUE (network_id, person_id, related_person_id, relation_kind);
ALTER TABLE "public"."alumni_connections" ADD CONSTRAINT "alumni_connections_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."alumni_invitations" ADD CONSTRAINT "alumni_invitations_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."alumni_invitations" ADD CONSTRAINT "alumni_invitations_token_key" UNIQUE (token);
ALTER TABLE "public"."alumni_network_settings" ADD CONSTRAINT "alumni_network_settings_pkey" PRIMARY KEY (network_id);
ALTER TABLE "public"."alumni_profiles" ADD CONSTRAINT "alumni_profiles_network_id_email_key" UNIQUE (network_id, email);
ALTER TABLE "public"."alumni_profiles" ADD CONSTRAINT "alumni_profiles_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."alumni_profiles" ADD CONSTRAINT "uq_alumni_profiles_id_network" UNIQUE (id, network_id);
ALTER TABLE "public"."organization_intelligence_query_signals" ADD CONSTRAINT "organization_intelligence_query_signals_pkey" PRIMARY KEY (id);
