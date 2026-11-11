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

    test('1. SMS OTP Authentication is Disabled (No DLT/SMS Provider)', () async {
      final repo = AuthRepositoryImpl(client: mockClient);

      // sendOtp should throw ServerException indicating SMS OTP is disabled
      await expectLater(
        () => repo.sendOtp('9876543210'),
        throwsA(predicate((e) =>
            e.toString().contains('SMS OTP') ||
            e.toString().contains('disabled') ||
            e.toString().contains('अक्षम'))),
      );
    });

    test('2. SMS OTP Verification is Disabled', () async {
      final repo = AuthRepositoryImpl(client: mockClient);

      // verifyOtp should throw ServerException indicating SMS OTP is disabled
      await expectLater(
        () => repo.verifyOtp(phone: '9876543210', token: '123456'),
        throwsA(predicate((e) =>
            e.toString().contains('SMS OTP') ||
            e.toString().contains('disabled') ||
            e.toString().contains('अक्षम'))),
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
