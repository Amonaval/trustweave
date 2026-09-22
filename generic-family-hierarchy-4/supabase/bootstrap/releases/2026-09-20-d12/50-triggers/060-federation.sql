-- TRUSTWEAVE D12 CANONICAL CURRENT-STATE BASELINE.
-- Materialized after fresh-project structural/security/API/behavior/product parity on 2026-09-20.
-- DO NOT apply these files to the historical golden project as an upgrade sequence.
-- Historical supabase/migrations/001..123 remain immutable upgrade history.

CREATE TRIGGER trg_nf8_capture_accepted_trust_receipt AFTER UPDATE OF status, responded_at ON federated_introductions FOR EACH ROW EXECUTE FUNCTION nf8_capture_accepted_trust_receipt();
