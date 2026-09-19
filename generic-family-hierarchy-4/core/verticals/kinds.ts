/** Small, dependency-free runtime vocabulary shared by transport and the manifest. */
export const NETWORK_VERTICAL_KINDS = [
  "family", "alumni", "association", "family-association", "housing-society",
  "organization", "business-trust", "franchise", "professional",
] as const;

export type NetworkVerticalKind = (typeof NETWORK_VERTICAL_KINDS)[number];
export type ProductizedVerticalKind = Exclude<NetworkVerticalKind,"family"|"alumni">;

export function isNetworkVerticalKind(value: unknown): value is NetworkVerticalKind {
  return typeof value === "string" && NETWORK_VERTICAL_KINDS.includes(value as NetworkVerticalKind);
}

export function isProductizedVerticalKind(value: unknown): value is ProductizedVerticalKind {
  return isNetworkVerticalKind(value)&&value!=="family"&&value!=="alumni";
}
