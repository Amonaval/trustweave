"use client";

import {Profiler, useEffect, useId, type ReactNode} from "react";
import {runtimeObservabilityStore} from "../store";
import {useRuntimeObservabilityEnabled} from "./RuntimeObservabilityContext";

export default function RuntimeProfiler({name, children, enabled}: {name: string; children: ReactNode; enabled?: boolean}) {
  const inheritedEnabled = useRuntimeObservabilityEnabled();
  const active = enabled ?? inheritedEnabled;
  const reactId = useId();
  const instanceId = `${name}-${reactId}`;

  useEffect(() => {
    if (!active) return;
    runtimeObservabilityStore.recordMount({name, instanceId, action: "mount", at: Date.now()});
    return () => runtimeObservabilityStore.recordMount({name, instanceId, action: "unmount", at: Date.now()});
  }, [active, instanceId, name]);

  if (!active) return <>{children}</>;

  return (
    <Profiler
      id={name}
      onRender={(id, phase, actualDuration, baseDuration, startTime, commitTime) => {
        runtimeObservabilityStore.recordRender({
          name: id,
          phase,
          actualDurationMs: actualDuration,
          baseDurationMs: baseDuration,
          startTimeMs: startTime,
          commitTimeMs: commitTime,
          at: Date.now(),
        });
      }}
    >
      {children}
    </Profiler>
  );
}
