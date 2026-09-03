import 'package:intl/intl.dart';

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2);
final _pct = NumberFormat('+#,##0.00;-#,##0.00', 'tr_TR');
final _time = DateFormat('d MMM, HH:mm', 'tr_TR');

String formatPrice(double v, {String suffix = ' TL'}) =>
    '${_tl.format(v).trim()}$suffix';

String formatPercent(double v) => '%${_pct.format(v)}';

String formatUpdatedNow() => _time.format(DateTime.now());
