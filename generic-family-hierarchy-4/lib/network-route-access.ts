import type {NetworkMembership} from "../core/network/contracts";
import {getVerticalAppComposition} from "../app-shell/vertical-runtime";
import type {NetworkRoute} from "./network-routes";
import {decideScopedAuthorization} from "../core/authorization/policy";

/** A route never grants access. The active membership comes from the server-backed RPC. */
export function authorizeNetworkSurface(route:NetworkRoute,memberships:readonly NetworkMembership[]):NetworkMembership {
 const unavailable=()=>new Error("This page is not available to your account.");
 const membership=memberships.find(row=>row.network.id.toLowerCase()===route.networkId&&row.status==="active");
 if(!membership)throw unavailable();
 const composition=getVerticalAppComposition(membership.network.verticalKind);
 if(composition.renderStatus!=="active")throw unavailable();
 const surfaces=[...composition.primaryNavigation,...composition.mobileMoreNavigation];
 const target=surfaces.find(item=>item.viewId===route.surface);
 if(!target)throw unavailable();
 const decision=decideScopedAuthorization(
  {
   membership:{networkId:membership.network.id,role:membership.role,status:membership.status},
   capability:target.capability||"network.context",
   action:"surface.open",
   purpose:"network-navigation",
   resource:{networkId:membership.network.id,kind:"network-surface",id:target.viewId},
  },
  {roles:target.adminOnly?["owner","admin"]:["owner","admin","member"],accessMode:"role-only",purposes:["network-navigation"]},
 );
 if(!decision.allowed)throw unavailable();
 return membership;
}
