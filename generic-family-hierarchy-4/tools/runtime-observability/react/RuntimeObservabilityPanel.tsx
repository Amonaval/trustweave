"use client";

import {useEffect, useMemo, useState, type CSSProperties} from "react";
import {runtimeObservabilityStore} from "../store";
import type {RuntimeSnapshot} from "../types";

const initial = (): RuntimeSnapshot => runtimeObservabilityStore.snapshot();

export default function RuntimeObservabilityPanel() {
  const [snapshot, setSnapshot] = useState<RuntimeSnapshot>(initial);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const refresh = () => setSnapshot(runtimeObservabilityStore.snapshot());
    const unsubscribe = runtimeObservabilityStore.subscribe(refresh);
    const timer = window.setInterval(refresh, 1000);
    return () => { unsubscribe(); window.clearInterval(timer); };
  }, []);

  const findings = useMemo(() => runtimeObservabilityStore.findings(snapshot), [snapshot]);
  const worstRender = [...snapshot.renders].sort((a,b) => b.actualDurationMs - a.actualDurationMs)[0];
  const slowRequests = snapshot.network.filter((item) => item.durationMs >= 1000).length;
  const critical = findings.filter((item) => item.severity === "critical").length;
  const warning = findings.filter((item) => item.severity === "warning").length;

  if (!open) {
    return (
      <button onClick={() => setOpen(true)} style={styles.badge} aria-label="Open runtime observability">
        TW Runtime {critical ? `• ${critical} critical` : warning ? `• ${warning} warning` : "• healthy"}
      </button>
    );
  }

  return (
    <aside style={styles.panel} aria-label="TrustWeave runtime observability panel">
      <div style={styles.header}>
        <div><strong>TrustWeave Runtime</strong><div style={styles.sub}>Local browser diagnostics • no telemetry upload</div></div>
        <button onClick={() => setOpen(false)} style={styles.close}>×</button>
      </div>

      <div style={styles.grid}>
        <Metric label="React commits" value={String(snapshot.renders.length)} />
        <Metric label="Worst commit" value={worstRender ? `${worstRender.actualDurationMs.toFixed(1)}ms` : "—"} />
        <Metric label="Requests" value={String(snapshot.network.length)} />
        <Metric label="Slow >1s" value={String(slowRequests)} />
        <Metric label="Long tasks" value={String(snapshot.longTasks.length)} />
        <Metric label="DOM nodes" value={snapshot.domNodes.toLocaleString()} />
      </div>

      <section style={styles.section}>
        <div style={styles.sectionTitle}>Pinpoint</div>
        {findings.length === 0 ? <div style={styles.good}>No high-confidence concern detected yet.</div> : findings.slice(0, 8).map((finding, index) => (
          <div key={`${finding.title}-${index}`} style={styles.finding}>
            <div><strong>{finding.severity.toUpperCase()}</strong> · {finding.title}</div>
            <div style={styles.sub}>{finding.detail}</div>
            <code style={styles.code}>{finding.evidence}</code>
          </div>
        ))}
      </section>

      <section style={styles.section}>
        <div style={styles.sectionTitle}>Recent network</div>
        {snapshot.network.slice(-8).reverse().map((item, index) => (
          <div key={`${item.at}-${index}`} style={styles.row}>
            <span>{item.method}</span><span style={styles.flex}>{shortUrl(item.url)}</span><strong>{item.durationMs.toFixed(0)}ms</strong>
          </div>
        ))}
      </section>

      <div style={styles.footer}>
        <button style={styles.action} onClick={() => runtimeObservabilityStore.reset()}>Reset session</button>
        <button style={styles.action} onClick={() => {
          const payload = JSON.stringify({...runtimeObservabilityStore.snapshot(), findings: runtimeObservabilityStore.findings()}, null, 2);
          navigator.clipboard?.writeText(payload).catch(() => {});
        }}>Copy report</button>
      </div>
    </aside>
  );
}

function Metric({label, value}: {label: string; value: string}) {
  return <div style={styles.metric}><div style={styles.sub}>{label}</div><strong>{value}</strong></div>;
}

function shortUrl(value: string) {
  try { const url = new URL(value, location.href); return `${url.pathname}${url.search}`.slice(0, 80); }
  catch { return value.slice(0, 80); }
}

const styles: Record<string, CSSProperties> = {
  badge: {position:"fixed",right:12,bottom:12,zIndex:2147483646,border:"1px solid #7c8cff",borderRadius:999,padding:"8px 12px",background:"#111827",color:"#fff",font:"12px system-ui",boxShadow:"0 8px 24px rgba(0,0,0,.25)",cursor:"pointer"},
  panel: {position:"fixed",right:12,bottom:12,zIndex:2147483646,width:"min(520px,calc(100vw - 24px))",maxHeight:"78vh",overflow:"auto",background:"#0b1020",color:"#e5e7eb",border:"1px solid #34405f",borderRadius:12,boxShadow:"0 18px 60px rgba(0,0,0,.45)",font:"12px system-ui"},
  header: {display:"flex",justifyContent:"space-between",gap:12,padding:12,borderBottom:"1px solid #27324b",position:"sticky",top:0,background:"#0b1020"},
  close: {border:0,background:"transparent",color:"#fff",fontSize:22,cursor:"pointer"},
  sub: {opacity:.68,fontSize:11,marginTop:2},
  grid: {display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:8,padding:12},
  metric: {background:"#121a30",border:"1px solid #27324b",borderRadius:8,padding:9},
  section: {padding:"0 12px 12px"},
  sectionTitle: {fontWeight:700,margin:"4px 0 8px"},
  finding: {borderLeft:"3px solid #f59e0b",background:"#121a30",padding:8,marginBottom:7,borderRadius:6},
  good: {background:"#10251d",border:"1px solid #20543f",padding:9,borderRadius:7},
  code: {display:"block",marginTop:5,whiteSpace:"pre-wrap",overflowWrap:"anywhere",opacity:.85},
  row: {display:"flex",gap:8,alignItems:"center",padding:"5px 0",borderBottom:"1px solid #1e2940"},
  flex: {flex:1,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"},
  footer: {display:"flex",gap:8,padding:12,borderTop:"1px solid #27324b",position:"sticky",bottom:0,background:"#0b1020"},
  action: {border:"1px solid #3b4b70",borderRadius:7,padding:"6px 9px",background:"#121a30",color:"#fff",cursor:"pointer"},
};
