import '../models/quote.dart';
import '../models/candle.dart';
import '../models/stock_detail.dart';
import 'cache_client.dart';
import 'cache_config.dart';
import 'yahoo_finance.dart';

/// Uygulamanın veri girişi. Ekranlar Yahoo'yu DEĞİL bunu çağırır.
///
///   • Önce statik önbellek (jsDelivr CDN) — ölçekli, ücretsiz, hızlı.
///   • Önbellek yoksa / yapılandırılmamışsa canlı Yahoo'ya düşer (geliştirme
///     modu ve ilk kurulum için).
///
/// Böylece 10.000 kullanıcının açılışı tek bir statik dosyaya gider.
class MarketRepository {
  MarketRepository({CacheClient? cache, YahooFinance? live})
      : _cache = cache ?? CacheClient.instance,
        _live = live ?? YahooFinance();

  final CacheClient _cache;
  final YahooFinance _live;

  bool get _cacheEnabled => CacheConfig.isConfigured;

  // -------------------------------------------------------------- endeks + liste

  /// Ana Sayfa özeti: endeks + takip/evren satırları. Tek CDN isteği.
  Future<MarketSnapshot> marketSnapshot({bool forceRefresh = false}) async {
    if (_cacheEnabled) {
      try {
        final j = await _cache.index(forceRefresh: forceRefresh);
        return MarketSnapshot.fromCacheIndex(j);
      } catch (_) {
        // yedeğe düş
      }
    }
    // Canlı yedek — yalnızca birkaç sembol (Yahoo'yu yormamak için).
    final idx = await _live
        .fetchQuote('XU100.IS')
        .then<Quote?>((q) => q)
        .catchError((_) => null);
    final stocks = await _live.fetchQuotes(const ['ASELS', 'THYAO', 'TUPRS']);
    return MarketSnapshot(
      updatedAt: DateTime.now(),
      market: idx,
      rows: [
        for (final q in stocks)
          MarketRow(
            code: q.bistCode,
            name: q.shortName,
            price: q.price,
            changePercent: q.changePercent,
            participation: false,
            partial: false,
            spark: q.spark,
          ),
      ],
      fromCache: false,
    );
  }

  // -------------------------------------------------------------- hisse detay

  Future<StockDetail> stockDetail(String code, {bool forceRefresh = false}) async {
    if (_cacheEnabled) {
      try {
        final j = await _cache.stock(code, forceRefresh: forceRefresh);
        return _detailFromCache(j);
      } catch (_) {
        // yedeğe düş
      }
    }
    return _live.fetchDetail(code);
  }

