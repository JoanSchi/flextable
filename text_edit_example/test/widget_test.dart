// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';

void main() {
  //testWidgets('Counter increments smoke test', (WidgetTester tester) async {});

  test('tt', () {
    final splayTree = SplayTreeMap<int, String>.from({4: 'test'});
    final t = splayTree.firstKeyAfter(4);
    print(t);
  });
}
