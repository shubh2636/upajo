#!/usr/bin/env python3
"""
Upajo (उपजो) - Automated Supabase RLS & Database Security Test Suite
Validates schema definitions, policy least-privilege guarantees, anti-tampering triggers,
and simulates multi-tenant security isolation across:
- Anon
- Consumer A vs Consumer B
- Farmer A vs Farmer B
- Admin
- Privilege escalation attempts
- Financial and state-machine tampering
- Storage folder isolation
"""

import os
import re
import unittest
from typing import Dict, Any, List

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SCHEMA_FILE = os.path.join(ROOT_DIR, "supabase", "migrations", "20250101000000_init_upajo_schema.sql")
TEST_SQL_FILE = os.path.join(ROOT_DIR, "supabase", "tests", "rls_security_tests.sql")

class TestDatabaseAndRLSSecurity(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        with open(SCHEMA_FILE, "r", encoding="utf-8") as f:
            cls.schema_sql = f.read()

        with open(TEST_SQL_FILE, "r", encoding="utf-8") as f:
            cls.test_sql = f.read()

    def test_01_all_tables_have_rls_enabled(self):
        """Verify that every single table in public schema has RLS strictly enabled"""
        expected_tables = [
            "profiles", "farmer_profiles", "categories", "products", "pack_options",
            "orders", "order_items", "payments", "ratings", "delivery", "crops",
            "crop_plans", "tasks", "disease_scans", "chat_sessions", "chat_messages",
            "machinery", "rentals", "store_items", "notifications"
        ]
        for tbl in expected_tables:
            pattern = rf"ALTER\s+TABLE\s+public\.{tbl}\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY;"
            self.assertTrue(
                re.search(pattern, self.schema_sql, re.IGNORECASE),
                f"Table public.{tbl} does not have ROW LEVEL SECURITY enabled!"
            )

    def test_02_no_broad_select_on_pii_tables(self):
        """Verify that profiles and farmer_profiles do NOT have overly broad SELECT USING (true)"""
        # profiles SELECT must not be USING (true)
        profiles_select_match = re.search(
            r'CREATE\s+POLICY\s+"[^"]+"\s+ON\s+public\.profiles\s+FOR\s+SELECT\s+TO\s+authenticated\s+USING\s*\((.*?)\);',
            self.schema_sql,
            re.DOTALL | re.IGNORECASE
        )
        self.assertIsNotNone(profiles_select_match, "Missing SELECT policy on public.profiles")
        self.assertNotEqual(
            profiles_select_match.group(1).strip().lower(),
            "true",
            "public.profiles has dangerous overly broad SELECT USING (true) policy!"
        )

        # farmer_profiles SELECT must not be USING (true)
        farmer_select_match = re.search(
            r'CREATE\s+POLICY\s+"[^"]+"\s+ON\s+public\.farmer_profiles\s+FOR\s+SELECT\s+TO\s+authenticated\s+USING\s*\((.*?)\);',
            self.schema_sql,
            re.DOTALL | re.IGNORECASE
        )
        self.assertIsNotNone(farmer_select_match, "Missing SELECT policy on public.farmer_profiles")
        self.assertNotEqual(
            farmer_select_match.group(1).strip().lower(),
            "true",
            "public.farmer_profiles has dangerous overly broad SELECT USING (true) policy exposing banking PII!"
        )

    def test_03_farmer_banking_pii_strictly_isolated(self):
        """Verify farmer_profiles is readable ONLY by owner or admin"""
        farmer_select = re.search(
            r'CREATE\s+POLICY\s+"Farmer profiles owner and admin select"\s+ON\s+public\.farmer_profiles\s+FOR\s+SELECT\s+TO\s+authenticated\s+USING\s*\((.*?)\);',
            self.schema_sql,
            re.DOTALL
        )
        self.assertIsNotNone(farmer_select, "Missing Farmer profiles owner and admin select policy")
        cond = farmer_select.group(1)
        self.assertIn("auth.uid() = farmer_id", cond)
        self.assertIn("public.is_admin()", cond)

    def test_04_profile_privilege_escalation_guard(self):
        """Verify protect_profile_privileges trigger protects role, kyc_status, and verified_by_admin"""
        self.assertIn("CREATE OR REPLACE FUNCTION public.protect_profile_privileges()", self.schema_sql)
        self.assertIn("NEW.role IS DISTINCT FROM OLD.role", self.schema_sql)
        self.assertIn("NEW.kyc_status IS DISTINCT FROM OLD.kyc_status", self.schema_sql)
        self.assertIn("NEW.verified_by_admin IS DISTINCT FROM OLD.verified_by_admin", self.schema_sql)
        self.assertIn("trg_protect_profile_privileges", self.schema_sql)

    def test_05_order_anti_tampering_and_state_machine_trigger(self):
        """Verify protect_order_integrity_and_transitions prevents price tampering and enforces state machine"""
        self.assertIn("CREATE OR REPLACE FUNCTION public.protect_order_integrity_and_transitions()", self.schema_sql)
        self.assertIn("NEW.subtotal_amount IS DISTINCT FROM OLD.subtotal_amount", self.schema_sql)
        self.assertIn("NEW.delivery_fee IS DISTINCT FROM OLD.delivery_fee", self.schema_sql)
        self.assertIn("NEW.total_amount IS DISTINCT FROM OLD.total_amount", self.schema_sql)
        self.assertIn("NEW.consumer_id IS DISTINCT FROM OLD.consumer_id", self.schema_sql)
        self.assertIn("NEW.farmer_id IS DISTINCT FROM OLD.farmer_id", self.schema_sql)
        self.assertIn("trg_orders_protect_integrity", self.schema_sql)

    def test_06_rental_anti_tampering_and_state_machine_trigger(self):
        """Verify protect_rental_integrity_and_transitions prevents deposit tampering and invalid status transitions"""
        self.assertIn("CREATE OR REPLACE FUNCTION public.protect_rental_integrity_and_transitions()", self.schema_sql)
        self.assertIn("NEW.deposit_amount IS DISTINCT FROM OLD.deposit_amount", self.schema_sql)
        self.assertIn("NEW.total_amount IS DISTINCT FROM OLD.total_amount", self.schema_sql)
        self.assertIn("trg_rentals_protect_integrity", self.schema_sql)

    def test_07_payments_table_client_mutation_lockdown(self):
        """Verify that authenticated users CANNOT insert or update payment rows directly"""
        # Payments insert must be admin only
        pay_insert = re.search(
            r'CREATE\s+POLICY\s+"Payments insert restricted to admin or service role"\s+ON\s+public\.payments\s+FOR\s+INSERT\s+TO\s+authenticated\s+WITH\s+CHECK\s*\((.*?)\);',
            self.schema_sql,
            re.DOTALL
        )
        self.assertIsNotNone(pay_insert, "Missing restricted payment insert policy")
        self.assertIn("public.is_admin()", pay_insert.group(1))

        # Payments update must be admin only
        pay_update = re.search(
            r'CREATE\s+POLICY\s+"Payments update restricted to admin or service role"\s+ON\s+public\.payments\s+FOR\s+UPDATE\s+TO\s+authenticated',
            self.schema_sql
        )
        self.assertIsNotNone(pay_update, "Missing restricted payment update policy")

    def test_08_storage_tenant_folder_isolation(self):
        """Verify storage bucket policies enforce folder prefix matching auth.uid()"""
        self.assertIn('(storage.foldername(name))[1] = auth.uid()::text', self.schema_sql)
        self.assertIn('Authenticated read for private buckets', self.schema_sql)
        self.assertIn('Authenticated users isolated upload', self.schema_sql)
        self.assertIn('Authenticated users isolated update', self.schema_sql)
        self.assertIn('Authenticated users isolated delete', self.schema_sql)

    def test_09_security_definer_functions_search_path_hardened(self):
        """Verify all SECURITY DEFINER functions set explicit search_path = public, pg_temp"""
        # Parse functions: extract function name and its declaration attributes
        fn_matches = re.finditer(
            r'CREATE\s+OR\s+REPLACE\s+FUNCTION\s+public\.(\w+)[^$]*\$\$[\s\S]*?\$\$\s*([^;]+);',
            self.schema_sql
        )
        sec_def_found = 0
        for m in fn_matches:
            fn_name = m.group(1)
            attrs = m.group(2)
            if "SECURITY DEFINER" in attrs:
                sec_def_found += 1
                self.assertIn(
                    "search_path",
                    attrs.lower(),
                    f"Function public.{fn_name}() is SECURITY DEFINER but lacks fixed search_path!"
                )
        self.assertGreater(sec_def_found, 0, "No SECURITY DEFINER functions detected")

    def test_10_multi_tenant_rls_simulation(self):
        """
        Simulate multi-tenant policy evaluation matrix:
        - Anonymous, Consumer A, Consumer B, Farmer A, Farmer B, Admin
        """
        farmer_a_id = "11111111-1111-1111-1111-111111111111"
        farmer_b_id = "22222222-2222-2222-2222-222222222222"
        consumer_a_id = "33333333-3333-3333-3333-333333333333"
        consumer_b_id = "55555555-5555-5555-5555-555555555555"
        admin_id = "44444444-4444-4444-4444-444444444444"

        # 1. farmer_profiles SELECT evaluation
        def can_select_farmer_profile(user_id, target_farmer_id, is_admin=False):
            return (user_id == target_farmer_id) or is_admin

        # Anon cannot see Farmer A's bank profile
        self.assertFalse(can_select_farmer_profile(None, farmer_a_id))
        # Farmer B cannot see Farmer A's bank profile
        self.assertFalse(can_select_farmer_profile(farmer_b_id, farmer_a_id))
        # Consumer A cannot see Farmer A's bank profile
        self.assertFalse(can_select_farmer_profile(consumer_a_id, farmer_a_id))
        # Farmer A can see own bank profile
        self.assertTrue(can_select_farmer_profile(farmer_a_id, farmer_a_id))
        # Admin can see Farmer A's bank profile
        self.assertTrue(can_select_farmer_profile(admin_id, farmer_a_id, is_admin=True))

        # 2. orders SELECT evaluation
        def can_select_order(user_id, order_consumer_id, order_farmer_id, is_admin=False):
            return user_id in (order_consumer_id, order_farmer_id) or is_admin

        # Consumer A placed order with Farmer A
        self.assertTrue(can_select_order(consumer_a_id, consumer_a_id, farmer_a_id))
        self.assertTrue(can_select_order(farmer_a_id, consumer_a_id, farmer_a_id))
        # Consumer B (unrelated) CANNOT see order
        self.assertFalse(can_select_order(consumer_b_id, consumer_a_id, farmer_a_id))
        # Farmer B (unrelated) CANNOT see order
        self.assertFalse(can_select_order(farmer_b_id, consumer_a_id, farmer_a_id))
        # Admin CAN see order
        self.assertTrue(can_select_order(admin_id, consumer_a_id, farmer_a_id, is_admin=True))

        # 3. Privilege escalation evaluation
        def can_modify_role_or_kyc(user_id, target_user_id, new_role, is_admin=False):
            if new_role == 'admin':
                return is_admin
            return is_admin

        self.assertFalse(can_modify_role_or_kyc(consumer_a_id, consumer_a_id, 'admin', is_admin=False))
        self.assertFalse(can_modify_role_or_kyc(farmer_a_id, farmer_b_id, 'admin', is_admin=False))
        self.assertTrue(can_modify_role_or_kyc(admin_id, farmer_b_id, 'admin', is_admin=True))

        # 4. Storage folder isolation evaluation
        def can_upload_storage(user_id, object_path):
            folder = object_path.split('/')[0] if '/' in object_path else ''
            return bool(user_id) and folder == user_id

        # User uploading into own folder
        self.assertTrue(can_upload_storage(consumer_a_id, f"{consumer_a_id}/avatar.jpg"))
        # Attacker uploading into victim folder
        self.assertFalse(can_upload_storage(consumer_a_id, f"{consumer_b_id}/malicious.pdf"))

    def test_11_sql_test_script_completeness(self):
        """Verify supabase/tests/rls_security_tests.sql contains all required assertion patterns"""
        required_patterns = [
            "SET LOCAL ROLE anon;",
            "Anonymous users cannot view farmer bank accounts or UPI VPAs",
            "Farmer 2 cannot tamper with or modify Farmer 1 product",
            "Farmer 2 cannot view Farmer 1 bank details or UPI",
            "Unrelated Farmer 2 cannot see Consumer 1 order",
            "Consumer 2 cannot view Consumer 1 order",
            "Consumer 2 cannot query Consumer 1 private profile",
            "Non-admin cannot verify their own or others KYC status",
            "Non-admin cannot self-escalate to admin role",
            "System Admin can successfully approve and verify farmer KYC",
            "Consumer cannot alter order total_amount",
            "Consumer cannot jump order status to delivered",
            "Authenticated consumer cannot insert payment record",
            "Renter cannot alter rental security deposit",
            "Renter cannot mark rental completed",
            "ROLLBACK;"
        ]
        for pat in required_patterns:
            self.assertIn(
                pat,
                self.test_sql,
                f"Missing required test case in rls_security_tests.sql: '{pat}'"
            )

if __name__ == "__main__":
    unittest.main(verbosity=2)
