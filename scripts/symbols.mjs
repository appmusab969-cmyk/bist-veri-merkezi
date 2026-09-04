// BIST evreni — artık statik değil, TradingView'in genel scanner API'sinden
// dinamik olarak keşfedilir (tüm işlem gören hisseler + BYF/ETF'ler + kapalı
// uçlu yatırım ortaklıkları). Aynı kaynak Python tarafında scripts/symbols.py
// içinde de kullanılır — iki dosya birbirinden bağımsız import edildiği için
// mantık (endpoint, filtre) elle senkron tutulmalıdır.
//
// Ağ isteği başarısız olursa (rate-limit, geçici kesinti) FALLBACK_UNIVERSE'e
// düşülür, böylece script asla boş evrenle çalışmaz.

import { writeFile, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CACHE_FILE = join(__dirname, '.universe_cache.json');

const TRADINGVIEW_SCAN_URL = 'https://scanner.tradingview.com/turkey/scan';
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/122.0 Safari/537.36';

export const INDEX_SYMBOL = 'XU100.IS';

// Son çare: TradingView erişilemezse kullanılan küçük, likit alt küme.
export const FALLBACK_UNIVERSE = [
  'ASELS', 'THYAO', 'TUPRS', 'BIMAS', 'KCHOL', 'SAHOL', 'FROTO', 'TOASO',
  'SISE', 'EREGL', 'KRDMD', 'PETKM', 'OYAKC', 'TCELL', 'PGSUS', 'AEFES',
  'CCOLA', 'MGROS', 'ULKER', 'TAVHL', 'ENKAI', 'SASA', 'ALARK', 'HEKTS',
  'GUBRF', 'VESTL', 'ARCLK', 'TKFEN', 'DOAS', 'ISDMR', 'YKBNK', 'AKBNK',
  'GARAN', 'ISCTR', 'HALKB', 'VAKBN', 'TTKOM', 'BRSAN', 'KONTR', 'SMRTG',
  'ODAS', 'ENJSA', 'AKSEN', 'ZOREN', 'CIMSA', 'AGHOL', 'BUCIM', 'OTKAR',
  'KARSN', 'TTRAK', 'EKGYO', 'ISGYO', 'TSKB', 'ALBRK', 'SKBNK', 'MPARK',
  'LKMNH', 'SELEC', 'BAGFS', 'GLYHO', 'MAVI',
];

// Katılım Endeksi'ne uygun (faizsiz) hisseler — uygulamadaki liste ile aynı olmalı.
export const PARTICIPATION = new Set([
  'ASELS', 'BIMAS', 'FROTO', 'TOASO', 'TUPRS', 'EREGL', 'KRDMD', 'PETKM',
  'SASA', 'HEKTS', 'GUBRF', 'BAGFS', 'CIMSA', 'BUCIM', 'OYAKC', 'ENKAI',
  'TKFEN', 'OTKAR', 'TTRAK', 'KONTR', 'SMRTG', 'ODAS', 'AKSEN', 'ZOREN',
  'MGROS', 'ULKER', 'CCOLA', 'AEFES', 'SELEC', 'MPARK', 'LKMNH', 'MAVI',
]);

/**
 * TradingView'in genel scanner API'sinden BIST'teki tüm sembolleri çeker.
 * @returns {Promise<Array<{code:string, name:string, type:string, subtype:string}>>}
 */
async function fetchTradingViewUniverse() {
  const res = await fetch(TRADINGVIEW_SCAN_URL, {
    method: 'POST',
    headers: { 'User-Agent': UA, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      filter: [{ left: 'exchange', operation: 'equal', right: 'BIST' }],
      columns: ['name', 'description', 'type', 'subtype'],
      range: [0, 1000],
    }),
  });
  if (!res.ok) throw new Error(`TradingView HTTP ${res.status}`);
  const body = await res.json();
  const rows = body?.data || [];
  return rows
    .map((row) => {
      const [code, name, type, subtype] = row.d;
      return { code: String(code).trim().toUpperCase(), name, type, subtype };
    })
    .filter((r) => /^[A-Z0-9]+$/.test(r.code));
}

/**
 * Tüm BIST evrenini (hisse + BYF + kapalı uçlu fon) döner. Ağ hatası
 * durumunda son başarılı sonucun yerel önbelleğine, o da yoksa
 * FALLBACK_UNIVERSE'e düşer.
 * @returns {Promise<Array<{code:string, name:string, type:string, subtype:string}>>}
 */
export async function discoverUniverse() {
  try {
    const rows = await fetchTradingViewUniverse();
    if (!rows.length) throw new Error('TradingView boş liste döndürdü');
    await writeFile(CACHE_FILE, JSON.stringify(rows), 'utf8').catch(() => {});
    return rows;
  } catch (e) {
    console.warn(`[Uyarı] TradingView evren keşfi başarısız: ${e}`);
    try {
      const cached = JSON.parse(await readFile(CACHE_FILE, 'utf8'));
      if (Array.isArray(cached) && cached.length) {
        console.warn(`[Bilgi] Yerel önbellekten ${cached.length} sembol kullanılıyor.`);
        return cached;
      }
    } catch {
      /* önbellek de yok, sabit listeye düş */
    }
    console.warn(`[Bilgi] Sabit FALLBACK_UNIVERSE kullanılıyor (${FALLBACK_UNIVERSE.length} sembol).`);
    return FALLBACK_UNIVERSE.map((code) => ({ code, name: null, type: 'stock', subtype: 'common' }));
  }
}

/**
 * Sadece sembol kodlarının düz, alfabetik sıralı listesini döner.
 * @param {{kinds?: Set<string>}} [opts]  kinds verilirse "type/subtype" (örn. "stock/common") filtrelenir.
 */
export async function getUniverseCodes(opts = {}) {
  const rows = await discoverUniverse();
  const filtered = opts.kinds
    ? rows.filter((r) => opts.kinds.has(`${r.type}/${r.subtype}`))
    : rows;
  return [...new Set(filtered.map((r) => r.code))].sort();
}
