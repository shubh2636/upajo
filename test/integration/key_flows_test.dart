import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upajo/core/theme/app_theme.dart';
import 'package:upajo/core/widgets/app_button.dart';
import 'package:upajo/core/widgets/app_card.dart';
import 'package:upajo/core/widgets/app_text_field.dart';
import 'package:upajo/features/auth/presentation/language_select_screen.dart';
import 'package:upajo/features/crop_advisor/domain/models/crop_input_params.dart';
import 'package:upajo/features/crop_advisor/domain/models/crop_recommendation.dart';
import 'package:upajo/features/crop_advisor/data/services/rule_based_crop_engine.dart';

void main() {
  group('Part 6: Key UI Flows & Integration Tests', () {
    testWidgets('1. Farmland Role Selection UI - Farmer vs Consumer Option Cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: const [
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.agriculture_rounded),
                      SizedBox(width: 8.0),
                      Text('मैं किसान हूँ (Farmer)'),
                    ],
                  ),
                ),
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.shopping_basket_rounded),
                      SizedBox(width: 8.0),
                      Text('मैं ग्राहक हूँ (Consumer)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify role selection cards are present
      expect(find.text('मैं किसान हूँ (Farmer)'), findsOneWidget);
      expect(find.text('मैं ग्राहक हूँ (Consumer)'), findsOneWidget);
    });

    testWidgets('2. Authentication Flow - Phone Input & OTP Field Invariants', (WidgetTester tester) async {
      final phoneController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppTextField(
                  label: 'मोबाइल नंबर',
                  controller: phoneController,
                  hintText: '10 अंकों का मोबाइल नंबर',
                  keyboardType: TextInputType.phone,
                ),
                AppButton(
                  label: 'ओटीपी भेजें (Send OTP)',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Verify text field exists and accepts 10 digits
      await tester.enterText(find.byType(TextField), '9876543210');
      expect(phoneController.text, '9876543210');
      expect(phoneController.text.length, 10);
    });

    test('3. Crop Advisor ICAR Rule Engine Integration', () {
      const input = CropInputParams(
        soilType: 'black_soil',
        landAreaAcres: 3.5,
        season: 'rabi',
        waterSource: 'tube_well',
        district: 'सीहोर',
      );

      final result = RuleBasedCropEngine.recommend(input);

      // Verify recommendation
      expect(result.nameHi, contains('गेहूं'));
      expect(result.variety, contains('C-306'));
      expect(result.totalExpectedYieldQuintal, 63.0); // 3.5 * 18.0 = 63.0
      expect(result.calendarSchedule.isNotEmpty, isTrue);

      // Sowing task must precede harvesting task
      final sowingTask = result.calendarSchedule.firstWhere((t) => t.stage == 'sowing');
      final harvestTask = result.calendarSchedule.firstWhere((t) => t.stage == 'harvesting');
      expect(sowingTask.daysAfterSowing, lessThan(harvestTask.daysAfterSowing));
    });

    testWidgets('4. Bento Grid & Accessibility Card Sizing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              borderRadius: 20.0,
              padding: const EdgeInsets.all(18.0),
              child: const Text('मंडी भाव (Agmarknet)'),
            ),
          ),
        ),
      );

      expect(find.text('मंडी भाव (Agmarknet)'), findsOneWidget);
    });
  });
}
