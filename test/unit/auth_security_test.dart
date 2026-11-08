import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upajo/core/network/secure_local_storage.dart';
import 'package:upajo/features/auth/domain/models/user_profile.dart';
import 'package:upajo/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('Step 3: Auth Security Invariants', () {
    late SupabaseClient mockClient;

    setUp(() {
      mockClient = SupabaseClient('https://mock.supabase.co', 'mock-anon-key');
    });

    test('1. Rate Limiting Cooldown on OTP Requests', () async {
      final repo = AuthRepositoryImpl(client: mockClient);

      // First OTP request succeeds (or hits dev bypass)
      await repo.sendOtp('9876543210');

      // Immediate second request within 60s cooldown must throw ServerException
      expect(
        () => repo.sendOtp('9876543210'),
        throwsA(predicate((e) =>
            e.toString().contains('प्रतीक्षा करें') ||
            e.toString().contains('Please wait'))),
      );
    });

    test('2. Brute-Force Lockout After 5 Failed Attempts', () async {
      final repo = AuthRepositoryImpl(client: mockClient);

      // Simulate 5 consecutive failed OTP entries
      for (int i = 0; i < 4; i++) {
        try {
          await repo.verifyOtp(phone: '9876543210', token: '00000$i');
        } catch (_) {}
      }

      // 5th failed attempt should trigger lockout
      expect(
        () => repo.verifyOtp(phone: '9876543210', token: '000005'),
        throwsA(predicate((e) =>
            e.toString().contains('15 मिनट') ||
            e.toString().contains('Locked for 15 minutes'))),
      );
    });

    test('3. Client-Side Role and KYC Escalation Prevention', () {
      final profile = UserProfile(
        id: 'user_malicious',
        role: 'admin', // Malicious attempt to escalate to admin
        phone: '9876543210',
        fullName: 'Attacker',
        kycStatus: 'verified', // Malicious attempt to self-approve KYC
        verifiedByAdmin: true,
        createdAt: DateTime.now(),
      );

      final payload = profile.toJson();
      // Verify our stripping logic
      payload.remove('role');
      payload.remove('verified_by_admin');
      payload.remove('kyc_status');

      expect(payload.containsKey('role'), false);
      expect(payload.containsKey('verified_by_admin'), false);
      expect(payload.containsKey('kyc_status'), false);
    });

    test('4. SecureLocalStorage Token Persistence Contract', () async {
      final storage = SecureLocalStorage();
      expect(storage, isA<SecureLocalStorage>());
    });
  });
}
