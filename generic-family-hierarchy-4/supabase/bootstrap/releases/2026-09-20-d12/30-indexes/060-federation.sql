-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX m6c_candidate_requester_idx ON public.cross_network_discovery_candidates USING btree (requester_user_id, expires_at DESC);
CREATE INDEX idx_federated_introduction_outcomes_intro ON public.federated_introduction_outcomes USING btree (introduction_id, recorded_at DESC);
CREATE INDEX idx_federated_introductions_requester ON public.federated_introductions USING btree (requester_user_id, status, updated_at DESC);
CREATE INDEX idx_federated_introductions_target ON public.federated_introductions USING btree (target_user_id, status, updated_at DESC);
CREATE INDEX idx_federated_request_routes_request ON public.federated_request_routes USING btree (request_id, status, score DESC);
CREATE INDEX idx_federated_requests_owner ON public.federated_requests USING btree (requester_user_id, status, updated_at DESC);
CREATE INDEX idx_federated_scope_profiles_scope ON public.federated_scope_profiles USING btree (umbrella_id, scope_key, active, updated_at DESC);
CREATE INDEX idx_federated_trust_receipts_request ON public.federated_trust_receipts USING btree (request_id, created_at DESC);
CREATE INDEX idx_federation_umbrellas_name ON public.federation_umbrellas USING btree (status, name);
CREATE INDEX m6d_effect_actor_idx ON public.network_effect_events USING btree (actor_user_id, created_at DESC);
CREATE INDEX m6d_effect_network_idx ON public.network_effect_events USING btree (source_network_id, event_type, created_at DESC);
CREATE INDEX idx_network_passports_visibility ON public.network_passports USING btree (visibility, directory_discoverable, updated_at DESC);
CREATE INDEX network_trust_bridges_pair_idx ON public.network_trust_bridges USING btree (LEAST(requester_network_id, recipient_network_id), GREATEST(requester_network_id, recipient_network_id), relationship_type);
CREATE INDEX network_trust_bridges_recipient_idx ON public.network_trust_bridges USING btree (recipient_network_id, status);
CREATE INDEX network_trust_bridges_requester_idx ON public.network_trust_bridges USING btree (requester_network_id, status);
CREATE INDEX idx_network_umbrella_affiliation_network ON public.network_umbrella_affiliations USING btree (network_id, status, updated_at DESC);
CREATE INDEX idx_network_umbrella_affiliation_umbrella ON public.network_umbrella_affiliations USING btree (umbrella_id, status, updated_at DESC);
CREATE INDEX m6c_intro_requester_idx ON public.trusted_introduction_requests USING btree (requester_user_id, created_at DESC);
CREATE INDEX m6c_intro_target_idx ON public.trusted_introduction_requests USING btree (target_user_id, status, created_at DESC);
