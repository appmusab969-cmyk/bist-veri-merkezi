// Şirket bildirimleri / haber akışı.
//
// KAP (kap.org.tr) 2024 sonrası tamamen JS-render bir SPA'ya geçti ve kararlı
// bir genel API'si kalmadı. Kırılgan scraping yerine, hisse bazında güvenilir
// ve bakım gerektirmeyen iki kaynak kullanıyoruz:
//
//   1. Yahoo Finance per-symbol RSS  (feeds.finance.yahoo.com) — şirket haber +
//      basın bültenleri; KAP özel durum açıklamaları çoğunlukla buraya da düşer.
//   2. KAP açık RSS (varsa) — genel akış, yedek.
//
// Hepsi başarısız olursa boş liste döner (uygulama "bildirim yok" gösterir).

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/122.0 Safari/537.36';

function decodeEntities(s) {
  return String(s || '')
    .replace(/<!\[CDATA\[(.*?)\]\]>/gs, '$1')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&')
    .trim();
}

function tag(block, name) {
  const m = block.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`, 'i'));
  return m ? decodeEntities(m[1]) : null;
}

function parseRssItems(xml) {
  const blocks = xml.match(/<item[\s\S]*?<\/item>/gi) || [];
  return blocks.map((b) => {
    const title = tag(b, 'title');
    const link =
      tag(b, 'link') || (b.match(/<link[^>]*href="([^"]+)"/i)?.[1] ?? null);
    const pub = tag(b, 'pubDate') || tag(b, 'updated') || tag(b, 'published');
    const desc = tag(b, 'description') || tag(b, 'summary');
    return {
      title,
      link,
      publishedAt: pub && !Number.isNaN(Date.parse(pub))
        ? new Date(pub).toISOString()
        : null,
      summary: desc ? desc.replace(/<[^>]+>/g, '').slice(0, 400) : null,
    };
  });
}

async function symbolFeed(code) {
  const sym = `${code}.IS`;
  const url =
    `https://feeds.finance.yahoo.com/rss/2.0/headline` +
    `?s=${encodeURIComponent(sym)}&region=TR&lang=tr-TR`;
  try {
    const res = await fetch(url, { headers: { 'User-Agent': UA } });
    if (!res.ok) return [];
    const xml = await res.text();
    return parseRssItems(xml).map((it) => ({ ...it, code }));
  } catch {
    return [];
  }
}

/**
 * @param {string[]} universe  Bildirim çekilecek hisse kodları
 * @returns {{ok:boolean, items:Array}}
 */
export async function fetchKapDisclosures(universe = [], { perSymbol = 6 } = {}) {
  const all = [];
  const CHUNK = 8;
  for (let i = 0; i < universe.length; i += CHUNK) {
    const part = universe.slice(i, i + CHUNK);
    const lists = await Promise.all(part.map((c) => symbolFeed(c)));
    for (const list of lists) all.push(...list.slice(0, perSymbol));
  }

  // Tarihe göre yeni -> eski
  all.sort((a, b) => {
    const ta = a.publishedAt ? Date.parse(a.publishedAt) : 0;
    const tb = b.publishedAt ? Date.parse(b.publishedAt) : 0;
    return tb - ta;
  });

  return { ok: all.length > 0, items: all };
}
