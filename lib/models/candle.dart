/// Tarihli fiyat noktası (Yahoo `chart` serisinden).
class Candle {
  const Candle({
    required this.time,
    required this.close,
    this.open,
    this.high,
    this.low,
    this.volume,
  });

  final DateTime time;
  final double close;
  final double? open;
  final double? high;
  final double? low;
  final double? volume;

  static List<Candle> listFromChartJson(Map<String, dynamic> json) {
    final result = (json['chart']?['result'] as List?)?.first
        as Map<String, dynamic>?;
    if (result == null) return const [];

    final ts = (result['timestamp'] as List?)?.cast<num>() ?? const [];
    final q = (result['indicators']?['quote'] as List?)?.first
        as Map<String, dynamic>?;
    if (q == null || ts.isEmpty) return const [];

    List<double?> col(String k) =>
        ((q[k] as List?) ?? const []).map((e) => (e as num?)?.toDouble()).toList();

    final closes = col('close');
    final opens = col('open');
    final highs = col('high');
    final lows = col('low');
    final vols = col('volume');

    final out = <Candle>[];
    for (var i = 0; i < ts.length && i < closes.length; i++) {
      final c = closes[i];
      if (c == null) continue;
      out.add(Candle(
        time: DateTime.fromMillisecondsSinceEpoch(ts[i].toInt() * 1000),
        close: c,
        open: i < opens.length ? opens[i] : null,
        high: i < highs.length ? highs[i] : null,
        low: i < lows.length ? lows[i] : null,
        volume: i < vols.length ? vols[i] : null,
      ));
    }
    return out;
  }
}
