import type {
  ImportColumnSchema,
  ImportReview,
  ParsedImportRow,
  ParsedImportSheet,
} from "../import/contracts";

export type ActivationFactCertainty = "exact" | "derived" | "ai_extracted" | "inferred";
export type ActivationFactStatus = "accepted" | "needs_review" | "rejected";
export type ActivationAttentionSeverity = "blocking" | "review" | "info";

export type ActivationSourceRef = {
  fileName: string;
  schemaVersion: string;
  sheetKey: string;
  sheetName: string;
  rowNumber: number;
  columnKey?: string;
  columnLabel?: string;
};

export type ActivationCandidateFact = {
  id: string;
  subjectKey: string;
  subjectLabel: string;
  subjectKind: string;
  predicate: string;
  value: unknown;
  certainty: ActivationFactCertainty;
  confidence: number;
  status: ActivationFactStatus;
  source: ActivationSourceRef;
};

export type ActivationAttentionItem = {
  id: string;
  code:
    | "IMPORT_BLOCKER"
    | "POSSIBLE_DUPLICATE_EMAIL"
    | "POSSIBLE_DUPLICATE_PHONE"
    | "POSSIBLE_DUPLICATE_NAME"
    | "MULTIPLE_HOUSEHOLD_CANDIDATES"
    | "MEMBERSHIP_STATUS_CONFLICT"
    | "MEMBERSHIP_PAYMENT_CONFLICT"
    | "REPRESENTATIVE_CONFLICT"
    | "LEADERSHIP_ROLE_CONFLICT";
  severity: ActivationAttentionSeverity;
  title: string;
  description: string;
  subjectKeys: string[];
  sourceRefs: ActivationSourceRef[];
};

export type ActivationPlanSummary = {
  sourceRows: number;
  entityRows: number;
  relationshipRows: number;
  domainRows: number;
  candidateFacts: number;
  acceptedFacts: number;
  reviewFacts: number;
  rejectedFacts: number;
  attentionItems: number;
  blockingItems: number;
  reviewItems: number;
};

export type NetworkActivationCompilation = {
  version: "network-activation-candidate.v1";
  verticalKind: string;
  sourceFileName: string;
  schemaVersion: string;
  facts: ActivationCandidateFact[];
  attention: ActivationAttentionItem[];
  summary: ActivationPlanSummary;
  canActivate: boolean;
  trustStatement: string;
};

const clean = (value: unknown) => String(value ?? "").trim();
const normalized = (value: unknown) =>
  clean(value)
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();

const compact = (value: unknown) => normalized(value).replace(/\s+/g, "");

function sourceFor(
  review: ImportReview,
  sheet: ParsedImportSheet,
  row: ParsedImportRow,
  column?: ImportColumnSchema,
): ActivationSourceRef {
  return {
    fileName: review.fileName,
    schemaVersion: review.schema.version,
    sheetKey: sheet.schema.key,
    sheetName: sheet.schema.name,
    rowNumber: row.rowNumber,
    columnKey: column?.key,
    columnLabel: column?.label,
  };
}

function stableIdForRow(sheet: ParsedImportSheet, row: ParsedImportRow) {
  const column = sheet.schema.columns.find((item) => item.target === "stableId");
  return column ? clean(row.values[column.key]) : "";
}

function labelForRow(sheet: ParsedImportSheet, row: ParsedImportRow) {
  const column = sheet.schema.columns.find((item) => item.target === "label");
  return column ? clean(row.values[column.key]) : "";
}

