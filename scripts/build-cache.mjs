// ============================================================================
//  Pusula — Günlük Önbellek Üreticisi
//  GitHub Actions'ta günde 1 kez çalışır. Tüm dış istekleri BURADA yapar,
//  sonucu ../data/cache/*.json içine yazar. 10.000 kullanıcı bu statik
//  dosyaları jsDelivr CDN'den okur -> sıfır sunucu maliyeti, sıfır rate-limit.
//
//  Kullanım:
//    node build-cache.mjs               # tüm evren
//    node build-cache.mjs --only ASELS THYAO
// ============================================================================

import { writeFile, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import { BIST_UNIVERSE, INDEX_SYMBOL, PARTICIPATION } from './symbols.mjs';
import {
  fetchChart,
  quoteFromChart,
  candlesFromChart,
  fetchQuoteSummary,
  sleep,
} from './yahoo.mjs';
import { normalizeDetail } from './fundamentals.mjs';
import { fetchKapDisclosures } from './kap.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, '..', 'data', 'cache');
const SCHEMA_VERSION = 1;

// CLI: --only ile alt küme
const onlyIdx = process.argv.indexOf('--only');
const UNIVERSE =
  onlyIdx >= 0 ? process.argv.slice(onlyIdx + 1).map((s) => s.toUpperCase()) : BIST_UNIVERSE;

// Yahoo'yu yormamak için küçük gruplar + gruplar arası bekleme.
const CHUNK = 6;
const GAP_MS = 1200;

const nowIso = () => new Date().toISOString();

async function writeJson(name, data) {
  const path = join(OUT_DIR, name);
  await writeFile(path, JSON.stringify(data), 'utf8');
  const kb = (Buffer.byteLength(JSON.stringify(data)) / 1024).toFixed(1);
  console.log(`  ✓ ${name}  (${kb} KB)`);
}

async function buildOne(code) {
  // 1) Günlük OHLC (teknik analiz + grafik yedeği) — 1 yıl
  const dailyChart = await fetchChart(code, { range: '1y', interval: '1d' });
  const candles = candlesFromChart(dailyChart);

  // 2) Gün içi quote (fiyat + spark)
  let quote;
  try {
    const intraday = await fetchChart(code, { range: '5d', interval: '30m' });
    quote = quoteFromChart(intraday);
  } catch {
    quote = quoteFromChart(dailyChart);
  }

  // 3) Temel veriler (crumb gerektirir; başarısızsa partial)
  const summary = await fetchQuoteSummary(code);
  const detail = normalizeDetail(summary, quote);
  detail.participation = PARTICIPATION.has(code);

  return {
    schemaVersion: SCHEMA_VERSION,
    code,
    updatedAt: nowIso(),
    detail,
    // Grafik yedeği için sıkıştırılmış seri (son 260 iş günü ≈ 1 yıl)
    candles: candles.slice(-260),
  };
}

async function main() {
  await mkdir(OUT_DIR, { recursive: true });
  console.log(`▶ Önbellek üretimi başladı — ${UNIVERSE.length} sembol\n`);

  const perSymbol = {};
  const summaryRows = [];
  const failures = [];

  for (let i = 0; i < UNIVERSE.length; i += CHUNK) {
    const part = UNIVERSE.slice(i, i + CHUNK);
    const results = await Promise.allSettled(part.map((c) => buildOne(c)));

    for (let j = 0; j < part.length; j++) {
      const code = part[j];
      const r = results[j];
      if (r.status === 'fulfilled') {
        perSymbol[code] = r.value;
        await writeJson(`stock/${code}.json`, r.value).catch(async () => {
          await mkdir(join(OUT_DIR, 'stock'), { recursive: true });
          await writeJson(`stock/${code}.json`, r.value);
        });
        const q = r.value.detail.quote;
        summaryRows.push({
          code,
          name: r.value.detail.longName || q.shortName,
          price: q.price,
          changePercent: +q.changePercent.toFixed(2),
          participation: r.value.detail.participation,
          partial: r.value.detail.partial,
          spark: (q.spark || []).slice(-24),
        });
      } else {
        failures.push({ code, error: String(r.reason).slice(0, 200) });
        console.warn(`  ✗ ${code}: ${r.reason}`);
      }
    }
    if (i + CHUNK < UNIVERSE.length) await sleep(GAP_MS);
  }

  // ---- Endeks
  let index = null;
  try {
    const idxChart = await fetchChart(INDEX_SYMBOL, { range: '5d', interval: '30m' });
    index = quoteFromChart(idxChart);
  } catch (e) {
    console.warn(`  ✗ endeks: ${e}`);
  }

  // ---- KAP bildirimleri
  let kap = { ok: false, items: [] };
  try {
    kap = await fetchKapDisclosures(UNIVERSE);
    console.log(`  ${kap.ok ? '✓' : '✗'} KAP: ${kap.items.length} bildirim`);
  } catch (e) {
    console.warn(`  ✗ KAP: ${e}`);
  }

  // ---- Toplu dosyalar (uygulama açılışta TEK isteği bunlara yapar)
  await mkdir(join(OUT_DIR, 'stock'), { recursive: true });

  await writeJson('index.json', {
    schemaVersion: SCHEMA_VERSION,
    updatedAt: nowIso(),
    generator: 'github-actions',
    counts: {
      requested: UNIVERSE.length,
      ok: summaryRows.length,
      failed: failures.length,
    },
    market: index,
    stocks: summaryRows.sort((a, b) => a.code.localeCompare(b.code)),
    failures,
  });

  await writeJson('kap.json', {
    schemaVersion: SCHEMA_VERSION,
    updatedAt: nowIso(),
    ok: kap.ok,
    items: kap.items,
  });

  console.log(
    `\n✔ Bitti: ${summaryRows.length}/${UNIVERSE.length} sembol, ` +
      `${failures.length} hata. Çıktı: data/cache/`,
  );

  // Actions job'unun kırmızı olması için: hepsi başarısızsa çık kodu 1
  if (summaryRows.length === 0) process.exit(1);
}

main().catch((e) => {
  console.error('KRİTİK:', e);
  process.exit(1);
});
