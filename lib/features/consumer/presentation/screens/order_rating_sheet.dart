import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../marketplace/domain/models/order_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class OrderRatingSheet extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderRatingSheet({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<OrderRatingSheet> createState() => _OrderRatingSheetState();
}

class _OrderRatingSheetState extends ConsumerState<OrderRatingSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitRating() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(marketplaceRepositoryProvider);

    try {
      final productId = widget.order.items.isNotEmpty
          ? widget.order.items.first.productId
          : '11111111-1111-1111-1111-111111111111';

      await repo.submitRating(
        orderId: widget.order.id,
        productId: productId,
        consumerId: user.id,
        farmerId: widget.order.farmerId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('धन्यवाद! आपकी रेटिंग सफलतापूर्वक दर्ज कर ली गई है'),
            backgroundColor: AppColors.primary500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('रेटिंग सबमिट करने में त्रुटि: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('फसल की गुणवत्ता को रेटिंग दें', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6.0),
          const Text('आपकी रेटिंग से अन्य परिवारों को शुद्ध अनाज चुनने में मदद मिलती है', style: TextStyle(fontSize: 12.0, color: AppColors.soil600), textAlign: TextAlign.center),
          const SizedBox(height: 20.0),

          // Star Rating Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              return IconButton(
                iconSize: 42.0,
                icon: Icon(
                  starNum <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.wheat500,
                ),
                onPressed: () => setState(() => _rating = starNum),
              );
            }),
          ),

          const SizedBox(height: 16.0),

          AppTextField(
            controller: _commentController,
            hintText: 'अपना अनुभव साझा करें (उदा. गेहूं बहुत साफ और दानेदार है)...',
            maxLines: 3,
          ),

          const SizedBox(height: 24.0),

          AppButton(
            label: 'रेटिंग सबमिट करें (Submit Rating)',
            onPressed: _submitRating,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
