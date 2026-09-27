"use client";

import {createContext, useContext} from "react";

export const RuntimeObservabilityContext = createContext(false);

export function useRuntimeObservabilityEnabled() {
  return useContext(RuntimeObservabilityContext);
}
