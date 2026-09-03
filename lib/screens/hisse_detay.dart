import 'package:flutter/material.dart';

import '../models/stock_detail.dart';
import '../models/candle.dart';
import '../services/yahoo_finance.dart';
import '../services/format.dart';
import '../services/technical.dart';
import '../services/app_settings.dart';
import '../widgets/sparkline.dart';

/// Herhangi bir BIST hissesi için genel detay ekranı.
/// Sekmeler: Özet · Rasyolar · Bilanço · Teknik
class HisseDetayScreen extends StatefulWidget {
  const HisseDetayScreen({super.key, required this.code, this.name});

  final String code; // "ASELS"
  final String? name;

  @override
  State<HisseDetayScreen> createState() => _HisseDetayScreenState();
}

class _HisseDetayScreenState extends State<HisseDetayScreen> {
  final _api = YahooFinance();
  late Future<_DetailBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<_DetailBundle> _load() async {
    final detail = await _api.fetchDetail(widget.code);
    List<Candle> daily = const [];
    try {
      daily = await _api.fetchHistory(widget.code, range: '6mo', interval: '1d');
    } catch (_) {}
    final signal =
        daily.isNotEmpty ? TechnicalSignal.fromCandles(daily) : null;
    return _DetailBundle(detail, daily, signal);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surfaceContainer,
          title: Text(widget.code),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Özet'),
              Tab(text: 'Rasyolar'),
              Tab(text: 'Bilanço'),
              Tab(text: 'Teknik'),
            ],
          ),
        ),
        body: FutureBuilder<_DetailBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return _CenteredNote(
                icon: Icons.cloud_off_rounded,
                title: 'Veri alınamadı',
                message: '${snap.error ?? 'Bilinmeyen hata'}',
                onRetry: () => setState(() => _future = _load()),
              );
            }
            final b = snap.data!;
            return TabBarView(
              children: [
                _OverviewTab(bundle: b),
                _MetricsTab(
                  title: 'Değerleme & Kârlılık',
                  metrics: b.detail.ratios,
                  partial: b.detail.partial,
                ),
                _MetricsTab(
                  title: 'Bilanço & Nakit',
                  metrics: b.detail.financials,
                  partial: b.detail.partial,
                ),
                _TechnicalTab(bundle: b),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailBundle {
  _DetailBundle(this.detail, this.daily, this.signal);
  final StockDetail detail;
  final List<Candle> daily;
  final TechnicalSignal? signal;
}

// ---------------------------------------------------------------- Özet

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.bundle});
  final _DetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final d = bundle.detail;
    final q = d.quote;
    final changeColor = q.isUp ? colors.primary : colors.error;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(d.longName,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          [d.sector, d.industry].where((e) => e != '—').join(' · '),
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatPrice(q.price),
                style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: colors.onSurface)),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${formatPercent(q.changePercent)}  (${formatPrice(q.change)})',
                style: text.bodyMedium?.copyWith(
                    color: changeColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (q.spark.length > 2)
          SizedBox(
            height: 90,
            child: Sparkline(values: q.spark, color: changeColor, fill: true),
          ),
        const SizedBox(height: 8),
        Text('Son güncelleme: ${formatUpdatedNow()} • Yahoo Finance',
            style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 20),
        if (d.recommendation != null || d.targetMeanPrice != null) ...[
          _RecommendationCard(detail: d),
          const SizedBox(height: 12),
        ],
        if (d.summary.isNotEmpty) _MetricGrid(metrics: d.summary),
        if (d.partial) ...[
          const SizedBox(height: 12),
          _PartialNote(),
        ],
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.detail});
  final StockDetail detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final target = detail.targetMeanPrice;
    final upside = (target != null && detail.quote.price > 0)
        ? (target - detail.quote.price) / detail.quote.price * 100
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANALİST GÖRÜŞÜ (YAHOO)',
              style: text.labelSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text('Konsensüs: ${detail.recommendationTr}',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ortalama hedef: ${formatPrice(target)}'
              '${upside != null ? '  (${formatPercent(upside)} potansiyel)' : ''}',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Metrik sekmesi

class _MetricsTab extends StatelessWidget {
  const _MetricsTab({
    required this.title,
    required this.metrics,
    required this.partial,
  });

  final String title;
  final List<Metric> metrics;
  final bool partial;

  @override
  Widget build(BuildContext context) {
    if (partial || metrics.isEmpty) {
      return _PartialNote(padded: true);
    }
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _MetricGrid(metrics: metrics),
        const SizedBox(height: 16),
        Text(
          'Kaynak: Yahoo Finance quoteSummary. Bazı alanlar şirket/ülke '
          'bazında boş gelebilir (—).',
          style: text.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < metrics.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: _cell(context, metrics[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < metrics.length
                      ? _cell(context, metrics[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, Metric m) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.label,
              style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            m.value,
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: m.isMissing ? colors.onSurfaceVariant : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Teknik

class _TechnicalTab extends StatelessWidget {
  const _TechnicalTab({required this.bundle});
  final _DetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final s = bundle.signal;
    if (s == null) {
      return _CenteredNote(
        icon: Icons.query_stats_rounded,
        title: 'Teknik veri yok',
        message: 'Yeterli geçmiş fiyat verisi alınamadı.',
      );
    }
    final accent = s.isBullish ? colors.primary : colors.error;
    final simple = AppSettings.instance.simpleExplanations;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
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
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.title,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Trend: ${s.trendTr} • Güven: ${s.confidence}/100',
                  style:
                      text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MetricGrid(metrics: [
          Metric('Son kapanış', formatPrice(s.lastClose)),
          Metric('20g ort. (SMA)', formatPrice(s.sma20)),
          Metric('50g ort. (SMA)', formatPrice(s.sma50)),
          Metric('20g değişim', formatPercent(s.changePercent20d)),
          Metric('20g en yüksek', formatPrice(s.periodHigh)),
          Metric('20g en düşük', formatPrice(s.periodLow)),
        ]),
        const SizedBox(height: 16),
        Text(
          simple
              ? 'Bu değerlendirme yalnızca fiyat hareketinden hesaplanır '
                  '(hareketli ortalama ve 20 günlük aralık). Yatırım tavsiyesi '
                  'değildir.'
              : 'Yöntem: SMA(20) kesişimi + SMA(20)/SMA(50) dizilişi + 20 günlük '
                  'Donchian kanalı kırılımı + momentum büyüklüğü. Hepsi ham fiyat '
                  'serisinden, dış servis olmadan hesaplanır. Yatırım tavsiyesi değildir.',
          style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
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
              'Fiyat ve teknik sekmeler çalışmaya devam eder.',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
    return padded ? Padding(padding: const EdgeInsets.all(20), child: child) : child;
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
                style:
                    text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
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
