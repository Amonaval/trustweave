-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_alumni_connections_person ON public.alumni_connections USING btree (network_id, person_id);
CREATE INDEX idx_alumni_connections_related ON public.alumni_connections USING btree (network_id, related_person_id);
CREATE INDEX idx_alumni_invitations_active ON public.alumni_invitations USING btree (network_id, status, expires_at);
CREATE INDEX idx_alumni_profiles_claimed ON public.alumni_profiles USING btree (network_id, claimed_by) WHERE (claimed_by IS NOT NULL);
CREATE INDEX idx_alumni_profiles_network_name ON public.alumni_profiles USING btree (network_id, full_name);
CREATE INDEX idx_alumni_profiles_network_year ON public.alumni_profiles USING btree (network_id, graduation_year);
CREATE UNIQUE INDEX uq_alumni_claimed_user_per_network ON public.alumni_profiles USING btree (network_id, claimed_by) WHERE (claimed_by IS NOT NULL);
CREATE INDEX idx_org_intel_query_network_created ON public.organization_intelligence_query_signals USING btree (network_id, created_at DESC);
