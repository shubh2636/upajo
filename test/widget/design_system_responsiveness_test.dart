import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upajo/core/constants/app_constants.dart';
import 'package:upajo/core/theme/app_theme.dart';
import 'package:upajo/features/auth/domain/repositories/auth_repository.dart';
import 'package:upajo/features/auth/domain/models/user_profile.dart';
import 'package:upajo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:upajo/features/auth/presentation/language_select_screen.dart';
import 'package:upajo/features/auth/presentation/screens/welcome_screen.dart';
import 'package:upajo/features/auth/presentation/screens/role_selection_screen.dart';

class PreloadedAssetLoader extends AssetLoader {
  final Map<String, Map<String, dynamic>> data;
  const PreloadedAssetLoader(this.data);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final key = locale.scriptCode != null
        ? '${locale.languageCode}-${locale.scriptCode}'
        : locale.languageCode;
    return data[key] ?? {};
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserProfile?> getCurrentProfile() async => null;

  @override
  Future<UserProfile?> restoreSession() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Map<String, dynamic>> loadAllTranslationsSync() {
  final res = <String, Map<String, dynamic>>{};
  for (final name in ['en', 'hi', 'hi-Latn']) {
    final f = File('assets/translations/$name.json');
    res[name] = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }
  return res;
}

Widget createResponsiveApp({
  required Widget child,
  required Map<String, Map<String, dynamic>> translations,
  required Locale locale,
  required Size screenSize,
  required double textScaleFactor,
}) {
  return EasyLocalization(
    supportedLocales: AppConstants.supportedLocales,
    path: 'assets/translations',
    fallbackLocale: AppConstants.defaultLocale,
    startLocale: locale,
    assetLoader: PreloadedAssetLoader(translations),
    saveLocale: false,
    child: ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: locale,
            home: MediaQuery(
              data: MediaQueryData(
                size: screenSize,
                textScaler: TextScaler.linear(textScaleFactor),
                padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
              ),
              child: SizedBox(
                width: screenSize.width,
                height: screenSize.height,
                child: child,
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  late Map<String, Map<String, dynamic>> translations;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    translations = loadAllTranslationsSync();
  });

  group('STEP 3: Responsive Layout & Accessibility Audits (360dp & 1.5x Font Scale)', () {
    final testLocales = [
      AppConstants.localeHindi,
      AppConstants.localeEnglish,
      AppConstants.localeHinglish,
    ];

    for (final loc in testLocales) {
      final locTag = loc.scriptCode != null ? '${loc.languageCode}-${loc.scriptCode}' : loc.languageCode;

      testWidgets('LanguageSelectScreen renders with zero overflow on 360dp phone ($locTag)', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createResponsiveApp(
            translations: translations,
            locale: loc,
            screenSize: const Size(360, 640),
            textScaleFactor: 1.0,
            child: const LanguageSelectScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero RenderFlex overflow on 360dp screen');
      });

      testWidgets('LanguageSelectScreen handles 1.5x font scale without overflow ($locTag)', (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createResponsiveApp(
            translations: translations,
            locale: loc,
            screenSize: const Size(360, 780),
            textScaleFactor: 1.5,
            child: const LanguageSelectScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow with 1.5x accessibility font scale');
      });

      testWidgets('RoleSelectionScreen renders with zero overflow on 360dp phone ($locTag)', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createResponsiveApp(
            translations: translations,
            locale: loc,
            screenSize: const Size(360, 640),
            textScaleFactor: 1.0,
            child: const RoleSelectionScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow on 360dp');
      });

      testWidgets('RoleSelectionScreen handles 1.5x font scale without overflow ($locTag)', (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createResponsiveApp(
            translations: translations,
            locale: loc,
            screenSize: const Size(360, 780),
            textScaleFactor: 1.5,
            child: const RoleSelectionScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow with 1.5x font scale');
      });

      testWidgets('WelcomeScreen renders on 360dp phone with 1.5x font ($locTag)', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createResponsiveApp(
            translations: translations,
            locale: loc,
            screenSize: const Size(360, 640),
            textScaleFactor: 1.5,
            child: const WelcomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Elevated buttons enforce >=48dp touch targets across design system', (tester) async {
      await tester.pumpWidget(
        createResponsiveApp(
          translations: translations,
          locale: AppConstants.localeHindi,
          screenSize: const Size(390, 844),
          textScaleFactor: 1.0,
          child: const Scaffold(
            body: WelcomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsWidgets);

      for (final btn in buttons.evaluate()) {
        final size = tester.getSize(find.byWidget(btn.widget));
        expect(size.height, greaterThanOrEqualTo(48.0));
      }
    });
  });
}

