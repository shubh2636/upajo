import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/krishi_sahayak_repository.dart';
import '../../../../core/config/env_config.dart';

class KrishiSahayakRepositoryImpl implements KrishiSahayakRepository {
  final SupabaseClient _supabase;
  final http.Client _httpClient;
  final String _mlServiceUrl;
  static const _uuid = Uuid();

  KrishiSahayakRepositoryImpl({
    SupabaseClient? supabase,
    http.Client? httpClient,
    String? mlServiceUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _httpClient = httpClient ?? http.Client(),
        _mlServiceUrl = mlServiceUrl ?? EnvConfig.apiBaseUrl;

  @override
  Future<ChatMessage> sendMessage({
    required String farmerId,
    required String userQuery,
    required List<ChatMessage> conversationHistory,
    String? cropContext,
    String? district,
    String? stateName,
    double? currentTemp,
    int? humidity,
    double? windSpeed,
  }) async {
    // 1. Try FastAPI Claude Proxy
    try {
      final payload = {
        'farmer_id': farmerId,
        'message': userQuery,
        'crop_context': cropContext ?? 'शरबती गेहूं (Sharbati Wheat)',
        'district': district ?? 'सीहोर',
        'state': stateName ?? 'मध्य प्रदेश',
        'temperature': currentTemp ?? 28.0,
        'humidity': humidity ?? 55,
        'wind_speed': windSpeed ?? 10.0,
        'history': conversationHistory
            .take(6)
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      };

      final session = _supabase.auth.currentSession;
      final headers = {
        'Content-Type': 'application/json',
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      };

      final response = await _httpClient
          .post(
            Uri.parse('$_mlServiceUrl/api/v1/krishi-sahayak/chat'),
            headers: headers,
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final replyText = data['reply'] as String? ?? 'राम-राम किसान भाई! मैं आपकी क्या सहायता कर सकता हूँ?';

        final assistantMsg = ChatMessage(
          id: _uuid.v4(),
          role: 'assistant',
          content: replyText,
          timestamp: DateTime.now(),
        );

        // Async log to Supabase in background
        _logToSupabase(farmerId, userQuery, replyText);

        return assistantMsg;
      }
    } catch (e) {
      debugPrint('[KrishiSahayak] Claude API proxy unavailable ($e), falling back to on-device expert advisor');
    }

    // 2. High-accuracy offline agronomy expert fallback
    final fallbackReply = _getRuleBasedAgronomyResponse(userQuery, cropContext, windSpeed);
    return ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      content: fallbackReply,
      timestamp: DateTime.now(),
    );
  }

  String _getRuleBasedAgronomyResponse(String query, String? crop, double? windSpeed) {
    final q = query.toLowerCase();

    if (q.contains('सिंचाई') || q.contains('पानी') || q.contains('irrigation')) {
      return 'राम-राम किसान साथी! गेहूं की पहली और सबसे महत्वपूर्ण सिंचाई बोआई के 20-25 दिन बाद (CRI - मुकुट जड़ अवस्था) पर करनी चाहिए। इस समय हल्की सिंचाई करें और साथ में 30 किग्रा यूरिया प्रति एकड़ दें। अधिक पानी भरने से बचें।';
    } else if (q.contains('पीली') || q.contains('धब्बे') || q.contains('झुलसा') || q.contains('रोग')) {
      return 'पत्तियों पर पीले धब्बे या झुलसा दिखने पर यह फफूंद का संक्रमण हो सकता है। प्राथमिक उपचार के लिए मैंकोजेब 75 WP (30 ग्राम प्रति 15 लीटर पंप) अथवा कॉपर ऑक्सीक्लोराइड का छिड़काव करें। आप कैमरा बटन से पत्ती की फोटो स्कैन करके सटीक रोग भी पहचान सकते हैं।';
    } else if (q.contains('कीटनाशक') || q.contains('छिड़काव') || q.contains('स्प्रे')) {
      if ((windSpeed ?? 0) > 18.0) {
        return 'चेतावनी: वर्तमान में हवा की गति तेज है। तेज हवा में कीटनाशक का छिड़काव न करें, क्योंकि दवा उड़कर बर्बाद होगी। हवा शांत होने पर ही सुरक्षात्मक मास्क व दस्ताने पहनकर छिड़काव करें।';
      }
      return 'वर्तमान में हवा की गति शांत है और मौसम छिड़काव के लिए अनुकूल है। हमेशा केंद्रीय कीटनाशक बोर्ड (CIB&RC) द्वारा अनुशंसित सुरक्षित मात्रा (15 लीटर पंप में 25-30 मिली/ग्राम) का ही प्रयोग करें।';
    } else if (q.contains('इल्ली') || q.contains('कीट') || q.contains('चना')) {
      return 'चने या दलहन में इल्ली (Helicoverpa) दिखने पर खेत में 5 फेरोमोन ट्रैप लगाएं और नीम का तेल (1500 PPM) 5 मिली/लीटर पानी में मिलाकर छिड़कें। गंभीर स्थिति में इमामेक्टिन बेंजोएट 5% SG (8-10 ग्राम प्रति 15L पंप) का उपयोग करें।';
    }

    return 'राम-राम किसान भाई! आपकी फसल की बेहतर पैदावार के लिए मैं सदैव तत्पर हूँ। आप बेझिझक बोआई, खाद, सिंचाई, मौसम या फसल रोग के बारे में पूछ सकते हैं। यदि तुरंत कृषि वैज्ञानिक से बात करनी हो तो टोल-फ्री किसान कॉल सेंटर 1800-180-1551 पर कॉल करें।';
  }

  Future<void> _logToSupabase(String farmerId, String userQuery, String assistantReply) async {
    try {
      final sessionId = _uuid.v4();
      await _supabase.from('chat_sessions').upsert({
        'id': sessionId,
        'farmer_id': farmerId,
        'title': 'कृषि सहायक परामर्श',
      });

      await _supabase.from('chat_messages').insert([
        {
          'id': _uuid.v4(),
          'session_id': sessionId,
          'farmer_id': farmerId,
          'role': 'user',
          'content': userQuery,
          'language': 'hi',
        },
        {
          'id': _uuid.v4(),
          'session_id': sessionId,
          'farmer_id': farmerId,
          'role': 'assistant',
          'content': assistantReply,
          'language': 'hi',
        },
      ]);
    } catch (e) {
      debugPrint('[KrishiSahayak] Supabase logging skipped: $e');
    }
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String farmerId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: true)
          .limit(20);

      return (response as List)
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[KrishiSahayak] Could not load chat history: $e');
      return [];
    }
  }

  @override
  Future<void> clearHistory(String farmerId) async {
    try {
      await _supabase.from('chat_messages').delete().eq('farmer_id', farmerId);
    } catch (e) {
      debugPrint('[KrishiSahayak] Could not clear history: $e');
    }
  }
}