function subjectForRow(sheet: ParsedImportSheet, row: ParsedImportRow) {
  const stableId = stableIdForRow(sheet, row);
  const label = labelForRow(sheet, row);

  if (sheet.schema.recordType === "entity") {
    return {
      key: stableId
        ? `${sheet.schema.entityKind || "entity"}:${stableId.toLowerCase()}`
        : `${sheet.schema.key}:row:${row.rowNumber}`,
      label: label || stableId || `${sheet.schema.name} row ${row.rowNumber}`,
      kind: sheet.schema.entityKind || "entity",
    };
  }

  if (sheet.schema.recordType === "relationship") {
    const from = clean(row.values.from_id || row.values.fromRef);
    const to = clean(row.values.to_id || row.values.toRef);
    return {
      key: `${sheet.schema.key}:${from.toLowerCase()}:${to.toLowerCase()}:${row.rowNumber}`,
      label: `${from || "?"} → ${to || "?"}`,
      kind: "relationship",
    };
  }

  const familyRef = clean(row.values.family_id);
  const period = clean(row.values.membership_year);
  return {
    key: familyRef || period
      ? `${sheet.schema.key}:${familyRef.toLowerCase()}:${period.toLowerCase()}:${row.rowNumber}`
      : `${sheet.schema.key}:row:${row.rowNumber}`,
    label: [familyRef, period].filter(Boolean).join(" · ") || `${sheet.schema.name} row ${row.rowNumber}`,
    kind: "domain",
  };
}

function buildFacts(review: ImportReview) {
  const facts: ActivationCandidateFact[] = [];

  for (const sheet of review.sheets) {
    for (const row of sheet.rows) {
      const subject = subjectForRow(sheet, row);
      for (const column of sheet.schema.columns) {
        const value = row.values[column.key];
        if (value === "" || value == null) continue;

        const rejected = row.status === "rejected";
        facts.push({
          id: `${sheet.schema.key}:${row.rowNumber}:${column.key}`,
          subjectKey: subject.key,
          subjectLabel: subject.label,
          subjectKind: subject.kind,
          predicate: column.key,
          value,
          certainty: "exact",
          confidence: rejected ? 0 : 1,
          status: rejected ? "rejected" : "accepted",
          source: sourceFor(review, sheet, row, column),
        });
      }
    }
  }

  return facts;
}

function importBlockers(review: ImportReview): ActivationAttentionItem[] {
  return review.issues
    .filter((issue) => issue.severity === "error")
    .map((issue, index) => {
      const matchingSheet = review.sheets.find(
        (sheet) => sheet.schema.name === issue.sheet || sheet.schema.key === issue.sheet,
      );
      const matchingRow = issue.row
        ? matchingSheet?.rows.find((row) => row.rowNumber === issue.row)
        : undefined;
      const column = matchingSheet?.schema.columns.find(
        (item) => item.label === issue.column || item.key === issue.column,
      );

      return {
        id: `import-blocker:${index}`,
        code: "IMPORT_BLOCKER" as const,
        severity: "blocking" as const,
        title: "Source data needs correction",
        description: issue.message,
        subjectKeys: matchingSheet && matchingRow
          ? [subjectForRow(matchingSheet, matchingRow).key]
          : [],
        sourceRefs: matchingSheet && matchingRow
          ? [sourceFor(review, matchingSheet, matchingRow, column)]
          : [],
      };
    });
}

type PersonCandidate = {
  subjectKey: string;
  label: string;
  email: string;
  phone: string;
  nameKey: string;
  emailKey: string;
  phoneKey: string;
  source: ActivationSourceRef;
};

function personCandidates(review: ImportReview): PersonCandidate[] {
  const candidates: PersonCandidate[] = [];
  for (const sheet of review.sheets.filter(
    (item) => item.schema.recordType === "entity" && item.schema.entityKind === "person",
  )) {
    const emailColumn = sheet.schema.columns.find((column) => column.key === "email");
    const phoneColumn = sheet.schema.columns.find((column) => column.key === "phone");
    for (const row of sheet.rows.filter((item) => item.status !== "rejected")) {
      const subject = subjectForRow(sheet, row);
      const label = labelForRow(sheet, row);
      const email = emailColumn ? clean(row.values[emailColumn.key]) : "";
      const phone = phoneColumn ? clean(row.values[phoneColumn.key]) : "";
      candidates.push({
        subjectKey: subject.key,
        label,
        email,
        phone,
        nameKey: normalized(label),
        emailKey: compact(email),
        phoneKey: phone.replace(/\D+/g,"").replace(/^91(?=\d{10}$)/,""),
        source: sourceFor(review, sheet, row),
      });
    }
  }
  return candidates;
}

