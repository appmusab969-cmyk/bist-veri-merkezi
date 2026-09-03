import 'dart:math' as math;

import 'package:flutter/material.dart';

class StockSummaryScreen extends StatelessWidget {
  const StockSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _StockHeader(colors: colors, text: text),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 132),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SummarySection(colors: colors, text: text),
                      const SizedBox(height: 24),
                      _DiagnosisCard(colors: colors, text: text),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomAction(colors: colors, text: text),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockHeader extends StatelessWidget {
  const _StockHeader({
    required this.colors,
    required this.text,
  });

  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .95),
        border: Border(
          bottom: BorderSide(color: colors.outline),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ASELS',
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 12,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Katılım Endeksine Uygun',
                                      overflow: TextOverflow.ellipsis,
                                      style: text.labelSmall?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          '305,50 TL',
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '+%2,18',
                          style: text.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Bugün, 15:42',
                          style: text.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _HealthScore(),
            ],
          ),
          const SizedBox(height: 16),
          _TabBar(colors: colors, text: text),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.secondary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: colors.onSecondary, size: 20),
        ),
      ),
    );
  }
}

class _HealthScore extends StatelessWidget {
  const _HealthScore();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _ScorePainter(
          trackColor: colors.surfaceContainerHighest,
          progressColor: colors.primary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '78',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              'sağlık',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  const _ScorePainter({
    required this.trackColor,
    required this.progressColor,
  });

  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 8) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final progress = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * .78,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _ScorePainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.colors,
    required this.text,
  });

  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Özet Kokpit',
      'Pro Analiz',
      'Rasyolar & 10 Yıllık',
      'Bilanço & Risk',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.secondary,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: Container(
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == 0 ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: i == 0
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                    fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.colors,
    required this.text,
  });

  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        title: 'ROE',
        value: '%38,2',
        badge: 'Güçlü',
        sector: 'Sektör medyanı %24,5',
        range: '%12 · %26 · %41',
        description:
            'Şirket, yatırılan her 100 TL sermayeden güçlü kâr üretiyor.',
        progress: .78,
        marker: .63,
      ),
      _MetricData(
        title: 'Net Borç / FAVÖK',
        value: '0,8x',
        badge: 'Çok İyi',
        sector: 'Sektör medyanı 1,6x',
        range: '0,2x · 1,1x · 3,4x',
        description:
            'Borç yükü yönetilebilir; operasyonel kâr borcu rahatça karşılıyor.',
        progress: .24,
        marker: .40,
      ),
      _MetricData(
        title: 'F / K',
        value: '18,6',
        badge: 'Pahalı',
        sector: 'Sektör medyanı 14,2',
        range: '7,8 · 13,5 · 24,1',
        description:
            'Güçlü beklentiler fiyatlanmış; yeni alımda sabır payı bırakılmalı.',
        progress: .71,
        marker: .58,
        warning: true,
      ),
      _MetricData(
        title: 'Serbest Nakit Akışı',
        value: '+4,8 Mr',
        badge: 'Pozitif',
        sector: 'Sektör medyanı +2,1 Mr TL',
        range: '-1,2 · +2,4 · +6,3',
        description:
            'Yatırımlardan sonra kasada kalan nakit, büyümeyi destekliyor.',
        progress: .76,
        marker: .55,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TEMEL GÖRÜNÜM',
                    style: text.labelSmall?.copyWith(
                      color: colors.primary,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hızlı Özet',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Son bilanço: 2025/12',
              style: text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 258,
          ),
          itemBuilder: (_, index) => _MetricCard(
            data: metrics[index],
            colors: colors,
            text: text,
          ),
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.badge,
    required this.sector,
    required this.range,
    required this.description,
    required this.progress,
    required this.marker,
    this.warning = false,
  });

  final String title;
  final String value;
  final String badge;
  final String sector;
  final String range;
  final String description;
  final double progress;
  final double marker;
  final bool warning;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.data,
    required this.colors,
    required this.text,
  });

  final _MetricData data;
  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final accent = data.warning ? colors.tertiary : colors.primary;

    return Material(
      color: colors.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: .3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.value,
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Text(
                        data.badge,
                        style: text.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data.sector,
                style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10 yıllık', style: _smallStyle(colors)),
                  Text(data.range, style: _smallStyle(colors)),
                ],
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 10,
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: data.progress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: constraints.maxWidth * data.marker - 6,
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surfaceContainer,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data.warning ? 'Uygun' : 'Düşük', style: _smallStyle(colors)),
                  Text('Sektör ibresi', style: _smallStyle(colors)),
                  Text('Yüksek', style: _smallStyle(colors)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  data.description,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSecondary,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Detayı aç',
                    style: text.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: accent, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _smallStyle(ColorScheme colors) => TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 9,
      );
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({
    required this.colors,
    required this.text,
  });

  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SADE TEŞHİS',
                      style: text.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bu Ekran Ne Söylüyor?',
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.primary.withValues(alpha: .1),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: colors.primary,
                  size: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Insight(
            color: colors.primary,
            title: 'Güçlü Yön',
            body:
                'Kârlılık, düşük borçluluk ve pozitif nakit üretimi aynı hikâyeyi destekliyor. Katılım kriterleri açısından görünüm olumlu.',
            colors: colors,
            text: text,
          ),
          const SizedBox(height: 16),
          _Insight(
            color: colors.tertiary,
            title: 'İzlenecek',
            body:
                'F/K oranı sektörün üzerinde. Fiyat yükselirken kâr büyümesinin bu farkı kapatıp kapatmadığını takip et.',
            colors: colors,
            text: text,
          ),
          const SizedBox(height: 16),
          _Insight(
            color: colors.primary,
            title: 'Son KAP Etkisi',
            body:
                'Yeni sipariş ve ihracat odaklı açıklamalar beklentiyi destekliyor; etkisi henüz temel görünümü değiştirecek ölçekte değil.',
            colors: colors,
            text: text,
          ),
          const SizedBox(height: 16),
          Divider(color: colors.outline),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu özet bir karar değil, araştırmaya başlamak için sakin bir çerçevedir.',
                  style: text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({
    required this.color,
    required this.title,
    required this.body,
    required this.colors,
    required this.text,
  });

  final Color color;
  final String title;
  final String body;
  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.55,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.colors,
    required this.text,
  });

  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .95),
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: colors.secondary,
            foregroundColor: colors.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 19),
              const SizedBox(width: 8),
              Text(
                'Metrikleri nasıl okuyacağını öğren',
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.north_east,
                color: colors.primary,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

