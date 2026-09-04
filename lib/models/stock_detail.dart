import 'quote.dart';

/// Bir metrik: ham değer + Yahoo'nun biçimlendirdiği metin.
class Metric {
  const Metric(this.label, this.value, {this.raw});
  final String label;
  final String value; // "48.26", "1.73T", "—"
  final double? raw;

  bool get isMissing => value == '—';
}

/// Bir hissenin temel/finansal görünümü.
class StockDetail {
  StockDetail({
    required this.quote,
    required this.longName,
    required this.sector,
    required this.industry,
    required this.currency,
    required this.summary,
    required this.ratios,
    required this.financials,
    this.recommendation,
    this.targetMeanPrice,
    this.fiftyTwoWeekLow,
    this.fiftyTwoWeekHigh,
    this.partial = false,
  });

  final Quote quote;
  final String longName;
  final String sector;
  final String industry;
  final String currency;

  /// Özet ekranı ("Fiyat & Piyasa")
  final List<Metric> summary;

  /// Rasyolar ekranı
  final List<Metric> ratios;

  /// Bilanço & sağlık ekranı
  final List<Metric> financials;

  final String? recommendation; // buy / hold / sell
  final double? targetMeanPrice;
  final double? fiftyTwoWeekLow;
  final double? fiftyTwoWeekHigh;

  /// crumb alınamadı; yalnızca fiyat verisi var.
  final bool partial;

  String get recommendationTr => switch (recommendation) {
        'strong_buy' => 'Güçlü Al',
        'buy' => 'Al',
        'hold' => 'Tut',
        'sell' => 'Sat',
        'strong_sell' => 'Güçlü Sat',
        _ => 'Veri yok',
      };

  factory StockDetail.fromQuoteOnly(Quote quote) {
    String n(double? v) => v == null ? '—' : _compact(v);
    return StockDetail(
      quote: quote,
      longName: quote.shortName,
      sector: '—',
      industry: '—',
      currency: quote.currency,
      fiftyTwoWeekLow: quote.fiftyTwoWeekLow,
      fiftyTwoWeekHigh: quote.fiftyTwoWeekHigh,
      summary: [
        Metric('Önceki kapanış', _compact(quote.previousClose)),
        Metric(
            'Gün aralığı',
            quote.dayLow != null && quote.dayHigh != null
                ? '${_compact(quote.dayLow!)} – ${_compact(quote.dayHigh!)}'
                : '—'),
        Metric(
            '52 hafta',
            quote.fiftyTwoWeekLow != null && quote.fiftyTwoWeekHigh != null
                ? '${_compact(quote.fiftyTwoWeekLow!)} – ${_compact(quote.fiftyTwoWeekHigh!)}'
                : '—'),
        Metric('Hacim', n(quote.volume)),
      ],
      ratios: const [],
      financials: const [],
      partial: true,
    );
  }

