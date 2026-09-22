-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_audit_log_network ON public.audit_log USING btree (network_id);
CREATE INDEX launch_demo_seed_issues_run_idx ON public.launch_demo_seed_issues USING btree (run_id, severity, section_key, row_ref);
CREATE INDEX launch_demo_seed_lineage_network_idx ON public.launch_demo_seed_lineage USING btree (network_id, dataset_version, section_key);
CREATE INDEX launch_demo_seed_runs_network_idx ON public.launch_demo_seed_runs USING btree (network_id, started_at DESC);
CREATE INDEX idx_network_assertion_decisions_assertion ON public.network_assertion_decisions USING btree (assertion_id);
CREATE INDEX idx_network_candidate_assertions_network_status ON public.network_candidate_assertions USING btree (network_id, status);
CREATE INDEX idx_network_contribution_audit ON public.network_contribution_audit USING btree (network_id, contribution_id, at DESC);
CREATE INDEX idx_network_contributions_open ON public.network_contributions USING btree (network_id, status, created_at DESC);
CREATE INDEX idx_network_dimension_values_dimension ON public.network_dimension_values USING btree (network_id, dimension_id, label);
CREATE INDEX idx_network_entities_network_kind ON public.network_entities USING btree (network_id, kind);
CREATE INDEX idx_network_entities_network_label_id ON public.network_entities USING btree (network_id, label, id);
CREATE UNIQUE INDEX uq_network_entities_external_ref ON public.network_entities USING btree (network_id, kind, external_ref) WHERE (external_ref IS NOT NULL);
CREATE INDEX idx_network_affiliations_value ON public.network_entity_affiliations USING btree (network_id, value_id, entity_id);
CREATE INDEX idx_network_entity_relationships_from ON public.network_entity_relationships USING btree (network_id, from_entity_id);
CREATE INDEX idx_network_entity_relationships_to ON public.network_entity_relationships USING btree (network_id, to_entity_id);
CREATE INDEX idx_network_relationships_network_id ON public.network_entity_relationships USING btree (network_id, id);
CREATE INDEX idx_network_evidence_network ON public.network_evidence_records USING btree (network_id);
CREATE INDEX idx_network_evidence_source ON public.network_evidence_records USING btree (source_id);
CREATE INDEX idx_network_knowledge_sources_network ON public.network_knowledge_sources USING btree (network_id);
CREATE INDEX idx_network_purge_receipts_actor_time ON public.network_purge_receipts USING btree (purged_by, purged_at DESC);
CREATE INDEX idx_network_settings_network ON public.network_settings USING btree (network_id);
CREATE UNIQUE INDEX uq_network_settings_network ON public.network_settings USING btree (network_id);
CREATE INDEX idx_networks_approval_status ON public.networks USING btree (approval_status, vertical_kind, created_at DESC);
CREATE INDEX idx_networks_vertical_kind ON public.networks USING btree (vertical_kind, status);
CREATE INDEX m7d_feedback_network_created_idx ON public.pilot_feedback USING btree (network_id, created_at DESC);
CREATE INDEX m7d_feedback_user_created_idx ON public.pilot_feedback USING btree (user_id, created_at DESC);
CREATE INDEX m7f_product_decision_actor_created_idx ON public.pilot_product_decisions USING btree (decided_by, created_at DESC);
CREATE INDEX idx_platform_feature_flags_vertical_bundle ON public.platform_feature_flags USING btree (vertical_kind, bundle_key);
