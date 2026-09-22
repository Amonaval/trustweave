-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_fca_finance_network_created ON public.family_association_finance_ledger USING btree (network_id, created_at DESC, id);
CREATE INDEX idx_fca_role_history_network_start ON public.family_association_role_history USING btree (network_id, starts_on DESC, id);
