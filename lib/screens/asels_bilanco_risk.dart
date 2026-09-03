import 'package:flutter/material.dart';

class AselsFinancialHealthScreen extends StatefulWidget {
  const AselsFinancialHealthScreen({super.key});

  @override
  State<AselsFinancialHealthScreen> createState() =>
      _AselsFinancialHealthScreenState();
}

class _AselsFinancialHealthScreenState
    extends State<AselsFinancialHealthScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HeaderDelegate(
                    minExtent: 238,
                    maxExtent: 238,
                    child: _Header(
                      selectedTab: _selectedTab,
                      onTabChanged: (value) =>
                          setState(() => _selectedTab = value),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 116),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _HealthSummaryCard(),
                      const SizedBox(height: 16),
                      _DebtLiquidityCard(),
                      const SizedBox(height: 16),
                      _CurrencyCard(),
                      const SizedBox(height: 16),
                      _CashCycleCard(),
                      const SizedBox(height: 16),
                      _RiskRadarCard(),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomAction(
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
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

class _Header extends StatelessWidget {
  const _Header({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface.withValues(alpha: .96),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _IconButton(
                  icon: Icons.arrow_back,
                  label: 'Geri dön',
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          _Pill(
                            icon: Icons.verified_user_outlined,
                            label: 'Katılım',
                            foreground: colors.primary,
                            background:
                                colors.primary.withValues(alpha: .14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Finansal dayanıklılık ve risk radarı',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                _IconButton(
                  icon: Icons.more_horiz,
                  label: 'Daha fazla seçenek',
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son fiyat',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '305,50 TL',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+%2,18',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .1),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: .25),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.primary.withValues(alpha: .7),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '78',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SAĞLIK',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'İyi durumda',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TabBar(
              selected: selectedTab,
              onChanged: onTabChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const labels = ['Bilanço', 'Kârlılık', 'Rasyolar', 'KAP'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == index ? colors.primary : null,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected == index
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: selected == index
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Card(
      borderColor: colors.primary.withValues(alpha: .25),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow('FİNANSAL SAĞLIK', colors.primary),
                    const SizedBox(height: 5),
                    _Heading('Dayanıklılık iyi', size: 20),
                    const SizedBox(height: 4),
                    Text(
                      'Borç seviyesi düşük, nakit dengesi ise şirketin operasyonlarını rahat taşıyor.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ScoreRing(),
            ],
          ),
          const SizedBox(height: 14),
          _Note(
            icon: Icons.auto_awesome,
            text:
                'Yapay zekâ notu: Borç baskısı düşük; asıl takip noktası tahsilat süresi.',
            background: colors.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

class _DebtLiquidityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            eyebrow: '01 · BORÇ & LİKİDİTE',
            title: 'Nakit tamponu güçlü',
            status: 'Çok güvenli',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.account_balance_outlined,
                  value: '0,8x',
                  label: 'Net Borç / FAVÖK',
                  progress: .27,
                  footer: 'Eşik 3,0x',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  icon: Icons.refresh,
                  value: '1,65',
                  label: 'Cari Oran',
                  progress: .66,
                  footer: 'Yeterli',
                  color: colors.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  icon: Icons.check_circle_outline,
                  value: '1,12',
                  label: 'Asit-Test',
                  progress: .58,
                  footer: 'İyi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Note(
            icon: Icons.info_outline,
            text:
                "ASELS'in borcu, faaliyetlerinden ürettiği kâra göre düşük. Kısa vadeli yükümlülüklerini karşılamak için yeterli likit varlığı bulunuyor.",
            background: colors.primary.withValues(alpha: .1),
          ),
          const _ExpandRow(label: 'Bu oranlar ne anlatıyor?'),
        ],
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            eyebrow: '02 · DÖVİZ & İHRACAT',
            title: 'Döviz dengesi pozitif',
            status: 'Pozitif',
            eyebrowColor: colors.secondary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _tileDecoration(colors),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primary.withValues(alpha: .14),
                  child: Icon(Icons.payments_outlined, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net döviz pozisyonu',
                        style: _mutedText(context, 10)),
                    const SizedBox(height: 2),
                    Text(
                      '+2,4 Mr TL',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.trending_up, color: colors.primary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ValueTile(
                  label: 'İhracat oranı',
                  value: '%42',
                  caption: 'Yüksek',
                  captionColor: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueTile(
                  label: 'Sektör karşılığı',
                  value: '%28',
                  caption: 'ASELS +14 puan',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Note(
            icon: Icons.public,
            text:
                'İhracat gelirleri ve pozitif döviz dengesi, TL’deki oynaklığın şirket üzerindeki etkisini azaltıyor.',
            background: colors.secondary.withValues(alpha: .12),
            iconColor: colors.secondary,
          ),
          const _ExpandRow(label: 'Döviz pozisyonunu detaylandır'),
        ],
      ),
    );
  }
}

class _CashCycleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            eyebrow: '03 · NAKİT DÖNGÜSÜ',
            title: 'İşletme sermayesi dengeli',
            status: 'Takipte',
            eyebrowColor: colors.tertiary,
            statusColor: colors.tertiary,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CycleTile(
                  icon: Icons.access_time,
                  value: '68',
                  label: 'DSO · Gün',
                  footer: 'İyileşiyor',
                  color: colors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CycleTile(
                  icon: Icons.inventory_2_outlined,
                  value: '45',
                  label: 'DIO · Gün',
                  footer: 'Normal',
                  color: colors.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CycleTile(
                  icon: Icons.calendar_month_outlined,
                  value: '55',
                  label: 'DPO · Gün',
                  footer: 'Dengeli',
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Note(
            icon: Icons.chat_bubble_outline,
            text:
                'Müşterilerden tahsilat süresi 68 gün. Bu süre iyileşiyor; stok ve tedarikçi dengesi şimdilik kontrollü.',
            background: colors.surfaceContainerHighest,
            iconColor: colors.tertiary,
          ),
          const _ExpandRow(label: 'Nakit döngüsünü basitçe açıkla'),
        ],
      ),
    );
  }
}

class _RiskRadarCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Card(
      background: colors.primary.withValues(alpha: .1),
      borderColor: colors.primary.withValues(alpha: .25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colors.primary,
                child: Icon(Icons.radar, color: colors.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow('RİSK RADARI', colors.primary),
                    const SizedBox(height: 4),
                    _Heading('Şu an sakin bir görünüm', size: 16),
                  ],
                ),
              ),
              _Pill(
                label: 'Düşük risk',
                foreground: colors.onPrimary,
                background: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Borçluluk ve döviz dengesi destekleyici. İzlenecek tek alan, tahsilat günlerinin daha da kısalıp kısalmadığı.',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Son finansal veri: 2025 4. çeyrek · Eğitim amaçlı araştırma',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface.withValues(alpha: .96),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.notifications_none, size: 20),
            label: const Text('ASELS için uyarı oluştur'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.background,
    this.borderColor,
  });

  final Widget child;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.eyebrow,
    required this.title,
    required this.status,
    this.eyebrowColor,
    this.statusColor,
  });

  final String eyebrow;
  final String title;
  final String status;
  final Color? eyebrowColor;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = eyebrowColor ?? colors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(eyebrow, color),
              const SizedBox(height: 5),
              _Heading(title, size: 18),
            ],
          ),
        ),
        _Pill(
          label: status,
          foreground: statusColor ?? colors.primary,
          background:
              (statusColor ?? colors.primary).withValues(alpha: .14),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.progress,
    required this.footer,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final double progress;
  final String footer;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _tileDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 17, color: foreground),
              Text(
                value,
                style: TextStyle(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: _mutedText(context, 10)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              color: foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(footer, style: _mutedText(context, 9)),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.label,
    required this.value,
    required this.caption,
    this.captionColor,
  });

  final String label;
  final String value;
  final String caption;
  final Color? captionColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _tileDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _mutedText(context, 10)),
          const SizedBox(height: 5),
          Text(value, style: _HeadingStyle(context, 18)),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              color: captionColor ?? colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight:
                  captionColor == null ? FontWeight.normal : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleTile extends StatelessWidget {
  const _CycleTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.footer,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final String footer;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _tileDecoration(colors),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 7),
          Text(value, style: _HeadingStyle(context, 18)),
          Text(label, style: _mutedText(context, 10)),
          const SizedBox(height: 8),
          Text(
            footer,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.text,
    required this.background,
    this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: iconColor ?? colors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandRow extends StatelessWidget {
  const _ExpandRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      button: true,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          fixedSize: const Size(40, 40),
          foregroundColor: colors.onSecondaryContainer,
          backgroundColor: colors.secondaryContainer,
          side: BorderSide(color: colors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 84,
      height: 84,
      child: CustomPaint(
        painter: _ScorePainter(
          trackColor: colors.surfaceContainerHighest,
          progressColor: colors.tertiary,
          foregroundColor: colors.onSurface,
          mutedColor: colors.onSurfaceVariant,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '78',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '/100',
              style: TextStyle(
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
    required this.foregroundColor,
    required this.mutedColor,
  });

  final Color trackColor;
  final Color progressColor;
  final Color foregroundColor;
  final Color mutedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .37;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final progress = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      2 * 3.1415926535 * .78,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _ScorePainter oldDelegate) =>
      trackColor != oldDelegate.trackColor ||
      progressColor != oldDelegate.progressColor;
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: _HeadingStyle(context, size),
      );
}

TextStyle _HeadingStyle(BuildContext context, double size) =>
    Theme.of(context).textTheme.titleMedium!.copyWith(
          fontSize: size,
          fontWeight: FontWeight.w800,
        );

TextStyle _mutedText(BuildContext context, double size) =>
    TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: size,
    );

BoxDecoration _tileDecoration(ColorScheme colors) => BoxDecoration(
      color: colors.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colors.outlineVariant),
    );