  static String _compact(double v) {
    if (v.abs() >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
    if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}Mr';
    if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}B';
    return v.toStringAsFixed(2);
  }

  factory StockDetail.fromSummaryJson(
    Quote quote,
    Map<String, dynamic> r,
  ) {
    final sd = (r['summaryDetail'] as Map<String, dynamic>?) ?? const {};
    final ks = (r['defaultKeyStatistics'] as Map<String, dynamic>?) ?? const {};
    final fd = (r['financialData'] as Map<String, dynamic>?) ?? const {};
    final pr = (r['price'] as Map<String, dynamic>?) ?? const {};

    String fmt(Map m, String key) {
      final v = m[key];
      if (v is Map && v['fmt'] != null) return v['fmt'].toString();
      if (v is num) return v.toString();
      return '—';
    }

    String pct(Map m, String key) {
      final v = m[key];
      if (v is Map && v['raw'] is num) {
        return '%${((v['raw'] as num) * 100).toStringAsFixed(2)}';
      }
      if (v is Map && v['fmt'] != null) return v['fmt'].toString();
      return '—';
    }

    double? raw(Map m, String key) {
      final v = m[key];
      if (v is Map && v['raw'] is num) return (v['raw'] as num).toDouble();
      if (v is num) return v.toDouble();
      return null;
    }

    return StockDetail(
      quote: quote,
      longName: (pr['longName'] ?? pr['shortName'] ?? quote.shortName).toString(),
      sector: (pr['sector'] ?? fd['sector'] ?? '—').toString(),
      industry: (pr['industry'] ?? '—').toString(),
      currency: (pr['currency'] ?? quote.currency).toString(),
      recommendation: fd['recommendationKey']?.toString(),
      targetMeanPrice: raw(fd, 'targetMeanPrice'),
      fiftyTwoWeekLow: raw(sd, 'fiftyTwoWeekLow'),
      fiftyTwoWeekHigh: raw(sd, 'fiftyTwoWeekHigh'),
      summary: [
        Metric('Piyasa değeri', fmt(sd, 'marketCap'), raw: raw(sd, 'marketCap')),
        Metric('Gün aralığı',
            '${fmt(sd, 'regularMarketDayLow')} – ${fmt(sd, 'regularMarketDayHigh')}'),
        Metric('52 hafta',
            '${fmt(sd, 'fiftyTwoWeekLow')} – ${fmt(sd, 'fiftyTwoWeekHigh')}'),
        Metric('Hacim', fmt(sd, 'volume'), raw: raw(sd, 'volume')),
        Metric('Ort. hacim', fmt(sd, 'averageVolume')),
        Metric('Temettü verimi', pct(sd, 'dividendYield')),
        Metric('Analist tavsiyesi',
            (fd['recommendationKey'] ?? '—').toString()),
        Metric('Hedef fiyat (ort.)', fmt(fd, 'targetMeanPrice'),
            raw: raw(fd, 'targetMeanPrice')),
      ],
      ratios: [
        Metric('F/K (12A)', fmt(sd, 'trailingPE'), raw: raw(sd, 'trailingPE')),
        Metric('F/K (ileri)', fmt(sd, 'forwardPE'), raw: raw(sd, 'forwardPE')),
        Metric('PD/DD', fmt(ks, 'priceToBook'), raw: raw(ks, 'priceToBook')),
        Metric('HBK (EPS)', fmt(ks, 'trailingEps'), raw: raw(ks, 'trailingEps')),
        Metric('PEG', fmt(ks, 'pegRatio')),
        Metric('FD/FAVÖK', fmt(ks, 'enterpriseToEbitda')),
        Metric('Net kâr marjı', pct(ks, 'profitMargins')),
        Metric('Brüt marj', pct(fd, 'grossMargins')),
        Metric('Faaliyet marjı', pct(fd, 'operatingMargins')),
        Metric('Özsermaye kârlılığı', pct(fd, 'returnOnEquity')),
        Metric('Temettü Verimi', pct(sd, 'dividendYield')),
        Metric('Payout Ratio', pct(sd, 'payoutRatio')),
      ],
      financials: [
        Metric('Toplam gelir', fmt(fd, 'totalRevenue'), raw: raw(fd, 'totalRevenue')),
        Metric('Gelir büyümesi', pct(fd, 'revenueGrowth')),
        Metric('FAVÖK', fmt(fd, 'ebitda')),
        Metric('Toplam nakit', fmt(fd, 'totalCash')),
        Metric('Toplam borç', fmt(fd, 'totalDebt')),
        Metric('Cari oran', fmt(fd, 'currentRatio'), raw: raw(fd, 'currentRatio')),
        Metric('Borç / Özsermaye', pct(fd, 'debtToEquity')),
        Metric('Hızlı oran', fmt(fd, 'quickRatio')),
        Metric('Serbest nakit akışı', fmt(fd, 'freeCashflow')),
        Metric('Faaliyet nakit akışı', fmt(fd, 'operatingCashflow')),
      ],
    );
  }
}
