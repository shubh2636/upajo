import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late Locale _selectedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale = context.locale;
  }

  void _onSelect(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
    context.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40.0),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12.0),

                      // Heading & Greeting
                      Center(
                        child: Container(
                          width: 72.0,
                          height: 72.0,
                          decoration: BoxDecoration(
                            color: AppColors.primary100,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary300, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.translate_rounded,
                              size: 38.0,
                              color: AppColors.primary600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      Text(
                        'language.select_title'.tr(),
                        style: AppTypography.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'language.select_subtitle'.tr(),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.soil600),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28.0),

                      // Hindi Option (Recommended / Default)
                      _buildLanguageCard(
                        locale: AppConstants.localeHindi,
                        badgeLetter: 'अ',
                        title: 'language.hi_name'.tr(),
                        subtitle: 'language.hi_desc'.tr(),
                        sample: 'सीधे खेत से थाली तक, सच्चा मंच',
                      ),

                      const SizedBox(height: 14.0),

                      // English Option
                      _buildLanguageCard(
                        locale: AppConstants.localeEnglish,
                        badgeLetter: 'A',
                        title: 'language.en_name'.tr(),
                        subtitle: 'language.en_desc'.tr(),
                        sample: 'Direct from soil to spoon, fair prices',
                      ),

                      const SizedBox(height: 14.0),

                      // Hinglish Option
                      _buildLanguageCard(
                        locale: AppConstants.localeHinglish,
                        badgeLetter: 'H',
                        title: 'language.hinglish_name'.tr(),
                        subtitle: 'language.hinglish_desc'.tr(),
                        sample: 'Khet se thali tak, seedha aur aasan',
                      ),

                      const Spacer(),
                      const SizedBox(height: 24.0),

                      // Proceed Button
                      AppButton(
                        label: 'common.continue'.tr(),
                        onPressed: () {
                          context.go(RouteNames.welcome);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 22.0),
                      ),
                      const SizedBox(height: 12.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

    );
  }

  Widget _buildLanguageCard({
    required Locale locale,
    required String badgeLetter,
    required String title,
    required String subtitle,
    required String sample,
  }) {
    final isSelected = _selectedLocale == locale;

    return AppCard(
      borderRadius: 18.0,
      borderWidth: isSelected ? 2.0 : 1.0,
      borderColor: isSelected ? AppColors.primary500 : AppColors.soil200,
      backgroundColor: isSelected ? AppColors.primary50 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      onTap: () => _onSelect(locale),
      child: Row(
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary500 : AppColors.soil100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                badgeLetter,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : AppColors.soil800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.primary800 : AppColors.soil900,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.soil600),
                ),
                const SizedBox(height: 2.0),
                Text(
                  sample,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: isSelected ? AppColors.primary700 : AppColors.soil500,
                  ),
                ),
              ],
            ),
          ),
          Radio<Locale>(
            value: locale,
            groupValue: _selectedLocale,
            activeColor: AppColors.primary500,
            onChanged: (val) {
              if (val != null) _onSelect(val);
            },
          ),
        ],
      ),
    );
  }
}
