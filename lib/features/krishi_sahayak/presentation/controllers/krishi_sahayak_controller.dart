import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/krishi_sahayak_repository.dart';
import '../../data/repositories/krishi_sahayak_repository_impl.dart';

final krishiSahayakRepositoryProvider = Provider<KrishiSahayakRepository>((ref) {
  return KrishiSahayakRepositoryImpl();
});

class KrishiSahayakState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isListening;
  final bool isSpeaking;
  final String? activeSpeakingId;
  final String recognizedWords;
  final String? errorMessage;

  const KrishiSahayakState({
    this.messages = const [],
    this.isLoading = false,
    this.isListening = false,
    this.isSpeaking = false,
    this.activeSpeakingId,
    this.recognizedWords = '',
    this.errorMessage,
  });

  KrishiSahayakState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isListening,
    bool? isSpeaking,
    String? activeSpeakingId,
    String? recognizedWords,
    String? errorMessage,
  }) {
    return KrishiSahayakState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      activeSpeakingId: activeSpeakingId,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      errorMessage: errorMessage,
    );
  }
}

class KrishiSahayakController extends StateNotifier<KrishiSahayakState> {
  final KrishiSahayakRepository _repository;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  static const _uuid = Uuid();

  KrishiSahayakController(this._repository) : super(const KrishiSahayakState()) {
    _initTts();
    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: 'welcome_msg',
          role: 'assistant',
          content: 'राम-राम किसान भाई! मैं आपका डिजिटल कृषि सहायक हूँ। आप मुझसे बोलकर या लिखकर अपनी फसल, खाद, सिंचाई, मौसम या फसल रोग के बारे में कोई भी सवाल पूछ सकते हैं।',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('hi-IN');
      await _flutterTts.setSpeechRate(0.85); // Gentle cadence for rural farmers
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        state = state.copyWith(isSpeaking: false, activeSpeakingId: null);
      });

      _flutterTts.setErrorHandler((_) {
        state = state.copyWith(isSpeaking: false, activeSpeakingId: null);
      });
    } catch (e) {
      debugPrint('[KrishiSahayak] TTS Init error: $e');
    }
  }

  Future<void> toggleListening({Function(String text)? onTextCaptured}) async {
    if (state.isListening) {
      await stopListening();
    } else {
      await startListening(onTextCaptured: onTextCaptured);
    }
  }

  Future<void> startListening({Function(String text)? onTextCaptured}) async {
    try {
      final available = await _speechToText.initialize(
        onError: (err) {
          debugPrint('[KrishiSahayak] Speech error: $err');
          state = state.copyWith(isListening: false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );

      if (available) {
        state = state.copyWith(isListening: true, recognizedWords: '');
        await _speechToText.listen(
          localeId: 'hi_IN',
          onResult: (result) {
            state = state.copyWith(recognizedWords: result.recognizedWords);
            if (result.finalResult && onTextCaptured != null) {
              onTextCaptured(result.recognizedWords);
            }
          },
        );
      }
    } catch (e) {
      debugPrint('[KrishiSahayak] STT listen failed: $e');
      state = state.copyWith(isListening: false);
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> speakMessage(String text, String messageId) async {
    if (state.isSpeaking && state.activeSpeakingId == messageId) {
      await stopSpeaking();
      return;
    }

    await stopSpeaking();
    state = state.copyWith(isSpeaking: true, activeSpeakingId: messageId);

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      state = state.copyWith(isSpeaking: false, activeSpeakingId: null);
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    state = state.copyWith(isSpeaking: false, activeSpeakingId: null);
  }

  Future<void> sendUserQuery({
    required String query,
    required String farmerId,
    String? cropContext,
    String? district,
    String? stateName,
    double? currentTemp,
    int? humidity,
    double? windSpeed,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: cleanQuery,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
      recognizedWords: '',
    );

    try {
      final assistantReply = await _repository.sendMessage(
        farmerId: farmerId,
        userQuery: cleanQuery,
        conversationHistory: state.messages,
        cropContext: cropContext,
        district: district,
        stateName: stateName,
        currentTemp: currentTemp,
        humidity: humidity,
        windSpeed: windSpeed,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantReply],
        isLoading: false,
      );

      // Auto read-aloud for illiterate or voice-first users
      speakMessage(assistantReply.content, assistantReply.id);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'सहायक से संपर्क नहीं हो सका: $e',
      );
    }
  }

  Future<void> clearChat(String farmerId) async {
    await stopSpeaking();
    await _repository.clearHistory(farmerId);
    _addInitialGreeting();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }
}

final krishiSahayakControllerProvider =
    StateNotifierProvider<KrishiSahayakController, KrishiSahayakState>((ref) {
  final repo = ref.watch(krishiSahayakRepositoryProvider);
  return KrishiSahayakController(repo);
});
