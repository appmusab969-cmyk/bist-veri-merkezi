import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quote.dart';

/// Ücretsiz, anahtarsız Yahoo Finance uç noktaları.
///
/// - `chart`  : fiyat + geçmiş seri
/// - `search` : sembol arama
///
/// Not: Bu uç noktalar resmi olarak dokümante edilmemiştir; kişisel/eğitim
/// amaçlı kullanım içindir. Ticari kullanımda lisanslı bir sağlayıcı gerekir.
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

  /// BIST kodunu Yahoo sembolüne çevirir: "ASELS" -> "ASELS.IS".
  static String toYahooSymbol(String input) {
    final s = input.trim().toUpperCase();
    if (s.isEmpty) return s;
    if (s.contains('.')) return s; // zaten sonek var
    return '$s.IS';
  }

  /// Tek bir hissenin anlık özetini getirir.
  Future<Quote> fetchQuote(
    String symbolOrCode, {
    String range = '1d',
    String interval = '5m',
  }) async {
    final symbol = toYahooSymbol(symbolOrCode);
    final uri = Uri.https(_chartHost, '/v8/finance/chart/$symbol', {
      'range': range,
      'interval': interval,
      'includePrePost': 'false',
    });

    final res = await _client.get(uri, headers: _headers).timeout(
          const Duration(seconds: 12),
        );
    if (res.statusCode != 200) {
      throw YahooException('Fiyat alınamadı (HTTP ${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final err = body['chart']?['error'];
    if (err != null) {
      throw YahooException('Yahoo hatası: ${err['description'] ?? err}');
    }
    return Quote.fromChartJson(body);
  }

  /// Birden çok hisseyi paralel getirir; hatalı olanları atlar.
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

  /// Sembol arama. BIST sonuçlarını öne alır.
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

    final res = await _client.get(uri, headers: _headers).timeout(
          const Duration(seconds: 12),
        );
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

  void dispose() => _client.close();
}

class YahooException implements Exception {
  const YahooException(this.message);
  final String message;
  @override
  String toString() => message;
}
