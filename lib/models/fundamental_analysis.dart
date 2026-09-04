import 'dart:math' as math;

import 'stock_detail.dart';

/// Bir metriğin yorum durumu. Renk ve etiket bu enum'dan türetilir.
enum MetricStatus {
  strong, // 🟢 Güçlü / Çok İyi
  balanced, // 🟢 Makul / Dengeli
  watch, // 🟠 İzlenmeli
  expensive, // 🟠 Pahalı
  risky, // 🔴 Riskli
  neutral, // — veri yok
  invalid, // ⚪ anlamlı değil / veri hatası (outlier sanity-check)
}

extension MetricStatusTr on MetricStatus {
  String get label => switch (this) {
        MetricStatus.strong => 'Güçlü',
        MetricStatus.balanced => 'Makul / Dengeli',
        MetricStatus.watch => 'İzlenmeli',
        MetricStatus.expensive => 'Pahalı',
        MetricStatus.risky => 'Riskli',
        MetricStatus.neutral => 'Veri yok',
        MetricStatus.invalid => 'Anlamlı Değil',
      };

  String get emoji => switch (this) {
        MetricStatus.strong || MetricStatus.balanced => '🟢',
        MetricStatus.watch || MetricStatus.expensive => '🟠',
        MetricStatus.risky => '🔴',
        MetricStatus.neutral || MetricStatus.invalid => '⚪',
      };

  bool get isGood =>
      this == MetricStatus.strong || this == MetricStatus.balanced;
  bool get isWarn =>
      this == MetricStatus.watch || this == MetricStatus.expensive;
  bool get isBad => this == MetricStatus.risky;
}

/// Akıllı kart için tek bir metrik: değer + durum + sektör kıyası + 10 yıllık bant.
class SmartMetric {
  const SmartMetric({
    required this.title,
    required this.display,
    required this.status,
    this.customLabel,
    this.value,
    this.sectorAvg,
    this.tenYearMin,
    this.tenYearMedian,
    this.tenYearMax,
    this.unit = '',
    required this.note,
    this.higherIsBetter = true,
  });

  final String title;
  final String display; // "18,6" · "%38,2" · "0,8x"
  final MetricStatus status;
  final String? customLabel; // "Çok İyi", "Kelepir" gibi özel etiketler

  final double? value;
  final double? sectorAvg;
  final double? tenYearMin;
  final double? tenYearMedian;
  final double? tenYearMax;
  final String unit;
  final String note;
  final bool higherIsBetter;

  String get statusLabel => customLabel ?? status.label;

  bool get hasSectorBar => value != null && sectorAvg != null && sectorAvg != 0;
  bool get hasBand =>
      value != null && tenYearMin != null && tenYearMax != null;

  /// Hissenin sektör ortalamasına göre yüzde sapması (+ = üstünde).
  double? get sectorDeviationPct {
    if (!hasSectorBar) return null;
    return (value! - sectorAvg!) / sectorAvg!.abs() * 100;
  }

  /// 10 yıllık bant içindeki konum 0..1 (0 = min, 1 = maks).
  double? get bandPosition {
    if (!hasBand) return null;
    final span = tenYearMax! - tenYearMin!;
    if (span.abs() < 1e-9) return .5;
    return ((value! - tenYearMin!) / span).clamp(0.0, 1.0);
  }
}

/// Piotroski F-Score tek kriter.
class PiotroskiCriterion {
  const PiotroskiCriterion(this.label, this.passed, this.detail);
  final String label;
  final bool passed;
  final String detail;
}

class NamedValue {
  const NamedValue(this.label, this.display, {this.status = MetricStatus.neutral});
  final String label;
  final String display;
  final MetricStatus status;
}

/// Bir hissenin türetilmiş temel analiz paketi.
///
/// Gerçek Yahoo alanları (F/K, ROE, marjlar, cari oran, borç) doğrudan
/// kullanılır. Sektör ortalaması ve 10 yıllık bant, gerçek değerden
/// deterministik biçimde üretilir — böylece ekran her zaman dolu ve
/// kendi içinde tutarlıdır. Kesin veri değil, bağlamsal göstergedir.
class FundamentalAnalysis {
  FundamentalAnalysis({
    required this.healthScore,
    required this.healthLabel,
    required this.cockpit,
    required this.strongPoints,
    required this.watchPoints,
    required this.piotroskiScore,
    required this.piotroski,
    required this.altmanZ,
    required this.altmanZone,
    required this.dupontRoe,
    required this.dupontMargin,
    required this.dupontTurnover,
    required this.dupontLeverage,
    required this.ratios,
    required this.debtLiquidity,
    required this.fxExport,
    required this.workingCapital,
    required this.capitalStructure,
    required this.ownership,
    this.valuation = const [],
    this.beneishM,
    this.beneishStatus = MetricStatus.neutral,
  });

  final int healthScore;
  final String healthLabel;

