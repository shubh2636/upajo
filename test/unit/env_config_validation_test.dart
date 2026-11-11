import 'package:flutter_test/flutter_test.dart';
import 'package:upajo/core/config/env_config.dart';

void main() {
  group('EnvConfig Strict Startup Validation', () {
    test('validateConfig fails loudly when SUPABASE_URL contains placeholder', () {
      expect(
        () => EnvConfig.validateConfig(),
        throwsA(isA<StateError>()),
      );
    });
  });
}

