import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gabay/providers/app_provider.dart';
import 'package:gabay/core/data_source_factory.dart';

void main() {
  testWidgets('GABAY app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(createAppDataSource())..init(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return const Scaffold(
                body: Center(child: Text('GABAY')),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('GABAY'), findsOneWidget);
  });
}