  Future<List<Candle>> history(String code,
      {String range = '1y', bool forceRefresh = false}) async {
    if (_cacheEnabled) {
      try {
        final j = await _cache.stock(code, forceRefresh: forceRefresh);
        final list = _candlesFromCache(j);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return _live.fetchHistory(code, range: range, interval: '1d');
  }

  // -------------------------------------------------------------- KAP

  Future<List<KapItem>> kapDisclosures(
      {String? code, bool forceRefresh = false}) async {
    if (!_cacheEnabled) return const [];
    try {
      final j = await _cache.kap(forceRefresh: forceRefresh);
      final items = ((j['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => KapItem.fromJson(m.cast<String, dynamic>()))
          .toList();
      if (code == null) return items;
      final up = code.toUpperCase();
      return items.where((i) => i.code == up).toList();
    } catch (_) {
      return const [];
    }
  }

  void dispose() => _live.dispose();

  // ============================================================ çeviriciler

  StockDetail _detailFromCache(Map<String, dynamic> j) {
    final d = (j['detail'] as Map).cast<String, dynamic>();
    final q = _quoteFromCache((d['quote'] as Map).cast<String, dynamic>());

    if (d['partial'] == true) {
      return StockDetail.fromQuoteOnly(q);
    }

    final ratios = (d['ratios'] as Map?)?.cast<String, dynamic>() ?? const {};
    final fin = (d['financials'] as Map?)?.cast<String, dynamic>() ?? const {};

    Metric m(Map<String, dynamic> src, String key, {bool percent = false}) {
      final v = src[key];
      if (v is num) {
        final raw = v.toDouble();
        final text = percent
            ? '%${raw.toStringAsFixed(2)}'
            : raw.toStringAsFixed(2);
        return Metric(key, text, raw: raw);
      }
      return Metric(key, '—');
    }

    final display = (d['display'] as Map?)?.cast<String, dynamic>() ?? const {};
    // Eski önbellek dosyalarında ham sayı yok; "display" içindeki biçimlendirilmiş
    // metinden ("0.11%") ayrıştırarak geriye dönük uyumluluk sağlıyoruz.
    Metric dividendYield() {
      final raw = ratios['Temettü Verimi'];
      if (raw is num) return Metric('Temettü Verimi', '%${raw.toStringAsFixed(2)}', raw: raw.toDouble());
      final text = display['dividendYield']?.toString();
      final parsed = text == null ? null : double.tryParse(text.replaceAll('%', '').trim());
      if (parsed != null) return Metric('Temettü Verimi', '%${parsed.toStringAsFixed(2)}', raw: parsed);
      return const Metric('Temettü Verimi', '—');
    }

    return StockDetail(
      quote: q,
      longName: (d['longName'] ?? q.shortName).toString(),
      sector: (d['sector'] ?? '—').toString(),
      industry: (d['industry'] ?? '—').toString(),
      currency: (d['currency'] ?? q.currency).toString(),
      recommendation: d['recommendation']?.toString(),
      targetMeanPrice: (d['targetMeanPrice'] as num?)?.toDouble(),
      fiftyTwoWeekLow: (d['fiftyTwoWeekLow'] as num?)?.toDouble(),
      fiftyTwoWeekHigh: (d['fiftyTwoWeekHigh'] as num?)?.toDouble(),
      summary: [
        if (d['display']?['marketCap'] != null)
          Metric('Piyasa değeri', d['display']['marketCap'].toString()),
        m(fin, 'Toplam gelir'),
        m(fin, 'Toplam nakit'),
        m(fin, 'Toplam borç'),
      ],
      ratios: [
        m(ratios, 'F/K (12A)'),
        m(ratios, 'F/K (ileri)'),
        m(ratios, 'PD/DD'),
        m(ratios, 'HBK (EPS)'),
        m(ratios, 'PEG'),
        m(ratios, 'FD/FAVÖK'),
        m(ratios, 'Net kâr marjı', percent: true),
        m(ratios, 'Brüt marj', percent: true),
        m(ratios, 'Faaliyet marjı', percent: true),
        m(ratios, 'Özsermaye kârlılığı', percent: true),
        dividendYield(),
        m(ratios, 'Payout Ratio', percent: true),
      ],
      financials: [
        m(fin, 'Toplam gelir'),
        m(fin, 'Gelir büyümesi', percent: true),
        m(fin, 'FAVÖK'),
        m(fin, 'Toplam nakit'),
        m(fin, 'Toplam borç'),
        m(fin, 'Cari oran'),
        m(fin, 'Borç / Özsermaye', percent: true),
        m(fin, 'Hızlı oran'),
        m(fin, 'Serbest nakit akışı'),
        m(fin, 'Faaliyet nakit akışı'),
      ],
    );
  }

  Quote _quoteFromCache(Map<String, dynamic> q) {
    final spark = ((q['spark'] as List?) ?? const [])
        .whereType<num>()
        .map((e) => e.toDouble())
        .toList();
    return Quote(
      symbol: (q['symbol'] ?? '${q['code']}.IS').toString(),
      shortName: (q['shortName'] ?? q['code'] ?? '').toString(),
      price: (q['price'] as num?)?.toDouble() ?? 0,
      previousClose: (q['previousClose'] as num?)?.toDouble() ?? 0,
      currency: (q['currency'] ?? 'TRY').toString(),
      spark: spark,
      dayLow: (q['dayLow'] as num?)?.toDouble(),
      dayHigh: (q['dayHigh'] as num?)?.toDouble(),
      fiftyTwoWeekLow: (q['fiftyTwoWeekLow'] as num?)?.toDouble(),
      fiftyTwoWeekHigh: (q['fiftyTwoWeekHigh'] as num?)?.toDouble(),
      volume: (q['volume'] as num?)?.toDouble(),
    );
  }

  List<Candle> _candlesFromCache(Map<String, dynamic> j) {
    final raw = (j['candles'] as List?) ?? const [];
    final out = <Candle>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final c = (e['c'] as num?)?.toDouble();
      if (c == null) continue;
      out.add(Candle(
        time: DateTime.fromMillisecondsSinceEpoch(
            ((e['t'] as num?)?.toInt() ?? 0) * 1000),
        close: c,
        open: (e['o'] as num?)?.toDouble(),
        high: (e['h'] as num?)?.toDouble(),
        low: (e['l'] as num?)?.toDouble(),
        volume: (e['v'] as num?)?.toDouble(),
      ));
    }
    return out;
  }
}

// ---------------------------------------------------------------- veri tipleri

class MarketSnapshot {
  MarketSnapshot({
    required this.updatedAt,
    required this.market,
    required this.rows,
    required this.fromCache,
  });

  final DateTime updatedAt;
  final Quote? market;
  final List<MarketRow> rows;
  final bool fromCache;

  factory MarketSnapshot.fromCacheIndex(Map<String, dynamic> j) {
    final mkt = j['market'] as Map?;
    return MarketSnapshot(
      updatedAt:
          DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      market: mkt == null ? null : _quoteFromIndexMarket(mkt.cast<String, dynamic>()),
      rows: ((j['stocks'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => MarketRow.fromJson(m.cast<String, dynamic>()))
          .toList(),
      fromCache: true,
    );
  }

  static Quote _quoteFromIndexMarket(Map<String, dynamic> m) => Quote(
        symbol: (m['symbol'] ?? 'XU100.IS').toString(),
        shortName: (m['shortName'] ?? 'BIST 100').toString(),
        price: (m['price'] as num?)?.toDouble() ?? 0,
        previousClose: (m['previousClose'] as num?)?.toDouble() ?? 0,
        currency: (m['currency'] ?? 'TRY').toString(),
        spark: ((m['spark'] as List?) ?? const [])
            .whereType<num>()
            .map((e) => e.toDouble())
            .toList(),
      );
}

class MarketRow {
  MarketRow({
    required this.code,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.participation,
    required this.partial,
    required this.spark,
  });

  final String code;
  final String name;
  final double price;
  final double changePercent;
  final bool participation;
  final bool partial;
  final List<double> spark;

  bool get isUp => changePercent >= 0;

  factory MarketRow.fromJson(Map<String, dynamic> m) => MarketRow(
        code: (m['code'] ?? '').toString(),
        name: (m['name'] ?? m['code'] ?? '').toString(),
        price: (m['price'] as num?)?.toDouble() ?? 0,
        changePercent: (m['changePercent'] as num?)?.toDouble() ?? 0,
        participation: m['participation'] == true,
        partial: m['partial'] == true,
        spark: ((m['spark'] as List?) ?? const [])
            .whereType<num>()
            .map((e) => e.toDouble())
            .toList(),
      );
}

class KapItem {
  KapItem({
    required this.title,
    required this.link,
    required this.publishedAt,
    required this.summary,
    required this.code,
  });

  final String title;
  final String? link;
  final DateTime? publishedAt;
  final String? summary;
  final String? code;

  factory KapItem.fromJson(Map<String, dynamic> m) => KapItem(
        title: (m['title'] ?? '').toString(),
        link: m['link']?.toString(),
        publishedAt: DateTime.tryParse(m['publishedAt']?.toString() ?? ''),
        summary: m['summary']?.toString(),
        code: m['code']?.toString(),
      );
}
