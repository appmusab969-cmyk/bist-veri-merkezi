import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:pusula/main.dart';

void main() {
  testWidgets('Uygulama açılır ve alt gezinme görünür', (tester) async {
    await initializeDateFormatting('tr_TR');
    await tester.pumpWidget(const PusulaApp());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Ana Sayfa'), findsWidgets);
    expect(find.text('Formasyonlar'), findsWidgets);
    expect(find.text('Ayarlar'), findsWidgets);
  });
}
