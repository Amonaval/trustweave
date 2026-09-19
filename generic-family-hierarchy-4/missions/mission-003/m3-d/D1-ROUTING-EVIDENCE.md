# M3-D1 — Addressable routing foundation (candidate evidence)

**Baseline:** `llm-push` D0 commit `bac11f64654cc0fa585a0732bbbb18be063e6916`. This slice establishes the first network/surface route contract. It does **not** certify every historical screen or a connected authenticated browser journey.

## Route contract, version 1

| URL | Owner | Meaning / gate |
| --- | --- | --- |
| `/` | App shell | Existing Discovery, sign in and My Networks. |
| `/network/{networkId}` | App shell | Network Home; canonical generated form includes `/home`. |
| `/network/{networkId}/{surface}` | Existing vertical app composition | A registered surface such as Family `/tree`, Family Community `/community`, Housing `/complaints`. Server-backed active membership and surface access are checked before network content renders. |
| `/invite/{token}`, `/society-invite/{token}`, `/public/*`, `/passport/{slug}` | Existing owners | Their existing public/private contracts remain unchanged. |

The `networkId` is a persisted opaque UUID, lowercase in generated URLs. Network names/slugs do not form identity and can change without breaking links. `surface` is a bounded token found in that network's existing vertical app composition. Temporary filters, editor state and transient modals remain local. This grammar leaves future capability-owned detail URLs open; a complaint/member/event ID is not yet a routable detail endpoint.

The new dynamic Next page mounts the existing shell. On entry, the shell reads the URL, calls `get_my_networks`, checks active membership and registered surface, activates the requested network through the existing `set_active_network` RPC, and hydrates under that context. Unknown network, inactive membership, unregistered surface and non-admin access to an admin surface all return the same unavailable response. Route checks add a UI gate; existing RLS/server authorization remains decisive for data operations. The unauthenticated link stays in the address bar through sign in, so hydration can resume it. Browser `popstate` and in-app navigation share the same parser.

`buildNotificationDeepLink` now emits the canonical network/surface URL for persisted UUIDs. Historical `twNetwork`/`twSurface` query links still resolve. Foreign-origin notification hrefs never become destinations. Resource IDs are withheld from new URLs until a capability-owned authorized detail route exists.

## Route inventory and migration backlog

| Vertical | First addressable surfaces | Follow-up |
| --- | --- | --- |
| Family | Home, Tree, Directory and other registered navigation views | Member detail requires an ID lookup with privacy-scoped authorization. |
| Family Community | Home, Community, Directory, Elections/Funds, Guide and admin where permitted | Event/household/member detail needs its own policy and absent/deleted semantics. |
| Housing | Home, Complaints, Notices, Directory, Amenities and admin where permitted | Complaint detail needs owner-specific read policy and explicit deleted/forbidden handling. |

Other registered vertical surfaces use the same route grammar through the composition registry; this is a contract check, not a connected runtime certification of all verticals. Add an authorized detail route when its capability provides a stable opaque resource ID and safe lookup. Public profiles and federation links keep their separately governed route contracts. Notification/item `twItem` legacy hints are not upgraded into a detail route.

## Verification and limits

- Route unit contracts cover three representative verticals, every registered navigation ID, invalid/private URL tokens, cross-tenant and inactive membership, admin denial, legacy notification fallback and external href rejection.
- Source syntax, TypeScript and production build are gates. The initial production build reports **754 kB First Load JS** for both `/` and `/network/[networkId]/[[...surface]]`; D1 does not reduce that cost. D7 must split static vertical imports and measure again.
- The local archive contains no connected Supabase QA credentials. Authenticated direct entry, sign in return, admin/member denial, refresh and browser back/forward across real networks still require a staging browser run with disposable users. Do not label D1 certified or proceed to D2 on source-only evidence.
- Route analytics, future mobile universal links, canonical redirect from `/network/{id}` to `/home`, and precise forbidden/removed/not-found resource semantics remain follow-up work. Avoid leaking network existence to unauthorized users.
