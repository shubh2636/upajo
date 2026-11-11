import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upajo/core/theme/app_colors.dart';
import 'package:upajo/core/theme/app_theme.dart';
import 'package:upajo/core/widgets/app_button.dart';
import 'package:upajo/core/widgets/app_text_field.dart';
import 'package:upajo/features/mandi/domain/models/mandi_price_model.dart';

void main() {
  group('Upajo Flutter Core Tests', () {
    testWidgets('AppButton has minimum accessible touch target >= 48dp', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              label: 'Submit',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(buttonFinder);
      expect(pressed, isTrue);
    });

    testWidgets('AppTextField renders label and hint cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Mobile Number',
              hintText: '9876543210',
            ),
          ),
        ),
      );

      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });

    test('MandiPriceModel parses Agmarknet JSON payload with 7-day historical trend', () {
      final json = {
        'id': 'mandi_wheat_sehore',
        'crop_name_hi': 'गेहूं (शरबती)',
        'crop_name_en': 'Wheat (Sharbati)',
        'mandi_name': 'सीहोर कृषि उपज मंडी',
        'district': 'सीहोर',
        'state': 'मध्य प्रदेश',
        'min_price': 2850.0,
        'max_price': 3650.0,
        'modal_price': 3280.0,
        'change_24h': 45.0,
        'arrivals_tonnes': 420.0,
        'price_date': '2026-11-07T12:00:00Z',
        'historical_trend': [3080.0, 3120.0, 3160.0, 3200.0, 3210.0, 3240.0, 3280.0],
      };

      final model = MandiPriceModel.fromJson(json);

      expect(model.id, 'mandi_wheat_sehore');
      expect(model.cropNameHi, 'गेहूं (शरबती)');
      expect(model.modalPrice, 3280.0);
      expect(model.historicalTrend.length, 7);
      expect(model.historicalTrend.last, 3280.0);
    });

    test('Farmland color tokens conform to accessible soil and harvest palette', () {
      expect(AppColors.primary500, const Color(0xFF25603A));
      expect(AppColors.wheat500, const Color(0xFFD8972C));
      expect(AppColors.clay500, const Color(0xFFBA4A38));
      expect(AppColors.soil50, const Color(0xFFFAF7F0));
      expect(AppColors.soil800, const Color(0xFF2E1F14));
    });
  });
}

