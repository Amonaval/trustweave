// TrustWeave QA control plane.
// Change this one file to expand or narrow connected product testing.
export const QA_VERTICALS=Object.freeze([
 'housing-society',
 'family-association'
]);

export const QA_ROLES=Object.freeze(['owner','admin','member']);

export const QA_CRAWL=Object.freeze({
 actionsPerShard:24,
 shardBudgetMs:120_000,
 shardTimeoutMs:180_000,
 cleanRetries:1,
 headed:true
});

export default Object.freeze({verticals:QA_VERTICALS,roles:QA_ROLES,crawl:QA_CRAWL});
