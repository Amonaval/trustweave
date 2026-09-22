"use client";

import {useMemo,useState} from "react";
import {AlertTriangle,FileSearch,ShieldCheck,UploadCloud} from "lucide-react";
import type {ImportReview,ImportSchema,ImportSheetSchema} from "../../core/import/contracts";
import {
  buildLeanMappedImportReview,
  createInitialLeanMappings,
  inspectLeanSourceWorkbook,
  sourceColumnsFor,
  suggestLeanSheetMapping,
  type LeanSheetMapping,
  type LeanSourceWorkbook,
} from "../../core/activation-autopilot/source-mapping";
import {NetworkSectionHead} from "./NetworkUi";

type Props={
  schema:ImportSchema;
  onReview:(review:ImportReview)=>void;
};

export default function LeanSourceMapping({schema,onReview}:Props){
  const [workbook,setWorkbook]=useState<LeanSourceWorkbook|null>(null);
  const [mappings,setMappings]=useState<LeanSheetMapping[]>([]);
  const [busy,setBusy]=useState(false);
  const [message,setMessage]=useState("");

  const mappingFor=(targetKey:string)=>mappings.find(item=>item.targetSheetKey===targetKey);

  const inspect=async(file:File)=>{
    setBusy(true);setMessage("");
    try{
      const next=inspectLeanSourceWorkbook(await file.arrayBuffer(),file.name);
      setWorkbook(next);
      setMappings(createInitialLeanMappings(next,schema));
    }catch(error:any){
      setWorkbook(null);setMappings([]);
      setMessage(error?.message||"TrustWeave could not inspect this file.");
    }finally{setBusy(false)}
  };

  const updateMapping=(targetKey:string,next:LeanSheetMapping)=>{
    setMappings(current=>[...current.filter(item=>item.targetSheetKey!==targetKey),next]);
  };

  const chooseSource=(target:ImportSheetSchema,sourceSheetName:string)=>{
    if(!workbook)return;
    if(!sourceSheetName){
      updateMapping(target.key,{
        targetSheetKey:target.key,
        sourceSheetName:"",
        headerRow:1,
        columns:Object.fromEntries(target.columns.map(column=>[column.key,null])),
      });
      return;
    }
    updateMapping(target.key,suggestLeanSheetMapping(workbook,target,sourceSheetName));
  };

  const chooseHeader=(target:ImportSheetSchema,headerRow:number)=>{
    if(!workbook)return;
    const current=mappingFor(target.key);
    if(!current?.sourceSheetName)return;
    updateMapping(target.key,suggestLeanSheetMapping(workbook,target,current.sourceSheetName,headerRow));
  };

  const chooseColumn=(target:ImportSheetSchema,columnKey:string,value:string)=>{
    const current=mappingFor(target.key);
    if(!current)return;
    updateMapping(target.key,{
      ...current,
      columns:{...current.columns,[columnKey]:value===""?null:Number(value)},
    });
  };

  const mappedTargets=mappings.filter(item=>item.sourceSheetName).length;
  const requiredTargetsMissing=schema.sheets.filter(target=>target.required&&!mappingFor(target.key)?.sourceSheetName);
  const requiredColumnsMissing=useMemo(()=>schema.sheets.flatMap(target=>{
    const mapping=mappingFor(target.key);
    if(!mapping?.sourceSheetName)return [];
    return target.columns.filter(column=>column.required&&mapping.columns[column.key]==null&&column.target!=="stableId")
      .map(column=>`${target.name} → ${column.label}`);
  }),[mappings,schema]);
  const previewIds=useMemo(()=>schema.sheets.flatMap(target=>{
    const mapping=mappingFor(target.key);
    if(!mapping?.sourceSheetName||target.recordType!=="entity")return [];
    return target.columns.filter(column=>column.target==="stableId"&&mapping.columns[column.key]==null)
      .map(column=>`${target.name} → ${column.label}`);
  }),[mappings,schema]);

  const build=()=>{
    if(!workbook)return;
    const review=buildLeanMappedImportReview(workbook,schema,mappings);
    onReview(review);
    setMessage(`Built a safe candidate from ${review.validRows+review.warningRows+review.rejectedRows} mapped source rows. Nothing was written to the network.`);
  };

  return <section data-testid="qa-naa-lean-source-mapping" className="card">
    <NetworkSectionHead
      kicker={<><FileSearch size={12}/> NAA-L1 · Lean source mapping</>}
      title="Use the Excel or CSV you already have"
      description="Tell TrustWeave what your columns mean. It applies confirmed mappings across the file and leaves anything uncertain unresolved instead of guessing."
    />

    <div className="product-import-card">
      <div>
        <UploadCloud/>
        <span>
          <h3>Bring an ordinary spreadsheet</h3>
          <p>No template migration first. Sheet/header detection is only a suggestion; you remain in control of meaning.</p>
        </span>
      </div>
      <label className="btn primary">
        <UploadCloud size={15}/> {busy?"Inspecting…":"Choose Excel / CSV"}
        <input
          data-testid="qa-naa-existing-file"
          hidden
          disabled={busy}
          type="file"
          accept=".xlsx,.xls,.csv"
          onChange={event=>event.target.files?.[0]&&void inspect(event.target.files[0])}
        />
      </label>
    </div>

    {workbook&&<div className="xp1-review">
      <div className="import-assurance">
        <ShieldCheck/>
        <span>
          <b>{workbook.fileName}</b> · {workbook.sheets.length} source sheet{workbook.sheets.length===1?"":"s"}.
          Map only what you understand. Unmapped source columns are ignored; missing required target data remains visible.
        </span>
      </div>

      {schema.sheets.map(target=>{
        const mapping=mappingFor(target.key);
        const source=mapping?.sourceSheetName?workbook.sheets.find(sheet=>sheet.name===mapping.sourceSheetName):undefined;
        const columns=source&&mapping?sourceColumnsFor(workbook,source.name,mapping.headerRow):[];
        return <section className="card" key={target.key} data-testid={`qa-naa-target-${target.key}`}>
          <NetworkSectionHead
            kicker={target.required?"Required target":"Optional target"}
            title={target.name}
            description={target.description}
          />
          <div className="form-grid">
            <label>
              Source sheet
              <select
                value={mapping?.sourceSheetName||""}
                onChange={event=>chooseSource(target,event.target.value)}
              >
                <option value="">Not mapped</option>
                {workbook.sheets.map(sheet=><option value={sheet.name} key={sheet.name}>
                  {sheet.name} · {sheet.rowCount} rows
                </option>)}
              </select>
            </label>
            {source&&mapping&&<label>
              Header row
              <select
                value={mapping.headerRow}
                onChange={event=>chooseHeader(target,Number(event.target.value))}
              >
                {Array.from({length:Math.min(30,Math.max(source.rowCount,1))},(_,index)=>index+1).map(row=>
                  <option value={row} key={row}>{row}{row===source.suggestedHeaderRow?" · suggested":""}</option>
                )}
              </select>
            </label>}
          </div>

          {source&&mapping&&<div className="table-wrap">
            <table>
              <thead><tr><th>TrustWeave field</th><th>Need</th><th>Your source column</th></tr></thead>
              <tbody>
                {target.columns.map(column=><tr key={column.key}>
                  <td>
                    <b>{column.label}</b>
                    <small>{column.description}</small>
                  </td>
                  <td>{column.required?"Required":"Optional"}</td>
                  <td>
                    <select
                      value={mapping.columns[column.key]??""}
                      onChange={event=>chooseColumn(target,column.key,event.target.value)}
                    >
                      <option value="">
                        {column.target==="stableId"&&target.recordType==="entity"
                          ?"Not mapped · generate preview ID only"
                          :"Not mapped"}
                      </option>
                      {columns.map(sourceColumn=><option value={sourceColumn.index} key={sourceColumn.index}>
                        {sourceColumn.label}{sourceColumn.sample?` · e.g. ${sourceColumn.sample}`:""}
                      </option>)}
                    </select>
                  </td>
                </tr>)}
              </tbody>
            </table>
          </div>}
        </section>;
      })}

      <div className="network-metric-grid">
        <div className="network-metric"><b>{mappedTargets}</b><span>Target sections mapped</span><small>{schema.sheets.length} available</small></div>
        <div className="network-metric"><b>{requiredTargetsMissing.length}</b><span>Required sections missing</span><small>Can still preview partial data</small></div>
        <div className="network-metric"><b>{requiredColumnsMissing.length}</b><span>Required fields unmapped</span><small>Remain blockers</small></div>
        <div className="network-metric"><b>{previewIds.length}</b><span>Preview IDs generated</span><small>Map stable IDs before activation</small></div>
      </div>

      {(requiredTargetsMissing.length>0||requiredColumnsMissing.length>0||previewIds.length>0)&&<div className="friendly-issues">
        {requiredTargetsMissing.map(target=><div className="issue-row warning" key={`sheet-${target.key}`}>
          <AlertTriangle/><span><b>Required target not mapped</b>{target.name}</span>
        </div>)}
        {requiredColumnsMissing.slice(0,8).map(label=><div className="issue-row warning" key={label}>
          <AlertTriangle/><span><b>Required field not mapped</b>{label}</span>
        </div>)}
        {previewIds.map(label=><div className="issue-row warning" key={`id-${label}`}>
          <AlertTriangle/><span><b>Preview-only identity</b>{label}. TrustWeave can preview rows, but activation stays blocked until you map a stable identifier.</span>
        </div>)}
      </div>}

      <div className="form-actions">
        <button
          data-testid="qa-naa-build-candidate"
          className="btn primary"
          disabled={busy||mappedTargets===0}
          onClick={build}
        >
          Build safe candidate
        </button>
      </div>
    </div>}

    {message&&<div className="notice">{message}</div>}
  </section>;
}
