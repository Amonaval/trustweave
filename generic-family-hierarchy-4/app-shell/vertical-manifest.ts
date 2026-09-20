import type {VerticalAppComposition,VerticalSurfaceDescriptor} from "../core/verticals/app-composition";
import type {VerticalDefinition} from "../core/verticals/contracts";
import {getCapabilityContract} from "../core/verticals/capability-manifest";
import {NETWORK_VERTICAL_KINDS,type NetworkVerticalKind} from "../core/verticals/kinds";
import {FAMILY_VERTICAL} from "../verticals/family/definition";
import {ALUMNI_VERTICAL} from "../verticals/alumni/definition";
import {ASSOCIATION_VERTICAL} from "../verticals/association/definition";
import {FAMILY_ASSOCIATION_VERTICAL} from "../verticals/family-association/definition";
import {HOUSING_SOCIETY_VERTICAL} from "../verticals/housing-society/definition";
import {ORGANIZATION_VERTICAL} from "../verticals/organization/definition";
import {BUSINESS_TRUST_VERTICAL} from "../verticals/business-trust/definition";
import {FRANCHISE_VERTICAL} from "../verticals/franchise/definition";
import {PROFESSIONAL_VERTICAL} from "../verticals/professional/definition";
import {FAMILY_APP_COMPOSITION} from "../verticals/family/runtime/composition";
import {ALUMNI_APP_COMPOSITION} from "../verticals/alumni/runtime/composition";
import {ASSOCIATION_APP_COMPOSITION} from "../verticals/association/runtime/composition";
import {FAMILY_ASSOCIATION_APP_COMPOSITION} from "../verticals/family-association/runtime/composition";
import {HOUSING_SOCIETY_APP_COMPOSITION} from "../verticals/housing-society/runtime/composition";
import {ORGANIZATION_APP_COMPOSITION} from "../verticals/organization/runtime/composition";
import {BUSINESS_TRUST_APP_COMPOSITION} from "../verticals/business-trust/runtime/composition";
import {FRANCHISE_APP_COMPOSITION} from "../verticals/franchise/runtime/composition";
import {PROFESSIONAL_APP_COMPOSITION} from "../verticals/professional/runtime/composition";
import {PRODUCTIZED_RUNTIME_META} from "../templates/productized/runtime-meta";
import type {ProductizedRuntimeMeta} from "../templates/productized/runtime-meta";

export type VerticalManifestEntry = Readonly<{
  definition:VerticalDefinition;
  app:VerticalAppComposition;
  runtimeMode:"family"|"alumni"|"productized-template";
  productizedConfig:ProductizedRuntimeMeta|null;
  loadingBoundary:"universal-shell"|"lazy-vertical-ui";
}>;

/** One authoritative runtime composition; other public registries are projections. */
export const VERTICAL_MANIFEST = Object.freeze({
  family:{definition:FAMILY_VERTICAL,app:FAMILY_APP_COMPOSITION,runtimeMode:"family",productizedConfig:null,loadingBoundary:"universal-shell"},
  alumni:{definition:ALUMNI_VERTICAL,app:ALUMNI_APP_COMPOSITION,runtimeMode:"alumni",productizedConfig:null,loadingBoundary:"lazy-vertical-ui"},
  association:{definition:ASSOCIATION_VERTICAL,app:ASSOCIATION_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_RUNTIME_META["association"],loadingBoundary:"lazy-vertical-ui"},
  "family-association":{definition:FAMILY_ASSOCIATION_VERTICAL,app:FAMILY_ASSOCIATION_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_RUNTIME_META["family-association"],loadingBoundary:"lazy-vertical-ui"},
  "housing-society":{definition:HOUSING_SOCIETY_VERTICAL,app:HOUSING_SOCIETY_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_RUNTIME_META["housing-society"],loadingBoundary:"lazy-vertical-ui"},
  organization:{definition:ORGANIZATION_VERTICAL,app:ORGANIZATION_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_RUNTIME_META["organization"],loadingBoundary:"lazy-vertical-ui"},
  "business-trust":{definition:BUSINESS_TRUST_VERTICAL,app:BUSINESS_TRUST_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_RUNTIME_META["business-trust"],loadingBoundary:"lazy-vertical-ui"},
  franchise:{definition:FRANCHISE_VERTICAL,app:FRANCHISE_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_RUNTIME_META["franchise"],loadingBoundary:"lazy-vertical-ui"},
  professional:{definition:PROFESSIONAL_VERTICAL,app:PROFESSIONAL_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_RUNTIME_META["professional"],loadingBoundary:"lazy-vertical-ui"},
} as const satisfies Record<NetworkVerticalKind,VerticalManifestEntry>);

export type VerticalManifest = typeof VERTICAL_MANIFEST;

export function getVerticalManifest<K extends NetworkVerticalKind>(kind:K):VerticalManifest[K];
export function getVerticalManifest(kind:string):VerticalManifest[NetworkVerticalKind];
export function getVerticalManifest(kind:string):VerticalManifest[NetworkVerticalKind] {
  if(!Object.prototype.hasOwnProperty.call(VERTICAL_MANIFEST,kind))throw new Error(`Unknown network vertical: ${kind}`);
  return VERTICAL_MANIFEST[kind as NetworkVerticalKind];
}

function assertManifest(){
  const keys=Object.keys(VERTICAL_MANIFEST);
  if(keys.length!==NETWORK_VERTICAL_KINDS.length)throw new Error("Vertical manifest and runtime vocabulary differ");
  for(const kind of NETWORK_VERTICAL_KINDS){
    const {definition,app,runtimeMode,productizedConfig,loadingBoundary}=getVerticalManifest(kind);
    if(definition.kind!==kind||app.kind!==kind||definition.status!==app.renderStatus||definition.featureCatalog.catalogId!==app.featureCatalogId)throw new Error(`Vertical identity mismatch: ${kind}`);
    if((runtimeMode==="productized-template")!==(productizedConfig!==null)||productizedConfig&&productizedConfig.kind!==kind)throw new Error(`Vertical config mismatch: ${kind}`);
    if(kind==="family"&&loadingBoundary!=="universal-shell"||kind!=="family"&&loadingBoundary!=="lazy-vertical-ui")throw new Error(`Vertical loading mismatch: ${kind}`);
    const features=new Set(definition.featureCatalog.features.map(feature=>feature.key));
    const capabilities=new Set<string>(definition.capabilities);
    for(const capability of capabilities)getCapabilityContract(capability);
    const surfaces=new Set<string>();
    for(const surface of [...app.primaryNavigation,...app.mobileMoreNavigation] as VerticalSurfaceDescriptor[]){
      if(surfaces.has(surface.viewId))throw new Error(`Duplicate ${kind} navigation surface: ${surface.viewId}`);
      surfaces.add(surface.viewId);
      if(surface.featureKey&&!features.has(surface.featureKey))throw new Error(`Unknown ${kind} surface feature: ${surface.featureKey}`);
      if(surface.capability&&!capabilities.has(surface.capability))throw new Error(`Unknown ${kind} surface capability: ${surface.capability}`);
    }
  }
}
assertManifest();