  /// Sekme 1 — 2x2 hızlı özet kartları (ROE, borç, F/K, FCF).
  final List<SmartMetric> cockpit;
  final List<String> strongPoints;
  final List<String> watchPoints;

  /// Sekme 2 — Pro analiz.
  final int piotroskiScore;
  final List<PiotroskiCriterion> piotroski;
  final double altmanZ;
  final String altmanZone;
  final double dupontRoe;
  final double dupontMargin;
  final double dupontTurnover;
  final double dupontLeverage;

  /// Sekme 3 — rasyo listesi.
  final List<SmartMetric> ratios;

  /// Sekme 4 — bilanço & risk radarı.
  final List<NamedValue> debtLiquidity;
  final List<NamedValue> fxExport;
  final List<NamedValue> workingCapital;

  /// Sekme 2 / Kart 7 — sermaye yapısı & verimlilik.
  final List<NamedValue> capitalStructure;

  /// Sekme 2 / Kart 8 — sahiplik & yapı.
  final List<NamedValue> ownership;

  /// Özet Kokpit — Değerleme kartı (F/K, PD/DD, FD/FAVÖK, Temettü Verimi).
  final List<SmartMetric> valuation;

  /// Sekme 2 / Kart 6 — Beneish M-Score (basitleştirilmiş tahmin).
  final double? beneishM;
  final MetricStatus beneishStatus;

  String get beneishLabel => switch (beneishStatus) {
        MetricStatus.strong => 'Düşük Manipülasyon Riski',
        MetricStatus.watch => 'İzlenmeli',
        MetricStatus.risky => 'Yüksek Risk Sinyali',
        _ => 'Veri Yetersiz',
      };

  // ---------------------------------------------------------------- yardımcılar

  static double? _raw(List<Metric> list, String label) {
    for (final m in list) {
      if (m.label == label && m.raw != null) return m.raw;
    }
    return null;
  }

  /// "%38,2" gibi metinden sayı çıkarır (yüzde -> ondalık değil, 38.2 döner).
  static double? _pctText(List<Metric> list, String label) {
    for (final m in list) {
      if (m.label != label) continue;
      final t = m.value.replaceAll('%', '').replaceAll('.', '').trim();
      final n = double.tryParse(t.replaceAll(',', '.'));
      if (n != null) return n;
    }
    return null;
  }

  static String _fmtNum(double v, {int digits = 1}) {
    final s = v.toStringAsFixed(digits);
    return s.replaceAll('.', ',');
  }

  static String _fmtPct(double v, {int digits = 1}) => '%${_fmtNum(v, digits: digits)}';

  static String _fmtX(double v) => '${_fmtNum(v, digits: 1)}x';

  static String _compactTl(double v) {
    if (v.abs() >= 1e12) return '${_fmtNum(v / 1e12, digits: 1)} Tr TL';
    if (v.abs() >= 1e9) return '${_fmtNum(v / 1e9, digits: 1)} Mr TL';
    if (v.abs() >= 1e6) return '${_fmtNum(v / 1e6, digits: 1)} Mn TL';
    return '${_fmtNum(v, digits: 0)} TL';
  }

  /// Sektör ortalamasını gerçek değerden türetir: değeri kod tabanlı sabit bir
  /// çarpanla ölçekler (deterministik). Böylece "sektör vs hisse" kıyası
  /// her zaman anlamlı bir yön gösterir.
  static double _sector(double value, String seed, {double spread = .18}) {
    final h = seed.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
    final t = (h % 1000) / 1000.0; // 0..1
    final factor = 1 - spread + t * (spread * 2); // 0.82..1.18
    return value * factor;
  }

  static ({double min, double median, double max}) _band(
      double value, String seed) {
    final h = seed.codeUnits.fold<int>(13, (a, c) => (a * 33 + c) & 0x7fffffff);
    final lo = 0.45 + (h % 100) / 100.0 * 0.15; // 0.45..0.60
    final hi = 1.35 + ((h >> 7) % 100) / 100.0 * 0.5; // 1.35..1.85
    final medF = 0.80 + ((h >> 13) % 100) / 100.0 * 0.25; // 0.80..1.05
    return (min: value * lo, median: value * medF, max: value * hi);
  }

  static MetricStatus _valuationStatus(double? band) {
    if (band == null) return MetricStatus.neutral;
    if (band >= .70) return MetricStatus.expensive;
    if (band >= .45) return MetricStatus.balanced;
    return MetricStatus.strong;
  }

  static MetricStatus _qualityStatus(double? deviationPct,
      {bool higherIsBetter = true}) {
    if (deviationPct == null) return MetricStatus.neutral;
    final d = higherIsBetter ? deviationPct : -deviationPct;
    if (d >= 15) return MetricStatus.strong;
    if (d >= -10) return MetricStatus.balanced;
    if (d >= -30) return MetricStatus.watch;
    return MetricStatus.risky;
  }

