import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/quote.dart';
import '../models/stock_detail.dart';
import '../models/candle.dart';

/// Ücretsiz Yahoo Finance uç noktaları.
///
/// - `chart`         : fiyat + geçmiş seri (anahtarsız)
/// - `search`        : sembol arama (anahtarsız)
/// - `quoteSummary`  : temel veriler (F/K, marj, borç...) — cookie + crumb ister
///
/// crumb/cookie akışı tarayıcı taklididir; kişisel/eğitim amaçlıdır.
class YahooFinance {
  YahooFinance({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _chartHost = 'query1.finance.yahoo.com';
  static const _searchHost = 'query2.finance.yahoo.com';

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/122.0 Safari/537.36',
    'Accept': 'application/json',
  };

  String? _crumb;
  String? _cookie;

  static String toYahooSymbol(String input) {
    final s = input.trim().toUpperCase();
    if (s.isEmpty) return s;
    if (s.contains('.')) return s;
    return '$s.IS';
  }

  // ---------------------------------------------------------------- chart

  Future<Quote> fetchQuote(
    String symbolOrCode, {
    String range = '1d',
    String interval = '5m',
  }) async {
    final body = await _chart(symbolOrCode, range: range, interval: interval);
    return Quote.fromChartJson(body);
  }

  Future<List<Quote>> fetchQuotes(
    List<String> codes, {
    String range = '1d',
    String interval = '5m',
  }) async {
    final results = await Future.wait(
      codes.map(
        (c) => fetchQuote(c, range: range, interval: interval)
            .then<Quote?>((q) => q)
            .catchError((_) => null),
      ),
    );
    return results.whereType<Quote>().toList();
  }

  /// Mum/çizgi grafiği için tarihli seri.
  Future<List<Candle>> fetchHistory(
    String symbolOrCode, {
    required String range,
    required String interval,
  }) async {
    final body = await _chart(symbolOrCode, range: range, interval: interval);
    return Candle.listFromChartJson(body);
  }

  Future<Map<String, dynamic>> _chart(
    String symbolOrCode, {
    required String range,
    required String interval,
  }) async {
    final symbol = toYahooSymbol(symbolOrCode);
    final uri = Uri.https(_chartHost, '/v8/finance/chart/$symbol', {
      'range': range,
      'interval': interval,
      'includePrePost': 'false',
    });
    final res = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw YahooException('Fiyat alınamadı (HTTP ${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final err = body['chart']?['error'];
    if (err != null) {
      throw YahooException('Yahoo hatası: ${err['description'] ?? err}');
    }
    return body;
  }

  // ---------------------------------------------------------------- search

  Future<List<SearchHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = Uri.https(_searchHost, '/v1/finance/search', {
      'q': q,
      'quotesCount': '15',
      'newsCount': '0',
      'lang': 'tr-TR',
      'region': 'TR',
    });
    final res = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw YahooException('Arama başarısız (HTTP ${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final quotes = (body['quotes'] as List?) ?? const [];

    final hits = quotes
        .whereType<Map<String, dynamic>>()
        .where((q) => (q['symbol'] as String?)?.isNotEmpty ?? false)
        .where((q) => (q['quoteType'] as String?) == 'EQUITY')
        .map(SearchHit.fromJson)
        .toList();
    hits.sort((a, b) {
      final aBist = a.symbol.endsWith('.IS') ? 0 : 1;
      final bBist = b.symbol.endsWith('.IS') ? 0 : 1;
      return aBist.compareTo(bBist);
    });
    return hits;
  }

  // ------------------------------------------------------------ quoteSummary

  Future<void> _ensureCrumb() async {
    if (_crumb != null && _cookie != null) return;

    // dart:io HttpClient — yönlendirmeleri kendimiz izleyip
    // her adımdaki Set-Cookie başlıklarını topluyoruz.
    final io = HttpClient()
      ..userAgent = _headers['User-Agent']
      ..connectionTimeout = const Duration(seconds: 10);
    final jar = <String, String>{};

    Future<HttpClientResponse> follow(Uri url, {int depth = 0}) async {
      final req = await io.getUrl(url);
      req.followRedirects = false;
      if (jar.isNotEmpty) {
        req.headers.set(HttpHeaders.cookieHeader,
            jar.entries.map((e) => '${e.key}=${e.value}').join('; '));
      }
      final res = await req.close();
      for (final c in res.cookies) {
        jar[c.name] = c.value;
      }
      if (res.statusCode >= 300 &&
          res.statusCode < 400 &&
          res.headers.value(HttpHeaders.locationHeader) != null &&
          depth < 5) {
        await res.drain<void>();
        final loc = Uri.parse(res.headers.value(HttpHeaders.locationHeader)!);
        return follow(loc.hasScheme ? loc : url.resolveUri(loc),
            depth: depth + 1);
      }
      return res;
    }

    try {
      for (final seed in const [
        'https://fc.yahoo.com/',
        'https://finance.yahoo.com/quote/AAPL/',
      ]) {
        try {
          final r = await follow(Uri.parse(seed));
          await r.drain<void>();
        } catch (_) {}
        if (jar.isNotEmpty) break;
      }

      if (jar.isEmpty) return;
      _cookie = jar.entries.map((e) => '${e.key}=${e.value}').join('; ');

      for (final host in const [_chartHost, _searchHost]) {
        try {
          final r = await follow(
              Uri.parse('https://$host/v1/test/getcrumb'));
          final body = await r.transform(utf8.decoder).join();
          if (r.statusCode == 200 &&
              body.isNotEmpty &&
              !body.contains('<') &&
              body.length < 40) {
            _crumb = body.trim();
            return;
          }
        } catch (_) {}
      }
    } finally {
      io.close(force: true);
    }
  }

  /// Bir hissenin temel verileri. crumb alınamazsa yalnızca `chart`
  /// verisinden kısmi bir [StockDetail] döner.
  Future<StockDetail> fetchDetail(String symbolOrCode) async {
    final symbol = toYahooSymbol(symbolOrCode);
    // Gün içi değişim için 1g; grafik zaten Özet sekmesinde 5g'den çizilir.
    final quote = await fetchQuote(symbolOrCode, range: '1d', interval: '5m');

    try {
      await _ensureCrumb();
      if (_crumb == null) return StockDetail.fromQuoteOnly(quote);

      final uri = Uri.https(
        _chartHost,
        '/v10/finance/quoteSummary/$symbol',
        {
          'modules':
              'summaryDetail,defaultKeyStatistics,financialData,price',
          'crumb': _crumb!,
        },
      );
      final res = await _client
          .get(uri, headers: {
            ..._headers,
            if (_cookie != null) 'Cookie': _cookie!,
          })
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return StockDetail.fromQuoteOnly(quote);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final result = (body['quoteSummary']?['result'] as List?)?.first
          as Map<String, dynamic>?;
      if (result == null) return StockDetail.fromQuoteOnly(quote);
      return StockDetail.fromSummaryJson(quote, result);
    } catch (_) {
      return StockDetail.fromQuoteOnly(quote);
    }
  }

  void dispose() => _client.close();
}

class YahooException implements Exception {
  const YahooException(this.message);
  final String message;
  @override
  String toString() => message;
}
