-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TRIGGER trg_xp6_contribution_review AFTER UPDATE OF status ON network_contributions FOR EACH ROW EXECUTE FUNCTION xp6_log_contribution_review();
CREATE TRIGGER trg_fca_seed_network_defaults AFTER INSERT ON networks FOR EACH ROW EXECUTE FUNCTION fca_seed_network_defaults_trigger();
CREATE TRIGGER trg_platform_feature_rollout_audit AFTER UPDATE ON platform_feature_flags FOR EACH ROW EXECUTE FUNCTION audit_platform_feature_rollout();
