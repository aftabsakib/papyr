import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bedbreaker/main.dart';

void main() {
  testWidgets('BedBreaker app renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const BedBreakerApp());
    expect(find.text('BedBreaker'), findsOneWidget);
  });
}
