import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'payment';
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _userTickets = [];
  bool _isLoadingTickets = true;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'उपजो पर भुगतान कब और कैसे मिलता है?',
      'a': 'ग्राहक द्वारा डिलीवरी प्राप्त होने और संतुष्टि की पुष्टि के 24 घंटे के भीतर राशि सीधे आपके बैंक खाते अथवा UPI में स्थानांतरित कर दी जाती है।'
    },
    {
      'q': 'क्या उपजो कोई कमीशन काटता है?',
      'a': 'नहीं, उपजो की वर्तमान प्रचार अवधि के दौरान 0% प्लेटफॉर्म कमीशन है। केवल 2% + 18% GST का वास्तविक पेमेंट गेटवे (Razorpay) शुल्क लागू होता है।'
    },
    {
      'q': 'खराब या सड़ी हुई उपज मिलने पर क्या करें?',
      'a': 'डिलीवरी के 48 घंटे के भीतर "नई शिकायत दर्ज करें" टैब में जाकर फोटो सहित शिकायत दर्ज करें। हमारी मध्यस्थ टीम 24 घंटे में रिफंड अथवा प्रतिस्थापन की प्रक्रिया पूर्ण करेगी।'
    },
    {
      'q': 'कृषि यंत्र की सुरक्षा राशि (Deposit) कब वापस होती है?',
      'a': 'उपकरण को सही सलामत वापस करने और मालिक द्वारा निरीक्षण के 24 घंटे के भीतर पूरी सुरक्षा राशि आपके खाते में वापस कर दी जाती है।'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTickets() async {
    final user = ref.read(authControllerProvider).userProfile;
    if (user != null) {
      try {
        final res = await SupabaseService.client
            .from('support_tickets')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        if (mounted) {
          setState(() {
            _userTickets = List<Map<String, dynamic>>.from(res as List);
            _isLoadingTickets = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingTickets = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingTickets = false);
      }
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authControllerProvider).userProfile;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया शिकायत दर्ज करने हेतु पहले लॉगिन करें।')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await SupabaseService.client.from('support_tickets').insert({
        'user_id': user.id,
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'description': _descController.text.trim(),
        'status': 'open',
        'priority': 'medium',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('शिकायत सफलतापूर्वक दर्ज हो गई है। टिकट नंबर जल्द एसएमएस द्वारा भेजा जाएगा।'),
          ),
        );
        _subjectController.clear();
        _descController.clear();
        _loadUserTickets();
        _tabController.animateTo(2); // Switch to "My Tickets"
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('त्रुटि: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _callHelpline() async {
    final uri = Uri.parse('tel:18001801551');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('मदद एवं शिकायत निवारण (Support)'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'अक्सर सवाल (FAQ)'),
            Tab(text: 'नई शिकायत'),
            Tab(text: 'मेरी शिकायतें'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildNewTicketTab(),
          _buildMyTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kisan Call Center direct card
        AppCard(
          elevation: 2,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_in_talk, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('किसान कॉल सेंटर (निःशुल्क)', style: AppTypography.titleMedium),
                        Text('टोल फ्री: 1800-180-1551 (सुबह 6 से रात 10)', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'कॉल करें (1800-180-1551)',
                icon: const Icon(Icons.call),
                onPressed: _callHelpline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('अक्सर पूछे जाने वाले प्रश्न', style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        ..._faqs.map(
          (faq) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(faq['q']!, style: AppTypography.titleSmall),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(faq['a']!, style: AppTypography.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('समस्या की श्रेणी चुनें', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'payment', child: Text('भुगतान / बैंक अंतरण (Payment / Bank)')),
                DropdownMenuItem(value: 'product_quality', child: Text('उत्पाद की गुणवत्ता / खराबी (Quality)')),
                DropdownMenuItem(value: 'delivery', child: Text('डिलीवरी एवं परिवहन (Delivery)')),
                DropdownMenuItem(value: 'machinery', child: Text('कृषि मशीनरी / उपकरण (Machinery)')),
                DropdownMenuItem(value: 'kyc', child: Text('किसान सत्यापन / KYC (Verification)')),
                DropdownMenuItem(value: 'other', child: Text('अन्य सहायता (Other)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _subjectController,
              label: 'समस्या का शीर्षक (Subject)',
              hintText: 'उदा. ऑर्डर #1024 का भुगतान अभी तक प्राप्त नहीं हुआ',
              validator: (val) => (val == null || val.trim().isEmpty) ? 'कृपया शीर्षक लिखें' : null,
            ),
            const SizedBox(height: 16),
            Text('विस्तृत विवरण (Description)', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'अपनी समस्या का पूरा विवरण यहाँ लिखें...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => (val == null || val.trim().length < 10) ? 'कृपया कम से कम 10 अक्षरों में विवरण लिखें' : null,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'शिकायत दर्ज करें (Submit Ticket)',
              icon: const Icon(Icons.send),
              isLoading: _isSubmitting,
              onPressed: _submitTicket,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userTickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('आपकी कोई लंबित शिकायत नहीं है', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text('यदि कोई समस्या हो तो नई शिकायत दर्ज करें।', style: AppTypography.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userTickets.length,
      itemBuilder: (context, index) {
        final t = _userTickets[index];
        final status = t['status'] ?? 'open';
        final isResolved = status == 'resolved' || status == 'closed';

        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isResolved ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isResolved ? Colors.green : Colors.amber.shade700),
                    ),
                    child: Text(
                      isResolved ? 'समाधान हुआ (Resolved)' : 'प्रक्रियाधीन (In Progress)',
                      style: TextStyle(
                        color: isResolved ? Colors.green.shade800 : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    t['created_at'] != null ? t['created_at'].toString().substring(0, 10) : '',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(t['subject']?.toString() ?? 'शिकायत', style: AppTypography.titleMedium),
              const SizedBox(height: 4),
              Text(t['description']?.toString() ?? '', style: AppTypography.bodyMedium),
              if (t['admin_response'] != null) ...[
                const Divider(height: 20),
                Text('उपजो सपोर्ट टीम का उत्तर:', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(t['admin_response'].toString(), style: AppTypography.bodyMedium),
              ],
            ],
          ),
        );
      },
    );
  }
}

