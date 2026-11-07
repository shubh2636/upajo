import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/domain/models/order_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';

class ConsumerOrdersScreen extends ConsumerStatefulWidget {
  const ConsumerOrdersScreen({super.key});

  @override
  ConsumerState<ConsumerOrdersScreen> createState() => _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState extends ConsumerState<ConsumerOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsumerOrders();
  }

  Future<void> _loadConsumerOrders() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      final repo = ref.read(marketplaceRepositoryProvider);
      try {
        final data = await repo.getConsumerOrders(user.id);
        if (mounted) setState(() { _orders = data; _isLoading = false; });
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('मेरे ऑर्डर (My Orders)'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 54.0, color: AppColors.soil400),
                      const SizedBox(height: 12.0),
                      Text('अभी कोई ऑर्डर नहीं है', style: AppTypography.headlineSmall),
                      const SizedBox(height: 6.0),
                      const Text('खेत से सीधी ताज़ी उपज का ऑर्डर करें', style: TextStyle(color: AppColors.soil600)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final isDelivered = order.status == 'delivered';

                    return AppCard(
                      padding: const EdgeInsets.all(16.0),
                      onTap: () {
                        context.push(RouteNames.orderDetail.replaceFirst(':id', order.id), extra: order);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                decoration: BoxDecoration(
                                  color: isDelivered ? AppColors.primary100 : AppColors.wheat100,
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  order.status,
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    color: isDelivered ? AppColors.primary800 : AppColors.wheat900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Text('किसान: ${order.farmerName ?? 'अन्नदाता किसान'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                          const SizedBox(height: 2.0),
                          Text(
                            '${order.deliveryMode == 'pickup' ? 'खेत से उठाना (Pickup)' : 'होम डिलीवरी'} • कुल राशि: ₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'ट्रैक करें >',
                                style: TextStyle(color: AppColors.primary600, fontWeight: FontWeight.bold, fontSize: 13.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

