-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."api_command_idempotency" ADD CONSTRAINT "api_command_idempotency_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."api_command_idempotency" ADD CONSTRAINT "api_command_idempotency_user_id_command_name_idempotency_ke_key" UNIQUE (user_id, command_name, idempotency_key);
ALTER TABLE "public"."change_requests" ADD CONSTRAINT "change_requests_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."contribution_suggestions" ADD CONSTRAINT "contribution_suggestions_signature_key" UNIQUE (signature);
ALTER TABLE "public"."guide_feedback" ADD CONSTRAINT "guide_feedback_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_ballot_eligibility" ADD CONSTRAINT "network_ballot_eligibility_pkey" PRIMARY KEY (ballot_id, user_id);
ALTER TABLE "public"."network_ballot_nominations" ADD CONSTRAINT "network_ballot_nominations_ballot_id_nominee_entity_id_key" UNIQUE (ballot_id, nominee_entity_id);
ALTER TABLE "public"."network_ballot_nominations" ADD CONSTRAINT "network_ballot_nominations_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_ballot_options" ADD CONSTRAINT "network_ballot_options_ballot_id_id_key" UNIQUE (ballot_id, id);
ALTER TABLE "public"."network_ballot_options" ADD CONSTRAINT "network_ballot_options_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_ballot_participation" ADD CONSTRAINT "network_ballot_participation_pkey" PRIMARY KEY (ballot_id, user_id);
ALTER TABLE "public"."network_ballot_participation" ADD CONSTRAINT "network_ballot_participation_receipt_id_key" UNIQUE (receipt_id);
ALTER TABLE "public"."network_ballot_votes" ADD CONSTRAINT "network_ballot_votes_ballot_id_anonymous_token_option_id_key" UNIQUE (ballot_id, anonymous_token, option_id);
ALTER TABLE "public"."network_ballot_votes" ADD CONSTRAINT "network_ballot_votes_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_ballots" ADD CONSTRAINT "network_ballots_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_fund_transactions" ADD CONSTRAINT "network_fund_transactions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."network_funds" ADD CONSTRAINT "network_funds_pkey" PRIMARY KEY (id);
