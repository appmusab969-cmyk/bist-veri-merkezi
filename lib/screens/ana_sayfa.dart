import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/quote.dart';
import '../services/market_repository.dart';
import '../services/format.dart';
import '../services/app_settings.dart';
import '../widgets/sparkline.dart';
import 'hisse_ara.dart';
import 'hisse_detay.dart';

class MarketCockpitScreen extends StatefulWidget {
  const MarketCockpitScreen({super.key});

  @override
  State<MarketCockpitScreen> createState() => _MarketCockpitScreenState();
}

class _MarketCockpitScreenState extends State<MarketCockpitScreen> {
  final _repo = MarketRepository();

  Quote? _index;
  List<Quote> _stocks = const [];
  DateTime? _updatedAt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
    _load();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _repo.dispose();
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _repo.marketSnapshot(forceRefresh: force);
      if (!mounted) return;
      // Katılım filtresi istemci tarafında uygulanır (sunucuya sorgu yok).
      final onlyParticipation = AppSettings.instance.participationFilter;
      final rows = snap.rows
          .where((r) => !onlyParticipation || r.participation)
          .map((r) => Quote(
                symbol: '${r.code}.IS',
                shortName: r.name,
                price: r.price,
                previousClose: r.price / (1 + r.changePercent / 100),
                currency: 'TRY',
                spark: r.spark,
              ))
          .toList();
      setState(() {
        _index = snap.market;
        _stocks = rows;
        _updatedAt = snap.updatedAt;
        _loading = false;
        if (_index == null && rows.isEmpty) {
          _error = 'Veri alınamadı. İnternet bağlantını kontrol et.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(force: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                    index: _index, loading: _loading, updatedAt: _updatedAt),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SearchButton(),
                    const SizedBox(height: 28),
                    _MarketBreadth(index: _index, stocks: _stocks),
                    const SizedBox(height: 28),
                    if (_error != null)
                      _ErrorCard(message: _error!, onRetry: _load)
                    else
                      _ResearchRadar(stocks: _stocks, loading: _loading),
                    const SizedBox(height: 28),
                    _ParticipationNotice(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.index, this.loading = false, this.updatedAt});

  final Quote? index;
  final bool loading;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final idx = index;
    final isUp = idx?.isUp ?? true;
    final changeColor = isUp ? colors.primary : colors.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PİYASA KOKPİTİ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ana Sayfa',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              _IconButton(
                icon: Icons.notifications_none_rounded,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bildirimler henüz aktif değil.'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'BIST 100',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        label: 'Açık',
                        color: colors.primary,
                        background: colors.primary.withValues(alpha: .15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        idx != null
                            ? formatPrice(idx.price, suffix: '')
                            : (loading ? '…' : '—'),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        idx != null ? formatPercent(idx.changePercent) : '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w700,
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
                    'Son güncelleme',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    updatedAt != null
                        ? formatRelative(updatedAt!)
                        : (loading ? 'yükleniyor…' : '—'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  _SearchButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HisseAraScreen()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: .35)),
          ),
          child: Row(
            children: [
              _CircleIcon(
                icon: Icons.search_rounded,
                foreground: colors.primary,
                background: colors.primary.withValues(alpha: .15),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hisse ara: ASELS, THYAO, TUPRS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
              Icon(Icons.arrow_outward_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Takip listesindeki hisselerin gün içi durumundan hesaplanan gerçek özet.
class _MarketBreadth extends StatelessWidget {
  const _MarketBreadth({required this.index, required this.stocks});

  final Quote? index;
  final List<Quote> stocks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final up = stocks.where((q) => q.isUp).length;
    final down = stocks.length - up;
    final avg = stocks.isEmpty
        ? 0.0
        : stocks.map((q) => q.changePercent).reduce((a, b) => a + b) /
            stocks.length;

    final idxColor =
        (index?.isUp ?? true) ? colors.primary : colors.error;

    return _Section(
      eyebrow: 'Canlı bakış',
      title: 'Piyasa Özeti',
      trailing: 'Hesaplanıyor',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index != null)
                Text(
                  'BIST 100: ${formatPrice(index!.price, suffix: '')}  '
                  '${formatPercent(index!.changePercent)}',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: idxColor,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Takip listesi: $up yükselen · $down düşen · '
                'ortalama ${formatPercent(avg)}',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                'Bu satır yalnızca canlı fiyatlardan hesaplanır; yorum içermez.',
                style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResearchRadar extends StatelessWidget {
  const _ResearchRadar({required this.stocks, required this.loading});

  final List<Quote> stocks;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (loading && stocks.isEmpty) {
      return _Section(
        eyebrow: 'Araştırma radarı',
        title: 'Takip Listesi',
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    final featured = stocks.isNotEmpty ? stocks.first : null;
    final rest = stocks.length > 1 ? stocks.sublist(1) : const <Quote>[];
    final chartColors = [AppColors.chart2, AppColors.chart3, AppColors.chart4];

    return _Section(
      eyebrow: 'Araştırma radarı',
      title: 'Takip Listesi',
      trailing: 'Canlı fiyat',
      trailingColor: colors.primary,
      children: [
        if (featured != null) _FeaturedStock(quote: featured),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < rest.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _CompactStock(
                    quote: rest[i],
                    chartColor: chartColors[i % chartColors.length],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _FeaturedStock extends StatelessWidget {
  const _FeaturedStock({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final changeColor = quote.isUp ? colors.primary : colors.error;

    return _TappableStock(
      code: quote.bistCode,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.primary,
                child: Text(
                  '1',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          quote.bistCode,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            quote.shortName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        text: '${formatPrice(quote.price)} ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(
                            text: formatPercent(quote.changePercent),
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: changeColor.withValues(alpha: .1),
                  border: Border.all(color: changeColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      quote.isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: changeColor,
                      size: 16,
                    ),
                    Text(
                      formatPercent(quote.changePercent),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Önceki kapanış: ${formatPrice(quote.previousClose)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gün içi değişim: ${formatPrice(quote.change)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 112,
                height: 42,
                child: Sparkline(
                  values: quote.spark,
                  color: changeColor,
                  fill: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.outline, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fiyatlar Yahoo Finance • gecikmeli olabilir',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HisseAraScreen()),
                ),
                child: Text(
                  'Ara  →',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

/// Bir kartı sarıp hisse detayına götüren yardımcı.
class _TappableStock extends StatelessWidget {
  const _TappableStock({required this.code, required this.child});
  final String code;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HisseDetayScreen(code: code),
        )),
        child: child,
      ),
    );
  }
}

class _CompactStock extends StatelessWidget {
  const _CompactStock({
    required this.quote,
    required this.chartColor,
  });

  final Quote quote;
  final Color chartColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final changeColor = quote.isUp ? colors.primary : colors.error;

    return _TappableStock(
      code: quote.bistCode,
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quote.bistCode,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                formatPercent(quote.changePercent),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatPrice(quote.price),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            width: double.infinity,
            child: Sparkline(values: quote.spark, color: changeColor),
          ),
          const SizedBox(height: 8),
          Text(
            quote.shortName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// Katılım filtresi durumunu gösteren ve tek dokunuşla açıp kapatan kart.
class _ParticipationNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final on = AppSettings.instance.participationFilter;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: on ? .10 : .04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withValues(alpha: on ? .25 : .12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            on ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
            color: colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              on
                  ? 'Katılım filtresi açık — yalnızca Katılım Endeksi hisseleri'
                  : 'Katılım filtresi kapalı — tüm hisseler gösteriliyor',
              style: text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: on,
            onChanged: AppSettings.instance.setParticipationFilter,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.eyebrow,
    required this.title,
    required this.children,
    this.trailing,
    this.trailingColor,
  });

  final String eyebrow;
  final String title;
  final List<Widget> children;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
                    eyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: trailingColor ?? colors.onSurfaceVariant,
                  fontWeight:
                      trailingColor == null ? FontWeight.normal : FontWeight.w800,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.size,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: foreground, size: size * .55),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: colors.secondary),
      style: IconButton.styleFrom(
        backgroundColor: colors.secondaryContainer,
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
      ),
    );
  }
}

