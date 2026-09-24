#!/usr/bin/env node
/**
 * Batch-screenshot slide HTML files into PNGs at a fixed viewport size.
 *
 * Usage:
 *   node screenshot_slides.mjs --config deck.config.json slide01.html slide02.html ...
 *   node screenshot_slides.mjs --config deck.config.json --out-dir out/ slides/*.html
 *
 * Each <name>.html becomes <name>.png (next to the source file, or under
 * --out-dir if given). Viewport size and device scale factor come from
 * deck.config.json so every slide in the deck renders at the same resolution.
 *
 * Requires the `playwright` npm package plus a downloaded Chromium build:
 *   npm install playwright && npx playwright install chromium
 */
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';

function parseArgs(argv) {
  const args = { files: [], config: null, outDir: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--config') args.config = argv[++i];
    else if (a === '--out-dir') args.outDir = argv[++i];
    else args.files.push(a);
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.files.length === 0) {
    console.error('Usage: node screenshot_slides.mjs --config deck.config.json slide01.html [slide02.html ...]');
    process.exit(1);
  }

  let config = { viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 };
  if (args.config) {
    config = { ...config, ...JSON.parse(fs.readFileSync(args.config, 'utf-8')) };
  }

  // A bare import resolves from this script's directory (the skill dir), so
  // also look in the current working directory, where the user installs it.
  let chromium;
  try {
    ({ chromium } = await import('playwright'));
  } catch {
    try {
      const require = createRequire(path.join(process.cwd(), 'noop.js'));
      ({ chromium } = await import(pathToFileURL(require.resolve('playwright')).href));
    } catch {
      console.error(
        "Playwright is not installed.\n" +
        "Run in the working directory: npm install playwright && npx playwright install chromium"
      );
      process.exit(1);
    }
  }

  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: config.viewport,
    deviceScaleFactor: config.deviceScaleFactor,
  });

  const results = [];
  for (const file of args.files) {
    const abs = path.resolve(file);
    const url = pathToFileURL(abs).href;
    await page.goto(url, { waitUntil: 'networkidle' });
    const outPath = args.outDir
      ? path.join(args.outDir, `${path.parse(file).name}.png`)
      : path.join(path.dirname(abs), `${path.parse(file).name}.png`);
    fs.mkdirSync(path.dirname(outPath), { recursive: true });
    await page.screenshot({ path: outPath });
    results.push({ input: abs, output: outPath });
  }

  await browser.close();
  console.log(JSON.stringify(results, null, 2));
}

main().catch((err) => {
  console.error(err.stack || err.message || err);
  process.exit(1);
});
