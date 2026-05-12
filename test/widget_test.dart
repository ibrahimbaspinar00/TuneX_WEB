import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:tunex/main.dart';
import 'package:tunex/providers/theme_provider.dart';

void main() {
  testWidgets('App loads with TuneX branding and light theme by default',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(initialThemeMode: ThemeMode.light),
        child: const TuneXApp(),
      ),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'TuneX');
    expect(app.themeMode, ThemeMode.light);
  });
}
