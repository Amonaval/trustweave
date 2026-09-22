import type {NetworkVerticalKind} from "../core/verticals/contracts";
import {NETWORK_VERTICAL_KINDS,isNetworkVerticalKind} from "../core/verticals/kinds";
import {VERTICAL_MANIFEST,getVerticalManifest,type VerticalManifest} from "./vertical-manifest";

type VerticalRegistry={readonly [K in NetworkVerticalKind]:VerticalManifest[K]["definition"]};

/** Compatibility projection; register a new vertical in vertical-manifest.ts. */
export const VERTICAL_REGISTRY=Object.freeze(Object.fromEntries(
  NETWORK_VERTICAL_KINDS.map(kind=>[kind,VERTICAL_MANIFEST[kind].definition])
)) as VerticalRegistry;

export const DEFAULT_VERTICAL_KIND:NetworkVerticalKind="family";

export function getVerticalDefinition<K extends NetworkVerticalKind>(kind:K):VerticalRegistry[K] {
  getVerticalManifest(kind); // fail closed even for an unchecked runtime string
  return VERTICAL_REGISTRY[kind];
}

export function getVerticalFeatureCatalog<K extends NetworkVerticalKind>(kind:K):VerticalRegistry[K]["featureCatalog"] {
  return getVerticalDefinition(kind).featureCatalog;
}

export function isRegisteredVerticalKind(value:string|null|undefined):value is NetworkVerticalKind {
  return isNetworkVerticalKind(value)&&Object.prototype.hasOwnProperty.call(VERTICAL_REGISTRY,value);
}
