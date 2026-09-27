"use client";

import {useEffect, useState, type ReactNode} from "react";
import {startBrowserObservation} from "../browser";
import RuntimeObservabilityPanel from "./RuntimeObservabilityPanel";
import RuntimeProfiler from "./RuntimeProfiler";
import {RuntimeObservabilityContext} from "./RuntimeObservabilityContext";

const STORAGE_KEY = "trustweave-runtime-observability";

export default function RuntimeObservabilityBridge({children}: {children: ReactNode}) {
  const [enabled, setEnabled] = useState(false);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const requested = params.get("twdebug");
    if (requested === "1") sessionStorage.setItem(STORAGE_KEY, "1");
    if (requested === "0") sessionStorage.removeItem(STORAGE_KEY);
    setEnabled(sessionStorage.getItem(STORAGE_KEY) === "1");
  }, []);

  useEffect(() => {
    if (!enabled) return;
    return startBrowserObservation();
  }, [enabled]);

  return (
    <RuntimeObservabilityContext.Provider value={enabled}>
      <RuntimeProfiler name="TrustWeaveRoot" enabled={enabled}>{children}</RuntimeProfiler>
      {enabled ? <RuntimeObservabilityPanel /> : null}
    </RuntimeObservabilityContext.Provider>
  );
}
