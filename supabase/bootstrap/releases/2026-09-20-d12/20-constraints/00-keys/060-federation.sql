-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."cross_network_discovery_candidates" ADD CONSTRAINT "cross_network_discovery_candidates_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federated_introduction_outcomes" ADD CONSTRAINT "federated_introduction_outcom_introduction_id_actor_user_id_key" UNIQUE (introduction_id, actor_user_id);
ALTER TABLE "public"."federated_introduction_outcomes" ADD CONSTRAINT "federated_introduction_outcomes_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federated_introductions" ADD CONSTRAINT "federated_introductions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federated_introductions" ADD CONSTRAINT "federated_introductions_route_id_key" UNIQUE (route_id);
ALTER TABLE "public"."federated_request_routes" ADD CONSTRAINT "federated_request_routes_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federated_request_routes" ADD CONSTRAINT "federated_request_routes_request_id_target_scope_profile_id_key" UNIQUE (request_id, target_scope_profile_id);
ALTER TABLE "public"."federated_requests" ADD CONSTRAINT "federated_requests_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federated_scope_profiles" ADD CONSTRAINT "federated_scope_profiles_owner_user_id_network_id_umbrella__key" UNIQUE (owner_user_id, network_id, umbrella_id, scope_key);
ALTER TABLE "public"."federated_scope_profiles" ADD CONSTRAINT "federated_scope_profiles_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federated_trust_receipts" ADD CONSTRAINT "federated_trust_receipts_introduction_id_key" UNIQUE (introduction_id);
ALTER TABLE "public"."federated_trust_receipts" ADD CONSTRAINT "federated_trust_receipts_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federation_umbrella_admins" ADD CONSTRAINT "federation_umbrella_admins_pkey" PRIMARY KEY (umbrella_id, user_id);
ALTER TABLE "public"."federation_umbrellas" ADD CONSTRAINT "federation_umbrellas_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."federation_umbrellas" ADD CONSTRAINT "federation_umbrellas_slug_key" UNIQUE (slug);
ALTER TABLE "public"."network_effect_events" ADD CONSTRAINT "network_effect_events_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_passports" ADD CONSTRAINT "network_passports_pkey" PRIMARY KEY (network_id);
ALTER TABLE "public"."network_passports" ADD CONSTRAINT "network_passports_public_slug_key" UNIQUE (public_slug);
ALTER TABLE "public"."network_trust_bridges" ADD CONSTRAINT "network_trust_bridges_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_umbrella_affiliations" ADD CONSTRAINT "network_umbrella_affiliations_network_id_umbrella_id_relati_key" UNIQUE (network_id, umbrella_id, relationship_type);
ALTER TABLE "public"."network_umbrella_affiliations" ADD CONSTRAINT "network_umbrella_affiliations_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."trusted_introduction_requests" ADD CONSTRAINT "trusted_introduction_requests_pkey" PRIMARY KEY (id);
