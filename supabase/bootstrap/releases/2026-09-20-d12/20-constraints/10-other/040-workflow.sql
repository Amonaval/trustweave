-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."api_command_idempotency" ADD CONSTRAINT "api_command_idempotency_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'completed'::text]));
ALTER TABLE "public"."api_command_idempotency" ADD CONSTRAINT "api_command_idempotency_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."change_requests" ADD CONSTRAINT "change_requests_action_check" CHECK (action::text = ANY (ARRAY['create_member'::character varying, 'update_member'::character varying, 'add_relationship'::character varying, 'remove_relationship'::character varying, 'import'::character varying, 'other'::character varying]::text[]));
ALTER TABLE "public"."change_requests" ADD CONSTRAINT "change_requests_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."change_requests" ADD CONSTRAINT "change_requests_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."change_requests" ADD CONSTRAINT "change_requests_status_check" CHECK (status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'cancelled'::character varying]::text[]));
ALTER TABLE "public"."change_requests" ADD CONSTRAINT "change_requests_submitted_by_fkey" FOREIGN KEY (submitted_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."change_requests" ADD CONSTRAINT "change_requests_target_member_id_fkey" FOREIGN KEY (target_member_id) REFERENCES family_members(id) ON DELETE SET NULL;
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_acted_by_fkey" FOREIGN KEY (acted_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_kind_check" CHECK (kind::text = ANY (ARRAY['missing_field'::character varying, 'orphan'::character varying, 'possible_duplicate'::character varying, 'incomplete_relationship'::character varying]::text[]));
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_member_id_fkey" FOREIGN KEY (member_id) REFERENCES family_members(id) ON DELETE CASCADE;
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_priority_check" CHECK (priority >= 1 AND priority <= 100);
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_status_check" CHECK (status::text = ANY (ARRAY['open'::character varying, 'accepted'::character varying, 'dismissed'::character varying, 'resolved'::character varying]::text[]));
ALTER TABLE "public"."guide_feedback" ADD CONSTRAINT "guide_feedback_feedback_type_check" CHECK (feedback_type = ANY (ARRAY['confusing'::text, 'missing'::text, 'feature_idea'::text, 'improvement'::text, 'bug'::text, 'family_need'::text, 'other'::text, 'helpful_yes'::text, 'helpful_no'::text, 'future_interest'::text]));
ALTER TABLE "public"."guide_feedback" ADD CONSTRAINT "guide_feedback_member_id_fkey" FOREIGN KEY (member_id) REFERENCES family_members(id) ON DELETE SET NULL;
ALTER TABLE "public"."guide_feedback" ADD CONSTRAINT "guide_feedback_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE SET NULL;
ALTER TABLE "public"."guide_feedback" ADD CONSTRAINT "guide_feedback_status_check" CHECK (status = ANY (ARRAY['new'::text, 'reviewing'::text, 'planned'::text, 'already_supported'::text, 'not_planned'::text, 'implemented'::text]));
ALTER TABLE "public"."guide_feedback" ADD CONSTRAINT "guide_feedback_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_ballot_eligibility" ADD CONSTRAINT "network_ballot_eligibility_ballot_id_fkey" FOREIGN KEY (ballot_id) REFERENCES network_ballots(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_eligibility" ADD CONSTRAINT "network_ballot_eligibility_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_eligibility" ADD CONSTRAINT "network_ballot_eligibility_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_nominations" ADD CONSTRAINT "network_ballot_nomination_status_check" CHECK (status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying]::text[]));
ALTER TABLE "public"."network_ballot_nominations" ADD CONSTRAINT "network_ballot_nominations_ballot_id_fkey" FOREIGN KEY (ballot_id) REFERENCES network_ballots(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_nominations" ADD CONSTRAINT "network_ballot_nominations_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_nominations" ADD CONSTRAINT "network_ballot_nominations_nominated_by_fkey" FOREIGN KEY (nominated_by) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_nominations" ADD CONSTRAINT "network_ballot_nominations_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_ballot_options" ADD CONSTRAINT "network_ballot_options_ballot_id_fkey" FOREIGN KEY (ballot_id) REFERENCES network_ballots(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_options" ADD CONSTRAINT "network_ballot_options_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_participation" ADD CONSTRAINT "network_ballot_participation_ballot_id_fkey" FOREIGN KEY (ballot_id) REFERENCES network_ballots(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_participation" ADD CONSTRAINT "network_ballot_participation_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_participation" ADD CONSTRAINT "network_ballot_participation_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_votes" ADD CONSTRAINT "network_ballot_votes_ballot_id_fkey" FOREIGN KEY (ballot_id) REFERENCES network_ballots(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_votes" ADD CONSTRAINT "network_ballot_votes_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_votes" ADD CONSTRAINT "network_ballot_votes_option_id_fkey" FOREIGN KEY (option_id) REFERENCES network_ballot_options(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballot_votes" ADD CONSTRAINT "network_ballot_votes_voter_user_id_fkey" FOREIGN KEY (voter_user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_ballots" ADD CONSTRAINT "network_ballot_choices_check" CHECK (max_choices >= 1 AND max_choices <= 10);
ALTER TABLE "public"."network_ballots" ADD CONSTRAINT "network_ballot_eligibility_check" CHECK (eligibility_mode::text = ANY (ARRAY['members'::character varying, 'admins'::character varying, 'family_representatives'::character varying]::text[]));
ALTER TABLE "public"."network_ballots" ADD CONSTRAINT "network_ballot_status_check" CHECK (status::text = ANY (ARRAY['draft'::character varying, 'open'::character varying, 'closed'::character varying, 'published'::character varying, 'cancelled'::character varying]::text[]));
ALTER TABLE "public"."network_ballots" ADD CONSTRAINT "network_ballot_type_check" CHECK (ballot_type::text = ANY (ARRAY['poll'::character varying, 'election'::character varying]::text[]));
ALTER TABLE "public"."network_ballots" ADD CONSTRAINT "network_ballots_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_ballots" ADD CONSTRAINT "network_ballots_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_fund_transactions" ADD CONSTRAINT "network_fund_transactions_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_fund_transactions" ADD CONSTRAINT "network_fund_transactions_fund_id_fkey" FOREIGN KEY (fund_id) REFERENCES network_funds(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_fund_transactions" ADD CONSTRAINT "network_fund_transactions_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_fund_transactions" ADD CONSTRAINT "network_fund_tx_amount_check" CHECK (amount > 0::numeric);
ALTER TABLE "public"."network_fund_transactions" ADD CONSTRAINT "network_fund_tx_kind_check" CHECK (transaction_kind::text = ANY (ARRAY['collection'::character varying, 'expense'::character varying, 'refund'::character varying, 'transfer_in'::character varying, 'transfer_out'::character varying, 'adjustment'::character varying]::text[]));
ALTER TABLE "public"."network_fund_transactions" ADD CONSTRAINT "network_fund_tx_visibility_check" CHECK (visibility::text = ANY (ARRAY['admins'::character varying, 'members'::character varying, 'highlighted'::character varying]::text[]));
ALTER TABLE "public"."network_funds" ADD CONSTRAINT "network_funds_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE "public"."network_funds" ADD CONSTRAINT "network_funds_kind_check" CHECK (fund_kind::text = ANY (ARRAY['general'::character varying, 'membership'::character varying, 'event'::character varying, 'donation'::character varying, 'reserve'::character varying, 'maintenance'::character varying, 'other'::character varying]::text[]));
ALTER TABLE "public"."network_funds" ADD CONSTRAINT "network_funds_network_id_fkey" FOREIGN KEY (network_id) REFERENCES networks(id) ON DELETE CASCADE;
ALTER TABLE "public"."network_funds" ADD CONSTRAINT "network_funds_status_check" CHECK (status::text = ANY (ARRAY['active'::character varying, 'closed'::character varying, 'archived'::character varying]::text[]));
ALTER TABLE "public"."network_funds" ADD CONSTRAINT "network_funds_target_check" CHECK (target_amount IS NULL OR target_amount >= 0::numeric);
ALTER TABLE "public"."network_funds" ADD CONSTRAINT "network_funds_visibility_check" CHECK (visibility::text = ANY (ARRAY['admins'::character varying, 'members'::character varying, 'highlighted'::character varying]::text[]));
