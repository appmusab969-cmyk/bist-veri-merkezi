import '../models/candle.dart';

enum TrendDirection { up, down, flat }

enum SignalKind {
  smaCrossUp, // fiyat 20 günlük ortalamayı yukarı kesti
  smaCrossDown, // aşağı kesti
  aboveSma, // ortalamanın üzerinde tutunuyor
  belowSma, // ortalamanın altında
  breakoutHigh, // son 20 günün en yükseğini aştı
  breakdownLow, // son 20 günün en düşüğünü kırdı
  none,
}

/// Ücretsiz, saf hesaplama ile basit teknik değerlendirme.
/// LLM veya dış servis kullanmaz — yalnızca fiyat serisi.
class TechnicalSignal {
  const TechnicalSignal({
    required this.kind,
    required this.trend,
    required this.confidence,
    required this.lastClose,
    required this.sma20,
    required this.sma50,
    required this.periodHigh,
    required this.periodLow,
    required this.changePercent20d,
  });

  final SignalKind kind;
  final TrendDirection trend;
  final int confidence; // 0..100
  final double lastClose;
  final double sma20;
  final double sma50;
  final double periodHigh;
  final double periodLow;
  final double changePercent20d;

  bool get isBullish =>
      kind == SignalKind.smaCrossUp ||
      kind == SignalKind.aboveSma ||
      kind == SignalKind.breakoutHigh;

  String get title => switch (kind) {
        SignalKind.smaCrossUp => '20 günlük ortalama yukarı kesildi',
        SignalKind.smaCrossDown => '20 günlük ortalama aşağı kesildi',
        SignalKind.aboveSma => 'Ortalamanın üzerinde tutunuyor',
        SignalKind.belowSma => 'Ortalamanın altında seyrediyor',
        SignalKind.breakoutHigh => 'Son 20 günün zirvesini aştı',
        SignalKind.breakdownLow => 'Son 20 günün dibini kırdı',
        SignalKind.none => 'Belirgin sinyal yok',
      };

  String get trendTr => switch (trend) {
        TrendDirection.up => 'Yükseliş',
        TrendDirection.down => 'Düşüş',
        TrendDirection.flat => 'Yatay',
      };

  static double _sma(List<double> v, int n) {
    if (v.length < n) return v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
    final slice = v.sublist(v.length - n);
    return slice.reduce((a, b) => a + b) / n;
  }

  /// Günlük kapanış serisinden hesaplar (en az ~25 nokta beklenir).
  static TechnicalSignal fromCandles(List<Candle> candles) {
    final closes = candles.map((c) => c.close).toList();
    if (closes.length < 5) {
      return TechnicalSignal(
        kind: SignalKind.none,
        trend: TrendDirection.flat,
        confidence: 0,
        lastClose: closes.isEmpty ? 0 : closes.last,
        sma20: 0,
        sma50: 0,
        periodHigh: 0,
        periodLow: 0,
        changePercent20d: 0,
      );
    }

    final last = closes.last;
    final prev = closes[closes.length - 2];
    final sma20 = _sma(closes, 20);
    final sma50 = _sma(closes, 50);
    final sma20Prev = _sma(closes.sublist(0, closes.length - 1), 20);

    final window = closes.length >= 21
        ? closes.sublist(closes.length - 21, closes.length - 1)
        : closes.sublist(0, closes.length - 1);
    final periodHigh = window.reduce((a, b) => a > b ? a : b);
    final periodLow = window.reduce((a, b) => a < b ? a : b);

    final ref20 = closes.length >= 21 ? closes[closes.length - 21] : closes.first;
    final change20 = ref20 == 0 ? 0.0 : (last - ref20) / ref20 * 100;

    final trend = change20 > 3
        ? TrendDirection.up
        : change20 < -3
            ? TrendDirection.down
            : TrendDirection.flat;

    SignalKind kind;
    if (prev <= sma20Prev && last > sma20) {
      kind = SignalKind.smaCrossUp;
    } else if (prev >= sma20Prev && last < sma20) {
      kind = SignalKind.smaCrossDown;
    } else if (last > periodHigh) {
      kind = SignalKind.breakoutHigh;
    } else if (last < periodLow) {
      kind = SignalKind.breakdownLow;
    } else if (last > sma20) {
      kind = SignalKind.aboveSma;
    } else if (last < sma20) {
      kind = SignalKind.belowSma;
    } else {
      kind = SignalKind.none;
    }

    // Güven: trend + ortalama diziliş + momentum büyüklüğü
    var score = 40;
    if ((kind == SignalKind.smaCrossUp || kind == SignalKind.breakoutHigh) &&
        trend == TrendDirection.up) {
      score += 25;
    }
    if ((kind == SignalKind.smaCrossDown || kind == SignalKind.breakdownLow) &&
        trend == TrendDirection.down) {
      score += 25;
    }
    if (sma20 > sma50 && last > sma20) score += 15;
    if (sma20 < sma50 && last < sma20) score += 15;
    score += (change20.abs().clamp(0, 20)).round();
    score = score.clamp(0, 100);

    return TechnicalSignal(
      kind: kind,
      trend: trend,
      confidence: score,
      lastClose: last,
      sma20: sma20,
      sma50: sma50,
      periodHigh: periodHigh,
      periodLow: periodLow,
      changePercent20d: change20.toDouble(),
    );
  }
}
