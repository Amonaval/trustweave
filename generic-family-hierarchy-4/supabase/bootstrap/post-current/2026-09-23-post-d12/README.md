# TrustWeave post-D12 bootstrap tail — 2026-09-23

Status: **current consolidated delta through migration 130**.

The certified D12 bootstrap release remains immutable and covers the accepted database state through migration 123. This tail keeps new/fresh Supabase projects aligned with accepted product schema changes made after that cut point without rewriting the D12 release.

## Coverage

This tail represents the **final effective state**, not a blind migration replay:

- **124** — Family Community activation-evidence RPCs.
- **125** — not repeated separately; its RSVP identity contract is superseded by the final implementation in 126.
- **126** — generic Community Object lifecycle, attendee/member detail and group membership administration.
- **127** — Platform Design Studio tables and RPCs.
- **128** — retains only the notification overload cleanup.
- **129** — not replayed; its platform Storage guard is superseded by the validated final contract in 130.
- **130** — runtime-proven Platform Design Studio Storage behavior: Storage RLS owns platform authorization while the shared trigger preserves the strong network-media tenant/user/path/quota contract.

## Fresh project apply order

1. Apply the immutable release named by `supabase/bootstrap/CURRENT`.
2. Apply `00-database.sql`.
3. Apply `10-storage-owner-context.sql` through hosted Supabase owner/dashboard context.

The owner-context split is intentional because hosted Supabase owns `storage.objects`.

## Existing databases

Do **not** use this tail as an upgrade shortcut on an existing TrustWeave database. Existing databases continue through `supabase/migrations/`.

## Bootstrap synchronization rule

A database change enters this current tail only after its runtime behavior has been proven. Experimental SQL patches stay out. Once proven, fold the **final effective contract** into this tail before closing the mission so a new Supabase project does not drift behind the product.

A later full canonical/bootstrap regeneration may absorb this tail into a new immutable release and reset `POST_CURRENT`.
