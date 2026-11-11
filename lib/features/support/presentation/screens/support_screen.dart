import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

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
        SnackBar(content: Text('support.login_to_submit'.tr())),
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
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('support.ticket_submitted'.tr()),
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
            content: Text(e.toString()),
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
        title: Text('support.title'.tr()),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'support.tab_faq'.tr()),
            Tab(text: 'support.tab_new_ticket'.tr()),
            Tab(text: 'support.tab_my_tickets'.tr()),
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
    final faqs = [
      {'q': 'support.faq_payment_q'.tr(), 'a': 'support.faq_payment_a'.tr()},
      {'q': 'support.faq_commission_q'.tr(), 'a': 'support.faq_commission_a'.tr()},
      {'q': 'support.faq_damaged_q'.tr(), 'a': 'support.faq_damaged_a'.tr()},
      {'q': 'support.faq_deposit_q'.tr(), 'a': 'support.faq_deposit_a'.tr()},
    ];

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
                        Text('support.kisan_call_center'.tr(), style: AppTypography.titleMedium),
                        Text('support.toll_free_timings'.tr(), style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'support.call_toll_free'.tr(),
                icon: const Icon(Icons.call),
                onPressed: _callHelpline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('support.faq_heading'.tr(), style: AppTypography.headlineSmall),
        const SizedBox(height: 12),
        ...faqs.map(
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
            Text('support.select_category'.tr(), style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: 'payment', child: Text('support.cat_payment'.tr())),
                DropdownMenuItem(value: 'product_quality', child: Text('support.cat_quality'.tr())),
                DropdownMenuItem(value: 'delivery', child: Text('support.cat_delivery'.tr())),
                DropdownMenuItem(value: 'machinery', child: Text('support.cat_machinery'.tr())),
                DropdownMenuItem(value: 'kyc', child: Text('support.cat_kyc'.tr())),
                DropdownMenuItem(value: 'other', child: Text('support.cat_other'.tr())),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _subjectController,
              label: 'support.ticket_subject_label'.tr(),
              hintText: 'support.subject_hint'.tr(),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'support.subject_error'.tr() : null,
            ),
            const SizedBox(height: 16),
            Text('support.ticket_desc_label'.tr(), style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'support.desc_hint'.tr(),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => (val == null || val.trim().length < 10) ? 'support.desc_min_error'.tr() : null,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'support.submit_ticket'.tr(),
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
            Text('support.no_tickets_title'.tr(), style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text('support.no_tickets_sub'.tr(), style: AppTypography.bodySmall),
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
                      isResolved ? 'support.status_resolved'.tr() : 'support.status_in_progress'.tr(),
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
              Text(t['subject']?.toString() ?? 'support.ticket_fallback'.tr(), style: AppTypography.titleMedium),
              const SizedBox(height: 4),
              Text(t['description']?.toString() ?? '', style: AppTypography.bodyMedium),
              if (t['admin_response'] != null) ...[
                const Divider(height: 20),
                Text('support.team_response'.tr(), style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
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
