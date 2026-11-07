import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/store_item_model.dart';
import '../../domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  final SupabaseClient _supabase;

  StoreRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<StoreItemModel>> getStoreCatalog({String? itemType}) async {
    try {
      var query = _supabase
          .from('store_items')
          .select('*')
          .eq('is_active', true);

      if (itemType != null && itemType != 'all') {
        query = query.eq('item_type', itemType);
      }

      final response = await query.order('price', ascending: true);
      final list = (response as List)
          .map((item) => StoreItemModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('[StoreRepo] Supabase query failed ($e), serving certified seed/fertilizer mock catalog');
    }

    return _getLocalMockCatalog(itemType: itemType);
  }

  @override
  Future<StoreItemModel?> getStoreItemById(String id) async {
    try {
      final response = await _supabase
          .from('store_items')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return StoreItemModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[StoreRepo] Could not fetch store item: $e');
    }

    return _getLocalMockCatalog().firstWhere(
      (item) => item.id == id,
      orElse: () => _getLocalMockCatalog().first,
    );
  }

  List<StoreItemModel> _getLocalMockCatalog({String? itemType}) {
    final all = [
      const StoreItemModel(
        id: 'store_seed_1',
        titleHi: 'प्रमाणित शरबती गेहूं बीज C-306',
        titleEn: 'Certified Sharbati Wheat Seeds C-306',
        itemType: 'seed',
        brand: 'NSC (National Seeds Corp)',
        price: 1450.0,
        packSize: '40 kg बोरी',
        stockQuantity: 200,
        imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600',
        descriptionHi: 'उच्च चमक, मीठा स्वाद और 98% अंकुरण क्षमता वाला शुद्ध आधार बीज। ICAR व NSC द्वारा प्रमाणित।',
        descriptionEn: 'High sheen, sweet taste, certified pure foundation seed.',
      ),
      const StoreItemModel(
        id: 'store_fert_1',
        titleHi: 'IFFCO जैविक नीम-खली खाद (Neem Cake)',
        titleEn: 'IFFCO Organic Neem Cake Fertilizer',
        itemType: 'fertilizer',
        brand: 'IFFCO Organic',
        price: 680.0,
        packSize: '25 kg बोरी',
        stockQuantity: 150,
        imageUrl: 'https://images.unsplash.com/photo-1585314062340-f1a5a7c9328d?w=600',
        descriptionHi: 'दीमक व सफेद लट (White Grub) से सुरक्षा और जमीन में नाइट्रोजन की धीमी निरंतर आपूर्ति।',
        descriptionEn: 'Natural pest repellent and organic nitrogen source.',
      ),
      const StoreItemModel(
        id: 'store_bio_1',
        titleHi: 'ट्राइकोडर्मा विरिडी जैव-फफूंदनाशक 1% WP',
        titleEn: 'Trichoderma Viride Bio-Fungicide 1% WP',
        itemType: 'bio_nutrient',
        brand: 'KRIBHCO',
        price: 220.0,
        packSize: '1 kg पैकेट',
        stockQuantity: 500,
        imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600',
        descriptionHi: 'जड़ गलन और उकठा (Wilt) रोग से सुरक्षा हेतु बीज एवं भूमि उपचार के लिए सर्वोत्तम जैविक मित्र फफूंद।',
        descriptionEn: 'Effective bio-control agent against seed & soil-borne pathogens.',
      ),
      const StoreItemModel(
        id: 'store_tool_1',
        titleHi: 'किसान क्राफ्ट हस्तचालित स्प्रेयर (16L)',
        titleEn: 'Kisan Kraft Knapsack Manual Sprayer 16L',
        itemType: 'farm_tool',
        brand: 'Kisan Kraft',
        price: 1850.0,
        packSize: '1 यूनिट (16L Tank)',
        stockQuantity: 80,
        imageUrl: 'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600',
        descriptionHi: 'टिकाऊ पीतल की नोजल, मजबूत केमिकल-प्रतिरोधी प्लास्टिक टंकी, हाई-प्रेशर पंप। 2 साल वारंटी।',
        descriptionEn: 'Durable brass nozzle with high pressure chamber.',
      ),
      const StoreItemModel(
        id: 'store_seed_2',
        titleHi: 'देसी चना बीज JAKi-9218 प्रमाणित',
        titleEn: 'Certified Desi Chickpea Seed JAKi-9218',
        itemType: 'seed',
        brand: 'MP State Agro',
        price: 2100.0,
        packSize: '30 kg बोरी',
        stockQuantity: 120,
        imageUrl: 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?w=600',
        descriptionHi: 'उकठा (Wilt) रोग रोधी, बड़े दाने वाली लोकप्रिय किस्म। कम पानी में भी बंपर पैदावार।',
        descriptionEn: 'High yielding drought and wilt resistant variety.',
      ),
      const StoreItemModel(
        id: 'store_fert_2',
        titleHi: 'IFFCO नैनो यूरिया (तरल / Liquid)',
        titleEn: 'IFFCO Nano Urea Liquid',
        itemType: 'fertilizer',
        brand: 'IFFCO Nano',
        price: 225.0,
        packSize: '500 ml बोतल',
        stockQuantity: 400,
        imageUrl: 'https://images.unsplash.com/photo-1586771107445-d3ca888129ff?w=600',
        descriptionHi: 'एक 500 मिली बोतल पारंपरिक 45 किग्रा यूरिया बोरी के बराबर काम करती है। 80% नाइट्रोजन अवशोषण।',
        descriptionEn: 'Revolutionary nanotechnology-based liquid fertilizer.',
      ),
    ];

    if (itemType != null && itemType != 'all') {
      return all.where((item) => item.itemType == itemType).toList();
    }
    return all;
  }
}
