import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../crop_advisor/presentation/controllers/crop_advisor_controller.dart';
import '../controllers/krishi_sahayak_controller.dart';
import '../../domain/models/chat_message.dart';

class KrishiSahayakScreen extends ConsumerStatefulWidget {
  const KrishiSahayakScreen({super.key});

  @override
  ConsumerState<KrishiSahayakScreen> createState() => _KrishiSahayakScreenState();
}

class _KrishiSahayakScreenState extends ConsumerState<KrishiSahayakScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickSuggestions = [
    'गेहूं में पहली सिंचाई कब करें?',
    'पत्तियों पर पीले धब्बे दिख रहे हैं',
    'क्या आज मौसम छिड़काव के लिए सही है?',
    'चने में इल्ली नियंत्रण के उपाय',
    'यूरिया की सही मात्रा कितनी है?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitMessage(String text) {
    if (text.trim().isEmpty) return;

    final user = ref.read(authControllerProvider).userProfile;
    final advisorState = ref.read(cropAdvisorControllerProvider);
    final farmerId = user?.id ?? 'demo_farmer_id';

    ref.read(krishiSahayakControllerProvider.notifier).sendUserQuery(
      query: text,
      farmerId: farmerId,
      cropContext: advisorState.recommendation?.nameHi ?? 'गेहूं (Wheat)',
      district: advisorState.district,
      stateName: advisorState.stateName,
      currentTemp: advisorState.weatherData?.currentTemp,
      humidity: advisorState.weatherData?.currentHumidity,
      windSpeed: advisorState.weatherData?.windSpeedKmH,
    );

    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(krishiSahayakControllerProvider);
    final controller = ref.read(krishiSahayakControllerProvider.notifier);
    final advisorState = ref.watch(cropAdvisorControllerProvider);
    final user = ref.watch(authControllerProvider).userProfile;
    final farmerId = user?.id ?? 'demo_farmer_id';

    // Auto-scroll when new messages arrive
    ref.listen(krishiSahayakControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.soil50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary300),
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.primary600, size: 22.0),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('sahayak.title'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5)),
                const Text('क्लाउड AI • हिंदी आवाज़ सहायता', style: TextStyle(fontSize: 11.0, color: AppColors.primary600, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'बातचीत साफ करें',
            onPressed: () => controller.clearChat(farmerId),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Farmer Context Ribbon
          _buildContextRibbon(advisorState),

          // 2. Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final msg = state.messages[index];
                return _buildMessageBubble(msg, controller);
              },
            ),
          ),

          // Loading typing indicator
          if (state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.primary500),
                  ),
                  const SizedBox(width: 10.0),
                  Text('कृषि सहायक उत्तर तैयार कर रहे हैं...', style: AppTypography.bodySmall.copyWith(color: AppColors.soil600)),
                ],
              ),
            ),

          // 3. Quick Suggestions Carousel
          _buildQuickSuggestions(),

          // 4. Voice & Text Input Bar
          _buildInputBar(state, controller),

          // 5. Emergency Helpline Footer
          _buildSafetyDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildContextRibbon(CropAdvisorState advisorState) {
    final weather = advisorState.weatherData;
    final crop = advisorState.recommendation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: AppColors.wheat100.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, size: 16.0, color: AppColors.primary600),
              const SizedBox(width: 6.0),
              Text(
                'फसल: ${crop?.nameHi ?? "गेहूं"} (${advisorState.district})',
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: AppColors.soil800),
              ),
            ],
          ),
          if (weather != null)
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 15.0, color: AppColors.wheat700),
                const SizedBox(width: 4.0),
                Text(
                  '${weather.currentTemp.toStringAsFixed(0)}°C • हवा ${weather.windSpeedKmH.toStringAsFixed(0)} km/h',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.soil700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, KrishiSahayakController controller) {
    final isUser = msg.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary600 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: Radius.circular(isUser ? 16.0 : 4.0),
            bottomRight: Radius.circular(isUser ? 4.0 : 16.0),
          ),
          border: isUser ? null : Border.all(color: AppColors.soil200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, size: 16.0, color: AppColors.primary600),
                      SizedBox(width: 4.0),
                      Text('कृषि सहायक', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary700)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      msg.isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                      color: msg.isSpeaking ? AppColors.terracotta500 : AppColors.soil600,
                      size: 22.0,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'बोलकर सुनें',
                    onPressed: () => controller.speakMessage(msg.content, msg.id),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 6.0),
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: isUser ? Colors.white : AppColors.soil900,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Container(
      height: 42.0,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        itemCount: _quickSuggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final prompt = _quickSuggestions[index];
          return ActionChip(
            label: Text(prompt),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.soil300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            labelStyle: const TextStyle(fontSize: 12.0, color: AppColors.soil800, fontWeight: FontWeight.w600),
            onPressed: () => _submitMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(KrishiSahayakState state, KrishiSahayakController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.soil200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Floating Microphone Button (Pulsing when active)
            GestureDetector(
              onTap: () {
                controller.toggleListening(
                  onTextCaptured: (text) {
                    _textController.text = text;
                    _submitMessage(text);
                  },
                );
              },
              child: Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: state.isListening ? AppColors.terracotta500 : AppColors.primary500,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (state.isListening ? AppColors.terracotta500 : AppColors.primary500).withOpacity(0.35),
                      blurRadius: state.isListening ? 14.0 : 6.0,
                      spreadRadius: state.isListening ? 4.0 : 0.0,
                    ),
                  ],
                ),
                child: Icon(
                  state.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 26.0,
                ),
              ),
            ),
            const SizedBox(width: 10.0),

            // Text Input Field
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _submitMessage,
                decoration: InputDecoration(
                  hintText: state.isListening ? 'सुन रहे हैं... बोलिए' : 'बोलें या सवाल लिखें...',
                  hintStyle: TextStyle(
                    color: state.isListening ? AppColors.terracotta600 : AppColors.soil400,
                    fontSize: 14.0,
                  ),
                  filled: true,
                  fillColor: AppColors.soil50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: const BorderSide(color: AppColors.soil300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: const BorderSide(color: AppColors.soil300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: const BorderSide(color: AppColors.primary500, width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),

            // Send Button
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary600, size: 28.0),
              onPressed: () => _submitMessage(_textController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      color: AppColors.soil100,
      child: const Text(
        'सुरक्षा चेतावनी: AI कीटनाशक सलाह मार्गदर्शक है। आपात स्थिति में निःशुल्क किसान कॉल सेंटर 1800-180-1551 पर संपर्क करें।',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.5, color: AppColors.soil600, fontWeight: FontWeight.w600),
      ),
    );
  }
}

