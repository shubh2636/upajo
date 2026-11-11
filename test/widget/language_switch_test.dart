import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upajo/core/constants/app_constants.dart';
import 'package:upajo/core/theme/app_theme.dart';
import 'package:upajo/core/widgets/empty_state_view.dart';
import 'package:upajo/core/widgets/error_view.dart';
import 'package:upajo/features/auth/domain/repositories/auth_repository.dart';
import 'package:upajo/features/auth/domain/models/user_profile.dart';
import 'package:upajo/features/auth/presentation/controllers/auth_controller.dart';
import 'package:upajo/features/auth/presentation/language_select_screen.dart';
import 'package:upajo/features/auth/presentation/screens/welcome_screen.dart';
import 'package:upajo/features/auth/presentation/screens/login_screen.dart';
import 'package:upajo/features/auth/presentation/screens/signup_screen.dart';
import 'package:upajo/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:upajo/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:upajo/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:upajo/features/auth/presentation/screens/delete_account_screen.dart';

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

Widget createScreenTester({
  required Widget Function(BuildContext) screenBuilder,
  required Map<String, Map<String, dynamic>> translations,
  Locale initialLocale = const Locale('hi'),
}) {
  return EasyLocalization(
    supportedLocales: AppConstants.supportedLocales,
    path: 'assets/translations',
    fallbackLocale: AppConstants.defaultLocale,
    startLocale: initialLocale,
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
            locale: context.locale,
            home: Builder(
              builder: (innerContext) {
                // KeyedSubtree with locale forces fresh build of the screen on language switch
                return KeyedSubtree(
                  key: ValueKey(innerContext.locale),
                  child: screenBuilder(innerContext),
                );
              },
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

  group('STEP 2: Language Switcher & Localization Tests (10 Key Screens)', () {
    testWidgets('1. LanguageSelectScreen switches title across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const LanguageSelectScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('अपनी भाषा चुनें'), findsOneWidget);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Choose Your Language'), findsOneWidget);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Apni bhasha chunein'), findsOneWidget);
    });

    testWidgets('2. WelcomeScreen switches tagline across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const WelcomeScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('सीधे खेत से घर तक — 100% शुद्ध एवं पारदर्शी'), findsOneWidget);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Direct from farm to fork — 100% pure & transparent'), findsOneWidget);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Seedhe khet se ghar tak — 100% shuddh aur transparent'), findsOneWidget);
    });

    testWidgets('3. LoginScreen switches headline across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const LoginScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('उपजो में आपका स्वागत है'), findsOneWidget);
      expect(find.text('लॉग इन करें'), findsWidgets);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Upajo'), findsOneWidget);
      expect(find.text('Log In'), findsWidgets);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Upajo me aapka swagat hai'), findsOneWidget);
      expect(find.text('Log In karein'), findsWidgets);
    });

    testWidgets('4. SignupScreen switches headline across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const SignupScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('खाता बनाएं'), findsWidgets);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsWidgets);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Khaata banayein'), findsWidgets);
    });

    testWidgets('5. ForgotPasswordScreen switches title across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const ForgotPasswordScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('पासवर्ड रीसेट करें'), findsOneWidget);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Reset Password'), findsOneWidget);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Password reset karein'), findsOneWidget);
    });

    testWidgets('6. VerifyOtpScreen switches header across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const VerifyOtpScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('ओटीपी सत्यापन'), findsOneWidget);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Verify OTP'), findsOneWidget);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('OTP verification'), findsOneWidget);
    });

    testWidgets('7. RoleSelectionScreen switches role title across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const RoleSelectionScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('आप उपजो का उपयोग किस रूप में करेंगे?'), findsOneWidget);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('How will you be using Upajo?'), findsOneWidget);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Aap Upajo ka use kis roop me karenge?'), findsOneWidget);
    });

    testWidgets('8. DeleteAccountScreen switches danger prompt across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return const DeleteAccountScreen();
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('खाता हटाएं'), findsWidgets);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Delete Account'), findsWidgets);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Account delete karein'), findsWidgets);
    });

    testWidgets('9. EmptyStateView renders localized title and button across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return Scaffold(
              body: EmptyStateView(
                title: 'common.empty'.tr(),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('यहाँ अभी कोई जानकारी नहीं है'), findsOneWidget);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('No data available here yet'), findsOneWidget);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Yahan abhi koi data nahi hai'), findsOneWidget);
    });

    testWidgets('10. ErrorView renders localized error badge and retry button across 3 languages', (tester) async {
      BuildContext? liveContext;

      await tester.pumpWidget(
        createScreenTester(
          translations: translations,
          screenBuilder: (ctx) {
            liveContext = ctx;
            return Scaffold(
              body: ErrorView(
                errorMessage: 'Network issue',
                onRetry: () {},
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Hindi
      expect(find.text('कुछ गड़बड़ हुई, पुनः प्रयास करें'), findsOneWidget);
      expect(find.text('पुनः प्रयास करें'), findsOneWidget);

      // Switch to English
      await liveContext!.setLocale(AppConstants.localeEnglish);
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong, please retry'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Switch to Hinglish
      await liveContext!.setLocale(AppConstants.localeHinglish);
      await tester.pumpAndSettle();
      expect(find.text('Kuch gadbad hui, dobara try karein'), findsOneWidget);
      expect(find.text('Dobara koshish karein'), findsOneWidget);
    });
  });
}
