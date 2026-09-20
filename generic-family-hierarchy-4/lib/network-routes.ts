/** Version 1 route grammar. Opaque persisted network IDs stay stable across renames. */
export type NetworkRoute = {networkId:string;surface:string};
const opaqueId=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const surfaceToken=/^[a-z][a-z0-9-]{0,39}$/;

export function networkSurfaceHref(networkId:string,surface="home"):string {
 if(!opaqueId.test(networkId)||!surfaceToken.test(surface))throw new Error("Invalid network route identifier");
 return `/network/${networkId.toLowerCase()}/${surface}`;
}

export function parseNetworkRoute(pathname:string):NetworkRoute|null|"invalid" {
 if(!pathname.startsWith("/network/"))return null;
 const parts=pathname.split("/");
 if((parts.length!==3&&parts.length!==4)||!opaqueId.test(parts[2])||(parts.length===4&&!surfaceToken.test(parts[3])))return "invalid";
 return {networkId:parts[2].toLowerCase(),surface:parts[3]||"home"};
}

/** History navigation uses the same grammar as direct entry; popstate is read by the shell. */
export function navigateNetworkSurface(networkId:string,surface:string,replace=false):void {
 if(typeof window==="undefined")return;
 const href=networkSurfaceHref(networkId,surface);
 if(window.location.pathname===href)return;
 window.history[replace?"replaceState":"pushState"]({},"",href);
 window.dispatchEvent(new Event("trustweave:route"));
}
