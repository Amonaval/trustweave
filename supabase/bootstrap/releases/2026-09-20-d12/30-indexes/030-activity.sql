-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_community_event_responses_network ON public.community_event_responses USING btree (network_id);
CREATE INDEX idx_community_events_network ON public.community_events USING btree (network_id);
CREATE INDEX idx_community_family_links_network ON public.community_family_links USING btree (network_id, status);
CREATE INDEX idx_community_group_members_network ON public.community_group_members USING btree (network_id);
CREATE INDEX idx_community_groups_network ON public.community_groups USING btree (network_id);
CREATE INDEX idx_intro_requests_requester ON public.community_introduction_requests USING btree (requester_user_id, status, created_at DESC);
CREATE INDEX idx_intro_requests_target ON public.community_introduction_requests USING btree (target_user_id, status, created_at DESC);
CREATE INDEX idx_community_posts_space ON public.community_posts USING btree (space_id, category, status, created_at DESC);
CREATE INDEX idx_community_profile_cards_space ON public.community_profile_cards USING btree (space_id, category, active);
CREATE INDEX idx_community_trust_edges_networks ON public.community_trust_edges USING btree (space_id, status, requester_network_id, recipient_network_id);
CREATE UNIQUE INDEX uq_community_trust_edge_pair ON public.community_trust_edges USING btree (space_id, LEAST(requester_network_id, recipient_network_id), GREATEST(requester_network_id, recipient_network_id));
CREATE INDEX idx_network_activities_network_sort_id ON public.network_activities USING btree (network_id, COALESCE(starts_at, created_at) DESC, id DESC);
CREATE INDEX idx_network_activities_network_type_date ON public.network_activities USING btree (network_id, activity_type, starts_at DESC NULLS LAST, created_at DESC);
CREATE INDEX idx_network_activity_comments_network_activity_created ON public.network_activity_comments USING btree (network_id, activity_id, created_at, id);
CREATE INDEX idx_network_media_assets_lifecycle ON public.network_media_assets USING btree (network_id, lifecycle_state, created_at DESC);
CREATE INDEX idx_network_media_assets_network_entity ON public.network_media_assets USING btree (network_id, entity_type, entity_id, created_at DESC);
CREATE INDEX idx_network_media_assets_network_kind ON public.network_media_assets USING btree (network_id, media_kind, created_at DESC);
CREATE INDEX idx_participation_events_network ON public.participation_events USING btree (network_id);
CREATE INDEX idx_participation_events_type_created ON public.participation_events USING btree (event_type, created_at DESC);
