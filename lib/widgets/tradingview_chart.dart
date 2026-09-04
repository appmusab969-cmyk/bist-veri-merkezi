import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// TradingView'in ücretsiz "Advanced Chart" widget'ını bir WebView içinde
/// gösterir. Grafik tamamen TradingView'in CDN'inden gelir — bizim sunucumuza
/// veya Yahoo'ya hiçbir yük binmez, %100 doğru fiyat/indikatör.
///
/// Mobilde (Android/iOS) çalışır. Web/masaüstünde WebView yoksa
/// [fallback] gösterilir (ör. yerli sparkline).
class TradingViewChart extends StatefulWidget {
  const TradingViewChart({
    super.key,
    required this.code,
    this.exchange = 'BIST',
    this.height = 380,
    this.interval = 'D',
    this.fallback,
  });

  final String code; // "ASELS"
  final String exchange; // BIST
  final double height;
  final String interval; // "D", "60", "W"...
  final Widget? fallback;

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  WebViewController? _controller;
  bool _loading = true;
  bool _unsupported = false;

  @override
  void initState() {
    super.initState();
    try {
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0E0E12))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadHtmlString(_html());
      _controller = c;
    } catch (_) {
      _unsupported = true;
    }
  }

  String _symbol() => '${widget.exchange}:${widget.code.toUpperCase()}';

  String _html() => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>
  html,body{margin:0;padding:0;background:#0E0E12;height:100%;overflow:hidden}
  #wrap{height:100vh;width:100vw}
</style>
</head>
<body>
<div id="wrap"><div class="tradingview-widget-container" style="height:100%">
  <div id="tv_chart" style="height:100%"></div>
</div></div>
<script src="https://s3.tradingview.com/tv.js"></script>
<script>
  new TradingView.widget({
    "container_id": "tv_chart",
    "symbol": "${_symbol()}",
    "interval": "${widget.interval}",
    "timezone": "Europe/Istanbul",
    "theme": "dark",
    "style": "1",
    "locale": "tr",
    "autosize": true,
    "hide_side_toolbar": false,
    "allow_symbol_change": false,
    "withdateranges": true,
    "studies": ["RSI@tv-basicstudies", "MASimple@tv-basicstudies"]
  });
</script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_unsupported || _controller == null) {
      return widget.fallback ??
          _Note(
            'Grafik bu platformda gösterilemiyor. Mobil uygulamada TradingView '
            'grafiği açılır.',
            colors,
          );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller!),
            if (_loading)
              Container(
                color: colors.surface,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, this.colors);
  final String text;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.show_chart_rounded, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant)),
            ),
          ],
        ),
      );
}
