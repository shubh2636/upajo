import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_motifs.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    if (SupabaseService.isAuthenticated) {
      // Check user role from profiles
      try {
        final profile = await SupabaseService.client
            .from('profiles')
            .select('role')
            .eq('id', SupabaseService.currentUserId!)
            .maybeSingle();

        if (profile != null && profile['role'] == 'farmer') {
          context.go(RouteNames.farmerDashboard);
          return;
        } else if (profile != null && profile['role'] == 'admin') {
          context.go(RouteNames.admin);
          return;
        }
      } catch (_) {
        // Fallback to consumer
      }
      context.go(RouteNames.consumerHome);
    } else {
      context.go(RouteNames.languageSelect);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary600,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Upajo Brand Icon Badge
                Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SeedSproutMotif(size: 64.0),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Name: उपजो | Upajo
                Text(
                  'app_name'.tr(),
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 40.0,
                  ),
                ),
                const SizedBox(height: 8.0),

                // Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'app_tagline'.tr(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.wheat200,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 48.0),
                const SizedBox(
                  width: 32.0,
                  height: 32.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.wheat400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

