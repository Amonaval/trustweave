import {runtimeObservabilityStore} from "./store";

type Cleanup = () => void;

let cleanup: Cleanup | null = null;

export function startBrowserObservation(): Cleanup {
  if (cleanup) return cleanup;
  const disposers: Cleanup[] = [];

  patchFetch(disposers);
  observeLongTasks(disposers);
  observeErrors(disposers);

  cleanup = () => {
    while (disposers.length) {
      try { disposers.pop()?.(); } catch {}
    }
    cleanup = null;
  };
  return cleanup;
}

function patchFetch(disposers: Cleanup[]) {
  if (typeof window === "undefined" || typeof window.fetch !== "function") return;
  const originalFetch = window.fetch;

  window.fetch = async function observedFetch(input: RequestInfo | URL, init?: RequestInit) {
    const method = String(init?.method ?? (input instanceof Request ? input.method : "GET")).toUpperCase();
    const url = input instanceof Request ? input.url : String(input);
    const started = performance.now();
    try {
      const response = await originalFetch.call(this, input, init);
      runtimeObservabilityStore.recordNetwork({
        method,
        url,
        status: response.status,
        ok: response.ok,
        durationMs: performance.now() - started,
        at: Date.now(),
      });
      return response;
    } catch (error) {
      runtimeObservabilityStore.recordNetwork({
        method,
        url,
        status: null,
        ok: false,
        durationMs: performance.now() - started,
        at: Date.now(),
        error: error instanceof Error ? error.message : String(error),
      });
      throw error;
    }
  };

  disposers.push(() => { window.fetch = originalFetch; });
}

function observeLongTasks(disposers: Cleanup[]) {
  if (typeof PerformanceObserver === "undefined") return;
  try {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        runtimeObservabilityStore.recordLongTask({durationMs: entry.duration, at: Date.now()});
      }
    });
    observer.observe({type: "longtask", buffered: true});
    disposers.push(() => observer.disconnect());
  } catch {}
}

function observeErrors(disposers: Cleanup[]) {
  if (typeof window === "undefined") return;

  const onError = (event: ErrorEvent) => runtimeObservabilityStore.recordError({
    kind: "error",
    message: event.message || "Unknown browser error",
    stack: event.error instanceof Error ? event.error.stack : undefined,
    at: Date.now(),
  });
  const onRejection = (event: PromiseRejectionEvent) => {
    const reason = event.reason;
    runtimeObservabilityStore.recordError({
      kind: "unhandledrejection",
      message: reason instanceof Error ? reason.message : String(reason),
      stack: reason instanceof Error ? reason.stack : undefined,
      at: Date.now(),
    });
  };

  window.addEventListener("error", onError);
  window.addEventListener("unhandledrejection", onRejection);
  disposers.push(() => window.removeEventListener("error", onError));
  disposers.push(() => window.removeEventListener("unhandledrejection", onRejection));
}
