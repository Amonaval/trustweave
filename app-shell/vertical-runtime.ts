import type {AppLocale,VerticalAppComposition,VerticalSurfaceDescriptor} from "../core/verticals/app-composition";
import type {NetworkVerticalKind} from "../core/verticals/contracts";
import {getVerticalCapabilityRuntime} from "./vertical-capabilities";
import {getVerticalManifest} from "./vertical-manifest";

export type VerticalRuntimeDefinition=Readonly<{
  kind:NetworkVerticalKind;
  definition:ReturnType<typeof getVerticalManifest>["definition"];
  capabilities:ReturnType<typeof getVerticalCapabilityRuntime>;
  app:VerticalAppComposition;
}>;

export function getVerticalAppComposition(kind:NetworkVerticalKind):VerticalAppComposition {
  return getVerticalManifest(kind).app;
}

export function getVerticalRuntimeDefinition(kind:NetworkVerticalKind):VerticalRuntimeDefinition {
  const manifest=getVerticalManifest(kind);
  return {kind,definition:manifest.definition,capabilities:getVerticalCapabilityRuntime(kind),app:manifest.app};
}

/** Skeleton verticals and unknown IDs fail closed. */
export function getRenderableVerticalRuntime(kind:NetworkVerticalKind):VerticalRuntimeDefinition {
  const requested=getVerticalRuntimeDefinition(kind);
  if(requested.app.renderStatus!=="active")throw new Error(`Vertical ${kind} is not user-visible yet.`);
  return requested;
}

export function localizedSurfaceLabel(surface:VerticalSurfaceDescriptor,locale:AppLocale):string {
  return surface.label[locale]||surface.label.en;
}
