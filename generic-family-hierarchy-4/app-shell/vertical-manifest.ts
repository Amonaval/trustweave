import type {VerticalAppComposition,VerticalSurfaceDescriptor} from "../core/verticals/app-composition";
import type {VerticalDefinition} from "../core/verticals/contracts";
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
import {PRODUCTIZED_NETWORK_CONFIGS} from "../templates/productized/config";
import type {ProductizedNetworkConfig} from "../templates/productized/config";

export type VerticalManifestEntry = Readonly<{
  definition:VerticalDefinition;
  app:VerticalAppComposition;
  runtimeMode:"family"|"alumni"|"productized-template";
  productizedConfig:ProductizedNetworkConfig|null;
}>;

/** One authoritative runtime composition; other public registries are projections. */
export const VERTICAL_MANIFEST = Object.freeze({
  family:{definition:FAMILY_VERTICAL,app:FAMILY_APP_COMPOSITION,runtimeMode:"family",productizedConfig:null},
  alumni:{definition:ALUMNI_VERTICAL,app:ALUMNI_APP_COMPOSITION,runtimeMode:"alumni",productizedConfig:null},
  association:{definition:ASSOCIATION_VERTICAL,app:ASSOCIATION_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_NETWORK_CONFIGS.association},
  "family-association":{definition:FAMILY_ASSOCIATION_VERTICAL,app:FAMILY_ASSOCIATION_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_NETWORK_CONFIGS["family-association"]},
  "housing-society":{definition:HOUSING_SOCIETY_VERTICAL,app:HOUSING_SOCIETY_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_NETWORK_CONFIGS["housing-society"]},
  organization:{definition:ORGANIZATION_VERTICAL,app:ORGANIZATION_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_NETWORK_CONFIGS.organization},
  "business-trust":{definition:BUSINESS_TRUST_VERTICAL,app:BUSINESS_TRUST_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_NETWORK_CONFIGS["business-trust"]},
  franchise:{definition:FRANCHISE_VERTICAL,app:FRANCHISE_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_NETWORK_CONFIGS.franchise},
  professional:{definition:PROFESSIONAL_VERTICAL,app:PROFESSIONAL_APP_COMPOSITION,runtimeMode:"productized-template",productizedConfig:PRODUCTIZED_NETWORK_CONFIGS.professional},
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
    const {definition,app,runtimeMode,productizedConfig}=getVerticalManifest(kind);
    if(definition.kind!==kind||app.kind!==kind||definition.status!==app.renderStatus||definition.featureCatalog.catalogId!==app.featureCatalogId)throw new Error(`Vertical identity mismatch: ${kind}`);
    if((runtimeMode==="productized-template")!==(productizedConfig!==null)||productizedConfig&&productizedConfig.kind!==kind)throw new Error(`Vertical config mismatch: ${kind}`);
    const features=new Set(definition.featureCatalog.features.map(feature=>feature.key));
    const capabilities=new Set<string>(definition.capabilities);
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
