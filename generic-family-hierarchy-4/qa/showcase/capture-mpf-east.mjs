import { chromium } from '@playwright/test';
import fs from 'node:fs/promises';
import path from 'node:path';

const args = Object.fromEntries(process.argv.slice(2).map((arg) => {
  const [key, ...rest] = arg.replace(/^--/, '').split('=');
  return [key, rest.length ? rest.join('=') : true];
}));


const baseUrl = String(args['base-url'] || process.env.TW_BASE_URL || 'http://127.0.0.1:3000').replace(/\/$/, '');
const mode = String(args.mode || 'desktop').toLowerCase();
const headed = Boolean(args.headed);
const slowMo = Number(args['slow-mo'] || 0);
const maxScreens = Number(args['max-screens'] || 80);
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
const outputRoot = path.resolve(String(args.out || path.join('artifact', 'mpf-east-showcase', stamp)));

const viewports = mode === 'both'
  ? [{ name: 'desktop', width: 1440, height: 1000 }, { name: 'mobile', width: 390, height: 844 }]
  : mode === 'mobile'
    ? [{ name: 'mobile', width: 390, height: 844 }]
    : [{ name: 'desktop', width: 1440, height: 1000 }];

const slug = (value) => String(value || 'screen')
  .trim()
  .toLowerCase()
  .replace(/[^a-z0-9]+/g, '-')
  .replace(/^-+|-+$/g, '')
  .slice(0, 70) || 'screen';

const pause = (ms = 450) => new Promise((resolve) => setTimeout(resolve, ms));

async function visible(locator) {
  try { return await locator.isVisible(); } catch { return false; }
}

