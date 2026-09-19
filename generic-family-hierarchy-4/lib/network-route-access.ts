import type {NetworkMembership} from "../core/network/contracts";
import {getVerticalAppComposition} from "../app-shell/vertical-runtime";
import type {NetworkRoute} from "./network-routes";

/** A route never grants access. The active membership comes from the server-backed RPC. */
export function authorizeNetworkSurface(route:NetworkRoute,memberships:readonly NetworkMembership[]):NetworkMembership {
 const unavailable=()=>new Error("This page is not available to your account.");
 const membership=memberships.find(row=>row.network.id.toLowerCase()===route.networkId&&row.status==="active");
 if(!membership)throw unavailable();
 const composition=getVerticalAppComposition(membership.network.verticalKind);
 if(composition.renderStatus!=="active")throw unavailable();
 const surfaces=[...composition.primaryNavigation,...composition.mobileMoreNavigation];
 const target=surfaces.find(item=>item.viewId===route.surface);
 if(!target||target.adminOnly&&membership.role!=="admin"&&membership.role!=="owner")throw unavailable();
 return membership;
}
