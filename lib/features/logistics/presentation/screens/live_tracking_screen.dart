import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../controllers/logistics_controller.dart';
import '../../domain/models/delivery_tracking_model.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const LiveTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logisticsControllerProvider.notifier).fetchTracking(widget.orderId);
    });
  }

  Future<void> _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logisticsControllerProvider);
    final tracking = state.tracking;

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: const Text('लाइव डिलीवरी ट्रैकिंग (OSM)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'वाहन की स्थिति पर केंद्रित करें',
            onPressed: () {
              if (tracking != null) {
                _mapController.move(
                  LatLng(tracking.liveLatitude, tracking.liveLongitude),
                  12.5,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'ताज़ा करें',
            onPressed: () => ref.read(logisticsControllerProvider.notifier).refreshLocation(widget.orderId),
          ),
        ],
      ),
      body: state.isLoading && tracking == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary500))
          : tracking == null
              ? const Center(child: Text('ट्रैकिंग जानकारी उपलब्ध नहीं है'))
              : Stack(
                  children: [
                    // 1. OpenStreetMap Layer
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(tracking.liveLatitude, tracking.liveLongitude),
                        initialZoom: 11.5,
                        minZoom: 6.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.upajo.app',
                        ),

                        // Route Polyline (Farm to City Destination)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                LatLng(tracking.pickupLatitude, tracking.pickupLongitude),
                                LatLng(tracking.liveLatitude, tracking.liveLongitude),
                                LatLng(tracking.dropLatitude, tracking.dropLongitude),
                              ],
                              color: AppColors.primary600,
                              strokeWidth: 4.5,
                            ),
                          ],
                        ),

                        // Markers: Farm Pickup, Live Vehicle, and Delivery Dropoff
                        MarkerLayer(
                          markers: [
                            // 1. Farm Marker
                            Marker(
                              point: LatLng(tracking.pickupLatitude, tracking.pickupLongitude),
                              width: 44.0,
                              height: 44.0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.wheat600,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
                                ),
                                child: const Icon(Icons.agriculture_rounded, color: Colors.white, size: 24.0),
                              ),
                            ),

                            // 2. Live Moving Vehicle Marker
                            Marker(
                              point: LatLng(tracking.liveLatitude, tracking.liveLongitude),
                              width: 52.0,
                              height: 52.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary500,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x33000000), blurRadius: 8.0, spreadRadius: 2.0),
                                  ],
                                ),
                                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28.0),
                              ),
                            ),

                            // 3. Consumer Dropoff Marker
                            Marker(
                              point: LatLng(tracking.dropLatitude, tracking.dropLongitude),
                              width: 44.0,
                              height: 44.0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.clay500,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4.0)],
                                ),
                                child: const Icon(Icons.home_rounded, color: Colors.white, size: 24.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 2. Floating Bottom Sheet with Driver Details & Progress
                    Positioned(
                      left: 14.0,
                      right: 14.0,
                      bottom: 14.0,
                      child: _buildTrackingCard(tracking),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTrackingCard(DeliveryTrackingModel tracking) {
    return AppCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner & ETA Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.primary200),
                ),
                child: Text(
                  tracking.deliveryPartner == 'self' ? 'किसान डायरेक्ट' : 'Porter Express',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: AppColors.primary700),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16.0, color: AppColors.wheat800),
                  const SizedBox(width: 4.0),
                  Text(
                    tracking.estimatedDeliveryAt != null
                        ? 'आगमन: ${DateFormat('hh:mm a').format(tracking.estimatedDeliveryAt!)}'
                        : 'मार्ग में (In Transit)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0, color: AppColors.soil900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Driver & Vehicle Details
          Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: const BoxDecoration(
                  color: AppColors.soil100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.soil700, size: 24.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracking.driverName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    Text(
                      'वाहन: ${tracking.vehicleNumber}',
                      style: const TextStyle(fontSize: 12.0, color: AppColors.soil600),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                icon: const Icon(Icons.phone_rounded, size: 16.0),
                label: const Text('कॉल करें', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                onPressed: () => _callDriver(tracking.driverPhone),
              ),
            ],
          ),
          const Divider(height: 20.0),

          // Route addresses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                children: [
                  Icon(Icons.circle, size: 10.0, color: AppColors.wheat600),
                  SizedBox(height: 14.0),
                  Icon(Icons.location_on_rounded, size: 14.0, color: AppColors.clay500),
                ],
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tracking.pickupAddress, style: const TextStyle(fontSize: 11.5, color: AppColors.soil700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8.0),
                    Text(tracking.dropAddress, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.soil900), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
