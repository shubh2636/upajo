import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _shelfLifeController = TextEditingController(text: '180');

  String _selectedCategoryId = '11111111-1111-1111-1111-111111111111';
  List<int> _selectedPackSizes = [10, 20, 50];
  List<String> _selectedDeliveryModes = ['pickup', 'self_delivery'];
  DateTime _harvestDate = DateTime.now();
  bool _isOrganic = false;
  File? _pickedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _shelfLifeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
        });
      }
    } catch (_) {
      // Ignored
    }
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कम से कम एक बोरी का आकार चुनें (10/20/50 kg)')),
      );
      return;
    }

    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) return;

    if (user.kycStatus != 'verified' && user.kycStatus != 'approved') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.clay500),
              SizedBox(width: 8.0),
              Text('KYC सत्यापन आवश्यक है', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'फसल प्रकाशित करने से पहले किसान KYC (पहचान पत्र व बैंक विवरण) पूर्ण होना अनिवार्य है ताकि खरीदारों को सत्यापित उपज मिल सके।',
            style: TextStyle(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('बाद में'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.push(RouteNames.farmerKyc);
              },
              child: const Text('KYC पूर्ण करें', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      String imageUrl = 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=800&q=80';

      if (_pickedImage != null) {
        imageUrl = await repo.uploadProductImage(_pickedImage!);
      }

      final product = ProductModel(
        id: '',
        farmerId: user.id,
        categoryId: _selectedCategoryId,
        titleHi: _titleController.text.trim(),
        titleEn: _titleController.text.trim(),
        descriptionHi: _descController.text.trim().isEmpty ? 'खेत से सीधी शुद्ध फसल' : _descController.text.trim(),
        descriptionEn: _descController.text.trim().isEmpty ? 'Farm fresh pure produce' : _descController.text.trim(),
        images: [imageUrl],
        pricePerKg: double.parse(_priceController.text.trim()),
        stockKg: double.parse(_stockController.text.trim()),
        packSizesKg: _selectedPackSizes,
        harvestDate: _harvestDate,
        shelfLifeDays: int.tryParse(_shelfLifeController.text.trim()) ?? 180,
        deliveryModes: _selectedDeliveryModes,
        isOrganic: _isOrganic,
        isActive: true,
        villageOrCity: user.villageOrCity ?? 'आष्टा',
        district: user.district ?? 'सीहोर',
        state: user.state ?? 'मध्य प्रदेश',
        pinCode: user.pinCode ?? '466116',
        createdAt: DateTime.now(),
      );

      await repo.addProduct(product);
      ref.read(marketplaceControllerProvider.notifier).loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('फसल सफलतापूर्वक प्रकाशित हो गई! (Produce Published)')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.clay500),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).userProfile;
    final isKycVerified = user?.kycStatus == 'verified' || user?.kycStatus == 'approved';

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('farmer.add_product'.tr()),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isKycVerified) ...[
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.wheat100,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.wheat400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.wheat800),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'फसल प्रकाशित करने के लिए आपका KYC सत्यापन आवश्यक है।',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.wheat900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(RouteNames.farmerKyc),
                        child: const Text('सत्यापित करें', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
              // Photo Upload Card
              AppCard(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_pickedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.file(
                          _pickedImage!,
                          height: 180.0,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 140.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.soil100,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppColors.soil300, width: 1.5, strokeAlign: BorderSide.strokeAlignCenter),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 40.0, color: AppColors.soil500),
                            const SizedBox(height: 8.0),
                            Text('farmer.take_photo'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2.0),
                            const Text('कम इंटरनेट के लिए फोटो स्वतः छोटी होगी', style: TextStyle(fontSize: 11.0, color: AppColors.soil500)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('कैमरा'),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('गैलरी'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Produce Name & Price
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _titleController,
                      label: 'farmer.product_name'.tr(),
                      hintText: 'उदा. शरबती गेहूं (ग्रेड-ए) या देसी चना',
                      validator: (val) => val == null || val.trim().isEmpty ? 'फसल का नाम लिखें' : null,
                    ),
                    const SizedBox(height: 14.0),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _priceController,
                            label: 'farmer.price_per_kg'.tr(),
                            hintText: 'उदा. 42',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => (val == null || double.tryParse(val) == null) ? 'भाव लिखें' : null,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: AppTextField(
                            controller: _stockController,
                            label: 'farmer.total_stock_kg'.tr(),
                            hintText: 'उदा. 500',
                            keyboardType: TextInputType.number,
                            validator: (val) => (val == null || double.tryParse(val) == null) ? 'स्टॉक लिखें' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Pack Sizes Selection (10kg, 20kg, 50kg)
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('farmer.pack_sizes'.tr(), style: AppTypography.headlineSmall),
                    const SizedBox(height: 4.0),
                    const Text('ग्राहक इन पैक में सीधे ऑर्डर कर सकेंगे:', style: TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                    const SizedBox(height: 12.0),

                    Row(
                      children: [10, 20, 50].map((size) {
                        final isSelected = _selectedPackSizes.contains(size);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    if (_selectedPackSizes.length > 1) _selectedPackSizes.remove(size);
                                  } else {
                                    _selectedPackSizes.add(size);
                                    _selectedPackSizes.sort();
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14.0),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary50 : Colors.white,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary500 : AppColors.soil200,
                                    width: isSelected ? 2.0 : 1.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  children: [
                                    Text('$size ${'common.kg'.tr()}', style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? AppColors.primary600 : AppColors.soil800)),
                                    const SizedBox(height: 4.0),
                                    Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 18.0, color: isSelected ? AppColors.primary500 : AppColors.soil400),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Delivery Options & Organic Toggle
              AppCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('farmer.delivery_options'.tr(), style: AppTypography.headlineSmall),
                    const SizedBox(height: 10.0),

                    CheckboxListTile(
                      value: _selectedDeliveryModes.contains('pickup'),
                      title: Text('farmer.pickup'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                      activeColor: AppColors.primary500,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedDeliveryModes.add('pickup');
                          } else if (_selectedDeliveryModes.length > 1) {
                            _selectedDeliveryModes.remove('pickup');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      value: _selectedDeliveryModes.contains('self_delivery'),
                      title: Text('farmer.self_delivery'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                      activeColor: AppColors.primary500,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedDeliveryModes.add('self_delivery');
                          } else if (_selectedDeliveryModes.length > 1) {
                            _selectedDeliveryModes.remove('self_delivery');
                          }
                        });
                      },
                    ),

                    const Divider(height: 24.0),

                    SwitchListTile(
                      value: _isOrganic,
                      title: Text('farmer.is_organic'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('बिना रासायनिक यूरिया या कीटनाशक वाली शुद्ध प्राकृतिक फसल', style: TextStyle(fontSize: 12.0)),
                      activeColor: AppColors.primary500,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _isOrganic = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),

              AppButton(
                label: 'farmer.publish_product'.tr(),
                onPressed: _onSubmit,
                isLoading: _isSubmitting,
                icon: const Icon(Icons.publish_rounded, size: 22.0),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}

