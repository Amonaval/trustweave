-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

ALTER TABLE "public"."family_creation_requests" ADD CONSTRAINT "family_creation_requests_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_digest_state" ADD CONSTRAINT "family_digest_state_pkey" PRIMARY KEY (network_id, user_id);
ALTER TABLE "public"."family_engagement_events" ADD CONSTRAINT "family_engagement_events_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_access" ADD CONSTRAINT "family_intake_access_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_access" ADD CONSTRAINT "family_intake_access_token_hash_key" UNIQUE (token_hash);
ALTER TABLE "public"."family_intake_conflicts" ADD CONSTRAINT "family_intake_conflicts_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_conflicts" ADD CONSTRAINT "family_intake_conflicts_staged_person_id_member_id_field_na_key" UNIQUE (staged_person_id, member_id, field_name);
ALTER TABLE "public"."family_intake_decisions" ADD CONSTRAINT "family_intake_decisions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_events" ADD CONSTRAINT "family_intake_events_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_match_candidates" ADD CONSTRAINT "family_intake_match_candidates_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_people" ADD CONSTRAINT "family_intake_people_access_id_client_ref_key" UNIQUE (access_id, client_ref);
ALTER TABLE "public"."family_intake_people" ADD CONSTRAINT "family_intake_people_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_relationships" ADD CONSTRAINT "family_intake_relationships_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_intake_sessions" ADD CONSTRAINT "family_intake_sessions_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."family_join_codes" ADD CONSTRAINT "family_join_codes_code_key" UNIQUE (code);
ALTER TABLE "public"."family_join_codes" ADD CONSTRAINT "family_join_codes_pkey" PRIMARY KEY (network_id);
ALTER TABLE "public"."family_relationships" ADD CONSTRAINT "family_relationships_person_id_related_person_id_relationsh_key" UNIQUE (person_id, related_person_id, relationship_type);
ALTER TABLE "public"."family_relationships" ADD CONSTRAINT "family_relationships_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."member_life_events" ADD CONSTRAINT "member_life_events_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."memories" ADD CONSTRAINT "memories_pkey" PRIMARY KEY (id);
ALTER TABLE "public"."memory_people" ADD CONSTRAINT "memory_people_pkey" PRIMARY KEY (memory_id, member_id);
ALTER TABLE "public"."memory_reactions" ADD CONSTRAINT "memory_reactions_pkey" PRIMARY KEY (memory_id, user_id);
ALTER TABLE "public"."profile_submissions" ADD CONSTRAINT "profile_submissions_pkey" PRIMARY KEY (id);
