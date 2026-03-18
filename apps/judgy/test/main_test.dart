import 'package:flutter_test/flutter_test.dart';
import 'package:judgy/main.dart';

void main() {
  group('App Initialization', () {
    test('setupSystemChrome function exists', () {
      // Verify the function is defined and callable
      expect(setupSystemChrome, isA<Function>());
    });

    test('setupFirebase function exists', () {
      // Verify the function is defined and callable
      expect(setupFirebase, isA<Function>());
    });

    test('initializeServices function exists', () {
      // Verify the function is defined and callable
      expect(initializeServices, isA<Function>());
    });
  });
}
