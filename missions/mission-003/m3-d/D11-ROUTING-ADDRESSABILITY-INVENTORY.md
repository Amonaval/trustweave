# D11 Routing / Addressability Inventory for School

## Existing platform grammar

Private School application state must use:

`/network/{networkId}/{surface}`

The network ID is an opaque persisted UUID. The surface is a bounded route token owned by the School app composition.

## Initial School surfaces

| Surface | Primary ownership | Detail-route policy |
| --- | --- | --- |
| home | shared shell + School composition | No detail ID |
| students | School + network affiliation | Student detail only after authorized resource lookup exists |
| classes | School + affiliation/groups | Class detail only after class-scoped server lookup exists |
| notices | activity + School audience adapter | Notice detail only after resource authorization exists |
| tasks | D5 workflow + School adapter | Task detail only after School-owned stable resource ID exists |
| ptm | events/workflow + School adapter | PTM appointment detail must enforce guardian/teacher/student scope |
| events | shared groups/events | Event detail may follow capability-owned resource route later |
| attendance | `school.attendance` | Never expose student/day identifiers without resource policy |
| transport | `school.transport` | Pickup/release detail is sensitive and must be capability-owned |
| concerns | D5 workflow + School concern adapter | Concern detail must be participant/admin scoped |
| guide | shared guide | No sensitive resource ID |
| admin | School admin | Existing admin-only route policy plus server authorization |

## Detail-route rule

D11 does not introduce `/school/.../` as a parallel grammar.

When a resource-level route becomes necessary, extend the Network OS route contract in a capability-owned way only after all of the following exist:

- stable opaque resource identifier;
- authorized server lookup;
- not-found/forbidden/deleted semantics;
- notification/deep-link owner;
- policy tests;
- no private labels or human-readable sensitive data embedded in the URL.

Until then, the surface route is the stable address and resource selection remains inside the authorized surface.
