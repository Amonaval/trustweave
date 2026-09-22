-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_api_command_idempotency_updated_at ON public.api_command_idempotency USING btree (updated_at);
CREATE INDEX idx_change_requests_network ON public.change_requests USING btree (network_id);
CREATE INDEX idx_change_requests_status_created ON public.change_requests USING btree (status, created_at DESC);
CREATE INDEX idx_change_requests_submitted_by ON public.change_requests USING btree (submitted_by);
CREATE INDEX idx_change_requests_target_member ON public.change_requests USING btree (target_member_id);
CREATE INDEX idx_contribution_suggestions_network ON public.contribution_suggestions USING btree (network_id);
CREATE INDEX idx_contribution_suggestions_status ON public.contribution_suggestions USING btree (status, priority DESC, created_at);
CREATE INDEX guide_feedback_signal_idx ON public.guide_feedback USING btree (guide_key, feedback_type, created_at DESC);
CREATE INDEX guide_feedback_status_created_idx ON public.guide_feedback USING btree (status, created_at DESC);
CREATE INDEX idx_ballot_eligibility_user ON public.network_ballot_eligibility USING btree (user_id, ballot_id);
CREATE INDEX idx_ballot_options_ballot ON public.network_ballot_options USING btree (ballot_id, sort_order);
CREATE INDEX idx_ballot_votes_results ON public.network_ballot_votes USING btree (ballot_id, option_id);
CREATE INDEX idx_network_ballots_network ON public.network_ballots USING btree (network_id, status, created_at DESC);
CREATE UNIQUE INDEX idx_network_fund_receipt_unique ON public.network_fund_transactions USING btree (network_id, receipt_no) WHERE (receipt_no IS NOT NULL);
CREATE INDEX idx_network_fund_transactions_fund_date ON public.network_fund_transactions USING btree (network_id, fund_id, occurred_on DESC, created_at DESC);
CREATE INDEX idx_network_funds_network_status ON public.network_funds USING btree (network_id, status, created_at DESC);
