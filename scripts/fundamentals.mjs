// Yahoo quoteSummary sonucunu, uygulamanın beklediği düz "detail" şekline çevirir.
// Hesaplama YOK — sadece güvenilir alanları isimlendirip normalize eder.
// (Türetilmiş sektör/10Y bantları ve skorlar uygulamada, istemci tarafında üretilir.)

const num = (m, k) => {
  const v = m?.[k];
  if (v && typeof v === 'object' && typeof v.raw === 'number') return v.raw;
  if (typeof v === 'number') return v;
  return null;
};
const fmt = (m, k) => {
  const v = m?.[k];
  if (v && typeof v === 'object' && v.fmt != null) return String(v.fmt);
  if (typeof v === 'number') return String(v);
  return null;
};
const pct = (m, k) => {
  const r = num(m, k);
  return r == null ? null : +(r * 100).toFixed(2); // 0.382 -> 38.2
};

/**
 * @param {object} summary  Yahoo quoteSummary.result[0]
 * @param {object} quote    quoteFromChart(...) çıktısı
 */
export function normalizeDetail(summary, quote) {
  if (!summary) {
    return { code: quote.code, partial: true, quote };
  }
  const sd = summary.summaryDetail || {};
  const ks = summary.defaultKeyStatistics || {};
  const fd = summary.financialData || {};
  const pr = summary.price || {};

  return {
    code: quote.code,
    partial: false,
    quote,
    longName: pr.longName || pr.shortName || quote.shortName,
    sector: pr.sector || fd.sector || '—',
    industry: pr.industry || '—',
    currency: pr.currency || quote.currency,
    recommendation: fd.recommendationKey ?? null,
    targetMeanPrice: num(fd, 'targetMeanPrice'),
    fiftyTwoWeekLow: num(sd, 'fiftyTwoWeekLow'),
    fiftyTwoWeekHigh: num(sd, 'fiftyTwoWeekHigh'),

    // Rasyolar (uygulamadaki Türkçe etiketlerle birebir)
    ratios: {
      'F/K (12A)': num(sd, 'trailingPE'),
      'F/K (ileri)': num(sd, 'forwardPE'),
      'PD/DD': num(ks, 'priceToBook'),
      'HBK (EPS)': num(ks, 'trailingEps'),
      PEG: num(ks, 'pegRatio'),
      'FD/FAVÖK': num(ks, 'enterpriseToEbitda'),
      'Net kâr marjı': pct(ks, 'profitMargins'),
      'Brüt marj': pct(fd, 'grossMargins'),
      'Faaliyet marjı': pct(fd, 'operatingMargins'),
      'Özsermaye kârlılığı': pct(fd, 'returnOnEquity'),
      'Temettü Verimi': pct(sd, 'dividendYield'),
      'Payout Ratio': pct(sd, 'payoutRatio'),
    },

    // Bilanço / nakit akışı
    financials: {
      'Toplam gelir': num(fd, 'totalRevenue'),
      'Gelir büyümesi': pct(fd, 'revenueGrowth'),
      FAVÖK: num(fd, 'ebitda'),
      'Toplam nakit': num(fd, 'totalCash'),
      'Toplam borç': num(fd, 'totalDebt'),
      'Cari oran': num(fd, 'currentRatio'),
      'Borç / Özsermaye': pct(fd, 'debtToEquity'),
      'Hızlı oran': num(fd, 'quickRatio'),
      'Serbest nakit akışı': num(fd, 'freeCashflow'),
      'Faaliyet nakit akışı': num(fd, 'operatingCashflow'),
    },

    // Ham gösterim metinleri (isteğe bağlı, UI'da "48.26B" gibi göstermek için)
    display: {
      marketCap: fmt(sd, 'marketCap'),
      volume: fmt(sd, 'volume'),
      averageVolume: fmt(sd, 'averageVolume'),
      dividendYield: fmt(sd, 'dividendYield'),
    },
  };
}
