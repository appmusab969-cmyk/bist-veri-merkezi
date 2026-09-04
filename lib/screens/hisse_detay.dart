import 'package:flutter/material.dart';

import '../models/stock_detail.dart';
import '../models/candle.dart';
import '../models/fundamental_analysis.dart';
import '../services/market_repository.dart';
import '../services/format.dart';
import '../services/technical.dart';
import '../services/app_settings.dart';
import '../widgets/sparkline.dart';
import '../widgets/health_ring.dart';
import '../widgets/smart_card.dart';
import '../widgets/tradingview_chart.dart';

/// Herhangi bir BIST hissesi için genel detay ekranı.
/// Sekmeler: Özet Kokpit · Pro Analiz · Rasyolar & 10Y · Bilanço & Risk
class HisseDetayScreen extends StatefulWidget {
  const HisseDetayScreen({super.key, required this.code, this.name});

  final String code; // "ASELS"
  final String? name;

  @override
  State<HisseDetayScreen> createState() => _HisseDetayScreenState();
}

class _HisseDetayScreenState extends State<HisseDetayScreen> {
  final _repo = MarketRepository();
  late Future<_DetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  Future<_DetailBundle> _load() async {
    final detail = await _repo.stockDetail(widget.code);
    List<Candle> daily = const [];
    try {
      daily = await _repo.history(widget.code);
    } catch (_) {}
    final signal = daily.isNotEmpty ? TechnicalSignal.fromCandles(daily) : null;
    final analysis =
        detail.partial ? null : FundamentalAnalysis.from(detail);
    final kap = await _repo.kapDisclosures(code: widget.code);
    return _DetailBundle(detail, daily, signal, analysis, kap);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: FutureBuilder<_DetailBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return SafeArea(
                child: _CenteredNote(
                  icon: Icons.cloud_off_rounded,
                  title: 'Veri alınamadı',
                  message: '${snap.error ?? 'Bilinmeyen hata'}',
                  onRetry: () => setState(() => _future = _load()),
                ),
              );
            }
            final b = snap.data!;
            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _StickyHeader(bundle: b),
                  Container(
                    color: colors.surfaceContainer,
                    child: const TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: 'Özet Kokpit'),
                        Tab(text: 'Grafik'),
                        Tab(text: 'Pro Analiz'),
                        Tab(text: 'Bilanço & KAP'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: b.detail.partial
                        ? _PartialNote(padded: true)
                        : TabBarView(
                            children: [
                              _CockpitTab(bundle: b),
                              _ChartTab(code: b.detail.quote.bistCode, bundle: b),
                              _ProAnalysisTab(analysis: b.analysis!),
                              _BilancoKapTab(analysis: b.analysis!, bundle: b),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailBundle {
  _DetailBundle(
      this.detail, this.daily, this.signal, this.analysis, this.kap);
  final StockDetail detail;
  final List<Candle> daily;
  final TechnicalSignal? signal;
  final FundamentalAnalysis? analysis;
  final List<KapItem> kap;
}

// ---------------------------------------------------------------- Sekme: Grafik

class _ChartTab extends StatelessWidget {
  const _ChartTab({required this.code, required this.bundle});
  final String code;
  final _DetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TradingViewChart(
          code: code,
          height: 420,
          fallback: bundle.daily.isNotEmpty
              ? SizedBox(
                  height: 200,
                  child: Sparkline(
                    values: bundle.daily.map((c) => c.close).toList(),
                    color: colors.primary,
                    fill: true,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          'Grafik TradingView ücretsiz widget\'ından gelir; fiyat ve '
          'indikatörler doğrudan TradingView tarafından hesaplanır. '
          'Sunucumuza yük binmez.',
          style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Sticky Header

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({required this.bundle});
  final _DetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final d = bundle.detail;
    final q = d.quote;
    final changeColor = q.isUp ? colors.primary : colors.error;
    final participation = isParticipationStock(d.quote.bistCode);
    final a = bundle.analysis;

    return Container(
      color: colors.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Text(d.quote.bistCode,
                  style: text.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: .5)),
              const Spacer(),
              if (a != null)
                Row(
                  children: [
                    HealthRing(score: a.healthScore),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 74),
                      child: Text(a.healthLabel,
                          style: text.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              height: 1.1)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatPrice(q.price),
                  style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900, color: colors.onSurface)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${formatPercent(q.changePercent)}  (${formatPrice(q.change)})',
                  style: text.bodyMedium?.copyWith(
                      color: changeColor, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(d.longName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (participation)
                _Badge(
                  icon: Icons.verified_user_rounded,
                  label: 'Katılım Endeksine Uygun',
                  color: colors.primary,
                ),
              _Badge(
                icon: Icons.schedule_rounded,
                label: formatUpdatedNow(),
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: text.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Sekme 1: Kokpit

class _CockpitTab extends StatelessWidget {
  const _CockpitTab({required this.bundle});
  final _DetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final a = bundle.analysis!;
    final q = bundle.detail.quote;
    final changeColor = q.isUp ? colors.primary : colors.error;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (q.spark.length > 2) ...[
          SizedBox(
            height: 80,
            child: Sparkline(values: q.spark, color: changeColor, fill: true),
          ),
          const SizedBox(height: 16),
        ],
        Text('Hızlı Özet',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        _Grid2x2(cards: a.cockpit),
        if (a.valuation.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SectionHeading(icon: Icons.sell_rounded, title: 'Değerleme'),
          const SizedBox(height: 8),
          _ValuationCard(items: a.valuation),
        ],
        const SizedBox(height: 18),
        _SmartConclusionCard(analysis: a, detail: bundle.detail),
        const SizedBox(height: 12),
        Text(
          'Sektör ortalaması ve 10 yıllık bant, mevcut Yahoo verisinden '
          'türetilmiş bağlamsal göstergelerdir; kesin tarihsel seri değildir. '
          'Yatırım tavsiyesi değildir.',
          style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Grid2x2 extends StatelessWidget {
  const _Grid2x2({required this.cards});
  final List<SmartMetric> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: SmartCard(metric: cards[i], compact: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < cards.length
                        ? SmartCard(metric: cards[i + 1], compact: true)
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ValuationCard extends StatelessWidget {
  const _ValuationCard({required this.items});
  final List<SmartMetric> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(m.title,
                        style: text.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  Text(m.display,
                      style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface)),
                  const SizedBox(width: 8),
                  StatusBadge(status: m.status, label: m.customLabel),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SmartConclusionCard extends StatelessWidget {
  const _SmartConclusionCard({required this.analysis, required this.detail});
  final FundamentalAnalysis analysis;
  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget line(IconData icon, Color color, String head, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: text.bodySmall
                        ?.copyWith(color: colors.onSurface, height: 1.4),
                    children: [
                      TextSpan(
                          text: '$head  ',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w800)),
                      TextSpan(text: body),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BU EKRAN NE SÖYLÜYOR?',
              style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          for (final s in analysis.strongPoints.take(2))
            line(Icons.check_circle_rounded, colors.primary, 'Güçlü Yön:',
                _tail(s)),
          for (final w in analysis.watchPoints.take(2))
            line(Icons.warning_amber_rounded, colors.tertiary, 'İzlenecek:',
                _tail(w)),
          if (detail.recommendation != null)
            line(Icons.groups_rounded, colors.primary, 'Analist Konsensüsü:',
                '${detail.recommendationTr}'
                '${detail.targetMeanPrice != null ? ' · ortalama hedef ${formatPrice(detail.targetMeanPrice!)}' : ''}.'),
        ],
      ),
    );
  }

  String _tail(String s) {
    final i = s.indexOf(': ');
    return i >= 0 ? s.substring(i + 2) : s;
  }
}

// ---------------------------------------------------------------- Sekme 2: Pro

class _ProAnalysisTab extends StatelessWidget {
  const _ProAnalysisTab({required this.analysis});
  final FundamentalAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final a = analysis;

    const valuationTitles = {
      'F/K',
      'PD/DD',
      'FD/FAVÖK',
      'PEG Oranı',
      'Temettü Verimi',
      'Payout Ratio',
    };
    const profitabilityTitles = {
      'Özsermaye Kâr. (ROE)',
      'Net Kâr Marjı',
      'Brüt Kâr Marjı',
      'Faaliyet Marjı',
    };
    final valuationMetrics =
        a.ratios.where((m) => valuationTitles.contains(m.title)).toList();
    final profitabilityMetrics = a.ratios
        .where((m) => profitabilityTitles.contains(m.title))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pro Analiz — 9 Kart',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text('Değerleme → Karlılık → Borç → Büyüme → Nakit → Kalite → '
            'Sermaye Yapısı → Sahiplik → Döviz',
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 14),

        // ---- Kart 1: Değerleme ----
        if (valuationMetrics.isNotEmpty) ...[
          _SectionHeading(
              icon: Icons.sell_rounded, title: '1 · Değerleme'),
          const SizedBox(height: 8),
          for (final m in valuationMetrics) ...[
            SmartCard(metric: m),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],

        // ---- Kart 2: Karlılık ----
        _SectionHeading(icon: Icons.trending_up_rounded, title: '2 · Karlılık'),
        const SizedBox(height: 8),
        for (final m in profitabilityMetrics) ...[
          SmartCard(metric: m),
          const SizedBox(height: 10),
        ],
        _DupontCard(analysis: a),
        const SizedBox(height: 14),

        // ---- Kart 3: Borç & Likidite ----
        _SectionHeading(
            icon: Icons.account_balance_rounded, title: '3 · Borç & Likidite'),
        const SizedBox(height: 8),
        _NamedListCard(
          title: 'Borç & Likidite',
          icon: Icons.account_balance_rounded,
          items: a.debtLiquidity,
          hideTitle: true,
        ),
        const SizedBox(height: 14),

        // ---- Kart 4: Büyüme ----
        _SectionHeading(icon: Icons.show_chart_rounded, title: '4 · Büyüme'),
        const SizedBox(height: 8),
        _NamedListCard(
          title: 'Büyüme',
          icon: Icons.show_chart_rounded,
          items: a.fxExport
              .where((v) => v.label.contains('Gelir Büyümesi'))
              .toList(),
          hideTitle: true,
        ),
        const SizedBox(height: 14),

        // ---- Kart 5: Nakit Akışı Kalitesi ----
        _SectionHeading(
            icon: Icons.sync_rounded, title: '5 · Nakit Akışı Kalitesi'),
        const SizedBox(height: 8),
        _NamedListCard(
          title: 'Nakit Döngüsü (İşletme Sermayesi)',
          icon: Icons.sync_rounded,
          items: a.workingCapital,
          hideTitle: true,
        ),
        const SizedBox(height: 14),

        // ---- Kart 6: Kalite / Risk Skorları ----
        _SectionHeading(
            icon: Icons.verified_rounded, title: '6 · Kalite / Risk Skorları'),
        const SizedBox(height: 8),
        _ScoreCard(
          title: 'Piotroski F-Score',
          big: '${a.piotroskiScore} / 9',
          status: a.piotroskiScore >= 7
              ? MetricStatus.strong
              : a.piotroskiScore >= 4
                  ? MetricStatus.balanced
                  : MetricStatus.risky,
          label: a.piotroskiScore >= 7
              ? 'Çok Güçlü'
              : a.piotroskiScore >= 4
                  ? 'Orta'
                  : 'Zayıf',
          child: Column(
            children: [
              const SizedBox(height: 8),
              _FillBar(fraction: a.piotroskiFill, color: colors.primary),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text('9 kriter kontrol listesi',
                    style: text.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                children: [
                  for (final c in a.piotroski)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            c.passed
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 15,
                            color: c.passed ? colors.primary : colors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(c.detail,
                                style: text.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Altman Z
        _ScoreCard(
          title: 'Altman Z-Score (İflas / Sıkıntı Riski)',
          big: a.altmanZ.toStringAsFixed(2).replaceAll('.', ','),
          status: a.altmanZ >= 3.0
              ? MetricStatus.strong
              : a.altmanZ >= 1.81
                  ? MetricStatus.watch
                  : MetricStatus.risky,
          label: a.altmanZone,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _ZoneBar(position: a.altmanBarPosition),
          ),
        ),
        const SizedBox(height: 12),
        // Beneish M-Score
        if (a.beneishM != null)
          _ScoreCard(
            title: 'Beneish M-Score (Kâr Manipülasyonu Tespiti)',
            big: a.beneishM!.toStringAsFixed(2).replaceAll('.', ','),
            status: a.beneishStatus,
            label: a.beneishLabel,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Eşik: M > -1,78 manipülasyon olasılığını artırır. Basitleştirilmiş '
                'tahmin: tam formül 8 bilanço kalemi gerektirir, burada nakit/kâr '
                'tutarlılığından türetildi.',
                style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Beneish M-Score için yeterli veri yok.',
                    style: text.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // ---- Kart 7: Sermaye Yapısı & Verimlilik ----
        _SectionHeading(
            icon: Icons.precision_manufacturing_rounded,
            title: '7 · Sermaye Yapısı & Verimlilik'),
        const SizedBox(height: 8),
        _NamedListCard(
          title: 'Sermaye Yapısı & Verimlilik',
          icon: Icons.precision_manufacturing_rounded,
          items: a.capitalStructure,
          hideTitle: true,
        ),
        const SizedBox(height: 14),

        // ---- Kart 8: Sahiplik & Yapı ----
        _SectionHeading(
            icon: Icons.groups_2_rounded, title: '8 · Sahiplik & Yapı'),
        const SizedBox(height: 8),
        _NamedListCard(
          title: 'Sahiplik & Yapı',
          icon: Icons.groups_2_rounded,
          items: a.ownership,
          hideTitle: true,
        ),
        const SizedBox(height: 14),

        // ---- Kart 9: Döviz & Dışa Açıklık ----
        _SectionHeading(
            icon: Icons.public_rounded, title: '9 · Döviz & Dışa Açıklık'),
        const SizedBox(height: 8),
        _NamedListCard(
          title: 'Döviz & Dışa Açıklık',
          icon: Icons.public_rounded,
          items: a.fxExport
              .where((v) => !v.label.contains('Gelir Büyümesi'))
              .toList(),
          hideTitle: true,
        ),
        const SizedBox(height: 12),
        Text(
          'Piotroski, Altman ve Beneish skorları; sahiplik, döviz ve '
          'sermaye yapısı göstergeleri, mevcut Yahoo temel verisinden '
          'basitleştirilmiş/tahmini yaklaşımlarla hesaplanır. Tam finansal '
          'tablo ayrıştırması değildir. Anlamsız (aşırı uç) oranlar '
          '"Anlamlı Değil" olarak işaretlenir, ham sayı gösterilmez.',
          style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.title,
    required this.big,
    required this.status,
    required this.label,
    required this.child,
  });
  final String title;
  final String big;
  final MetricStatus status;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: text.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
              ),
              StatusBadge(status: status, label: label),
            ],
          ),
          const SizedBox(height: 6),
          Text(big,
              style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: statusColor(context, status))),
          child,
        ],
      ),
    );
  }
}

class _FillBar extends StatelessWidget {
  const _FillBar({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 8,
        backgroundColor: colors.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _ZoneBar extends StatelessWidget {
  const _ZoneBar({required this.position});
  final double position; // 0..1

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      return Column(
        children: [
          SizedBox(
            height: 18,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                        flex: 36,
                        child: _seg(colors.error, 'Riskli', text, colors)),
                    Expanded(
                        flex: 24,
                        child: _seg(colors.tertiary, 'Gri', text, colors)),
                    Expanded(
                        flex: 40,
                        child: _seg(colors.primary, 'Güvenli', text, colors)),
                  ],
                ),
                Positioned(
                  left: (w - 3) * position,
                  child: Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                          color: colors.onSurface,
                          borderRadius: BorderRadius.circular(2))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: text.labelSmall?.copyWith(fontSize: 9)),
              Text('1,81', style: text.labelSmall?.copyWith(fontSize: 9)),
              Text('3,0', style: text.labelSmall?.copyWith(fontSize: 9)),
              Text('5+', style: text.labelSmall?.copyWith(fontSize: 9)),
            ],
          ),
        ],
      );
    });
  }

  Widget _seg(Color c, String label, TextTheme text, ColorScheme colors) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withValues(alpha: .22),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label,
            style: text.labelSmall
                ?.copyWith(color: c, fontWeight: FontWeight.w700, fontSize: 9)),
      );
}

class _DupontCard extends StatelessWidget {
  const _DupontCard({required this.analysis});
  final FundamentalAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final a = analysis;

    String n(double v, {String u = ''}) {
      final s = v.abs() >= 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(2);
      return '${s.replaceAll('.', ',')}$u';
    }

    Widget factor(String label, String value) => Column(
          children: [
            Text(value,
                style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900, color: colors.onSurface)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant, fontSize: 9)),
          ],
        );

    Widget op(String s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(s,
              style: text.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant, fontWeight: FontWeight.w700)),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DuPont ROE Ayrıştırması',
              style: text.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('ROE: ${n(a.dupontRoe, u: '%')}',
              style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900, color: colors.primary)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: factor('Net Kâr Marjı', n(a.dupontMargin, u: '%'))),
              op('×'),
              Expanded(
                  child: factor('Aktif Devir Hızı', n(a.dupontTurnover))),
              op('×'),
              Expanded(
                  child: factor('Kaldıraç Çarpanı', n(a.dupontLeverage))),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Sekme 4: Bilanço & KAP

class _BilancoKapTab extends StatelessWidget {
  const _BilancoKapTab({required this.analysis, required this.bundle});
  final FundamentalAnalysis analysis;
  final _DetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final a = analysis;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KapCard(items: bundle.kap),
        const SizedBox(height: 16),
        Text('Rasyolar & 10 Yıllık Tarihçe',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Her satır: değer · durum · sektör kıyası · 10 yıl min–medyan–maks',
            style:
                text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (a.ratios.isEmpty)
          Text('Yahoo bu şirket için yeterli temel veri döndürmedi.',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant))
        else
          for (final m in a.ratios) ...[
            SmartCard(metric: m),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 6),
        _NamedListCard(
          title: 'Borç & Likidite',
          icon: Icons.account_balance_rounded,
          items: a.debtLiquidity,
        ),
        const SizedBox(height: 12),
        _NamedListCard(
          title: 'Döviz & İhracat',
          icon: Icons.public_rounded,
          items: a.fxExport,
        ),
        const SizedBox(height: 12),
        _NamedListCard(
          title: 'Nakit Döngüsü (İşletme Sermayesi)',
          icon: Icons.sync_rounded,
          items: a.workingCapital,
        ),
        if (bundle.signal != null) ...[
          const SizedBox(height: 12),
          _TechnicalMini(signal: bundle.signal!),
        ],
        const SizedBox(height: 12),
        Text(
          'Döviz pozisyonu, ihracat oranı ve nakit döngüsü günleri; Yahoo '
          'ayrıntılı bilanço vermediğinden mevcut verilerden yaklaşık olarak '
          'üretilmiştir.',
          style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _KapCard extends StatelessWidget {
  const _KapCard({required this.items});
  final List<KapItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_rounded,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('KAP Bildirimleri',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text('Bu hisse için son önbellekte bildirim yok.',
                style:
                    text.bodySmall?.copyWith(color: colors.onSurfaceVariant))
          else
            for (final k in items.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600)),
                    if (k.publishedAt != null)
                      Text(formatDate(k.publishedAt!),
                          style: text.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
                letterSpacing: .2)),
      ],
    );
  }
}

