export type RenderPhase = "mount" | "update" | "nested-update";

export type RenderSample = {
  name: string;
  phase: RenderPhase;
  actualDurationMs: number;
  baseDurationMs: number;
  startTimeMs: number;
  commitTimeMs: number;
  at: number;
};

export type NetworkSample = {
  method: string;
  url: string;
  status: number | null;
  ok: boolean | null;
  durationMs: number;
  at: number;
  error?: string;
};

export type RuntimeErrorSample = {
  kind: "error" | "unhandledrejection";
  message: string;
  stack?: string;
  at: number;
};

export type LongTaskSample = { durationMs: number; at: number };

export type MountSample = {
  name: string;
  instanceId: string;
  action: "mount" | "unmount";
  at: number;
};

export type RuntimeSnapshot = {
  startedAt: number;
  renders: RenderSample[];
  network: NetworkSample[];
  errors: RuntimeErrorSample[];
  longTasks: LongTaskSample[];
  mounts: MountSample[];
  domNodes: number;
  route: string;
};

export type DiagnosticFinding = {
  severity: "info" | "warning" | "critical";
  title: string;
  detail: string;
  evidence: string;
};