function duplicateAttention(review: ImportReview): ActivationAttentionItem[] {
  const people = personCandidates(review);
  const attention: ActivationAttentionItem[] = [];

  const addGrouped = (
    code: "POSSIBLE_DUPLICATE_EMAIL" | "POSSIBLE_DUPLICATE_PHONE" | "POSSIBLE_DUPLICATE_NAME",
    keyOf: (candidate: PersonCandidate) => string,
    title: string,
    description: (items: PersonCandidate[]) => string,
  ) => {
    const groups = new Map<string, PersonCandidate[]>();
    for (const person of people) {
      const key = keyOf(person);
      if (!key) continue;
      const group = groups.get(key) || [];
      group.push(person);
      groups.set(key, group);
    }

    for (const [key, items] of groups) {
      const uniqueSubjects = [...new Set(items.map((item) => item.subjectKey))];
      if (uniqueSubjects.length < 2) continue;
      attention.push({
        id: `${code.toLowerCase()}:${key}`,
        code,
        severity: "review",
        title,
        description: description(items),
        subjectKeys: uniqueSubjects,
        sourceRefs: items.map((item) => item.source),
      });
    }
  };

  addGrouped(
    "POSSIBLE_DUPLICATE_EMAIL",
    (candidate) => candidate.emailKey,
    "Possible duplicate person",
    (items) =>
      `${items.map((item) => item.label || item.subjectKey).join(" / ")} share the same email address. Confirm whether these records represent one person.`,
  );

  addGrouped(
    "POSSIBLE_DUPLICATE_PHONE",
    (candidate) => candidate.phoneKey,
    "Possible duplicate person",
    (items) =>
      `${items.map((item) => item.label || item.subjectKey).join(" / ")} share the same phone number. Confirm whether these records represent one person.`,
  );

  addGrouped(
    "POSSIBLE_DUPLICATE_NAME",
    (candidate) => candidate.nameKey,
    "Same name appears more than once",
    (items) =>
      `${items[0]?.label || "This name"} appears in multiple person rows. Keep them separate only when they are genuinely different people.`,
  );

  return attention;
}

function householdAttention(review: ImportReview): ActivationAttentionItem[] {
  const sheet = review.sheets.find((item) => item.schema.key === "household_membership");
  if (!sheet) return [];

  const byPerson = new Map<string, { families: Set<string>; rows: ParsedImportRow[] }>();
  for (const row of sheet.rows.filter((item) => item.status !== "rejected")) {
    const person = clean(row.values.from_id || row.values.fromRef).toLowerCase();
    const family = clean(row.values.to_id || row.values.toRef).toLowerCase();
    if (!person || !family) continue;
    const current = byPerson.get(person) || { families: new Set<string>(), rows: [] };
    current.families.add(family);
    current.rows.push(row);
    byPerson.set(person, current);
  }

  const attention: ActivationAttentionItem[] = [];
  for (const [person, entry] of byPerson) {
    if (entry.families.size < 2) continue;
    attention.push({
      id: `multiple-households:${person}`,
      code: "MULTIPLE_HOUSEHOLD_CANDIDATES",
      severity: "review",
      title: "Person is linked to more than one household",
      description: `${person.toUpperCase()} is linked to ${[...entry.families].join(", ")}. Confirm the intended household before activation.`,
      subjectKeys: [`person:${person}`],
      sourceRefs: entry.rows.map((row) => sourceFor(review, sheet, row)),
    });
  }

  return attention;
}

