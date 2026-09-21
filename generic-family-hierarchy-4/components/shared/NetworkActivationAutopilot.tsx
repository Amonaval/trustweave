"use client";

import {useState} from "react";
import {
  AlertTriangle,
  CheckCircle2,
  Download,
  FileSearch,
  FileSpreadsheet,
  ShieldCheck,
  Sparkles,
  UploadCloud,
} from "lucide-react";
import {getImportSchema} from "../../core/import/registry";
import {downloadImportWorkbook} from "../../core/import/workbook";
import {parseImportWorkbook} from "../../core/import/parser";
import type {ImportCommitResult,ImportReview} from "../../core/import/contracts";
import {
  compileNetworkActivationCandidate,
  type NetworkActivationCompilation,
} from "../../core/activation-autopilot/compiler";
import {NetworkSectionHead} from "./NetworkUi";

type Props = {
  onCommit: (review: ImportReview) => Promise<ImportCommitResult>;
  onCommitted?: (result: ImportCommitResult) => Promise<void> | void;
};

const displayValue = (value: unknown) => {
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
};

export default function NetworkActivationAutopilot({onCommit,onCommitted}: Props) {
  const schema = getImportSchema("family-association");
  const [review,setReview] = useState<ImportReview | null>(null);
  const [candidate,setCandidate] = useState<NetworkActivationCompilation | null>(null);
  const [busy,setBusy] = useState(false);
  const [message,setMessage] = useState("");
  const [activated,setActivated] = useState<ImportCommitResult | null>(null);

  const read = async (file: File) => {
    setBusy(true);
    setMessage("");
    setActivated(null);
    try {
      const parsed = await parseImportWorkbook(await file.arrayBuffer(),file.name,schema);
      const compiled = compileNetworkActivationCandidate(parsed);
      setReview(parsed);
      setCandidate(compiled);
    } catch (error: any) {
      setReview(null);
      setCandidate(null);
      setMessage(error?.message || "TrustWeave could not read this activation pack.");
    } finally {
      setBusy(false);
    }
  };

  const activate = async () => {
    if (!review || !candidate?.canActivate) return;
    setBusy(true);
    setMessage("");
    try {
      const result = await onCommit(review);
      setActivated(result);
      setMessage(result.message);
      await onCommitted?.(result);
    } catch (error: any) {
      setMessage(error?.message || "Network activation failed.");
    } finally {
      setBusy(false);
    }
  };

  const factsToPreview = candidate?.facts
    .filter((fact) => fact.status !== "rejected")
    .slice(0,12) || [];

  return <section data-testid="qa-network-activation-autopilot" className="card xp1-guided-import">
    <NetworkSectionHead
      kicker={<><Sparkles size={12}/> Network Activation Autopilot · V1</>}
      title="Bring the organization you already have"
      description="Upload existing Association records. TrustWeave compiles them into a candidate governed network, shows exactly what it understood, and stops for human judgment when records conflict."
    />

    <div className="product-import-card">
      <div>
        <FileSpreadsheet/>
        <span>
          <h3>Start with the existing Association workbook</h3>
          <p>People, households, relationships and annual membership history are analyzed before anything is written to the network.</p>
        </span>
      </div>
      <button
        data-testid="qa-activation-pack-download"
        className="btn"
        onClick={()=>downloadImportWorkbook(schema)}
      >
        <Download size={15}/> Download activation workbook
      </button>
      <label className="btn primary">
        <UploadCloud size={15}/> {busy?"Understanding records…":"Analyze existing records"}
        <input
          data-testid="qa-activation-pack-file"
          hidden
          disabled={busy}
          type="file"
          accept=".xlsx,.xls,.csv"
          onChange={event=>event.target.files?.[0]&&void read(event.target.files[0])}
        />
      </label>
    </div>

    <div className="import-assurance">
      <ShieldCheck/>
      <span>
        <b>Trust boundary:</b> source claims are never silently upgraded into canonical truth. Ambiguous or conflicting records block activation until they are resolved.
      </span>
    </div>

    {candidate&&<div data-testid="qa-network-activation-candidate" className="xp1-review">
      <div className={`review-hero ${candidate.canActivate?"ready":"needs-help"}`}>
        {candidate.canActivate?<CheckCircle2/>:<AlertTriangle/>}
        <div>
          <h3>{candidate.canActivate?"Candidate network is ready to activate":"TrustWeave needs your help before activation"}</h3>
          <p>
            {candidate.sourceFileName} · {candidate.summary.sourceRows} source rows · {candidate.summary.candidateFacts} candidate facts · {candidate.summary.attentionItems} attention items
          </p>
        </div>
      </div>

      <div className="network-metric-grid">
        <div className="network-metric"><b>{candidate.summary.entityRows}</b><span>People / family records</span><small>Candidate entities</small></div>
        <div className="network-metric"><b>{candidate.summary.relationshipRows}</b><span>Relationship rows</span><small>Household structure</small></div>
        <div className="network-metric"><b>{candidate.summary.domainRows}</b><span>Institutional rows</span><small>Membership history</small></div>
        <div className="network-metric"><b>{candidate.summary.acceptedFacts}</b><span>Source-backed facts</span><small>Ready without interpretation</small></div>
        <div className="network-metric"><b>{candidate.summary.reviewItems}</b><span>Human decisions</span><small>Never auto-resolved</small></div>
      </div>

      {candidate.attention.length>0&&<section className="card">
        <NetworkSectionHead
          kicker={<><AlertTriangle size={12}/> Needs attention</>}
          title={`${candidate.attention.length} item${candidate.attention.length===1?"":"s"} need review`}
          description="V1 fails closed: TrustWeave shows contradictions and possible duplicates instead of guessing."
        />
        <div className="friendly-issues">
          {candidate.attention.map((item)=><div className={`issue-row ${item.severity==="blocking"?"error":"warning"}`} key={item.id}>
            <AlertTriangle/>
            <span>
              <b>{item.title}</b>
              {item.description}
              {item.sourceRefs.length>0&&<small>
                {" "}Source: {item.sourceRefs.slice(0,3).map(ref=>`${ref.sheetName} row ${ref.rowNumber}`).join(" · ")}
              </small>}
            </span>
          </div>)}
        </div>
      </section>}

      <section className="card">
        <NetworkSectionHead
          kicker={<><FileSearch size={12}/> Provenance preview</>}
          title="What TrustWeave believes it read"
          description="Every candidate fact keeps its source location so later intelligence can explain where institutional truth came from."
        />
        <div className="table-wrap">
          <table>
            <thead><tr><th>Subject</th><th>Fact</th><th>Value</th><th>Source</th></tr></thead>
            <tbody>
              {factsToPreview.map((fact)=><tr key={fact.id}>
                <td>{fact.subjectLabel}</td>
                <td>{fact.predicate.replaceAll("_"," ")}</td>
                <td>{displayValue(fact.value)}</td>
                <td>{fact.source.sheetName} · row {fact.source.rowNumber}{fact.source.columnLabel?` · ${fact.source.columnLabel}`:""}</td>
              </tr>)}
            </tbody>
          </table>
        </div>
      </section>

      <div className="import-assurance">
        <ShieldCheck/>
        <span>{candidate.trustStatement}</span>
      </div>

      <div className="form-actions">
        <button className="btn" disabled={busy} onClick={()=>{setReview(null);setCandidate(null);setMessage("");setActivated(null)}}>Clear</button>
        <button
          data-testid="qa-network-activation-commit"
          className="btn primary"
          disabled={busy||!candidate.canActivate||!!activated}
          onClick={()=>void activate()}
        >
          {busy?"Activating…":activated?"Network activated":"Activate governed network"}
        </button>
      </div>
    </div>}

    {activated&&<div data-testid="qa-network-activation-result" className="notice">
      <b>Activation complete.</b> {activated.message} The network can now be inspected through its normal Community, Directory and administration surfaces.
    </div>}
    {message&&!activated&&<div data-testid="qa-network-activation-message" className="notice">{message}</div>}
  </section>;
}