class _NamedListCard extends StatelessWidget {
  const _NamedListCard(
      {required this.title,
      required this.icon,
      required this.items,
      this.hideTitle = false});
  final String title;
  final IconData icon;
  final List<NamedValue> items;
  final bool hideTitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hideTitle) ...[
            Row(
              children: [
                Icon(icon, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(title,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (items.isEmpty)
            Text('Bu kategori için yeterli veri yok.',
                style: text.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(it.label,
                        style: text.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  Text(it.display,
                      style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface)),
                  if (it.status != MetricStatus.neutral) ...[
                    const SizedBox(width: 8),
                    StatusBadge(status: it.status),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TechnicalMini extends StatelessWidget {
  const _TechnicalMini({required this.signal});
  final TechnicalSignal signal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final s = signal;
    final accent = s.isBullish ? colors.primary : colors.error;
    final simple = AppSettings.instance.simpleExplanations;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  s.isBullish
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Teknik Görünüm: ${s.title}',
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              'Trend: ${s.trendTr} • Güven: ${s.confidence}/100 • '
              'Son: ${formatPrice(s.lastClose)} • SMA20: ${formatPrice(s.sma20)} • '
              'SMA50: ${formatPrice(s.sma50)}',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            simple
                ? 'Yalnızca fiyat hareketinden (hareketli ortalama + 20 günlük '
                    'aralık) hesaplanır. Yatırım tavsiyesi değildir.'
                : 'Yöntem: SMA(20) kesişimi + SMA(20)/SMA(50) dizilişi + 20 '
                    'günlük Donchian kırılımı + momentum. Yatırım tavsiyesi değildir.',
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- ortak

class _PartialNote extends StatelessWidget {
  const _PartialNote({this.padded = false});
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Temel veriler şu an alınamadı (Yahoo oturum anahtarı reddedildi). '
              'Fiyat, sağlık skoru ve analiz sekmeleri için tekrar deneyin.',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
    return padded
        ? Padding(padding: const EdgeInsets.all(16), child: child)
        : child;
  }
}

class _CenteredNote extends StatelessWidget {
  const _CenteredNote({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: text.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.5)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                  onPressed: onRetry, child: const Text('Yeniden dene')),
            ],
          ],
        ),
      ),
    );
  }
}
