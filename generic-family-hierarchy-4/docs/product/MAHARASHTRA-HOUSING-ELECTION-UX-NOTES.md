# Maharashtra Housing Society Election UX Notes

**Checked:** 2026-09-22  
**Purpose:** Product/UX implementation note, not legal advice.

## Product decision

TrustWeave must distinguish:

1. **Statutory managing-committee election** for a Maharashtra co-operative housing society.
2. **Ordinary member poll / preference vote** inside the society.

The generic TrustWeave online ballot must **not** be presented as a legally sufficient substitute for a statutory committee election unless a future compliance review establishes that for the exact society/category and election method.

For Type E housing societies (up to 250 members as of 31 March of the preceding year), the 2021 amendment to the Maharashtra Co-operative Societies (Election to Committee) Rules creates a dedicated process under Rules 76-A onward.

## Type E process reflected in the UX

- appoint an eligible Returning Officer before the existing committee tenure expires;
- prepare/publish a provisional voter list;
- accept and decide claims/objections and publish the final voter list;
- declare the election programme;
- receive nominations;
- scrutinize nominations;
- allow withdrawal and publish final contesting candidates/symbols;
- declare candidates elected unopposed where candidates do not exceed seats, otherwise conduct the poll;
- count votes and declare results;
- complete committee constitution / office-bearer process separately.

TrustWeave's current housing election surface is therefore an **organize / record / communicate** surface. Ordinary member polls may continue to use in-app voting. A statutory housing committee election shows candidates and process status, but the product does not claim the in-app selection is the official poll.

## Why the old UI was confusing

The shared component used the software term **ballot** for both elections and polls, exposed a generic draft/open/closed/published lifecycle, and silently disabled choices when the current account was not eligible or when the configured voting window had expired.

The field-feedback fix:

- uses “Committee election” and “Member poll” in Housing;
- explains what ballot means instead of requiring the user to know the term;
- shows the Maharashtra process in order;
- explains why a vote is unavailable;
- uses native radio/checkbox controls for ordinary in-app voting;
- prevents the Housing statutory-election record from masquerading as an online statutory vote.

## Authoritative sources reviewed

- Maharashtra Co-operative Societies Act, 1960, section 73CB, current English edition published by the Maharashtra Co-operation Department.
- Maharashtra Co-operative Societies (Election to Committee) Rules, 2014.
- Maharashtra Government Gazette notification dated 6 April 2021 adding Part X-1A / Rules 76-A onward for Type E housing societies.
- Maharashtra Commissioner for Co-operation / Registrar process page for managing-committee elections.

Re-check the current Act, Rules, society bye-laws, SCEA directions and Registrar/Returning-Officer requirements before representing any future workflow as legally compliant.
