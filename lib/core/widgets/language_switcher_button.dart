import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

class LanguageSwitcherButton extends StatelessWidget {
  final bool isDark;

  const LanguageSwitcherButton({super.key, this.isDark = false});

  static String getLanguageDisplayName(Locale locale) {
    if (locale.languageCode == 'hi' && locale.scriptCode == 'Latn') {
      return 'Hinglish';
    } else if (locale.languageCode == 'hi') {
      return 'हिन्दी';
    } else {
      return 'English';
    }
  }

  static void showLanguagePicker(BuildContext context) {
    final currentLocale = context.locale;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.soil50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.soil300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 18.0),
              Text(
                'language.select_title'.tr(),
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6.0),
              Text(
                'language.select_subtitle'.tr(),
                style: AppTypography.bodySmall.copyWith(color: AppColors.soil600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),

              // Hindi Option
              _buildOptionCard(
                context: ctx,
                locale: AppConstants.localeHindi,
                title: 'language.hi_name'.tr(),
                subtitle: 'language.hi_desc'.tr(),
                isSelected: currentLocale == AppConstants.localeHindi,
                badgeLetter: 'अ',
              ),
              const SizedBox(height: 12.0),

              // English Option
              _buildOptionCard(
                context: ctx,
                locale: AppConstants.localeEnglish,
                title: 'language.en_name'.tr(),
                subtitle: 'language.en_desc'.tr(),
                isSelected: currentLocale == AppConstants.localeEnglish,
                badgeLetter: 'A',
              ),
              const SizedBox(height: 12.0),

              // Hinglish Option
              _buildOptionCard(
                context: ctx,
                locale: AppConstants.localeHinglish,
                title: 'language.hinglish_name'.tr(),
                subtitle: 'language.hinglish_desc'.tr(),
                isSelected: currentLocale == AppConstants.localeHinglish,
                badgeLetter: 'H',
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOptionCard({
    required BuildContext context,
    required Locale locale,
    required String title,
    required String subtitle,
    required bool isSelected,
    required String badgeLetter,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      borderRadius: 16.0,
      borderColor: isSelected ? AppColors.primary500 : AppColors.soil200,
      borderWidth: isSelected ? 2.0 : 1.0,
      backgroundColor: isSelected ? AppColors.primary50 : Colors.white,
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
      },
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary500 : AppColors.soil100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                badgeLetter,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : AppColors.soil800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.primary700 : AppColors.soil900,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.soil600),
                ),
              ],
            ),
          ),
          Radio<Locale>(
            value: locale,
            groupValue: context.locale,
            activeColor: AppColors.primary500,
            onChanged: (val) {
              if (val != null) {
                context.setLocale(val);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.locale;
    final langName = getLanguageDisplayName(current);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showLanguagePicker(context),
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.soil100,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.soil300,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 18.0,
                color: isDark ? Colors.white : AppColors.primary600,
              ),
              const SizedBox(width: 6.0),
              Text(
                langName,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.soil800,
                ),
              ),
              const SizedBox(width: 4.0),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16.0,
                color: isDark ? Colors.white70 : AppColors.soil600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
