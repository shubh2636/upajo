import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../marketplace/domain/models/order_model.dart';
import '../../../marketplace/presentation/controllers/marketplace_controller.dart';

class FarmerOrdersScreen extends ConsumerStatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  ConsumerState<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends ConsumerState<FarmerOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _updatingOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      final repo = ref.read(marketplaceRepositoryProvider);
      try {
        final data = await repo.getFarmerOrders(user.id);
        if (mounted) setState(() { _orders = data; _isLoading = false; });
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    setState(() => _updatingOrderId = orderId);
    final repo = ref.read(marketplaceRepositoryProvider);
    try {
      await repo.updateOrderStatus(orderId, newStatus);
      await _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Text('farmer.pending_orders'.tr()),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_rounded, size: 54.0, color: AppColors.soil400),
                      const SizedBox(height: 12.0),
                      Text('common.empty'.tr(), style: AppTypography.headlineSmall),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14.0),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final isPickup = order.deliveryMode == 'pickup';

                    String? nextStatus;
                    String? nextLabel;

                    if (order.status == 'confirmed') {
                      nextStatus = 'harvesting_packed';
                      nextLabel = 'farmer.mark_packed'.tr();
                    } else if (order.status == 'harvesting_packed') {
                      nextStatus = isPickup ? 'ready_for_pickup' : 'out_for_delivery';
                      nextLabel = isPickup ? 'farmer.ready_for_pickup'.tr() : 'farmer.mark_out_delivery'.tr();
                    } else if (order.status == 'out_for_delivery' || order.status == 'ready_for_pickup') {
                      nextStatus = 'delivered';
                      nextLabel = 'farmer.mark_delivered'.tr();
                    }

                    return AppCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.0)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: order.status == 'delivered' ? AppColors.primary100 : AppColors.wheat100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  order.status,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: order.status == 'delivered' ? AppColors.primary800 : AppColors.wheat900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),

                          Text('${'farmer.customer_label'.tr()}: ${order.deliveryAddress['full_name'] ?? ''} (+91 ${order.deliveryAddress['phone'] ?? ''})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text('${order.deliveryAddress['address_line'] ?? ''}, ${order.deliveryAddress['village_or_city'] ?? ''} - ${order.deliveryAddress['pin_code'] ?? ''}', style: const TextStyle(fontSize: 12.0, color: AppColors.soil600)),
                          const SizedBox(height: 10.0),

                          // Items summary
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(color: AppColors.soil100, borderRadius: BorderRadius.circular(8.0)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isPickup ? 'farmer.pickup'.tr() : 'consumer.home_delivery'.tr(), style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600)),
                                Text('${'farmer.total_amount_label'.tr()}: ₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary600)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14.0),

                          Row(
                            children: [
                              // WhatsApp Action
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('farmer.whatsapp_generated'.tr())),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.green, size: 18.0),
                                  label: const Text('WhatsApp', style: TextStyle(fontSize: 12.5)),
                                ),
                              ),
                              if (nextStatus != null && nextLabel != null) ...[
                                const SizedBox(width: 10.0),
                                Expanded(
                                  flex: 2,
                                  child: AppButton(
                                    height: 48.0,
                                    label: nextLabel,
                                    isLoading: _updatingOrderId == order.id,
                                    onPressed: () => _updateStatus(order.id, nextStatus!),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!isPickup) ...[
                            const SizedBox(height: 10.0),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary700,
                                  side: const BorderSide(color: AppColors.primary300),
                                ),
                                onPressed: () => context.push(RouteNames.liveTracking, extra: order.id),
                                icon: const Icon(Icons.navigation_rounded, size: 18.0),
                                label: Text('farmer.live_tracking_map'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