function membershipConflictAttention(review: ImportReview): ActivationAttentionItem[] {
  const sheet = review.sheets.find((item) => item.schema.key === "association_membership");
  if (!sheet) return [];

  const groups = new Map<
    string,
    {
      statuses: Set<string>;
      representatives: Set<string>;
      paymentSignatures: Set<string>;
      rows: ParsedImportRow[];
      family: string;
      year: string;
    }
  >();

  for (const row of sheet.rows.filter((item) => item.status !== "rejected")) {
    const family = clean(row.values.family_id).toLowerCase();
    const year = normalized(row.values.membership_year);
    const status = normalized(row.values.status);
    const representative = clean(row.values.representative_id).toLowerCase();
    const paymentSignature = [
      norm(row.values.payment_status),
      clean(row.values.amount_paid),
      clean(row.values.payment_reference),
    ].join("|");
    if (!family || !year) continue;

    const key = `${family}|${year}`;
    const current = groups.get(key) || {
      statuses: new Set<string>(),
      representatives: new Set<string>(),
      paymentSignatures: new Set<string>(),
      rows: [],
      family,
      year: clean(row.values.membership_year),
    };
    if (status) current.statuses.add(status);
    if (representative) current.representatives.add(representative);
    if (paymentSignature.replaceAll("|","")) current.paymentSignatures.add(paymentSignature);
    current.rows.push(row);
    groups.set(key, current);
  }

  const attention: ActivationAttentionItem[] = [];
  for (const [key, entry] of groups) {
    if (entry.statuses.size > 1) {
      attention.push({
        id: `membership-status-conflict:${key}`,
        code: "MEMBERSHIP_STATUS_CONFLICT",
        severity: "review",
        title: "Membership history conflicts",
        description: `${entry.family.toUpperCase()} has more than one status for ${entry.year}. Confirm the status that should become canonical.`,
        subjectKeys: [`family:${entry.family}`],
        sourceRefs: entry.rows.map((row) => sourceFor(review, sheet, row)),
      });
    }
    if (entry.representatives.size > 1) {
      attention.push({
        id: `representative-conflict:${key}`,
        code: "REPRESENTATIVE_CONFLICT",
        severity: "review",
        title: "More than one representative is listed",
        description: `${entry.family.toUpperCase()} has multiple representatives for ${entry.year}: ${[...entry.representatives].map((value) => value.toUpperCase()).join(", ")}.`,
        subjectKeys: [`family:${entry.family}`],
        sourceRefs: entry.rows.map((row) => sourceFor(review, sheet, row)),
      });
    }
    if (entry.paymentSignatures.size > 1) {
      attention.push({
        id: `membership-payment-conflict:${key}`,
        code: "MEMBERSHIP_PAYMENT_CONFLICT",
        severity: "review",
        title: "Membership payment records disagree",
        description: `${entry.family.toUpperCase()} has different payment state, amount or references for ${entry.year}. Choose the source row that should become canonical.`,
        subjectKeys: [`family:${entry.family}`],
        sourceRefs: entry.rows.map((row) => sourceFor(review, sheet, row)),
      });
    }
  }

  return attention;
}