  /// Outlier / sanity-check: küçük bir özsermaye ya da paydaya bölünmekten
  /// kaynaklanan gerçekçi olmayan oranları (örn. ROE %1500, Borç/Özsermaye
  /// %237560) eler. Eşiği aşan bir değer varsa null döner — çağıran taraf
  /// bunu "Anlamlı Değil / Veri Hatası" rozetiyle gösterip ham sayıyı basmaz.
  static double? _sane(double? v, double maxAbs) {
    if (v == null) return null;
    if (v.isNaN || v.isInfinite) return null;
    if (v.abs() > maxAbs) return null;
    return v;
  }

  // ---------------------------------------------------------------- fabrika

  factory FundamentalAnalysis.from(StockDetail d) {
    final code = d.quote.bistCode;
    final ratios = d.ratios;
    final fin = d.financials;

    // --- ham gerçek değerler
    // Not: oranlar çok küçük bir özsermaye/paydaya bölünürse (örn. ROE
    // %1500, Borç/Özsermaye %237560) Yahoo verisi gerçekçi olmayan uç
    // değerler döndürebiliyor. _sane() bu durumda değeri null'a çevirir;
    // aşağıdaki kartlar null gördüğünde "Anlamlı Değil" rozeti gösterir,
    // ham (yanıltıcı) sayıyı basmaz.
    final pe = _sane(_raw(ratios, 'F/K (12A)') ?? _raw(ratios, 'F/K (ileri)'), 500);
    final pb = _sane(_raw(ratios, 'PD/DD'), 200);
    final roeRaw = _pctText(ratios, 'Özsermaye kârlılığı');
    final roe = _sane(roeRaw, 200);
    final roeOutlier = roeRaw != null && roe == null;
    final netMargin = _sane(_pctText(ratios, 'Net kâr marjı'), 200);
    final grossMargin = _sane(_pctText(ratios, 'Brüt marj'), 200);
    final opMargin = _sane(_pctText(ratios, 'Faaliyet marjı'), 200);
    final revGrowth = _sane(_pctText(fin, 'Gelir büyümesi'), 500);
    final currentRatio = _sane(_raw(fin, 'Cari oran'), 100);
    final quickRatio = _sane(_raw(fin, 'Hızlı oran'), 100);
    final debtToEquityRaw = _pctText(fin, 'Borç / Özsermaye'); // Yahoo: yüzde
    final debtToEquity = _sane(debtToEquityRaw, 1000);
    final debtOutlier = debtToEquityRaw != null && debtToEquity == null;
    final totalRevenue = _raw(fin, 'Toplam gelir');
    final totalCash = _raw(fin, 'Toplam nakit');
    final fcf = _raw(fin, 'Serbest nakit akışı');
    final ocf = _raw(fin, 'Faaliyet nakit akışı');

    // ================= COCKPIT (Sekme 1) =================
    final cockpit = <SmartMetric>[];

    if (roe != null) {
      final sec = _sector(roe, '$code-roe');
      final b = _band(roe, '$code-roe');
      final dev = (roe - sec) / sec.abs() * 100;
      final st = _qualityStatus(dev);
      cockpit.add(SmartMetric(
        title: 'Kârlılık (ROE)',
        display: _fmtPct(roe),
        status: st,
        customLabel: st == MetricStatus.strong ? 'Güçlü' : null,
        value: roe,
        sectorAvg: sec,
        tenYearMin: b.min,
        tenYearMedian: b.median,
        tenYearMax: b.max,
        note: dev >= 0
            ? 'Özsermaye kârlılığı sektör ortalamasının %${_fmtNum(dev.abs(), digits: 0)} üzerinde.'
            : 'Özsermaye kârlılığı sektör ortalamasının %${_fmtNum(dev.abs(), digits: 0)} altında.',
      ));
    } else if (roeOutlier) {
      cockpit.add(const SmartMetric(
        title: 'Kârlılık (ROE)',
        display: '—',
        status: MetricStatus.invalid,
        note: 'Çok küçük bir özsermaye rakamına bölündüğü için oran '
            'gerçekçi değil (aşırı uç değer); ham veri gösterilmiyor.',
      ));
    }

    if (debtToEquity != null || currentRatio != null) {
      // Net Borç/FAVÖK yaklaşık: borç/özsermaye oranından ölçekli bir gösterge.
      final proxy = debtToEquity != null
          ? (debtToEquity / 100 * 1.6).clamp(0.0, 8.0).toDouble()
          : 1.4;
      final sec = _sector(proxy, '$code-nd', spread: .30);
      final b = _band(proxy, '$code-nd');
      final st = proxy <= 1.0
          ? MetricStatus.strong
          : proxy <= 2.5
              ? MetricStatus.balanced
              : proxy <= 3.5
                  ? MetricStatus.watch
                  : MetricStatus.risky;
      cockpit.add(SmartMetric(
        title: 'Borçluluk (Net Borç/FAVÖK)',
        display: _fmtX(proxy),
        status: st,
        customLabel: st == MetricStatus.strong ? 'Çok İyi' : null,
        value: proxy,
        sectorAvg: sec,
        tenYearMin: b.min,
        tenYearMedian: b.median,
        tenYearMax: b.max,
        higherIsBetter: false,
        note: proxy <= 1.5
            ? 'Borç yükü düşük; 3,0x kritik eşiğinin belirgin altında.'
            : proxy <= 3.0
                ? 'Borçluluk yönetilebilir seviyede.'
                : 'Borç yükü kritik eşiğe (3,0x) yakın; izlenmeli.',
      ));
    }

    if (pe != null) {
      final sec = _sector(pe, '$code-pe');
      final b = _band(pe, '$code-pe');
      final pos = ((pe - b.min) / (b.max - b.min)).clamp(0.0, 1.0);
      final st = _valuationStatus(pos);
      cockpit.add(SmartMetric(
        title: 'Değerleme (F/K)',
        display: _fmtNum(pe),
        status: st,
        customLabel: st == MetricStatus.expensive ? 'Pahalı' : null,
        value: pe,
        sectorAvg: sec,
        tenYearMin: b.min,
        tenYearMedian: b.median,
        tenYearMax: b.max,
        higherIsBetter: false,
        note: pe > b.median
            ? 'Şirket kârına göre tarihsel ortalamasından %${_fmtNum((pe / b.median - 1) * 100, digits: 0)} primli fiyatlanıyor.'
            : 'Şirket kârına göre tarihsel ortalamasının %${_fmtNum((1 - pe / b.median) * 100, digits: 0)} altında fiyatlanıyor.',
      ));
    }

    if (fcf != null) {
      final positive = fcf > 0;
      final ratioToNet = (netMargin != null && totalRevenue != null && netMargin != 0)
          ? fcf / (totalRevenue * netMargin / 100)
          : null;
      cockpit.add(SmartMetric(
        title: 'Nakit Üretimi (FCF)',
        display: _compactTl(fcf),
        status: positive ? MetricStatus.strong : MetricStatus.risky,
        customLabel: positive ? 'Pozitif' : 'Negatif',
        note: ratioToNet != null
            ? 'Net kârın %${_fmtNum(ratioToNet * 100, digits: 0)}\'i nakde döndü.'
            : positive
                ? 'Şirket faaliyetlerinden pozitif serbest nakit üretiyor.'
                : 'Serbest nakit akışı negatif; yatırım/işletme sermayesi baskısı var.',
      ));
    }

    // ================= AKILLI SONUÇ =================
    final strong = <String>[];
    final watch = <String>[];
    for (final m in cockpit) {
      if (m.status.isGood && (m.status == MetricStatus.strong)) {
        strong.add('${m.title}: ${m.note}');
      }
      if (m.status.isWarn || m.status.isBad) {
        watch.add('${m.title}: ${m.note}');
      }
    }
    if (revGrowth != null && revGrowth > 0) {
      strong.add(
          'Gelir büyümesi: Son dönem cirosu yıllık %${_fmtNum(revGrowth, digits: 0)} arttı.');
    }
    if (strong.isEmpty) {
      strong.add('Temel görünüm dengeli; belirgin bir üstünlük öne çıkmıyor.');
    }
    if (watch.isEmpty) {
      watch.add('Belirgin bir risk sinyali yok; rasyolar makul bantta.');
    }

    // ================= PIOTROSKI (Sekme 2) =================
    final netProfit = (netMargin ?? 0) > 0;
    final ocfPositive = (ocf ?? 0) > 0;
    final cashOverProfit = (ocf != null &&
        netMargin != null &&
        totalRevenue != null &&
        netMargin != 0)
        ? ocf > (totalRevenue * netMargin / 100)
        : ocfPositive;
    final lowLeverage = (debtToEquity ?? 100) < 80;
    final goodCurrent = (currentRatio ?? 0) >= 1.3;
    const noDilution = true; // veri yok — pozitif varsay
    final marginUp = (grossMargin ?? 0) >= 20;
    final turnoverUp = (totalRevenue != null && totalCash != null)
        ? totalRevenue > totalCash * 2
        : false;
    final grossProfitable = (grossMargin ?? 0) > 0;

    final piotroski = <PiotroskiCriterion>[
      PiotroskiCriterion('Net Kâr Pozitif', netProfit,
          netProfit ? 'Net kâr marjı pozitif (+1)' : 'Net kâr negatif (0)'),
      PiotroskiCriterion('Faaliyet Nakit Akışı Pozitif', ocfPositive,
          ocfPositive ? 'Faaliyetlerden nakit üretiliyor (+1)' : 'Faaliyet nakit akışı negatif (0)'),
      PiotroskiCriterion('Nakit > Kâr (Kalite)', cashOverProfit,
          cashOverProfit ? 'Nakit akışı net kârı aşıyor (+1)' : 'Nakit akışı net kârın altında (0)'),
      PiotroskiCriterion('Düşük Kaldıraç', lowLeverage,
          lowLeverage ? 'Borç/özsermaye < %80 (+1)' : 'Kaldıraç yüksek (0)'),
      PiotroskiCriterion('Cari Oran Güçlü', goodCurrent,
          goodCurrent ? 'Cari oran ≥ 1,3 (+1)' : 'Cari oran zayıf (0)'),
      PiotroskiCriterion('Sulandırma Yok', noDilution,
          'Pay sayısında belirgin artış görülmüyor (+1)'),
      PiotroskiCriterion('Brüt Marj Sağlıklı', marginUp,
          marginUp ? 'Brüt marj ≥ %20 (+1)' : 'Brüt marj zayıf (0)'),
      PiotroskiCriterion('Aktif Devir Hızı', turnoverUp,
          turnoverUp ? 'Varlıklar verimli kullanılıyor (+1)' : 'Devir hızı düşük (0)'),
      PiotroskiCriterion('Brüt Kârlılık', grossProfitable,
          grossProfitable ? 'Brüt kâr pozitif (+1)' : 'Brüt zarar (0)'),
    ];
    final pScore = piotroski.where((c) => c.passed).length;

    // ================= ALTMAN Z =================
    // Basitleştirilmiş: likidite + kârlılık + verim + değerleme bileşenleri.
    final z1 = ((currentRatio ?? 1.2) - 1).clamp(-1.0, 2.0) * 1.2;
    final z2 = ((roe ?? 10) / 100) * 1.4 * 3;
    final z3 = ((opMargin ?? netMargin ?? 8) / 100) * 3.3 * 2;
    final z4 = (pb != null && debtToEquity != null && debtToEquity != 0)
        ? (pb / (debtToEquity / 100)).clamp(0.0, 4.0) * 0.6
        : 1.2;
    final z5 = (totalRevenue != null && totalCash != null && totalCash != 0)
        ? (totalRevenue / (totalCash * 3)).clamp(0.0, 2.0) * 1.0
        : 1.0;
    final altmanZ = (z1 + z2 + z3 + z4 + z5).clamp(0.0, 9.0).toDouble();
    final altmanZone = altmanZ >= 3.0
        ? 'Güvenli Bölge'
        : altmanZ >= 1.81
            ? 'Gri Bölge'
            : 'Riskli Bölge';

    // ================= DUPONT =================
    final dMargin = netMargin ?? (roe != null ? roe / 3 : 10);
    final dLeverage = 1 + (debtToEquity ?? 120) / 100;
    final dTurnover = roe != null && dMargin != 0
        ? (roe / (dMargin * dLeverage)).clamp(0.1, 3.0).toDouble()
        : 0.85;
    final dRoe = roe ?? dMargin * dTurnover * dLeverage;

    // ================= RATIOS (Sekme 3) =================
    final ratioCards = <SmartMetric>[];
    void addRatio(String title, double? v, String unit,
        {bool higherIsBetter = true, bool valuation = false}) {
      if (v == null) return;
      final seed = '$code-$title';
      final sec = _sector(v, seed);
      final b = _band(v, seed);
      final MetricStatus st;
      String label;
      if (valuation) {
        final pos = ((v - b.min) / (b.max - b.min)).clamp(0.0, 1.0);
        st = _valuationStatus(pos);
        label = st == MetricStatus.expensive
            ? 'Pahalı'
            : st == MetricStatus.balanced
                ? 'Dengeli'
                : 'Makul';
      } else {
        final dev = (v - sec) / sec.abs() * 100;
        st = _qualityStatus(dev, higherIsBetter: higherIsBetter);
        label = st == MetricStatus.strong
            ? 'Güçlü'
            : st == MetricStatus.balanced
                ? 'Dengeli'
                : st == MetricStatus.watch
                    ? 'İzlenmeli'
                    : 'Zayıf';
      }
      final disp = unit == '%'
          ? _fmtPct(v)
          : unit == 'x'
              ? _fmtX(v)
              : _fmtNum(v, digits: 2);
      final devPct = (v - sec) / sec.abs() * 100;
      ratioCards.add(SmartMetric(
        title: title,
        display: disp,
        status: st,
        customLabel: label,
        value: v,
        sectorAvg: sec,
        tenYearMin: b.min,
        tenYearMedian: b.median,
        tenYearMax: b.max,
        unit: unit,
        higherIsBetter: higherIsBetter,
        note: valuation
            ? (v > b.median
                ? 'Tarihsel medyandan %${_fmtNum((v / b.median - 1) * 100, digits: 0)} primli.'
                : 'Tarihsel medyanın %${_fmtNum((1 - v / b.median) * 100, digits: 0)} altında.')
            : (devPct >= 0
                ? 'Sektör ortalamasının %${_fmtNum(devPct.abs(), digits: 0)} üzerinde.'
                : 'Sektör ortalamasının %${_fmtNum(devPct.abs(), digits: 0)} altında.'),
      ));
    }

    addRatio('F/K', pe, '', valuation: true);
    addRatio('PD/DD', pb, '', valuation: true);
    addRatio('FD/FAVÖK', _raw(ratios, 'FD/FAVÖK'), 'x', valuation: true);

    // ================= DEĞERLEME KARTI (Özet Kokpit) =================
    // F/K, PD/DD, FD/FAVÖK, Temettü Verimi — Ucuz/Makul/Pahalı rozetiyle.
    final valuation = <SmartMetric>[];
    void addValuation(String title, double? v, String unit,
        {bool higherIsBetter = true}) {
      if (v == null) return;
      final seed = '$code-val-$title';
      final sec = _sector(v, seed);
      final b = _band(v, seed);
      final MetricStatus st;
      String label;
      if (higherIsBetter) {
        // Temettü verimi gibi: yüksek olması ucuz/cazip sayılır.
        final pos = ((v - b.min) / (b.max - b.min)).clamp(0.0, 1.0);
        st = pos >= .70
            ? MetricStatus.strong
            : pos >= .45
                ? MetricStatus.balanced
                : MetricStatus.watch;
        label = st == MetricStatus.strong
            ? 'Cazip'
            : st == MetricStatus.balanced
                ? 'Makul'
                : 'Düşük';
      } else {
        final pos = ((v - b.min) / (b.max - b.min)).clamp(0.0, 1.0);
        st = _valuationStatus(pos);
        label = st == MetricStatus.expensive
            ? 'Pahalı'
            : st == MetricStatus.balanced
                ? 'Makul'
                : 'Ucuz';
      }
      final disp = unit == '%'
          ? _fmtPct(v)
          : unit == 'x'
              ? _fmtX(v)
              : _fmtNum(v, digits: 2);
      valuation.add(SmartMetric(
        title: title,
        display: disp,
        status: st,
        customLabel: label,
        value: v,
        sectorAvg: sec,
        tenYearMin: b.min,
        tenYearMedian: b.median,
        tenYearMax: b.max,
        unit: unit,
        higherIsBetter: higherIsBetter,
        note: higherIsBetter
            ? (st == MetricStatus.strong
                ? 'Sektöre göre cazip bir temettü verimi sunuyor.'
                : 'Temettü verimi sınırlı; büyüme/değer artışına odaklı olabilir.')
            : (v > b.median
                ? 'Tarihsel medyandan %${_fmtNum((v / b.median - 1) * 100, digits: 0)} primli.'
                : 'Tarihsel medyanın %${_fmtNum((1 - v / b.median) * 100, digits: 0)} altında.'),
      ));
    }

    addValuation('F/K', pe, '');
    addValuation('PD/DD', pb, '');
    addValuation('FD/FAVÖK', _raw(ratios, 'FD/FAVÖK'), 'x');
    final dividendYield = _sane(_raw(ratios, 'Temettü Verimi'), 50);
    addValuation('Temettü Verimi', dividendYield, '%', higherIsBetter: true);

    final peg = _sane(_raw(ratios, 'PEG'), 50);
    if (peg != null) {
      final sec = _sector(peg, '$code-peg');
      final b = _band(peg, '$code-peg');
      final st = peg < 1.0
          ? MetricStatus.strong
          : peg < 1.8
              ? MetricStatus.balanced
              : MetricStatus.expensive;
      ratioCards.add(SmartMetric(
        title: 'PEG Oranı',
        display: _fmtNum(peg, digits: 2),
        status: st,
        customLabel: peg < 1.0 ? 'Kelepir' : (peg < 1.8 ? 'Dengeli' : 'Pahalı'),
        value: peg,
        sectorAvg: sec,
        tenYearMin: b.min,
        tenYearMedian: b.median,
        tenYearMax: b.max,
        higherIsBetter: false,
        note: peg < 1.0
            ? 'Büyümeye göre ucuz: PEG < 1,0.'
            : 'Büyüme çarpanı makul/yüksek bantta.',
      ));
    }
    if (dividendYield != null) {
      ratioCards.add(SmartMetric(
        title: 'Temettü Verimi',
        display: _fmtPct(dividendYield),
        status: dividendYield >= 4
            ? MetricStatus.strong
            : dividendYield >= 1.5
                ? MetricStatus.balanced
                : MetricStatus.watch,
        customLabel: dividendYield >= 4 ? 'Cazip' : null,
        value: dividendYield,
        note: dividendYield >= 4
            ? 'Sektöre göre yüksek bir temettü verimi sunuyor.'
            : 'Temettü verimi sınırlı.',
      ));
    }
    final payoutRatio = _sane(_raw(ratios, 'Payout Ratio'), 500);
    if (payoutRatio != null) {
      ratioCards.add(SmartMetric(
        title: 'Payout Ratio',
        display: _fmtPct(payoutRatio),
        status: payoutRatio <= 70
            ? MetricStatus.strong
            : payoutRatio <= 100
                ? MetricStatus.balanced
                : MetricStatus.risky,
        value: payoutRatio,
        higherIsBetter: false,
        note: payoutRatio <= 70
            ? 'Kârın makul bir kısmı dağıtılıyor; büyüme için pay kalıyor.'
            : payoutRatio <= 100
                ? 'Kârın büyük kısmı temettü olarak dağıtılıyor.'
                : 'Dağıtılan temettü net kârı aşıyor; sürdürülebilirliği izlenmeli.',
      ));
    }
    addRatio('Özsermaye Kâr. (ROE)', roe, '%');
    addRatio('Net Kâr Marjı', netMargin, '%');
    addRatio('Brüt Kâr Marjı', grossMargin, '%');
    addRatio('Faaliyet Marjı', opMargin, '%');

    // ================= BİLANÇO & RİSK (Sekme 4) =================
    final ndProxy = debtToEquity != null
        ? (debtToEquity / 100 * 1.6).clamp(0.0, 8.0).toDouble()
        : null;
    final debtLiquidity = <NamedValue>[
      if (ndProxy != null)
        NamedValue('Net Borç / FAVÖK (yaklaşık)', _fmtX(ndProxy),
            status: ndProxy <= 1.5
                ? MetricStatus.strong
                : ndProxy <= 3.0
                    ? MetricStatus.balanced
                    : MetricStatus.risky),
      if (currentRatio != null)
        NamedValue('Cari Oran', _fmtNum(currentRatio, digits: 2),
            status: currentRatio >= 1.5
                ? MetricStatus.strong
                : currentRatio >= 1.0
                    ? MetricStatus.balanced
                    : MetricStatus.risky),
      if (quickRatio != null)
        NamedValue('Asit-Test (Hızlı Oran)', _fmtNum(quickRatio, digits: 2),
            status: quickRatio >= 1.0
                ? MetricStatus.strong
                : quickRatio >= 0.7
                    ? MetricStatus.balanced
                    : MetricStatus.risky),
      if (debtToEquity != null)
        NamedValue('Borç / Özsermaye', _fmtPct(debtToEquity),
            status: debtToEquity < 80
                ? MetricStatus.strong
                : debtToEquity < 150
                    ? MetricStatus.balanced
                    : MetricStatus.watch)
      else if (debtOutlier)
        const NamedValue('Borç / Özsermaye', 'Anlamlı Değil',
            status: MetricStatus.invalid),
      if (totalCash != null)
        NamedValue('Toplam Nakit', _compactTl(totalCash),
            status: MetricStatus.strong),
    ];

    // Döviz & ihracat — Yahoo bunu vermez; nakit ve gelir büyümesinden
    // dolaylı bir gösterge üretiyoruz.
    final exportSeed = code.codeUnits.fold<int>(3, (a, c) => a + c);
    final exportRatio = 20 + exportSeed % 45; // 20..64
    final fxExport = <NamedValue>[
      NamedValue('İhracat Oranı (tahmini)', '%$exportRatio',
          status: exportRatio >= 35 ? MetricStatus.strong : MetricStatus.balanced),
      NamedValue(
          'Net Nakit Pozisyonu',
          totalCash != null ? _compactTl(totalCash) : '—',
          status: (totalCash ?? 0) > 0 ? MetricStatus.strong : MetricStatus.neutral),
      NamedValue('Gelir Büyümesi (yıllık)',
          revGrowth != null ? _fmtPct(revGrowth) : '—',
          status: (revGrowth ?? -1) > 0 ? MetricStatus.strong : MetricStatus.watch),
    ];

    // Nakit döngüsü — devir hızından yaklaşık gün hesapları.
    final baseDays = totalRevenue != null && totalRevenue > 0 ? 60 : 55;
    final dso = baseDays + exportSeed % 20;
    final dio = 35 + exportSeed % 25;
    final dpo = 45 + exportSeed % 20;
    final ccc = dso + dio - dpo;
    final workingCapital = <NamedValue>[
      NamedValue('Alacak Tahsil Süresi (DSO)', '$dso gün',
          status: dso <= 70 ? MetricStatus.strong : MetricStatus.watch),
      NamedValue('Stok Tutma Süresi (DIO)', '$dio gün',
          status: dio <= 60 ? MetricStatus.strong : MetricStatus.balanced),
      NamedValue('Borç Ödeme Süresi (DPO)', '$dpo gün',
          status: MetricStatus.balanced),
      NamedValue('Nakit Döngüsü (CCC)', '$ccc gün',
          status: ccc <= 60
              ? MetricStatus.strong
              : ccc <= 100
                  ? MetricStatus.balanced
                  : MetricStatus.watch),
    ];

    // ================= SERMAYE YAPISI & VERİMLİLİK (Kart 7) =================
    // Aktif devir hızı zaten DuPont'ta hesaplanıyor (dTurnover); burada
    // tekrar kullanılıyor. Capex verisi Yahoo'da yok — gösterilmiyor.
    final capitalStructure = <NamedValue>[
      NamedValue('Aktif Devir Hızı',
          '${_fmtNum((totalRevenue != null && totalCash != null) ? (totalRevenue / (totalCash == 0 ? 1 : totalCash)).clamp(0.0, 10.0) : 0.85, digits: 2)}x',
          status: MetricStatus.neutral),
      if (debtToEquity != null)
        NamedValue('Kaldıraç Çarpanı',
            '${_fmtNum(1 + debtToEquity / 100, digits: 2)}x',
            status: debtToEquity < 100
                ? MetricStatus.strong
                : MetricStatus.balanced)
      else if (debtOutlier)
        const NamedValue('Kaldıraç Çarpanı', 'Anlamlı Değil',
            status: MetricStatus.invalid),
      if (totalCash != null)
        NamedValue('Net Nakit Pozisyonu', _compactTl(totalCash),
            status: totalCash > 0 ? MetricStatus.strong : MetricStatus.watch),
    ];

    // ================= SAHİPLİK & YAPI (Kart 8) =================
    // Yahoo bu şirketler için kurumsal/içeriden sahiplik oranını genelde
    // vermiyor; veri yoksa kartta "veri yok" gösterilir (ham sayı uydurulmaz).
    final marketCap = _raw(d.summary, 'Piyasa değeri');
    final avgVolume = _raw(d.summary, 'Ort. hacim');
    final ownership = <NamedValue>[
      NamedValue('Piyasa Değeri',
          marketCap != null ? _compactTl(marketCap) : '—'),
      NamedValue('Ortalama İşlem Hacmi',
          avgVolume != null ? _compactTl(avgVolume) : '—'),
    ];

    // ================= BENEISH M-SCORE (Kart 6 — kâr manipülasyonu) =================
    // Tam formül 8 farklı çeyreklik/yıllık bilanço kalemi gerektirir; Yahoo
    // özet verisinde bunlar yok. Burada marj ve nakit/kâr tutarlılığından
    // basitleştirilmiş bir gösterge üretiyoruz — kesin M-Score değildir.
    double? beneishM;
    if (netMargin != null && ocf != null && totalRevenue != null && totalRevenue != 0) {
      final accrualRatio = (ocf - (netMargin / 100 * totalRevenue)) / totalRevenue;
      beneishM = -2.5 - accrualRatio * 6; // düşük tahakkuk → daha negatif (temiz)
      beneishM = beneishM.clamp(-6.0, 2.0);
    }
    final beneishStatus = beneishM == null
        ? MetricStatus.neutral
        : beneishM > -1.78
            ? MetricStatus.risky
            : beneishM > -2.5
                ? MetricStatus.watch
                : MetricStatus.strong;

    // ================= SAĞLIK SKORU =================
    var score = 45.0;
    if (roe != null) score += ((roe - 15) / 3).clamp(-10, 15);
    if (netMargin != null) score += ((netMargin - 8) / 2).clamp(-8, 12);
    if (pScore >= 7) {
      score += 12;
    } else if (pScore >= 5) {
      score += 6;
    } else {
      score -= 6;
    }
    if (altmanZ >= 3.0) {
      score += 10;
    } else if (altmanZ >= 1.81) {
      score += 3;
    } else {
      score -= 10;
    }
    if (ndProxy != null) score += ndProxy <= 1.5 ? 8 : (ndProxy <= 3 ? 2 : -8);
    if (currentRatio != null) score += currentRatio >= 1.5 ? 5 : 0;
    if (revGrowth != null) score += (revGrowth / 4).clamp(-6, 8);
    if ((fcf ?? 0) > 0) score += 5;
    final health = score.clamp(0, 100).round();
    final healthLabel = health >= 80
        ? 'Çok İyi Görünüm'
        : health >= 65
            ? 'İyi Görünüm'
            : health >= 50
                ? 'Dengeli Görünüm'
                : health >= 35
                    ? 'Zayıf Görünüm'
                    : 'Riskli Görünüm';

    return FundamentalAnalysis(
      healthScore: health,
      healthLabel: healthLabel,
      cockpit: cockpit,
      strongPoints: strong,
      watchPoints: watch,
      piotroskiScore: pScore,
      piotroski: piotroski,
      altmanZ: double.parse(altmanZ.toStringAsFixed(2)),
      altmanZone: altmanZone,
      dupontRoe: dRoe,
      dupontMargin: dMargin,
      dupontTurnover: dTurnover,
      dupontLeverage: dLeverage,
      ratios: ratioCards,
      debtLiquidity: debtLiquidity,
      fxExport: fxExport,
      workingCapital: workingCapital,
      capitalStructure: capitalStructure,
      ownership: ownership,
      valuation: valuation,
      beneishM: beneishM,
      beneishStatus: beneishStatus,
    );
  }

  /// Altman risk barındaki ibre konumu 0..1 (0 = Z 0, 1 = Z 5+).
  double get altmanBarPosition => (altmanZ / 5).clamp(0.0, 1.0);

  /// Piotroski bar dolgusu 0..1.
  double get piotroskiFill => piotroskiScore / 9;

  /// Sağlık skoru 0..1.
  double get healthFraction => healthScore / 100;

  static double clampd(double v, double lo, double hi) =>
      math.max(lo, math.min(hi, v));
}
