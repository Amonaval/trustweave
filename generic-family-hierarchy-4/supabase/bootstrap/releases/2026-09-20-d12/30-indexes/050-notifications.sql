-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE INDEX idx_network_notification_roles_lookup ON public.network_notification_roles USING btree (network_id, role_key, active);
CREATE INDEX idx_notification_preferences_network ON public.notification_preferences USING btree (network_id);
CREATE INDEX idx_notifications_network ON public.notifications USING btree (network_id);
CREATE INDEX idx_notifications_network_user_created ON public.notifications USING btree (network_id, user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notifications USING btree (user_id, read_at);
CREATE INDEX idx_notifications_user_created ON public.notifications USING btree (user_id, created_at DESC);
CREATE INDEX idx_notifications_user_unread_created ON public.notifications USING btree (user_id, read_at, created_at DESC) WHERE (archived_at IS NULL);
CREATE INDEX idx_push_subscriptions_user_active ON public.push_subscriptions USING btree (user_id, active, last_seen_at DESC);
