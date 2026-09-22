import {SCALE_BUDGETS} from "../scale/contracts";

export type GraphWalkBudget={maxDepth?:number;maxVisitedNodes?:number;maxExaminedEdges?:number};
export type GraphWalkResult={nodeIds:string[];depthReached:number;examinedEdges:number;truncated:boolean};

export function boundedGraphWalk(edges:readonly {fromEntityId:string;toEntityId:string}[],startEntityId:string,budget:GraphWalkBudget={}):GraphWalkResult{
 const maxDepth=Math.max(0,Math.min(SCALE_BUDGETS.graphMaxDepth,Math.floor(budget.maxDepth??SCALE_BUDGETS.graphMaxDepth)));
 const maxVisited=Math.max(1,Math.min(SCALE_BUDGETS.graphMaxVisitedNodes,Math.floor(budget.maxVisitedNodes??SCALE_BUDGETS.graphMaxVisitedNodes)));
 const maxEdges=Math.max(1,Math.min(SCALE_BUDGETS.graphMaxExaminedEdges,Math.floor(budget.maxExaminedEdges??SCALE_BUDGETS.graphMaxExaminedEdges)));
 const adjacency=new Map<string,string[]>();let examinedEdges=0;let truncated=false;
 for(const edge of edges){
  if(examinedEdges>=maxEdges){truncated=true;break}
  examinedEdges++;
  const a=adjacency.get(edge.fromEntityId)||[];a.push(edge.toEntityId);adjacency.set(edge.fromEntityId,a);
  const b=adjacency.get(edge.toEntityId)||[];b.push(edge.fromEntityId);adjacency.set(edge.toEntityId,b);
 }
 const visited=new Set<string>([startEntityId]);let frontier=[startEntityId];let depth=0;
 while(frontier.length&&depth<maxDepth&&visited.size<maxVisited){
  const next:string[]=[];
  for(const node of frontier){
   for(const neighbor of adjacency.get(node)||[]){
    if(visited.has(neighbor))continue;
    if(visited.size>=maxVisited){truncated=true;break}
    visited.add(neighbor);next.push(neighbor);
   }
   if(visited.size>=maxVisited)break;
  }
  if(!next.length)break;
  frontier=next;depth++;
 }
 if(frontier.length&&depth>=maxDepth)truncated=true;
 return {nodeIds:[...visited],depthReached:depth,examinedEdges,truncated};
}
