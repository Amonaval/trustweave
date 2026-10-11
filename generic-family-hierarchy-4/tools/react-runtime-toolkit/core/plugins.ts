import type {FindingRule,NetworkDecoder,NetworkSample,RuntimeSnapshot} from './types';
const decoders:NetworkDecoder[]=[]; const rules:FindingRule[]=[];
export function registerNetworkDecoder(decoder:NetworkDecoder){decoders.push(decoder);return()=>{const i=decoders.indexOf(decoder);if(i>=0)decoders.splice(i,1)}}
export function decodeNetwork(sample:NetworkSample){for(const decoder of decoders){try{const value=decoder(sample);if(value!=null)return value}catch{}}return undefined}
export function registerFindingRule(rule:FindingRule){rules.push(rule);return()=>{const i=rules.indexOf(rule);if(i>=0)rules.splice(i,1)}}
export function runFindingRules(snapshot:RuntimeSnapshot,config:any){return rules.flatMap(rule=>{try{return rule(snapshot,config)||[]}catch{return[]}})}
