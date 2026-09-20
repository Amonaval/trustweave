import type {QaVerticalKind} from './qa/runtime/catalog.mjs';
export const QA_VERTICALS:readonly QaVerticalKind[];
export const QA_ROLES:readonly ('owner'|'admin'|'member')[];
export const QA_CRAWL:Readonly<{
 actionsPerShard:number;
 shardBudgetMs:number;
 shardTimeoutMs:number;
 cleanRetries:number;
 headed:boolean;
}>;
declare const config:Readonly<{verticals:typeof QA_VERTICALS;roles:typeof QA_ROLES;crawl:typeof QA_CRAWL}>;
export default config;
