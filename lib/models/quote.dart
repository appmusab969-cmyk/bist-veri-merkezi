/// Bir hisseye ait anlık fiyat özeti (Yahoo Finance `chart` API'sinden).
class Quote {
  const Quote({
    required this.symbol,
    required this.shortName,
    required this.price,
    required this.previousClose,
    required this.currency,
    this.spark = const [],
  });

  final String symbol; // "ASELS.IS"
  final String shortName;
  final double price;
  final double previousClose;
  final String currency;

  /// Gün içi / son dönem kapanış serisi (mini grafik için).
  final List<double> spark;

  double get change => price - previousClose;
  double get changePercent =>
      previousClose == 0 ? 0 : (change / previousClose) * 100;
  bool get isUp => change >= 0;

  /// "ASELS.IS" -> "ASELS"
  String get bistCode =>
      symbol.endsWith('.IS') ? symbol.substring(0, symbol.length - 3) : symbol;

  factory Quote.fromChartJson(Map<String, dynamic> json) {
    final result = (json['chart']?['result'] as List?)?.first
        as Map<String, dynamic>?;
    if (result == null) {
      throw const FormatException('Yahoo yanıtı boş');
    }
    final meta = result['meta'] as Map<String, dynamic>;

    final closes = <double>[];
    final indicators = result['indicators']?['quote'] as List?;
    if (indicators != null && indicators.isNotEmpty) {
      final raw = (indicators.first as Map<String, dynamic>)['close'] as List?;
      if (raw != null) {
        for (final v in raw) {
          if (v is num) closes.add(v.toDouble());
        }
      }
    }

    final price = (meta['regularMarketPrice'] as num?)?.toDouble() ??
        (closes.isNotEmpty ? closes.last : 0.0);
    final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble() ??
        (meta['previousClose'] as num?)?.toDouble() ??
        price;

    return Quote(
      symbol: meta['symbol'] as String? ?? '',
      shortName: (meta['shortName'] ?? meta['longName'] ?? meta['symbol'] ?? '')
          .toString(),
      price: price,
      previousClose: prevClose,
      currency: meta['currency'] as String? ?? 'TRY',
      spark: closes,
    );
  }
}

/// Arama sonucu (Yahoo `search` API'si).
class SearchHit {
  const SearchHit({
    required this.symbol,
    required this.name,
    required this.exchange,
  });

  final String symbol;
  final String name;
  final String exchange;

  String get bistCode =>
      symbol.endsWith('.IS') ? symbol.substring(0, symbol.length - 3) : symbol;

  factory SearchHit.fromJson(Map<String, dynamic> json) => SearchHit(
        symbol: json['symbol'] as String? ?? '',
        name: (json['shortname'] ?? json['longname'] ?? '').toString(),
        exchange: json['exchDisp'] as String? ?? '',
      );
}
