import 'package:flutter/material.dart';

import '../models/fundamental_analysis.dart';

/// Bir [MetricStatus] için tema rengini verir.
Color statusColor(BuildContext context, MetricStatus s) {
  final c = Theme.of(context).colorScheme;
  return switch (s) {
    MetricStatus.strong || MetricStatus.balanced => c.primary,
    MetricStatus.watch || MetricStatus.expensive => c.tertiary,
    MetricStatus.risky => c.error,
    MetricStatus.neutral || MetricStatus.invalid => c.onSurfaceVariant,
  };
}

/// Durum rozeti: `[Güçlü 🟢]` biçiminde.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.label});
  final MetricStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        '${label ?? status.label} ${status.emoji}',
        style: text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

/// Sektör ortalaması çizgisi + hissenin sapmasını gösteren ibre.
class _SectorBar extends StatelessWidget {
  const _SectorBar({required this.metric});
  final SmartMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dev = metric.sectorDeviationPct ?? 0;
    // Sapmayı -60..+60 aralığına sıkıştırıp 0..1 konuma çeviriyoruz.
    final t = ((dev.clamp(-60.0, 60.0)) + 60) / 120;
    final good = metric.higherIsBetter ? dev >= 0 : dev <= 0;
    final markColor = good ? colors.primary : colors.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sektör kıyası',
            style: text.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          '${dev >= 0 ? '+' : ''}${dev.toStringAsFixed(0).replaceAll('.', ',')}% '
          '(sektör: ${_fmt(metric.sectorAvg!, metric.unit)})',
          style: text.labelSmall?.copyWith(
              color: markColor, fontWeight: FontWeight.w700, fontSize: 10),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return SizedBox(
            height: 14,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Sektör ortalaması çizgisi (orta).
                Align(
                  alignment: Alignment.center,
                  child: Container(width: 2, height: 14, color: colors.onSurfaceVariant),
                ),
                // Hisse ibresi.
                Positioned(
                  left: (w - 10) * t,
                  top: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: markColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// 10 yıllık min–medyan–maks bandı + anlık konum noktası.
class _BandBar extends StatelessWidget {
  const _BandBar({required this.metric});
  final SmartMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pos = metric.bandPosition ?? .5;
    final medPos = () {
      final span = metric.tenYearMax! - metric.tenYearMin!;
      if (span.abs() < 1e-9) return .5;
      return ((metric.tenYearMedian! - metric.tenYearMin!) / span)
          .clamp(0.0, 1.0);
    }();
    final dotColor = pos >= .7
        ? colors.tertiary
        : pos <= .35
            ? colors.primary
            : colors.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('10 yıl bandı',
            style: text.labelSmall
                ?.copyWith(color: colors.onSurfaceVariant, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          'medyan: ${_fmt(metric.tenYearMedian!, metric.unit)} • %${(pos * 100).toStringAsFixed(0)} dilim',
          style: text.labelSmall
              ?.copyWith(color: colors.onSurfaceVariant, fontSize: 10),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return SizedBox(
            height: 16,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        colors.primary.withValues(alpha: .35),
                        colors.tertiary.withValues(alpha: .35),
                        colors.error.withValues(alpha: .35),
                      ]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  left: (w - 2) * medPos,
                  top: 1,
                  child: Container(width: 2, height: 14, color: colors.onSurfaceVariant),
                ),
                Positioned(
                  left: (w - 12) * pos,
                  top: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('min ${_fmt(metric.tenYearMin!, metric.unit)}',
                style: text.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant, fontSize: 9)),
            Text('maks ${_fmt(metric.tenYearMax!, metric.unit)}',
                style: text.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant, fontSize: 9)),
          ],
        ),
      ],
    );
  }
}

String _fmt(double v, String unit) {
  final s = v.abs() >= 100
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(v.abs() >= 10 ? 1 : 2);
  final t = s.replaceAll('.', ',');
  return unit == '%' ? '%$t' : (unit == 'x' ? '${t}x' : t);
}

/// Tam akıllı kart: başlık + büyük değer + rozet + sektör barı + 10 yıl bandı + açıklama.
class SmartCard extends StatelessWidget {
  const SmartCard({super.key, required this.metric, this.compact = false});
  final SmartMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Text(
              metric.title,
              style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            StatusBadge(status: metric.status, label: metric.customLabel),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    metric.title,
                    style: text.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: metric.status, label: metric.customLabel),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            metric.display,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: statusColor(context, metric.status),
            ),
          ),
          if (metric.hasSectorBar) ...[
            SizedBox(height: compact ? 8 : 10),
            _SectorBar(metric: metric),
          ],
          if (metric.hasBand) ...[
            SizedBox(height: compact ? 8 : 10),
            _BandBar(metric: metric),
          ],
          const SizedBox(height: 8),
          Text(
            metric.note,
            style: text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}
