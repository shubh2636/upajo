import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/delivery_tracking_model.dart';
import '../../domain/repositories/logistics_repository.dart';
import '../services/manual_delivery_adapter.dart';
import '../services/third_party_logistics_adapter.dart';

class LogisticsRepositoryImpl implements LogisticsRepository {
  final SupabaseClient _supabase;
  final ManualSelfDeliveryAdapter _manualAdapter;
  final ThirdPartyLogisticsAdapter _partnerAdapter;

  LogisticsRepositoryImpl({
    SupabaseClient? supabase,
    ManualSelfDeliveryAdapter? manualAdapter,
    ThirdPartyLogisticsAdapter? partnerAdapter,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _manualAdapter = manualAdapter ?? ManualSelfDeliveryAdapter(),
        _partnerAdapter = partnerAdapter ?? ThirdPartyLogisticsAdapter();

  @override
  Future<DeliveryTrackingModel> getOrderTracking(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery')
          .select('*')
          .eq('order_id', orderId)
          .maybeSingle();

      if (response != null) {
        return DeliveryTrackingModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[LogisticsRepo] Could not query Supabase delivery: $e');
    }

    return await _manualAdapter.getLiveTracking('UPJ-TRK-$orderId');
  }

  @override
  Future<DeliveryTrackingModel> dispatchDelivery({
    required String orderId,
    required String mode,
    required String pickupAddress,
    required String dropAddress,
    required double packageWeightKg,
    required String recipientName,
    required String recipientPhone,
  }) async {
    final adapter = (mode == 'partner_delivery' || mode == 'porter')
        ? _partnerAdapter
        : _manualAdapter;

    final tracking = await adapter.createShipment(
      orderId: orderId,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      packageWeightKg: packageWeightKg,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
    );

    try {
      await _supabase.from('delivery').upsert(tracking.toSupabaseJson());
    } catch (e) {
      debugPrint('[LogisticsRepo] Could not upsert delivery row: $e');
    }

    return tracking;
  }

  @override
  Future<void> updateDeliveryStatus({
    required String trackingId,
    required String status,
    double? lat,
    double? lng,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (lat != null && lng != null) {
        updateData['live_lat'] = lat;
        updateData['live_lng'] = lng;
      }
      await _supabase.from('delivery').update(updateData).eq('id', trackingId);
    } catch (e) {
      debugPrint('[LogisticsRepo] Could not update delivery: $e');
    }
  }
}

