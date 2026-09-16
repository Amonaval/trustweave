import fs from "node:fs";
import path from "node:path";
import { EnvironmentManager } from "./environment-manager.mjs";
import { buildCockpit } from "./cockpit-snapshot.mjs";
const root = process.cwd(),
  evidenceDir = "release-evidence/M3-C9/runtime";
const snapshot = buildCockpit({ root });
const manager = new EnvironmentManager({ root, evidenceDir });
let browser, page;
const checks = [];
const ok = (n, v) => checks.push([n, !!v]);
try {
  const launched = await manager.launchBrowser();
  browser = launched.browser;
  page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const preview = await manager.startPreview({
    env: {
      NEXT_PUBLIC_SUPABASE_URL: "http://127.0.0.1:54321",
      NEXT_PUBLIC_SUPABASE_ANON_KEY: "runtime-test-anon-key",
    },
  });
  const response = await page.goto(`${preview.baseURL}/company`, {
    waitUntil: "domcontentloaded",
    timeout: 60000,
  });
  try {
    await page.locator('[data-testid="founder-cockpit"]').waitFor({ timeout: 60000 });
  } catch (error) {
    const body = (await page.locator("body").innerText()).slice(0, 1200);
    throw new Error(`Cockpit did not render: ${String(error)}; body=${body}; preview=${preview.log().slice(-1200)}`);
  }
  const text = await page.locator("body").innerText();
  const measure = await page.evaluate(() => ({
    overflow:
      document.documentElement.scrollWidth -
      document.documentElement.clientWidth,
    headings: [...document.querySelectorAll("h1,h2")].map((x) => x.textContent),
    summaryHeight:
      document.querySelector("summary")?.getBoundingClientRect().height || 0,
  }));
  ok("real cockpit route responds", response?.status() === 200);
  ok(
    "company health and autonomy are visible",
    /Company health/.test(text) && /Autonomy score/.test(text),
  );
  ok(
    "debate, missions, decisions, risks and evidence are visible",
    [
      "Executive debate",
      "Mission state",
      "Decisions & risks",
      "Evidence",
    ].every((x) => text.includes(x)),
  );
  ok(
    "Founder interventions and blockers are visible",
    text.includes("Founder interventions") && text.includes("Blocking risks"),
  );
  ok("next moves are visible", text.includes("Next moves"));
  ok("optional drill-down is operable", measure.summaryHeight >= 44);
  ok("mobile cockpit has no horizontal overflow", measure.overflow <= 1);
  ok(
    "snapshot contains no secret values",
    !JSON.stringify(snapshot).match(
      /service_role|private key|runtime-test-anon-key/i,
    ),
  );
  const report = {
    generatedAt: new Date().toISOString(),
    status: checks.every((x) => x[1]) ? "PASS" : "FAIL",
    browser: launched.source,
    route: "/company",
    viewport: { width: 390, height: 844 },
    measure,
    snapshot: { health: snapshot.health, autonomy: snapshot.autonomy },
    checks: checks.map(([name, pass]) => ({ name, pass })),
  };
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(
    path.join(evidenceDir, "cockpit-runtime.json"),
    JSON.stringify(report, null, 2) + "\n",
  );
} finally {
  if (page) await page.close().catch(() => {});
  if (browser) await browser.close().catch(() => {});
  manager.cleanup();
}
let failures = 0;
for (const [n, p] of checks) {
  console.log(`${p ? "PASS" : "FAIL"} ${n}`);
  if (!p) failures++;
}
console.log(
  `M3-C9 Founder cockpit gate: ${checks.length - failures}/${checks.length} passed.`,
);
if (failures) process.exit(1);
