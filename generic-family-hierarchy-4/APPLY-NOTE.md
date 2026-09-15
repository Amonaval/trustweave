# Housing minor UX follow-up

Apply these files over the latest TrustWeave source tree.

## Changes
- Service desk health now shows up to 3 open complaint titles and includes a **View complaints** action.
- Housing admin Operations passes navigation into the service-desk card.
- Governance admin Committee & Meetings now immediately shows:
  - current/active committee term and assignments,
  - scheduled meetings,
  - empty-state guidance when a term exists but roles are not assigned.
- Active/latest committee term auto-selects for role assignment after load/save.

No database migration is required.
Regression Mission 2 remains paused.

Validation:
- static syntax scan: 344 TS/TSX, 0 syntax errors
- HS-4 governance gate: 28/28 PASS
- residential flagship gate: 12/12 PASS
