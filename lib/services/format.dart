import 'package:intl/intl.dart';

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2);
final _pct = NumberFormat('+#,##0.00;-#,##0.00', 'tr_TR');
final _time = DateFormat('d MMM, HH:mm', 'tr_TR');

String formatPrice(double v, {String suffix = ' TL'}) =>
    '${_tl.format(v).trim()}$suffix';

String formatPercent(double v) => '%${_pct.format(v)}';

String formatUpdatedNow() => _time.format(DateTime.now());

String formatDate(DateTime d) => _time.format(d.toLocal());

/// "3 saat önce" gibi göreli süre — önbelleğin ne kadar taze olduğunu göstermek için.
String formatRelative(DateTime d) {
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} saat önce';
  return '${diff.inDays} gün önce';
}