async function captureViewport(browser, viewport) {
  const dir = path.join(outputRoot, viewport.name);
  await fs.mkdir(dir, { recursive: true });
  const context = await browser.newContext({ viewport: { width: viewport.width, height: viewport.height } });
  const page = await context.newPage();
  let sequence = 0;
  const captured = [];

  const shot = async (name, note = '') => {
    if (sequence >= maxScreens) return;
    sequence += 1;
    const file = `${String(sequence).padStart(2, '0')}-${slug(name)}.png`;
    await page.screenshot({ path: path.join(dir, file), fullPage: true });
    captured.push({ file, note });
    console.log(`[${viewport.name}] ${file}${note ? ` — ${note}` : ''}`);
  };

  const settle = async () => {
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    await pause();
  };

  console.log(`\nOpening ${baseUrl} (${viewport.name})`);
  await page.goto(`${baseUrl}/`, { waitUntil: 'domcontentloaded', timeout: 30_000 });
  await page.getByTestId('qa-public-discovery').waitFor({ state: 'visible', timeout: 20_000 });
  await settle();
  await shot('public-discovery', 'TrustWeave public landing / discovery');

  // The public product gallery now exposes Playground directly from each card.
  // Match the Family Community / Cultural Association card by content so this
  // remains stable even if gallery ordering changes. Keep the current third-card
  // position only as a fallback for local revisions with slightly different copy.
  const gallery = page.locator('.public-product-gallery-grid').first();
  await gallery.waitFor({ state: 'visible', timeout: 10_000 });

  const namedCommunityCard = gallery
    .locator('article')
    .filter({ hasText: /Family Community\s*\/\s*Cultural Association/i })
    .first();
  const thirdGalleryCard = gallery.locator('article').nth(2);
  const communityCard = await visible(namedCommunityCard)
    ? namedCommunityCard
    : thirdGalleryCard;

  if (!(await visible(communityCard))) {
    const diagnosticDir = path.join(outputRoot, viewport.name, '_diagnostics');
    await fs.mkdir(diagnosticDir, { recursive: true });
    await page.screenshot({
      path: path.join(diagnosticDir, 'community-gallery-card-not-found.png'),
      fullPage: true,
    }).catch(() => {});
    await fs.writeFile(
      path.join(diagnosticDir, 'community-gallery-card-not-found.html'),
      await page.content(),
      'utf8',
    ).catch(() => {});
    throw new Error(
      `Family Community / Cultural Association gallery card was not found. ` +
      `Diagnostics written to ${diagnosticDir}`,
    );
  }

  const enter = communityCard
    .getByRole('button', { name: /Playground/i })
    .first();

  if (!(await visible(enter))) {
    const diagnosticDir = path.join(outputRoot, viewport.name, '_diagnostics');
    await fs.mkdir(diagnosticDir, { recursive: true });
    await page.screenshot({
      path: path.join(diagnosticDir, 'community-gallery-no-playground-button.png'),
      fullPage: true,
    }).catch(() => {});
    await fs.writeFile(
      path.join(diagnosticDir, 'community-gallery-no-playground-button.html'),
      await page.content(),
      'utf8',
    ).catch(() => {});
    throw new Error(
      `Family Community / Cultural Association card was found, but its Playground button was not. ` +
      `Diagnostics written to ${diagnosticDir}`,
    );
  }

  await enter.click();

  await settle();

  // Do not depend on a single historical QA id here. The Family Association
  // shell has evolved across missions; the stable product-shell/navigation
  // classes are a safer local showcase contract.
  const familyAssociationShell = page.getByTestId('qa-vertical-shell-family-association');
  const productShell = page.locator('.product-network-app').first();
  const productNav = page.locator('.product-side-nav, .product-mobile-bottom-nav').first();
  const anyQaNav = page.locator('[data-testid^="qa-nav-"]').first();

  try {
    await Promise.any([
      familyAssociationShell.waitFor({ state: 'visible', timeout: 15_000 }),
      productShell.waitFor({ state: 'visible', timeout: 15_000 }),
      productNav.waitFor({ state: 'visible', timeout: 15_000 }),
      anyQaNav.waitFor({ state: 'visible', timeout: 15_000 }),
    ]);
  } catch {
    
    const diagnosticDir = path.join(outputRoot, viewport.name, '_diagnostics');
    await fs.mkdir(diagnosticDir, { recursive: true });
    await page.screenshot({ path: path.join(diagnosticDir, 'playground-entry-timeout.png'), fullPage: true }).catch(() => {});
    await fs.writeFile(path.join(diagnosticDir, 'playground-entry-timeout.html'), await page.content(), 'utf8').catch(() => {});
    throw new Error(
      `MPF East Playground did not reach a recognizable product shell after 15s. ` +
      `Current URL: ${page.url()}. Diagnostics written to ${diagnosticDir}`
    );
  }

  await settle();


  // Guard against accidentally entering a different Playground vertical.
  // This is intentionally a soft check because local labels can be translated
  // or renamed while the underlying Family Association surface remains valid.
  const shellText = await page.locator('body').innerText().catch(() => '');
  if (!/MPF|Pune East|Family Community|Association/i.test(shellText)) {
    console.warn(
      `[${viewport.name}] Warning: Playground shell opened, but MPF/Family Association text was not detected. ` +
      `Continuing capture from ${page.url()}.`
    );
  }


  await shot('mpf-east-playground-home', 'MPF Pune East Playground initial screen');

  async function openDesktopMoreIfNeeded(testId) {
    const target = page.getByTestId(testId).first();
    if (await visible(target)) return target;
    const details = page.locator('details.product-nav-more').first();
    if (await details.count()) {
      await details.evaluate((el) => { el.open = true; });
      await pause(1150);
    }
    return target;
  }

  async function openMobileMoreIfNeeded(viewId) {
    const direct = page.getByTestId(`qa-nav-${viewId}`).first();
    if (await visible(direct)) return direct;
    const moreButton = page.locator('.product-mobile-bottom-nav button').filter({ hasText: /More/i }).first();
    if (await visible(moreButton)) {
      await moreButton.click();
      await pause(2150);
      const item = page.getByTestId(`qa-mobile-more-${viewId}`).first();
      if (await visible(item)) return item;
    }
    return direct;
  }

  const navIds = await page.locator('button[data-testid^="qa-nav-"]').evaluateAll((nodes) =>
    [...new Set(nodes.map((node) => node.getAttribute('data-testid')).filter(Boolean))]
  );

  for (const testId of navIds) {
    if (sequence >= maxScreens) break;
    const viewId = testId.replace('qa-nav-', '');
    let target = viewport.name === 'mobile'
      ? await openMobileMoreIfNeeded(viewId)
      : await openDesktopMoreIfNeeded(testId);

    if (!(await visible(target))) {
      // On mobile a menu may have closed/re-rendered; retry once.
      if (viewport.name === 'mobile') target = await openMobileMoreIfNeeded(viewId);
    }
    if (!(await visible(target))) continue;

    const label = (await target.innerText().catch(() => viewId)).trim() || viewId;
    await target.click();
    await settle();
    await shot(`surface-${viewId}-${label}`, `Top-level Playground surface: ${label}`);

    // Progressive section selectors are heavily used in Community, Guide and other workspaces.
    const selectCount = await page.locator('select[data-testid="qa-section-select"]:visible').count();
    for (let selectIndex = 0; selectIndex < selectCount; selectIndex += 1) {
      const selector = page.locator('select[data-testid="qa-section-select"]:visible').nth(selectIndex);
      const options = await selector.locator('option').evaluateAll((opts) => opts.map((o) => ({ value: o.value, label: o.textContent || o.value })));
      const original = await selector.inputValue().catch(() => '');
      for (const option of options) {
        if (sequence >= maxScreens) break;
        try {
          await selector.selectOption(option.value);
          await pause(2300);
          await shot(`surface-${viewId}-section-${selectIndex + 1}-${option.label}`, `${label} → ${option.label}`);
        } catch {
          // Some workspaces replace the selector while switching sections. Re-query on next pass.
        }
      }
      const refreshed = page.locator('select[data-testid="qa-section-select"]:visible').nth(selectIndex);
      if (original && await refreshed.count()) await refreshed.selectOption(original).catch(() => {});
    }

    // Family Community directory has useful showcase modes worth capturing individually.
    if (viewId === 'directory') {
      const modes = ['all', 'families', 'representatives', 'members'];
      for (const directoryMode of modes) {
        const button = page.getByTestId(`qa-fca-directory-mode-${directoryMode}`);
        if (await visible(button)) {
          await button.click();
          await pause(2250);
          await shot(`directory-${directoryMode}`, `Families & Members → ${directoryMode}`);
        }
      }

      // Capture a representative entity/profile detail if available.
      const firstCard = page.locator('.product-entity-card .entity-open-btn').first();
      if (await visible(firstCard)) {
        await firstCard.click();
        await page.locator('.network-entity-detail').waitFor({ state: 'visible', timeout: 5_000 }).catch(() => {});
        await pause(2200);
        await shot('directory-first-profile-detail', 'Representative family/member detail panel');
        const close = page.locator('.network-entity-detail .modal-x').first();
        if (await visible(close)) await close.click();
      }
    }

    // Family Structure offers two important ways of viewing the same network.
    if (viewId === 'explorer') {
      for (const labelText of ['Structure Map', 'Guided Drilldown']) {
        const button = page.getByRole('button', { name: new RegExp(labelText, 'i') }).first();
        if (await visible(button)) {
          await button.click();
          await pause(1350);
          await shot(`family-structure-${labelText}`, `Family Structure → ${labelText}`);
        }
      }
    }
  }

  const indexLines = [
    `# MPF East Playground Screenshots — ${viewport.name}`,
    '',
    `Generated: ${new Date().toISOString()}`,
    `Base URL: ${baseUrl}`,
    `Viewport: ${viewport.width}×${viewport.height}`,
    '',
    ...captured.map((item, index) => `${index + 1}. \`${item.file}\`${item.note ? ` — ${item.note}` : ''}`),
    '',
    'These screenshots were captured from the read-only Family Community / Cultural Association Playground.',
  ];
  await fs.writeFile(path.join(dir, 'INDEX.md'), indexLines.join('\n'), 'utf8');
  await context.close();
  return { viewport, captured };
}

await fs.mkdir(outputRoot, { recursive: true });
const browser = await chromium.launch({ headless: !headed, slowMo });
const results = [];
try {
  for (const viewport of viewports) results.push(await captureViewport(browser, viewport));
} finally {
  await browser.close();
}

const summary = [
  '# MPF East Playground Capture',
  '',
  `Generated: ${new Date().toISOString()}`,
  `Base URL: ${baseUrl}`,
  '',
  ...results.flatMap(({ viewport, captured }) => [
    `## ${viewport.name}`,
    '',
    `Captured ${captured.length} screenshots at ${viewport.width}×${viewport.height}.`,
    `See \`${viewport.name}/INDEX.md\` for the ordered list.`,
    '',
  ]),
  'Tip: share the best 8–12 screenshots rather than every image, or combine them into a PDF/contact sheet for WhatsApp.',
];
await fs.writeFile(path.join(outputRoot, 'README.md'), summary.join('\n'), 'utf8');

console.log(`\nDone. Screenshots written to:\n${outputRoot}`);