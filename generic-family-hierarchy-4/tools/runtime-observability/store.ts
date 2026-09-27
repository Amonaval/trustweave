import type {
  DiagnosticFinding,
  LongTaskSample,
  MountSample,
  NetworkSample,
  RenderSample,
  RuntimeErrorSample,
  RuntimeSnapshot,
} from "./types";

const MAX_SAMPLES = 300;

class RuntimeObservabilityStore {
  private startedAt = Date.now();
  private renders: RenderSample[] = [];
  private network: NetworkSample[] = [];
  private errors: RuntimeErrorSample[] = [];
  private longTasks: LongTaskSample[] = [];
  private mounts: MountSample[] = [];
  private listeners = new Set<() => void>();

  subscribe = (listener: () => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  private emit() {
    for (const listener of this.listeners) listener();
  }

  private push<T>(list: T[], item: T) {
    list.push(item);
    if (list.length > MAX_SAMPLES) list.splice(0, list.length - MAX_SAMPLES);
    this.emit();
  }

  recordRender(sample: RenderSample) { this.push(this.renders, sample); }
  recordNetwork(sample: NetworkSample) { this.push(this.network, sample); }
  recordError(sample: RuntimeErrorSample) { this.push(this.errors, sample); }
  recordLongTask(sample: LongTaskSample) { this.push(this.longTasks, sample); }
  recordMount(sample: MountSample) { this.push(this.mounts, sample); }

  reset() {
    this.startedAt = Date.now();
    this.renders = [];
    this.network = [];
    this.errors = [];
    this.longTasks = [];
    this.mounts = [];
    this.emit();
  }

  snapshot(): RuntimeSnapshot {
    return {
      startedAt: this.startedAt,
      renders: [...this.renders],
      network: [...this.network],
      errors: [...this.errors],
      longTasks: [...this.longTasks],
      mounts: [...this.mounts],
      domNodes: typeof document === "undefined" ? 0 : document.getElementsByTagName("*").length,
      route: typeof location === "undefined" ? "" : `${location.pathname}${location.search}`,
    };
  }

  findings(snapshot = this.snapshot()): DiagnosticFinding[] {
    const findings: DiagnosticFinding[] = [];

    const renderGroups = new Map<string, RenderSample[]>();
    for (const sample of snapshot.renders) {
      const group = renderGroups.get(sample.name) ?? [];
      group.push(sample);
      renderGroups.set(sample.name, group);
    }
    for (const [name, samples] of renderGroups) {
      const slow = samples.filter((sample) => sample.actualDurationMs >= 50);
      if (slow.length) {
        const worst = Math.max(...slow.map((sample) => sample.actualDurationMs));
        findings.push({
          severity: worst >= 150 ? "critical" : "warning",
          title: `${name} has expensive React commits`,
          detail: `${slow.length}/${samples.length} observed commits took at least 50ms.`,
          evidence: `worst ${worst.toFixed(1)}ms`,
        });
      }
    }

    const slowNetwork = snapshot.network.filter((sample) => sample.durationMs >= 1000);
    if (slowNetwork.length) {
      const worst = slowNetwork.reduce((a, b) => a.durationMs > b.durationMs ? a : b);
      findings.push({
        severity: worst.durationMs >= 3000 ? "critical" : "warning",
        title: "Slow network calls are blocking the experience",
        detail: `${slowNetwork.length} request(s) exceeded 1s.`,
        evidence: `${worst.method} ${shortUrl(worst.url)} ${worst.durationMs.toFixed(0)}ms`,
      });
    }

    const repeats = new Map<string, NetworkSample[]>();
    for (const sample of snapshot.network) {
      if (sample.method !== "GET" && sample.method !== "HEAD") continue;
      const key = `${sample.method} ${normalizeUrl(sample.url)}`;
      const group = repeats.get(key) ?? [];
      group.push(sample);
      repeats.set(key, group);
    }
    for (const [key, samples] of repeats) {
      if (samples.length >= 4) {
        const windowMs = samples[samples.length - 1].at - samples[0].at;
        if (windowMs <= 10000) {
          findings.push({
            severity: "warning",
            title: "Repeated request burst detected",
            detail: `${samples.length} equivalent requests occurred within ${(windowMs / 1000).toFixed(1)}s.`,
            evidence: key,
          });
        }
      }
    }

    if (snapshot.errors.length) {
      const latest = snapshot.errors[snapshot.errors.length - 1];
      findings.push({
        severity: "critical",
        title: "Browser runtime errors observed",
        detail: `${snapshot.errors.length} error/rejection event(s) captured. Errors are observed only; they are not swallowed or recovered by this tool.`,
        evidence: latest.message,
      });
    }

    const recentLongTasks = snapshot.longTasks.filter((task) => Date.now() - task.at <= 30000);
    if (recentLongTasks.length >= 3) {
      const total = recentLongTasks.reduce((sum, task) => sum + task.durationMs, 0);
      findings.push({
        severity: total >= 1000 ? "critical" : "warning",
        title: "Main thread is repeatedly blocked",
        detail: `${recentLongTasks.length} long tasks occurred in the last 30s.`,
        evidence: `${total.toFixed(0)}ms total long-task time`,
      });
    }

    const remounts = rapidRemountFindings(snapshot.mounts);
    findings.push(...remounts);

    if (snapshot.domNodes >= 5000) {
      findings.push({
        severity: snapshot.domNodes >= 10000 ? "critical" : "warning",
        title: "Large DOM detected",
        detail: "A large DOM can amplify layout, style and memory costs.",
        evidence: `${snapshot.domNodes.toLocaleString()} nodes`,
      });
    }

    return findings.sort((a, b) => rank(b.severity) - rank(a.severity));
  }
}

function rank(severity: DiagnosticFinding["severity"]) {
  return severity === "critical" ? 3 : severity === "warning" ? 2 : 1;
}

function normalizeUrl(url: string) {
  try {
    const parsed = new URL(url, typeof location === "undefined" ? "http://local" : location.href);
    parsed.searchParams.sort();
    return `${parsed.origin}${parsed.pathname}?${parsed.searchParams.toString()}`;
  } catch {
    return url;
  }
}

function shortUrl(url: string) {
  try {
    const parsed = new URL(url, typeof location === "undefined" ? "http://local" : location.href);
    return `${parsed.pathname}${parsed.search}`.slice(0, 110);
  } catch {
    return url.slice(0, 110);
  }
}

function rapidRemountFindings(mounts: MountSample[]): DiagnosticFinding[] {
  const byName = new Map<string, MountSample[]>();
  for (const sample of mounts) {
    const group = byName.get(sample.name) ?? [];
    group.push(sample);
    byName.set(sample.name, group);
  }

  const findings: DiagnosticFinding[] = [];
  for (const [name, samples] of byName) {
    if (samples.length < 8) continue;
    const recent = samples.filter((sample) => Date.now() - sample.at <= 5000);
    const unmounts = recent.filter((sample) => sample.action === "unmount").length;
    const mountsCount = recent.filter((sample) => sample.action === "mount").length;
    if (mountsCount >= 4 && unmounts >= 4) {
      findings.push({
        severity: "warning",
        title: `${name} is rapidly remounting`,
        detail: "This is rate-based evidence of mount/unmount churn, not a cumulative component-count heuristic.",
        evidence: `${mountsCount} mounts + ${unmounts} unmounts in 5s`,
      });
    }
  }
  return findings;
}

export const runtimeObservabilityStore = new RuntimeObservabilityStore();
