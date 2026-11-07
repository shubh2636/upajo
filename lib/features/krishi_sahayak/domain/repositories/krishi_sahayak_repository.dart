import '../models/chat_message.dart';

abstract class KrishiSahayakRepository {
  /// Sends user query to FastAPI Claude proxy with injected farmer context
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
  });

  /// Loads previous chat messages from Supabase
  Future<List<ChatMessage>> getChatHistory(String farmerId);

  /// Clears current session history
  Future<void> clearHistory(String farmerId);
}

