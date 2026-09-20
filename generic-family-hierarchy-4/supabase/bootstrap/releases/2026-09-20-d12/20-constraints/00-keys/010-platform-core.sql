-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."audit_log" ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."launch_demo_seed_authorizations" ADD CONSTRAINT "launch_demo_seed_authorizations_pkey" PRIMARY KEY (network_id, dataset_version);
ALTER TABLE "public"."launch_demo_seed_issues" ADD CONSTRAINT "launch_demo_seed_issues_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."launch_demo_seed_lineage" ADD CONSTRAINT "launch_demo_seed_lineage_pkey" PRIMARY KEY (network_id, dataset_version, section_key, row_ref);
ALTER TABLE "public"."launch_demo_seed_runs" ADD CONSTRAINT "launch_demo_seed_runs_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_archive_membership_state" ADD CONSTRAINT "network_archive_membership_state_pkey" PRIMARY KEY (network_id, user_id);
ALTER TABLE "public"."network_assertion_decisions" ADD CONSTRAINT "network_assertion_decisions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_bridge_codes" ADD CONSTRAINT "network_bridge_codes_code_key" UNIQUE (code);
ALTER TABLE "public"."network_bridge_codes" ADD CONSTRAINT "network_bridge_codes_pkey" PRIMARY KEY (network_id);
ALTER TABLE "public"."network_candidate_assertions" ADD CONSTRAINT "network_candidate_assertions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_contribution_audit" ADD CONSTRAINT "network_contribution_audit_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_contributions" ADD CONSTRAINT "network_contributions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_dimension_values" ADD CONSTRAINT "network_dimension_values_network_id_dimension_id_value_key_key" UNIQUE (network_id, dimension_id, value_key);
ALTER TABLE "public"."network_dimension_values" ADD CONSTRAINT "network_dimension_values_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_dimension_values" ADD CONSTRAINT "uq_network_dimension_values_id_network" UNIQUE (id, network_id);
ALTER TABLE "public"."network_dimensions" ADD CONSTRAINT "network_dimensions_network_id_dimension_key_key" UNIQUE (network_id, dimension_key);
ALTER TABLE "public"."network_dimensions" ADD CONSTRAINT "network_dimensions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_dimensions" ADD CONSTRAINT "uq_network_dimensions_id_network" UNIQUE (id, network_id);
ALTER TABLE "public"."network_entities" ADD CONSTRAINT "network_entities_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_entities" ADD CONSTRAINT "uq_network_entities_id_network" UNIQUE (id, network_id);
ALTER TABLE "public"."network_entity_affiliations" ADD CONSTRAINT "network_entity_affiliations_pkey" PRIMARY KEY (network_id, entity_id, dimension_id, value_id);
ALTER TABLE "public"."network_entity_relationships" ADD CONSTRAINT "network_entity_relationships_network_id_from_entity_id_to_e_key" UNIQUE (network_id, from_entity_id, to_entity_id, relationship_type);
ALTER TABLE "public"."network_entity_relationships" ADD CONSTRAINT "network_entity_relationships_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_evidence_records" ADD CONSTRAINT "network_evidence_records_network_id_source_id_chunk_id_cont_key" UNIQUE (network_id, source_id, chunk_id, content_hash);
ALTER TABLE "public"."network_evidence_records" ADD CONSTRAINT "network_evidence_records_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_feature_settings" ADD CONSTRAINT "network_feature_settings_pkey" PRIMARY KEY (network_id, feature_key);
ALTER TABLE "public"."network_group_memberships" ADD CONSTRAINT "network_group_memberships_pkey" PRIMARY KEY (group_id, user_id);
ALTER TABLE "public"."network_groups" ADD CONSTRAINT "network_groups_network_id_name_key" UNIQUE (network_id, name);
ALTER TABLE "public"."network_groups" ADD CONSTRAINT "network_groups_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_groups" ADD CONSTRAINT "uq_network_groups_id_network" UNIQUE (id, network_id);
ALTER TABLE "public"."network_join_codes" ADD CONSTRAINT "network_join_codes_code_key" UNIQUE (code);
ALTER TABLE "public"."network_join_codes" ADD CONSTRAINT "network_join_codes_pkey" PRIMARY KEY (network_id);
ALTER TABLE "public"."network_knowledge_sources" ADD CONSTRAINT "network_knowledge_sources_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_projections" ADD CONSTRAINT "network_projections_network_id_projection_key_key" UNIQUE (network_id, projection_key);
ALTER TABLE "public"."network_projections" ADD CONSTRAINT "network_projections_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_purge_receipts" ADD CONSTRAINT "network_purge_receipts_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_quick_start_state" ADD CONSTRAINT "network_quick_start_state_pkey" PRIMARY KEY (network_id, user_id);
ALTER TABLE "public"."network_settings" ADD CONSTRAINT "network_settings_pkey" PRIMARY KEY (network_id);
ALTER TABLE "public"."networks" ADD CONSTRAINT "networks_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."networks" ADD CONSTRAINT "networks_slug_key" UNIQUE (slug);
ALTER TABLE "public"."pilot_feedback" ADD CONSTRAINT "pilot_feedback_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."pilot_product_decisions" ADD CONSTRAINT "pilot_product_decisions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."platform_feature_flags" ADD CONSTRAINT "platform_feature_flags_pkey" PRIMARY KEY (feature_key);
ALTER TABLE "public"."platform_feature_rollout_audit" ADD CONSTRAINT "platform_feature_rollout_audit_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."platform_onboarding_settings" ADD CONSTRAINT "platform_onboarding_settings_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."platform_owner_audit" ADD CONSTRAINT "platform_owner_audit_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."platform_owners" ADD CONSTRAINT "platform_owners_pkey" PRIMARY KEY (user_id);
ALTER TABLE "public"."platform_playground_features" ADD CONSTRAINT "platform_playground_features_pkey" PRIMARY KEY (feature_key);
ALTER TABLE "public"."platform_showcase_verticals" ADD CONSTRAINT "platform_showcase_verticals_pkey" PRIMARY KEY (vertical_kind);
ALTER TABLE "public"."productized_network_settings" ADD CONSTRAINT "productized_network_settings_pkey" PRIMARY KEY (network_id);
ALTER TABLE "public"."user_feature_discoveries" ADD CONSTRAINT "user_feature_discoveries_pkey" PRIMARY KEY (user_id, feature_key, announcement_version);
