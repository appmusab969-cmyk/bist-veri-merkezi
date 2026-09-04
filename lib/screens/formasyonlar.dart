import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../services/market_repository.dart';
import '../services/format.dart';
import '../services/technical.dart';
import '../services/app_settings.dart';
import '../widgets/sparkline.dart';
import 'hisse_detay.dart';

class _Row {
  _Row(this.code, this.quote, this.signal, this.spark);
  final String code;
  final Quote quote;
  final TechnicalSignal signal;
  final List<double> spark;

  bool get participation => isParticipationStock(code);
}

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  final _repo = MarketRepository();

  int _filter = 0; // 0 Tümü · 1 Yükseliş sinyali · 2 Katılım · 3 Yüksek güven
  bool _loading = true;
  String? _error;
  List<_Row> _rows = [];

  static const _filters = ['Tümü', 'Yükseliş sinyali', 'Katılım', 'Yüksek güven'];

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_onSettings);
    _scan();
  }

  List<String> _universe = const [];

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _repo.dispose();
    super.dispose();
  }

  void _onSettings() => setState(() {});

  Future<void> _scan({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Evren + fiyatlar tek statik dosyadan (index.json) gelir.
      final snap = await _repo.marketSnapshot(forceRefresh: force);
      _universe = snap.rows.map((r) => r.code).toList();
      final byCode = {for (final r in snap.rows) r.code: r};

      // Teknik sinyal için günlük OHLC — her biri hisse başına tek statik dosya,
      // 12 saat CDN'de önbelleklenir. 10.000 kullanıcı arka uca yük bindirmez.
      final rows = <_Row>[];
      const chunk = 8;
      for (var i = 0; i < _universe.length; i += chunk) {
        final part =
            _universe.sublist(i, (i + chunk).clamp(0, _universe.length));
        final results = await Future.wait(part.map((code) async {
          try {
            final hist = await _repo.history(code);
            if (hist.length < 25) return null;
            final sig = TechnicalSignal.fromCandles(hist);
            final r = byCode[code]!;
            final q = Quote(
              symbol: '$code.IS',
              shortName: r.name,
              price: r.price,
              previousClose: r.price / (1 + r.changePercent / 100),
              currency: 'TRY',
              spark: r.spark,
            );
            return _Row(
              code,
              q,
              sig,
              hist.sublist(hist.length - 40).map((c) => c.close).toList(),
            );
          } catch (_) {
            return null;
          }
        }));
        rows.addAll(results.whereType<_Row>());
        if (mounted) setState(() => _rows = _sorted(rows));
      }
      if (!mounted) return;
      setState(() {
        _rows = _sorted(rows);
        _loading = false;
        if (rows.isEmpty) _error = 'Tarama sonucu boş. Bağlantıyı kontrol et.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<_Row> _sorted(List<_Row> rows) {
    final copy = [...rows];
    copy.sort((a, b) => b.signal.confidence.compareTo(a.signal.confidence));
    return copy;
  }

  List<_Row> get _visible {
    final s = AppSettings.instance;
    return _rows.where((r) {
      if (s.participationFilter && !r.participation) return false;
      if (s.highConfidenceOnly && r.signal.confidence < 60) return false;
      switch (_filter) {
        case 1:
          if (!r.signal.isBullish) return false;
          break;
        case 2:
          if (!r.participation) return false;
          break;
        case 3:
          if (r.signal.confidence < 70) return false;
          break;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final rows = _visible;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _scan,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ALGORİTMİK TARAMA',
                          style: text.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Formasyonlar',
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'Fiyat serisinden hareketli ortalama kesişimi ve '
                        '20 günlük kanal kırılımı taranır. LLM kullanılmaz.',
                        style: text.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ChoiceChip(
                      selected: _filter == i,
                      label: Text(_filters[i]),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = i),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      if (_loading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (_loading) const SizedBox(width: 8),
                      Text(
                        _loading
                            ? 'Taranıyor… (${_rows.length}/${_universe.length})'
                            : '${rows.length} sonuç',
                        style: text.labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!,
                        style: text.bodyMedium?.copyWith(color: colors.error)),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverList.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _FormationTile(row: rows[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormationTile extends StatelessWidget {
  const _FormationTile({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final s = row.signal;
    final accent = s.isBullish ? colors.primary : colors.error;
    final q = row.quote;
    final changeColor = q.isUp ? colors.primary : colors.error;

    return Material(
      color: colors.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HisseDetayScreen(code: row.code),
        )),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: s.confidence >= 70
                  ? accent.withValues(alpha: .45)
                  : colors.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(row.code,
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  if (row.participation) ...[
                    const SizedBox(width: 8),
                    _Tag(text: 'Katılım', color: colors.primary),
                  ],
                  const Spacer(),
                  Text(formatPercent(q.changePercent),
                      style: text.labelMedium?.copyWith(
                          color: changeColor, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 2),
              Text(s.title,
                  style: text.labelSmall
                      ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatPrice(q.price),
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          'Trend ${s.trendTr} • Güven ${s.confidence}/100',
                          style: text.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    height: 38,
                    child: Sparkline(values: row.spark, color: accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
