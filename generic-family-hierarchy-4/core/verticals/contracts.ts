import type { FeatureCatalog } from "../features/contracts";

export type { NetworkVerticalKind } from "./kinds";
import type { NetworkVerticalKind } from "./kinds";

export type { VerticalCapabilityId } from "./capability-manifest";
import type { VerticalCapabilityId } from "./capability-manifest";

export type VerticalNetworkLabels = {
  entityLabel: string; entityLabelPlural: string; levelLabel: string; levelLabelPlural: string;
  parentLabel: string; childLabel: string; peerLabel: string;
};

export type VerticalDefinition = {
  kind: NetworkVerticalKind;
  displayName: string;
  iconToken: string;
  themeToken: string;
  capabilities: readonly VerticalCapabilityId[];
  featureCatalog: FeatureCatalog;
  legacyNetworkLabels: VerticalNetworkLabels;
  status: "active" | "skeleton";
};
