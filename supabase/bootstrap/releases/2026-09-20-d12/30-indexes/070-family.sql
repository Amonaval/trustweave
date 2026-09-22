-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE UNIQUE INDEX uq_family_creation_pending_user ON public.family_creation_requests USING btree (requester_user_id) WHERE ((status)::text = 'pending'::text);
CREATE INDEX family_engagement_network_created_idx ON public.family_engagement_events USING btree (network_id, created_at DESC);
CREATE INDEX idx_family_intake_access_session ON public.family_intake_access USING btree (session_id, status);
CREATE INDEX idx_family_intake_events_network ON public.family_intake_events USING btree (network_id, event_name, created_at DESC);
CREATE INDEX idx_family_intake_candidates_person ON public.family_intake_match_candidates USING btree (staged_person_id, score DESC);
CREATE INDEX idx_family_intake_people_access ON public.family_intake_people USING btree (access_id);
CREATE INDEX idx_family_intake_people_session_name ON public.family_intake_people USING btree (session_id, normalized_name);
CREATE INDEX idx_family_intake_relationships_access ON public.family_intake_relationships USING btree (access_id);
CREATE INDEX idx_family_intake_sessions_network ON public.family_intake_sessions USING btree (network_id, created_at DESC);
CREATE INDEX idx_family_relationships_network ON public.family_relationships USING btree (network_id);
CREATE INDEX idx_family_relationships_person ON public.family_relationships USING btree (person_id);
CREATE INDEX idx_family_relationships_related ON public.family_relationships USING btree (related_person_id);
CREATE UNIQUE INDEX uq_family_relationships_spouse_pair ON public.family_relationships USING btree (LEAST(person_id, related_person_id), GREATEST(person_id, related_person_id)) WHERE ((relationship_type)::text = 'spouse'::text);
CREATE INDEX idx_member_life_events_member_date ON public.member_life_events USING btree (member_id, event_date);
CREATE INDEX idx_member_life_events_network ON public.member_life_events USING btree (network_id);
CREATE INDEX idx_member_life_events_visibility ON public.member_life_events USING btree (visibility);
CREATE INDEX idx_memories_member_created ON public.memories USING btree (member_id, created_at DESC);
CREATE INDEX idx_memories_network ON public.memories USING btree (network_id);
CREATE INDEX memories_network_event_idx ON public.memories USING btree (network_id, event_id, created_at DESC);
CREATE INDEX idx_memory_people_member ON public.memory_people USING btree (member_id, memory_id);
CREATE INDEX idx_memory_people_network ON public.memory_people USING btree (network_id);
CREATE INDEX memory_reactions_network_idx ON public.memory_reactions USING btree (network_id, memory_id);
CREATE INDEX idx_profile_submissions_network ON public.profile_submissions USING btree (network_id);
