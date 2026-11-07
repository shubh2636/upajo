import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
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
  String _selectedLangCode = 'hi';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLangCode = context.locale.languageCode;
  }

  void _onSelect(String code) {
    setState(() {
      _selectedLangCode = code;
    });
    context.setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Heading & Greeting
              Center(
                child: Container(
                  width: 76.0,
                  height: 76.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary300, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.translate_rounded,
                      size: 40.0,
                      color: AppColors.primary600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              Text(
                'अपनी भाषा चुनें\nChoose Your Language',
                style: AppTypography.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'आप इसे बाद में कभी भी बदल सकते हैं',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.soil600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36.0),

              // Hindi Option (Recommended / Default)
              AppCard(
                borderRadius: 16.0,
                borderColor: _selectedLangCode == 'hi'
                    ? AppColors.primary500
                    : AppColors.soil200,
                backgroundColor: _selectedLangCode == 'hi'
                    ? AppColors.primary50
                    : Colors.white,
                onTap: () => _onSelect('hi'),
                child: Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: _selectedLangCode == 'hi'
                            ? AppColors.primary500
                            : AppColors.soil100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'अ',
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                            color: _selectedLangCode == 'hi'
                                ? Colors.white
                                : AppColors.soil800,
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
                            'हिंदी (Hindi)',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.soil900,
                            ),
                          ),
                          Text(
                            'सरल एवं आसान हिंदी में उपयोग करें',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: 'hi',
                      groupValue: _selectedLangCode,
                      activeColor: AppColors.primary500,
                      onChanged: (val) => _onSelect(val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14.0),

              // English Option
              AppCard(
                borderRadius: 16.0,
                borderColor: _selectedLangCode == 'en'
                    ? AppColors.primary500
                    : AppColors.soil200,
                backgroundColor: _selectedLangCode == 'en'
                    ? AppColors.primary50
                    : Colors.white,
                onTap: () => _onSelect('en'),
                child: Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: _selectedLangCode == 'en'
                            ? AppColors.primary500
                            : AppColors.soil100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                            color: _selectedLangCode == 'en'
                                ? Colors.white
                                : AppColors.soil800,
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
                            'English',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.soil900,
                            ),
                          ),
                          Text(
                            'Continue in English language',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: 'en',
                      groupValue: _selectedLangCode,
                      activeColor: AppColors.primary500,
                      onChanged: (val) => _onSelect(val!),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Proceed Button
              AppButton(
                label: 'common.continue'.tr(),
                onPressed: () {
                  context.go(RouteNames.login);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 22.0),
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }
}

