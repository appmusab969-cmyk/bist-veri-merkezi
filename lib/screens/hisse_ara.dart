import 'dart:async';

import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../services/yahoo_finance.dart';
import '../services/format.dart';
import '../widgets/sparkline.dart';

/// Canlı hisse arama ekranı — Yahoo Finance `search` + `chart` uç noktaları.
class HisseAraScreen extends StatefulWidget {
  const HisseAraScreen({super.key});

  @override
  State<HisseAraScreen> createState() => _HisseAraScreenState();
}

class _HisseAraScreenState extends State<HisseAraScreen> {
  final _api = YahooFinance();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<SearchHit> _hits = const [];
  bool _loading = false;
  String? _error;
  int _reqId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _api.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _hits = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    final id = ++_reqId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hits = await _api.search(q);
      if (!mounted || id != _reqId) return;
      setState(() {
        _hits = hits;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _reqId) return;
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
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainer,
        title: const Text('Hisse Ara'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _search,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                hintText: 'ASELS, THYAO, TUPRS…',
                hintStyle: TextStyle(color: colors.onSurfaceVariant),
                prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _CenteredNote(
        icon: Icons.cloud_off_rounded,
        title: 'Arama yapılamadı',
        message: _error!,
      );
    }
    if (_controller.text.trim().length < 2) {
      return _CenteredNote(
        icon: Icons.travel_explore_rounded,
        title: 'Bir hisse kodu yaz',
        message:
            'En az 2 karakter gir. Sonuçlar Yahoo Finance’ten canlı çekilir; '
            'fiyatlar gecikmeli olabilir.',
      );
    }
    if (_hits.isEmpty) {
      return _CenteredNote(
        icon: Icons.search_off_rounded,
        title: 'Sonuç bulunamadı',
        message: '“${_controller.text.trim()}” için eşleşen hisse yok.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _hits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final hit = _hits[i];
        return _ResultCard(
          hit: hit,
          quoteFuture: _api.fetchQuote(hit.symbol),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.hit, required this.quoteFuture});

  final SearchHit hit;
  final Future<Quote> quoteFuture;

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
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hit.bistCode.characters.take(2).toString(),
                  style: text.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.bistCode,
                      style: text.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      hit.name.isEmpty ? hit.exchange : hit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<Quote>(
            future: quoteFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (snap.hasError || !snap.hasData) {
                return Text(
                  'Fiyat alınamadı',
                  style: text.labelSmall?.copyWith(color: colors.error),
                );
              }
              final q = snap.data!;
              final changeColor = q.isUp ? colors.primary : colors.error;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatPrice(q.price),
                          style: text.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${formatPercent(q.changePercent)}  •  önceki ${formatPrice(q.previousClose)}',
                          style: text.labelSmall?.copyWith(color: changeColor),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    height: 36,
                    child: Sparkline(
                      values: q.spark,
                      color: changeColor,
                      fill: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CenteredNote extends StatelessWidget {
  const _CenteredNote({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
            Text(
              title,
              style: text.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