function leadershipConflictAttention(review: ImportReview): ActivationAttentionItem[] {
  const sheet = review.sheets.find((item) => item.schema.key === "leadership_history");
  if (!sheet) return [];

  const singularRoles = new Set([
    "president",
    "president-elect",
    "past-president",
    "secretary",
    "treasurer",
    "chairperson",
  ]);
  const groups = new Map<string,{people:Set<string>;rows:ParsedImportRow[];year:string;role:string}>();

  for (const row of sheet.rows.filter((item) => item.status !== "rejected")) {
    const person = clean(row.values.person_id).toLowerCase();
    const year = normalized(row.values.membership_year);
    const role = normalized(row.values.role_key).replace(/\s+/g,"-");
    if (!person || !year || !role || !singularRoles.has(role)) continue;
    const key = `${year}|${role}`;
    const current = groups.get(key) || {
      people: new Set<string>(),
      rows: [],
      year: clean(row.values.membership_year),
      role,
    };
    current.people.add(person);
    current.rows.push(row);
    groups.set(key,current);
  }

  const attention: ActivationAttentionItem[] = [];
  for (const [key,entry] of groups) {
    if (entry.people.size < 2) continue;
    attention.push({
      id: `leadership-role-conflict:${key}`,
      code: "LEADERSHIP_ROLE_CONFLICT",
      severity: "review",
      title: "Leadership history conflicts",
      description: `More than one person is listed as ${entry.role.replaceAll("-"," ")} for ${entry.year}. Confirm the correct office holder before activation.`,
      subjectKeys: [...entry.people].map((person) => `person:${person}`),
      sourceRefs: entry.rows.map((row) => sourceFor(review,sheet,row)),
    });
  }
  return attention;
}

function markReviewFacts(
  facts: ActivationCandidateFact[],
  attention: ActivationAttentionItem[],
): ActivationCandidateFact[] {
  const reviewItems = attention.filter((item) => item.severity !== "info");
  const reviewSubjects = new Set(reviewItems.flatMap((item) => item.subjectKeys));
  const reviewRows = new Set(
    reviewItems.flatMap((item) =>
      item.sourceRefs.map((ref) => `${ref.fileName}|${ref.sheetKey}|${ref.rowNumber}`),
    ),
  );

  return facts.map((fact) => {
    if (fact.status === "rejected") return fact;
    const rowKey = `${fact.source.fileName}|${fact.source.sheetKey}|${fact.source.rowNumber}`;
    if (!reviewSubjects.has(fact.subjectKey) && !reviewRows.has(rowKey)) return fact;
    return {
      ...fact,
      status: "needs_review" as const,
      confidence: Math.min(fact.confidence, 0.8),
    };
  });
}

export function compileNetworkActivationCandidate(
  review: ImportReview,
): NetworkActivationCompilation {
  const initialFacts = buildFacts(review);
  const attention = [
    ...importBlockers(review),
    ...duplicateAttention(review),
    ...householdAttention(review),
    ...membershipConflictAttention(review),
    ...leadershipConflictAttention(review),
  ];
  const facts = markReviewFacts(initialFacts, attention);

  const entityRows = review.sheets
    .filter((sheet) => sheet.schema.recordType === "entity")
    .reduce((total, sheet) => total + sheet.rows.length, 0);
  const relationshipRows = review.sheets
    .filter((sheet) => sheet.schema.recordType === "relationship")
    .reduce((total, sheet) => total + sheet.rows.length, 0);
  const domainRows = review.sheets
    .filter((sheet) => sheet.schema.recordType === "domain")
    .reduce((total, sheet) => total + sheet.rows.length, 0);
  const blockingItems = attention.filter((item) => item.severity === "blocking").length;
  const reviewItems = attention.filter((item) => item.severity === "review").length;

  const summary: ActivationPlanSummary = {
    sourceRows: entityRows + relationshipRows + domainRows,
    entityRows,
    relationshipRows,
    domainRows,
    candidateFacts: facts.length,
    acceptedFacts: facts.filter((fact) => fact.status === "accepted").length,
    reviewFacts: facts.filter((fact) => fact.status === "needs_review").length,
    rejectedFacts: facts.filter((fact) => fact.status === "rejected").length,
    attentionItems: attention.length,
    blockingItems,
    reviewItems,
  };

  return {
    version: "network-activation-candidate.v1",
    verticalKind: review.schema.verticalKind,
    sourceFileName: review.fileName,
    schemaVersion: review.schema.version,
    facts,
    attention,
    summary,
    canActivate: review.canCommit && blockingItems === 0 && reviewItems === 0,
    trustStatement:
      "No inferred or ambiguous fact is written automatically. Every candidate fact keeps its source location, and items needing judgment block activation until resolved.",
  };
}
