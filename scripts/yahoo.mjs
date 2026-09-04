// Yahoo Finance ücretsiz uç noktaları — SUNUCU TARAFI (GitHub Actions içinde) kullanım.
// Bu dosya günde 1 kez çalışır; 10.000 kullanıcı bunu ASLA doğrudan çağırmaz.

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/122.0 Safari/537.36';

const CHART_HOST = 'https://query1.finance.yahoo.com';
const SEARCH_HOST = 'https://query2.finance.yahoo.com';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Basit yeniden deneme + üstel gecikme (Yahoo ara sıra 429/503 döner). */
async function getJson(url, { headers = {}, tries = 4 } = {}) {
  let lastErr;
  for (let i = 0; i < tries; i++) {
    try {
      const res = await fetch(url, {
        headers: { 'User-Agent': UA, Accept: 'application/json', ...headers },
      });
      if (res.status === 429 || res.status === 503) {
        await sleep(1500 * (i + 1));
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status} @ ${url}`);
      return await res.json();
    } catch (e) {
      lastErr = e;
      await sleep(800 * (i + 1));
    }
  }
  throw lastErr;
}

export function toYahooSymbol(code) {
  const s = String(code).trim().toUpperCase();
  if (!s || s.includes('.')) return s;
  return `${s}.IS`;
}

// ----------------------------------------------------------------- chart / quote

export async function fetchChart(code, { range = '1d', interval = '5m' } = {}) {
  const sym = toYahooSymbol(code);
  const url =
    `${CHART_HOST}/v8/finance/chart/${encodeURIComponent(sym)}` +
    `?range=${range}&interval=${interval}&includePrePost=false`;
  const body = await getJson(url);
  const err = body?.chart?.error;
  if (err) throw new Error(`Yahoo: ${err.description || JSON.stringify(err)}`);
  const r = body?.chart?.result?.[0];
  if (!r) throw new Error(`Boş chart yanıtı: ${sym}`);
  return r;
}

export function quoteFromChart(r) {
  const meta = r.meta || {};
  const q = r.indicators?.quote?.[0] || {};
  const ts = r.timestamp || [];
  const closes = (q.close || []).filter((v) => typeof v === 'number');
  const price =
    meta.regularMarketPrice ?? (closes.length ? closes[closes.length - 1] : 0);
  const prevClose =
    meta.chartPreviousClose ?? meta.previousClose ?? (closes.length ? closes[0] : price);
  return {
    symbol: meta.symbol,
    code: (meta.symbol || '').replace(/\.IS$/, ''),
    shortName: meta.shortName || meta.symbol,
    currency: meta.currency || 'TRY',
    price,
    previousClose: prevClose,
    change: price - prevClose,
    changePercent: prevClose ? ((price - prevClose) / prevClose) * 100 : 0,
    dayLow: meta.regularMarketDayLow ?? null,
    dayHigh: meta.regularMarketDayHigh ?? null,
    fiftyTwoWeekLow: meta.fiftyTwoWeekLow ?? null,
    fiftyTwoWeekHigh: meta.fiftyTwoWeekHigh ?? null,
    volume: meta.regularMarketVolume ?? null,
    spark: closes.slice(-40),
    lastTimestamp: ts.length ? ts[ts.length - 1] : null,
  };
}

/** Günlük OHLC serisi — teknik analiz ve grafik yedeği için. */
export function candlesFromChart(r) {
  const ts = r.timestamp || [];
  const q = r.indicators?.quote?.[0] || {};
  const out = [];
  for (let i = 0; i < ts.length; i++) {
    const o = q.open?.[i];
    const h = q.high?.[i];
    const l = q.low?.[i];
    const c = q.close?.[i];
    const v = q.volume?.[i];
    if ([o, h, l, c].some((x) => typeof x !== 'number')) continue;
    out.push({ t: ts[i], o, h, l, c, v: typeof v === 'number' ? v : 0 });
  }
  return out;
}

// ----------------------------------------------------------------- quoteSummary

let _crumb = null;
let _cookie = null;

/** Bir yanıttaki tüm Set-Cookie başlıklarını `k=v; k=v` biçiminde toplar. */
function collectCookies(res, jar) {
  // Node 20+ : getSetCookie() birden fazla başlığı dizi olarak verir.
  const list =
    typeof res.headers.getSetCookie === 'function'
      ? res.headers.getSetCookie()
      : (res.headers.get('set-cookie') ? [res.headers.get('set-cookie')] : []);
  for (const c of list) {
    const [pair] = c.split(';');
    const eq = pair.indexOf('=');
    if (eq > 0) jar[pair.slice(0, eq).trim()] = pair.slice(eq + 1).trim();
  }
}

const jarToHeader = (jar) =>
  Object.entries(jar)
    .map(([k, v]) => `${k}=${v}`)
    .join('; ');

async function ensureCrumb() {
  if (_crumb && _cookie) return;
  const jar = {};

  // 1) Çerez tohumu: birkaç aday. redirect:'follow' ile her adımın çerezi alınır.
  for (const seed of [
    'https://finance.yahoo.com/quote/AAPL/',
    'https://fc.yahoo.com/',
    'https://www.yahoo.com/',
  ]) {
    try {
      const r = await fetch(seed, { headers: { 'User-Agent': UA } });
      collectCookies(r, jar);
      await r.text().catch(() => {});
    } catch {
      /* sıradaki tohum */
    }
    if (jar.A1 || jar.A3 || jar.B) break;
  }
  if (Object.keys(jar).length === 0) return;
  _cookie = jarToHeader(jar);

  // 2) Bu çerezle eşleşen crumb.
  for (const host of [CHART_HOST, SEARCH_HOST]) {
    try {
      const res = await fetch(`${host}/v1/test/getcrumb`, {
        headers: { 'User-Agent': UA, Cookie: _cookie, Accept: 'text/plain' },
      });
      collectCookies(res, jar);
      _cookie = jarToHeader(jar);
      const txt = await res.text();
      if (res.ok && txt && txt.length < 40 && !txt.includes('<')) {
        _crumb = txt.trim();
        return;
      }
    } catch {
      /* dene diğerini */
    }
  }
}

/** Temel veriler (F/K, marj, borç, nakit akışı...). crumb yoksa null döner. */
export async function fetchQuoteSummary(code) {
  await ensureCrumb();
  if (!_crumb) return null;
  const sym = toYahooSymbol(code);
  const modules = 'summaryDetail,defaultKeyStatistics,financialData,price';
  const url =
    `${CHART_HOST}/v10/finance/quoteSummary/${encodeURIComponent(sym)}` +
    `?modules=${modules}&crumb=${encodeURIComponent(_crumb)}`;
  try {
    const body = await getJson(url, _cookie ? { headers: { Cookie: _cookie } } : {});
    return body?.quoteSummary?.result?.[0] ?? null;
  } catch {
    return null;
  }
}

export { sleep };
