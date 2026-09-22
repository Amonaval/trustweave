import {SCALE_BUDGETS} from "../../core/scale/contracts";

export type WorkExecutionPlan={mode:"inline"|"external-required";itemCount:number;chunkSize:number;chunks:number};

export function planBackgroundWork(itemCount:number,inlineLimit=SCALE_BUDGETS.inlineBackgroundItems,chunkSize=SCALE_BUDGETS.backgroundChunkItems):WorkExecutionPlan{
 const count=Math.max(0,Math.floor(itemCount));
 const chunk=Math.max(1,Math.floor(chunkSize));
 return {mode:count<=inlineLimit?"inline":"external-required",itemCount:count,chunkSize:chunk,chunks:Math.ceil(count/chunk)};
}
