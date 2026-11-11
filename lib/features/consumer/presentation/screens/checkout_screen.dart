import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/domain/models/order_model.dart';
import '../../../marketplace/presentation/controllers/cart_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _pinCodeController = TextEditingController();

  String _paymentMethod = 'upi_razorpay'; // 'upi_razorpay' or 'cod'
  late Razorpay _razorpay;
  OrderModel? _pendingOrder;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone;
      _addressController.text = user.addressLine ?? '';
      _cityController.text = user.villageOrCity ?? '';
      _districtController.text = user.district ?? '';
      _pinCodeController.text = user.pinCode ?? '';
    }

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingOrder == null) return;
    setState(() => _isProcessing = true);

    try {
      // Cryptographically verify signature on server edge function
      final isVerified = await ref.read(cartControllerProvider.notifier).verifyPayment(
            orderId: _pendingOrder!.id,
            razorpayOrderId: response.orderId ?? '',
            razorpayPaymentId: response.paymentId ?? '',
            razorpaySignature: response.signature ?? '',
          );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('consumer.order_placed_success'.tr()),
              backgroundColor: AppColors.primary500,
            ),
          );
          context.go(RouteNames.orderDetail.replaceFirst(':id', _pendingOrder!.id), extra: _pendingOrder);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('consumer.signature_failed'.tr()),
              backgroundColor: AppColors.clay500,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.clay500,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message ?? 'Payment failed'),
        backgroundColor: AppColors.clay500,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.walletName ?? '')),
    );
  }

  void _onPlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartState = ref.read(cartControllerProvider);
    if (cartState.items.isEmpty) return;

    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    setState(() => _isProcessing = true);

    final addressPayload = {
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address_line': _addressController.text.trim(),
      'village_or_city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'pin_code': _pinCodeController.text.trim(),
      'payment_method': _paymentMethod,
    };

    // 1. Create order in pending_payment state
    final order = await ref.read(cartControllerProvider.notifier).placeOrder(
          consumerId: user.id,
          deliveryAddress: addressPayload,
        );

    if (order == null) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.error'.tr())),
        );
      }
      return;
    }

    _pendingOrder = order;

    if (_paymentMethod == 'upi_razorpay') {
      try {
        // 2. Fetch server-computed Razorpay order amount from Edge Function
        final rzpOrder = await ref.read(cartControllerProvider.notifier).createRazorpayOrder(order.id);

        final options = {
          'key': rzpOrder['key_id'] ?? EnvConfig.razorpayKeyId,
          'amount': rzpOrder['amount'], // Authoritative server-calculated paise
          'name': 'Upajo',
          'description': 'Farm produce payment',
          'order_id': rzpOrder['razorpay_order_id'],
          'prefill': {
            'contact': _phoneController.text.trim(),
            'name': _nameController.text.trim(),
          },
        };

        _razorpay.open(options);
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.clay500,
            ),
          );
        }
      }
    } else {
      // Cash on Delivery
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('consumer.order_confirmed_cod'.tr()),
            backgroundColor: AppColors.primary500,
          ),
        );
        context.go(RouteNames.orderDetail.replaceFirst(':id', order.id), extra: order);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('consumer.checkout_title'.tr()),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Address Card
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('consumer.delivery_address'.tr(), style: AppTypography.headlineSmall),
                    const SizedBox(height: 14.0),

                    AppTextField(
                      controller: _nameController,
                      label: 'consumer.recipient_name'.tr(),
                      validator: (val) => val == null || val.trim().isEmpty ? 'consumer.enter_name'.tr() : null,
                    ),
                    const SizedBox(height: 12.0),

                    AppTextField(
                      controller: _phoneController,
                      label: 'auth.phone_label'.tr(),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().length != 10 ? 'auth.invalid_phone'.tr() : null,
                    ),
                    const SizedBox(height: 12.0),

                    AppTextField(
                      controller: _addressController,
                      label: 'consumer.address_label'.tr(),
                      hintText: 'consumer.address_hint'.tr(),
                      validator: (val) => val == null || val.trim().isEmpty ? 'consumer.enter_address'.tr() : null,
                    ),
                    const SizedBox(height: 12.0),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _cityController,
                            label: 'auth.village_city'.tr(),
                            validator: (val) => val == null || val.trim().isEmpty ? 'consumer.enter_city'.tr() : null,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppTextField(
                            controller: _pinCodeController,
                            label: 'auth.pincode'.tr(),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.trim().length != 6 ? 'consumer.enter_pincode'.tr() : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Payment Selection Card
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('consumer.choose_payment'.tr(), style: AppTypography.headlineSmall),
                    const SizedBox(height: 12.0),

                    RadioListTile<String>(
                      value: 'upi_razorpay',
                      groupValue: _paymentMethod,
                      title: Text('consumer.pay_upi_razorpay'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('consumer.payment_upi_subtitle'.tr(), style: const TextStyle(fontSize: 11.5)),
                      activeColor: AppColors.primary500,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    const Divider(height: 16.0),

                    RadioListTile<String>(
                      value: 'cod',
                      groupValue: _paymentMethod,
                      title: Text('consumer.pay_cod'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('consumer.payment_cod_subtitle'.tr(), style: const TextStyle(fontSize: 11.5)),
                      activeColor: AppColors.primary500,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Total Summary
              AppCard(
                padding: const EdgeInsets.all(18.0),
                backgroundColor: AppColors.primary50,
                borderColor: AppColors.primary200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${'consumer.total_payable'.tr()}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0)),
                    Text('₹${cartState.total.toStringAsFixed(0)}', style: AppTypography.displaySmall.copyWith(color: AppColors.primary600)),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),

              AppButton(
                label: 'consumer.pay_and_place_order'.tr(),
                onPressed: _onPlaceOrder,
                isLoading: _isProcessing,
                icon: const Icon(Icons.lock_outline_rounded, size: 20.0),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

