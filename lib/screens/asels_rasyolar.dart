import 'package:flutter/material.dart';

class AselsRatiosScreen extends StatefulWidget {
  const AselsRatiosScreen({
    super.key,
    this.onBack,
    this.onShare,
    this.onCreateAlert,
  });

  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onCreateAlert;

  @override
  State<AselsRatiosScreen> createState() => _AselsRatiosScreenState();
}

class _AselsRatiosScreenState extends State<AselsRatiosScreen> {
  int _selectedTab = 1;

  static const _tabs = ['Özet', 'Rasyolar', 'Kârlılık', '10 yıllık'];

  static const _metrics = [
    _Metric(
      title: 'F/K',
      subtitle: 'Fiyat / kâr oranı',
      value: '18,6',
      average: '14,2',
      status: 'Pahalı',
      description:
          'Hisse, sektör kârına göre daha yüksek bir fiyat primiyle işlem görüyor.',
      progress: .78,
      tone: _MetricTone.destructive,
      expandable: true,
    ),
    _Metric(
      title: 'PD/DD',
      subtitle: 'Piyasa değeri / özkaynak',
      value: '4,2',
      average: '3,8',
      status: 'Dengeli',
      description:
          'Şirketin varlıklarına göre fiyatı sektör seviyesine yakın.',
      progress: .61,
      tone: _MetricTone.accent,
      expandable: true,
    ),
    _Metric(
      title: 'FD/FAVÖK',
      subtitle: 'Şirket değeri / faaliyet kârı',
      value: '12,4',
      average: '13,1',
      status: 'Makul',
      description:
          'Faaliyet kârına göre değerleme, sektörün biraz altında kalıyor.',
      progress: .55,
      tone: _MetricTone.primary,
      expandable: true,
    ),
    _Metric(
      title: 'PEG',
      subtitle: 'Büyümeye göre değerleme',
      value: '0,78',
      average: '1,12',
      status: 'Kelepir',
      description:
          'Büyüme beklentisine kıyasla fiyatı daha ölçülü görünüyor.',
      progress: .38,
      tone: _MetricTone.primary,
      highlighted: true,
      expandable: true,
    ),
    _Metric(
      title: 'ROE',
      subtitle: 'Özkaynak kârlılığı',
      value: '%38,2',
      average: '%24,6',
      status: 'Güçlü',
      description:
          'Şirket, ortakların koyduğu sermayeyi sektörün üzerinde verimli kullanıyor.',
      progress: .84,
      tone: _MetricTone.primary,
    ),
    _Metric(
      title: 'ROIC',
      subtitle: 'Yatırılan sermaye kârlılığı',
      value: '%29,4',
      average: '%18,1',
      status: 'Güçlü',
      description:
          'İşletmeye yatırılan her 100 TL, güçlü bir faaliyet getirisi üretiyor.',
      progress: .76,
      tone: _MetricTone.primary,
    ),
    _Metric(
      title: 'Brüt Kâr Marjı',
      subtitle: 'Satıştan kalan ilk kâr payı',
      value: '%34,0',
      average: '%27,5',
      status: 'Sektör üstü',
      description:
          'Ürün ve hizmet satışlarında maliyetlerini iyi yönetiyor.',
      progress: .72,
      tone: _MetricTone.primary,
    ),
    _Metric(
      title: 'FAVÖK Marjı',
      subtitle: 'Ana işten kalan faaliyet payı',
      value: '%26,5',
      average: '%21,3',
      status: 'Sektör üstü',
      description:
          'Ana faaliyetlerden elde edilen kâr, benzer şirketlerden daha yüksek.',
      progress: .68,
      tone: _MetricTone.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HeaderDelegate(
                    minExtent: 224,
                    maxExtent: 224,
                    child: _buildHeader(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildIntro(context),
                      const SizedBox(height: 20),
                      ..._metrics.map(
                        (metric) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MetricCard(metric: metric),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _ValuationHistoryCard(),
                      const SizedBox(height: 16),
                      const _CalmReadingCard(),
                    ]),
                  ),
                ),
              ],
            ),
            _BottomAction(
              onPressed: widget.onCreateAlert,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .96),
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          children: [
            Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Geri dön',
                  onPressed: widget.onBack,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          _Pill(
                            label: 'Katılım',
                            foreground: colors.primary,
                            background:
                                colors.primary.withValues(alpha: .15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rasyolar & 10 yıllık görünüm',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _HeaderButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Paylaş',
                  onPressed: widget.onShare,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PriceSummary(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(
                  _tabs.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedTab == index
                              ? colors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          _tabs[index],
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _selectedTab == index
                                        ? colors.onPrimary
                                        : colors.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
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
                    'SADE KARŞILAŞTIRMA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Değerleme & kârlılık',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              'Sektör: Savunma',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            'Her oranı, ASELS’in sektöründeki benzer şirketlerle ve kendi geçmişiyle birlikte okuyun.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.55,
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      child;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => false;
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        style: IconButton.styleFrom(
          foregroundColor: colors.onSecondary,
          backgroundColor: colors.secondary,
          side: BorderSide(color: colors.outlineVariant),
          fixedSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Overline('SON FİYAT'),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '305,50 TL',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+%2,18',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Veri tarihi',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '18 Haz 2025 · 15:42',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  Color _toneColor(ColorScheme colors) => switch (metric.tone) {
        _MetricTone.destructive => colors.error,
        _MetricTone.accent => colors.tertiary,
        _MetricTone.primary => colors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = _toneColor(colors);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border.all(
          color: metric.highlighted
              ? colors.primary.withValues(alpha: .35)
              : colors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: metric.highlighted
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .05),
                  blurRadius: 18,
                ),
              ]
            : null,
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
                      metric.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              _Pill(
                label: metric.status,
                foreground: toneColor,
                background: toneColor.withValues(alpha: .15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric.value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sektör ortalaması',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.average,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: metric.progress,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(toneColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            metric.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          if (metric.expandable) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: colors.outlineVariant),
            InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detaylı kıyası aç',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValuationHistoryCard extends StatelessWidget {
  const _ValuationHistoryCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border.all(color: colors.outlineVariant),
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
                      'GEÇMİŞE BAKIŞ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.tertiary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '10 yıllık değerleme bandı',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              _Pill(
                label: 'F/K',
                foreground: colors.onSecondary,
                background: colors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bugünkü oran, ASELS’in son 10 yıldaki değerleme aralığında nerede duruyor?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 16,
                      child: _Band(
                        color: colors.surfaceContainerHighest,
                        height: 8,
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * .27,
                      right: constraints.maxWidth * .18,
                      top: 16,
                      child: _Band(
                        color: colors.tertiary.withValues(alpha: .45),
                        height: 8,
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * .57,
                      top: 5,
                      child: Container(
                        width: 1,
                        height: 30,
                        color: colors.tertiary,
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * .71,
                      top: 0,
                      child: Transform.translate(
                        offset: const Offset(-16, 0),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.tertiary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.surfaceContainer,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BandLabel('Min 4,8'),
              _BandLabel('Medyan 11,4', accent: true),
              _BandLabel('Güncel 18,6'),
              _BandLabel('Max 24,1'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 18, color: colors.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'F/K, geçmiş ortalamasının üzerinde. Ancak güçlü kârlılık ve büyüme bu primi kısmen açıklıyor.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSecondary,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalmReadingCard extends StatelessWidget {
  const _CalmReadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .10),
        border: Border.all(color: colors.primary.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user_outlined,
                size: 19, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sakin okuma',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ASELS’in fiyatı ucuz değil; fakat kârlılık rasyoları ve büyüme görünümü güçlü. Tek bir orana değil, bütün hikâyeye birlikte bakın.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSecondary,
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: .96),
          border: Border(
            top: BorderSide(color: colors.primary.withValues(alpha: .3)),
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_none_rounded, size: 20),
            label: const Text('ASELS için uyarı oluştur'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _Overline extends StatelessWidget {
  const _Overline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _BandLabel extends StatelessWidget {
  const _BandLabel(this.text, {this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: accent ? colors.tertiary : colors.onSurfaceVariant,
            fontWeight: accent ? FontWeight.w800 : FontWeight.w400,
          ),
    );
  }
}

enum _MetricTone { destructive, accent, primary }

class _Metric {
  const _Metric({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.average,
    required this.status,
    required this.description,
    required this.progress,
    required this.tone,
    this.highlighted = false,
    this.expandable = false,
  });

  final String title;
  final String subtitle;
  final String value;
  final String average;
  final String status;
  final String description;
  final double progress;
  final _MetricTone tone;
  final bool highlighted;
  final bool expandable;
}