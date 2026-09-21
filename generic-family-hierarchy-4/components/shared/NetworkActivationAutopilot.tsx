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
  type ActivationSourceRef,
  type NetworkActivationCompilation,
} from "../../core/activation-autopilot/compiler";
import {
  applyActivationResolutions,
  type ActivationResolutionDecision,
} from "../../core/activation-autopilot/resolution";
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
  const [decisions,setDecisions] = useState<ActivationResolutionDecision[]>([]);
  const [busy,setBusy] = useState(false);
  const [message,setMessage] = useState("");
  const [activated,setActivated] = useState<ImportCommitResult | null>(null);

  const resolution = review&&candidate
    ? applyActivationResolutions(review,candidate,decisions)
    : null;

  const read = async (file: File) => {
    setBusy(true);
    setMessage("");
    setActivated(null);
    setDecisions([]);
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

  const decide = (decision: ActivationResolutionDecision) => {
    setDecisions(current=>[
      ...current.filter(item=>item.attentionId!==decision.attentionId),
      decision,
    ]);
    setActivated(null);
  };

  const activate = async () => {
    if (!resolution?.canActivate) return;
    setBusy(true);
    setMessage("");
    try {
      const result = await onCommit(resolution.review);
      setActivated(result);
      setMessage(result.message);
      await onCommitted?.(result);
    } catch (error: any) {
      setMessage(error?.message || "Network activation failed.");
    } finally {
      setBusy(false);
    }
  };

  const rowPreview = (source: ActivationSourceRef) => {
    const sheet = review?.sheets.find(item=>item.schema.key===source.sheetKey);
    const row = sheet?.rows.find(item=>item.rowNumber===source.rowNumber);
    if (!row) return `${source.sheetName} row ${source.rowNumber}`;
    const values = Object.entries(row.values)
      .filter(([,value])=>value!==""&&value!=null)
      .slice(0,5)
      .map(([key,value])=>`${key.replaceAll("_"," ")}: ${displayValue(value)}`)
      .join(" · ");
    return values || `${source.sheetName} row ${source.rowNumber}`;
  };

  const factsToPreview = candidate?.facts
    .filter((fact) => fact.status !== "rejected")
    .slice(0,12) || [];

  return <section data-testid="qa-network-activation-autopilot" className="card xp1-guided-import">
    <NetworkSectionHead
      kicker={<><Sparkles size={12}/> Network Activation Autopilot · V1</>}
      title="Bring the organization you already have"
      description="Upload existing Association records. TrustWeave compiles them into a candidate governed network, shows exactly what it understood, and asks only about ambiguity before anything becomes canonical."
    />

    <div className="product-import-card">
      <div>
        <FileSpreadsheet/>
        <span>
          <h3>Start with the existing Association workbook</h3>
          <p>People, households, representatives, annual membership and leadership history are analyzed before anything is written to the network.</p>
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
        <b>Trust boundary:</b> source claims are never silently upgraded into canonical truth. Ambiguous or conflicting records stop for an explicit human decision.
      </span>
    </div>

    {candidate&&resolution&&<div data-testid="qa-network-activation-candidate" className="xp1-review">
      <div className={`review-hero ${resolution.canActivate?"ready":"needs-help"}`}>
        {resolution.canActivate?<CheckCircle2/>:<AlertTriangle/>}
        <div>
          <h3>{resolution.canActivate?"Candidate network is ready to activate":"TrustWeave needs a few decisions before activation"}</h3>
          <p>
            {candidate.sourceFileName} · {candidate.summary.sourceRows} source rows · {candidate.summary.candidateFacts} candidate facts · {resolution.unresolvedAttentionIds.length} unresolved
          </p>
        </div>
      </div>

      <div className="network-metric-grid">
        <div className="network-metric"><b>{candidate.summary.entityRows}</b><span>People / family records</span><small>Candidate entities</small></div>
        <div className="network-metric"><b>{candidate.summary.relationshipRows}</b><span>Relationship rows</span><small>Household structure</small></div>
        <div className="network-metric"><b>{candidate.summary.domainRows}</b><span>Institutional rows</span><small>Membership + leadership</small></div>
        <div className="network-metric"><b>{candidate.summary.acceptedFacts}</b><span>Source-backed facts</span><small>Ready without interpretation</small></div>
        <div className="network-metric"><b>{resolution.unresolvedAttentionIds.length}</b><span>Human decisions left</span><small>{resolution.resolvedAttentionIds.length} resolved</small></div>
      </div>

      {candidate.attention.length>0&&<section className="card">
        <NetworkSectionHead
          kicker={<><AlertTriangle size={12}/> Ambiguity inbox</>}
          title="Review only what the machine should not decide"
          description="Confirm legitimate duplicates or choose the source row that should become canonical. Contradictory choices remain blocked."
        />
        <div className="friendly-issues">
          {candidate.attention.map((item)=>{
            const decision=decisions.find(value=>value.attentionId===item.id);
            const resolved=resolution.resolvedAttentionIds.includes(item.id);
            const conflicting=resolution.conflictingDecisionIds.includes(item.id);
            const rowChoices=[...new Map(item.sourceRefs.map(ref=>[`${ref.sheetKey}|${ref.rowNumber}`,ref])).values()];
            const duplicate=item.code==="POSSIBLE_DUPLICATE_EMAIL"||item.code==="POSSIBLE_DUPLICATE_NAME";
            return <div
              className={`issue-row ${item.severity==="blocking"||conflicting?"error":resolved?"":"warning"}`}
              data-testid={`qa-activation-attention-${item.code.toLowerCase()}`}
              key={item.id}
            >
              {resolved?<CheckCircle2/>:<AlertTriangle/>}
              <span>
                <b>{resolved?"Resolved · ":""}{item.title}</b>
                {item.description}
                {item.sourceRefs.length>0&&<small>
                  {" "}Source: {item.sourceRefs.slice(0,4).map(ref=>`${ref.sheetName} row ${ref.rowNumber}`).join(" · ")}
                </small>}
                {conflicting&&<small>Your linked decisions disagree. Choose the same canonical row for both items.</small>}
                {item.severity==="blocking"&&<small>Correct this source error and analyze the pack again.</small>}
                {item.severity==="review"&&duplicate&&<div className="card-actions">
                  <button
                    className={`btn small ${decision?.action==="keep_separate"?"primary":""}`}
                    disabled={busy}
                    onClick={()=>decide({attentionId:item.id,action:"keep_separate"})}
                  >
                    Confirm separate people
                  </button>
                  <small>If these are the same person, leave unresolved for now rather than merging uncertain identity automatically.</small>
                </div>}
                {item.severity==="review"&&!duplicate&&<div className="card-actions">
                  {rowChoices.map(ref=>{
                    const selected=decision?.action==="keep_source_row"&&decision.sheetKey===ref.sheetKey&&decision.rowNumber===ref.rowNumber;
                    return <button
                      className={`btn small ${selected?"primary":""}`}
                      disabled={busy}
                      key={`${ref.sheetKey}-${ref.rowNumber}`}
                      onClick={()=>decide({attentionId:item.id,action:"keep_source_row",sheetKey:ref.sheetKey,rowNumber:ref.rowNumber})}
                    >
                      Use row {ref.rowNumber}: {rowPreview(ref)}
                    </button>;
                  })}
                </div>}
              </span>
            </div>;
          })}
        </div>
      </section>}

      <section className="card">
        <NetworkSectionHead
          kicker={<><FileSearch size={12}/> Provenance preview</>}
          title="What TrustWeave believes it read"
          description="Every candidate fact keeps its source location. Resolution removes losing contradictory rows from the activation plan instead of rewriting history."
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
        <span>
          {candidate.trustStatement}
          {resolution.skippedSourceRows.length>0&&` ${resolution.skippedSourceRows.length} losing conflicting source row${resolution.skippedSourceRows.length===1?" is":"s are"} excluded from the activation plan.`}
        </span>
      </div>

      <div className="form-actions">
        <button className="btn" disabled={busy} onClick={()=>{setReview(null);setCandidate(null);setDecisions([]);setMessage("");setActivated(null)}}>Clear</button>
        <button
          data-testid="qa-network-activation-commit"
          className="btn primary"
          disabled={busy||!resolution.canActivate||!!activated}
          onClick={()=>void activate()}
        >
          {busy?"Activating…":activated?"Network activated":resolution.canActivate?"Activate governed network":"Resolve attention items first"}
        </button>
      </div>
    </div>}

    {activated&&<div data-testid="qa-network-activation-result" className="notice">
      <b>Activation complete.</b> {activated.message} The network can now be inspected through its normal Community, Directory and administration surfaces.
    </div>}
    {message&&!activated&&<div data-testid="qa-network-activation-message" className="notice">{message}</div>}
  </section>;
}
