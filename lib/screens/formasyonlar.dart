import 'package:flutter/material.dart';

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  int _selectedFilter = 0;

  final _filters = const [
    ('Tümü', '18'),
    ('Yukarı Kırılım', '7'),
    ('Katılım Uygun', '11'),
    ('Yüksek Güven', '6'),
  ];

  final _formations = const [
    Formation(
      symbol: 'ASELS',
      icon: Icons.flag_outlined,
      status: 'Yukarı kırılım gerçekleşti',
      price: '305,50 TL',
      confidence: '86% güven',
      pattern: 'Flama',
      target: '310–325 TL',
      colorType: FormationColor.primary,
      chartType: ChartType.asels,
      participation: true,
    ),
    Formation(
      symbol: 'OYAKC',
      icon: Icons.local_cafe_outlined,
      status: 'Kırılım eşiğinde',
      price: '24,86 TL',
      confidence: '79% güven',
      pattern: 'Fincan-Kulp',
      target: '26,10–27,00 TL',
      colorType: FormationColor.accent,
      chartType: ChartType.oyakc,
    ),
    Formation(
      symbol: 'TOASO',
      icon: Icons.alt_route_outlined,
      status: 'Boyun çizgisi test ediliyor',
      price: '287,25 TL',
      confidence: '74% güven',
      pattern: 'Ters Omuz-Baş-Omuz',
      target: '302–315 TL',
      colorType: FormationColor.muted,
      chartType: ChartType.toaso,
    ),
    Formation(
      symbol: 'TUPRS',
      icon: Icons.trending_up,
      status: 'Yukarı yön korunuyor',
      price: '161,80 TL',
      confidence: '82% güven',
      pattern: 'Yükselen Üçgen',
      target: '168–174 TL',
      colorType: FormationColor.primary,
      chartType: ChartType.tuprs,
      participation: true,
    ),
    Formation(
      symbol: 'SISE',
      icon: Icons.change_history_outlined,
      status: 'Yön teyidi bekleniyor',
      price: '43,72 TL',
      confidence: '71% güven',
      pattern: 'Simetrik Üçgen',
      target: '46,20–48,00 TL',
      colorType: FormationColor.accent,
      chartType: ChartType.sise,
    ),
    Formation(
      symbol: 'KCHOL',
      icon: Icons.show_chart,
      status: 'Kırılım sonrası tutunuyor',
      price: '192,10 TL',
      confidence: '77% güven',
      pattern: 'Yatay Kanal',
      target: '201–208 TL',
      colorType: FormationColor.primary,
      chartType: ChartType.kchol,
      participation: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFilters(context),
                  const SizedBox(height: 24),
                  _buildResults(context),
                  const SizedBox(height: 24),
                  _buildParticipationBanner(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALGORİTMİK TARAMA',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Formasyonlar',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fiyat hareketlerinde tekrar eden yapıları senin için sade biçimde tarıyoruz.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                tooltip: 'Güven puanı açıklaması',
                style: IconButton.styleFrom(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                  side: BorderSide(color: colors.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.help_outline),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .10),
              border: Border.all(color: colors.primary.withValues(alpha: .25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primary.withValues(alpha: .15),
                  child: Icon(Icons.document_scanner_outlined,
                      size: 19, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugün 18 formasyon bulundu',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Güven, yapının ne kadar net oluştuğunu anlatır.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          final filter = _filters[index];

          return ChoiceChip(
            selected: selected,
            label: Text('${filter.$1}  ${filter.$2}'),
            onSelected: (_) => setState(() => _selectedFilter = index),
            labelStyle: TextStyle(
              color: selected ? colors.onPrimary : colors.onSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: colors.secondary,
            selectedColor: colors.primary,
            side: BorderSide(
              color: selected
                  ? colors.primary
                  : index == 2
                      ? colors.primary.withValues(alpha: .3)
                      : colors.outline,
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                    'CANLI TARAMA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bugün Tespit Edilenler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '18 sonuç',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              border: Border.all(color: colors.outline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _formations.length; i++)
                  _FormationTile(
                    formation: _formations[i],
                    isLast: i == _formations.length - 1,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: colors.onSecondary,
            backgroundColor: colors.secondary,
            side: BorderSide(color: colors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Kalan 12 formasyonu göster'),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: colors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipationBanner(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .10),
        border: Border.all(color: colors.primary.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primary.withValues(alpha: .15),
            child: Icon(Icons.verified_user_outlined, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Katılım filtresi açık',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Uygun olmayan hisseleri gizleyerek 11 formasyonu gösterir.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.toggle_on, size: 32, color: colors.primary),
        ],
      ),
    );
  }

}

class _FormationTile extends StatelessWidget {
  const _FormationTile({
    required this.formation,
    required this.isLast,
  });

  final Formation formation;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlight = formation.colorType == FormationColor.primary
        ? colors.primary
        : formation.colorType == FormationColor.accent
            ? colors.tertiary
            : colors.onSurfaceVariant;

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: colors.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: highlight.withValues(alpha: .13),
                  child: Icon(formation.icon, size: 19, color: highlight),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: highlight,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surfaceContainer, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
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
                            Row(
                              children: [
                                Text(
                                  formation.symbol,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                if (formation.participation) ...[
                                  const SizedBox(width: 8),
                                  _ParticipationTag(color: colors.primary),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formation.status,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: highlight,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formation.price,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formation.confidence,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: highlight,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formation.pattern,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: colors.onSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                children: [
                                  const TextSpan(text: 'Hedef bölge '),
                                  TextSpan(
                                    text: formation.target,
                                    style: TextStyle(
                                      color: colors.tertiary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 108,
                        height: 38,
                        child: CustomPaint(
                          painter: _ChartPainter(
                            type: formation.chartType,
                            lineColor: highlight,
                            guideColor: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipationTag extends StatelessWidget {
  const _ParticipationTag({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            'Katılım',
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.type,
    required this.lineColor,
    required this.guideColor,
  });

  final ChartType type;
  final Color lineColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final guide = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    final points = switch (type) {
      ChartType.asels => [31, 27, 29, 18, 21, 15, 20, 14, 18, 8, 5],
      ChartType.oyakc => [11, 12, 28, 29, 31, 12, 11, 22, 23, 18, 16],
      ChartType.toaso => [15, 24, 17, 31, 10, 29, 17, 21, 12],
      ChartType.tuprs => [30, 25, 27, 19, 22, 14, 17, 10, 8],
      ChartType.sise => [10, 27, 13, 24, 16, 21, 18, 20, 16],
      ChartType.kchol => [27, 25, 27, 24, 26, 24, 26, 14, 12, 9],
    };

    for (var i = 0; i < points.length; i++) {
      final x = 3 + (i * (size.width - 6) / (points.length - 1));
      final y = points[i] * size.height / 38;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);

    guide
      ..strokeWidth = 1.1
      ..color = guideColor.withValues(alpha: .7);
    guide.shader = null;
    final guidePath = Path()
      ..moveTo(size.width * .65, size.height * .6)
      ..lineTo(size.width * .96, size.height * .3);
    canvas.drawPath(guidePath, guide);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.guideColor != guideColor;
}

enum FormationColor { primary, accent, muted }

enum ChartType { asels, oyakc, toaso, tuprs, sise, kchol }

class Formation {
  const Formation({
    required this.symbol,
    required this.icon,
    required this.status,
    required this.price,
    required this.confidence,
    required this.pattern,
    required this.target,
    required this.colorType,
    required this.chartType,
    this.participation = false,
  });

  final String symbol;
  final IconData icon;
  final String status;
  final String price;
  final String confidence;
  final String pattern;
  final String target;
  final FormationColor colorType;
  final ChartType chartType;
  final bool participation;
}