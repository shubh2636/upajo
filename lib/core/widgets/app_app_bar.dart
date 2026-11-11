import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'language_switcher_button.dart';

/// Reusable earthy high-contrast AppBar for Upajo screens
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showLanguageSwitcher;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showLanguageSwitcher = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (subtitle != null ? 14.0 : 0.0) + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      elevation: elevation,
      scrolledUnderElevation: 1.0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.soil800,
      centerTitle: false,
      leading: leading ??
          (showBackButton && canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.soil800),
                  onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                )
              : null),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.soil900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6.0),
              // Signature Seed-Sprout micro badge
              Container(
                width: 6.0,
                height: 6.0,
                decoration: const BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2.0),
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.soil600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        if (showLanguageSwitcher) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: LanguageSwitcherButton(),
          ),
        ],
      ],
      bottom: bottom,
    );
  }
}

