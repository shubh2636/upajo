import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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
    _executeOrderCreation(paymentId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('भुगतान असफल रहा: ${response.message}'),
        backgroundColor: AppColors.clay500,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _executeOrderCreation(paymentId: response.walletName);
  }

  void _onPlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartState = ref.read(cartControllerProvider);
    if (cartState.items.isEmpty) return;

    if (_paymentMethod == 'upi_razorpay') {
      setState(() => _isProcessing = true);
      final totalInPaise = (cartState.total * 100).toInt();

      var options = {
        'key': EnvConfig.razorpayKeyId,
        'amount': totalInPaise,
        'name': 'उपजो (Upajo)',
        'description': 'खेत से सीधी ताज़ी फसल का भुगतान',
        'prefill': {
          'contact': _phoneController.text.trim(),
          'name': _nameController.text.trim(),
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        // Fallback for emulator / direct checkout
        _executeOrderCreation();
      }
    } else {
      // Cash on Delivery
      _executeOrderCreation();
    }
  }

  void _executeOrderCreation({String? paymentId}) async {
    setState(() => _isProcessing = true);
    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    final addressPayload = {
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address_line': _addressController.text.trim(),
      'village_or_city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'pin_code': _pinCodeController.text.trim(),
      'payment_method': _paymentMethod,
      'payment_id': paymentId,
    };

    final order = await ref.read(cartControllerProvider.notifier).placeOrder(
          consumerId: user.id,
          deliveryAddress: addressPayload,
        );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (order != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('बधाई! आपका ऑर्डर सफलतापूर्वक दर्ज हो गया है (Order Confirmed)'),
            backgroundColor: AppColors.primary500,
          ),
        );
        context.go(RouteNames.orderDetail.replaceFirst(':id', order.id), extra: order);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ऑर्डर बनाने में त्रुटि हुई।')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('चेकआउट (Checkout)'),
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
                    Text('डिलीवरी / संपर्क पता (Address)', style: AppTypography.headlineSmall),
                    const SizedBox(height: 14.0),

                    AppTextField(
                      controller: _nameController,
                      label: 'प्राप्तकर्ता का नाम',
                      validator: (val) => val == null || val.trim().isEmpty ? 'नाम लिखें' : null,
                    ),
                    const SizedBox(height: 12.0),

                    AppTextField(
                      controller: _phoneController,
                      label: 'संपर्क मोबाइल नंबर',
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().length != 10 ? '10 अंकों का फोन नंबर' : null,
                    ),
                    const SizedBox(height: 12.0),

                    AppTextField(
                      controller: _addressController,
                      label: 'मकान / पता',
                      hintText: 'गली, मोहल्ला या लैंडमार्क',
                      validator: (val) => val == null || val.trim().isEmpty ? 'पता लिखें' : null,
                    ),
                    const SizedBox(height: 12.0),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _cityController,
                            label: 'गाँव / शहर',
                            validator: (val) => val == null || val.trim().isEmpty ? 'शहर लिखें' : null,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppTextField(
                            controller: _pinCodeController,
                            label: 'पिन कोड',
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.trim().length != 6 ? '6 अंक' : null,
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
                    Text('भुगतान का माध्यम (Payment Method)', style: AppTypography.headlineSmall),
                    const SizedBox(height: 12.0),

                    RadioListTile<String>(
                      value: 'upi_razorpay',
                      groupValue: _paymentMethod,
                      title: const Text('UPI / ऑनलाइन भुगतान (Razorpay)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('गूगल पे, फोनपे, पेटीएम या कार्ड द्वारा तुरंत सुरक्षित भुगतान', style: TextStyle(fontSize: 11.5)),
                      activeColor: AppColors.primary500,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    const Divider(height: 16.0),

                    RadioListTile<String>(
                      value: 'cod',
                      groupValue: _paymentMethod,
                      title: const Text('डिलीवरी पर नकद (Cash on Delivery)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('उपज मिलने पर किसान या डिलीवरी पार्टनर को नकद भुगतान करें', style: TextStyle(fontSize: 11.5)),
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
                    const Text('कुल देय राशि (Payable):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0)),
                    Text('₹${cartState.total.toStringAsFixed(0)}', style: AppTypography.displaySmall.copyWith(color: AppColors.primary600)),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),

              AppButton(
                label: 'भुगतान करें एवं ऑर्डर पूरा करें (Place Order)',
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

