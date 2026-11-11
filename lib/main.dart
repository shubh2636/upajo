import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_constants.dart';
import 'core/network/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/backend_not_configured_screen.dart';
import 'features/disease_detection/data/repositories/disease_detection_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Load environment variables safely
  await EnvConfig.initialize(failLoudly: false);

  // If backend credentials are empty or contain "your-project", show full-screen message
  if (!EnvConfig.isBackendConfigured) {
    runApp(
      BackendNotConfiguredApp(
        reason: EnvConfig.configErrorReason ?? 'Supabase configuration missing or invalid.',
      ),
    );
    return;
  }

  // Initialize Supabase Client
  await SupabaseService.initialize();

  // Preload disease scan TFLite model and agronomic database
  try {
    await DiseaseDetectionRepositoryImpl().preloadModel();
  } catch (e) {
    debugPrint('[DiseaseDetection] Preload notice: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: AppConstants.supportedLocales,
      path: AppConstants.translationsPath,
      fallbackLocale: AppConstants.defaultLocale,
      startLocale: AppConstants.defaultLocale,
      child: const ProviderScope(
        child: UpajoApp(),
      ),
    ),
  );
}

class UpajoApp extends StatelessWidget {
  const UpajoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
