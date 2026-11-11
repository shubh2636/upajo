import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:upajo/core/utils/formatters.dart';

void main() {
  group('Localization Parity & Clean Language Audits (STEP 1 CI Check)', () {
    late Map<String, dynamic> enJson;
    late Map<String, dynamic> hiJson;
    late Map<String, dynamic> hinglishJson;

    late Map<String, String> enLeaves;
    late Map<String, String> hiLeaves;
    late Map<String, String> hinglishLeaves;

    Map<String, String> flatten(Map<String, dynamic> map, [String prefix = '']) {
      final result = <String, String>{};
      for (final entry in map.entries) {
        final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        if (entry.value is Map<String, dynamic>) {
          result.addAll(flatten(entry.value as Map<String, dynamic>, key));
        } else {
          result[key] = entry.value.toString();
        }
      }
      return result;
    }

    setUpAll(() {
      final enFile = File('assets/translations/en.json');
      final hiFile = File('assets/translations/hi.json');
      final hinglishFile = File('assets/translations/hi-Latn.json');

      expect(enFile.existsSync(), isTrue, reason: 'en.json must exist');
      expect(hiFile.existsSync(), isTrue, reason: 'hi.json must exist');
      expect(hinglishFile.existsSync(), isTrue, reason: 'hi-Latn.json must exist');

      enJson = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
      hiJson = json.decode(hiFile.readAsStringSync()) as Map<String, dynamic>;
      hinglishJson = json.decode(hinglishFile.readAsStringSync()) as Map<String, dynamic>;

      enLeaves = flatten(enJson);
      hiLeaves = flatten(hiJson);
      hinglishLeaves = flatten(hinglishJson);
    });

    test('100% key parity across English, Hindi, and Hinglish translation files', () {
      final enKeys = enLeaves.keys.toSet();
      final hiKeys = hiLeaves.keys.toSet();
      final hinglishKeys = hinglishLeaves.keys.toSet();

      final missingInHi = enKeys.difference(hiKeys);
      final missingInEn = hiKeys.difference(enKeys);
      final missingInHinglish = enKeys.difference(hinglishKeys);
      final extraInHinglish = hinglishKeys.difference(enKeys);

      expect(missingInHi, isEmpty, reason: 'Keys in en.json missing from hi.json: $missingInHi');
      expect(missingInEn, isEmpty, reason: 'Keys in hi.json missing from en.json: $missingInEn');
      expect(missingInHinglish, isEmpty, reason: 'Keys in en.json missing from hi-Latn.json: $missingInHinglish');
      expect(extraInHinglish, isEmpty, reason: 'Extra keys in hi-Latn.json: $extraInHinglish');
      expect(enLeaves.length, equals(hiLeaves.length));
      expect(enLeaves.length, equals(hinglishLeaves.length));
    });

    test('No empty strings or placeholder strings in any translation file', () {
      for (final entry in enLeaves.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue, reason: 'en.json has empty key: ${entry.key}');
        expect(entry.value.contains('TODO'), isFalse, reason: 'en.json contains placeholder: ${entry.key}');
      }
      for (final entry in hiLeaves.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue, reason: 'hi.json has empty key: ${entry.key}');
        expect(entry.value.contains('TODO'), isFalse, reason: 'hi.json contains placeholder: ${entry.key}');
      }
      for (final entry in hinglishLeaves.entries) {
        expect(entry.value.trim().isNotEmpty, isTrue, reason: 'hi-Latn.json has empty key: ${entry.key}');
        expect(entry.value.contains('TODO'), isFalse, reason: 'hi-Latn.json contains placeholder: ${entry.key}');
      }
    });

    test('Zero Devanagari characters in en.json and hi-Latn.json', () {
      final devanagariRegex = RegExp(r'[\u0900-\u097F]');

      for (final entry in enLeaves.entries) {
        final matches = devanagariRegex.allMatches(entry.value);
        expect(
          matches.isEmpty,
          isTrue,
          reason: 'en.json contains Devanagari character in key "${entry.key}": "${entry.value}"',
        );
      }

      for (final entry in hinglishLeaves.entries) {
        final matches = devanagariRegex.allMatches(entry.value);
        expect(
          matches.isEmpty,
          isTrue,
          reason: 'hi-Latn.json contains Devanagari character in key "${entry.key}": "${entry.value}"',
        );
      }
    });

    test('Zero bilingual mixed strings (no "Hindi (English)" or "English (Hindi)") in any file', () {
      final bilingualPattern = RegExp(
        r'[\u0900-\u097F]+[^\)\(\n]*\([A-Za-z]+[A-Za-z\s]*\)|[A-Za-z]+[^\)\(\n]*\([\u0900-\u097F]+[\u0900-\u097F\s]*\)',
      );

      for (final entry in enLeaves.entries) {
        expect(
          bilingualPattern.hasMatch(entry.value),
          isFalse,
          reason: 'en.json contains mixed bilingual text in "${entry.key}": "${entry.value}"',
        );
      }
      for (final entry in hiLeaves.entries) {
        expect(
          bilingualPattern.hasMatch(entry.value),
          isFalse,
          reason: 'hi.json contains mixed bilingual text in "${entry.key}": "${entry.value}"',
        );
      }
      for (final entry in hinglishLeaves.entries) {
        expect(
          bilingualPattern.hasMatch(entry.value),
          isFalse,
          reason: 'hi-Latn.json contains mixed bilingual text in "${entry.key}": "${entry.value}"',
        );
      }
    });

    test('hi.json contains proper Devanagari text (not Latin-only paragraphs)', () {
      final devanagariRegex = RegExp(r'[\u0900-\u097F]');
      const allowedLatinKeys = {
        'common.rupee_symbol',
        'common.whatsapp',
        'language.en_name',
        'language.hinglish_name',
        'auth.phone_hint',
        'auth.pincode_hint',
        'auth.total_acres_hint',
      };

      for (final entry in hiLeaves.entries) {
        if (allowedLatinKeys.contains(entry.key)) continue;
        expect(
          devanagariRegex.hasMatch(entry.value),
          isTrue,
          reason: 'hi.json key "${entry.key}" lacks Devanagari text: "${entry.value}"',
        );
      }
    });

    test('AppFormatters formats currency, weights, and areas per locale', () {
      const hi = Locale('hi');
      const en = Locale('en');
      const hinglish = Locale.fromSubtags(languageCode: 'hi', scriptCode: 'Latn');

      // Currency
      expect(AppFormatters.currency(1250, locale: hi), contains('1,250'));
      expect(AppFormatters.currency(1250, locale: en), contains('1,250'));
      expect(AppFormatters.currency(1250, locale: hinglish), contains('1,250'));

      // Weight
      expect(AppFormatters.weight(10, locale: hi), equals('10 किग्रा'));
      expect(AppFormatters.weight(10, locale: en), equals('10 kg'));
      expect(AppFormatters.weight(10, locale: hinglish), equals('10 kg'));

      // Area
      expect(AppFormatters.area(2.5, locale: hi), equals('2.5 एकड़'));
      expect(AppFormatters.area(2.5, locale: en), equals('2.5 acres'));
      expect(AppFormatters.area(2.5, locale: hinglish), equals('2.5 acres'));
    });
  });
}
