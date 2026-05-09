// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:kanziapp/core/constants/app_constants.dart';

void main() {
  testWidgets('AppConstants should have correct app name',
      (WidgetTester tester) async {
    // Test app constants
    expect(AppConstants.appName, 'Kanzi');
    expect(AppConstants.roomCodeLength, 6);
  });
}
