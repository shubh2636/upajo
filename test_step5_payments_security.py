#!/usr/bin/env python3
"""
Step 5: Payments and Money Logic Security Test Suite
Validates:
1. Razorpay server-side order amount computation (Edge Function rejects client-side pricing).
2. HMAC-SHA256 signature verification (No simulation backdoors like order_sim_).
3. Webhook signature verification and idempotency deduplication (prevents replay attacks).
4. Atomic stock deduction logic (PostgreSQL FOR UPDATE row locks preventing overselling).
5. Removal of hardcoded marketing claims and addition of data-driven 'estimate' labels.
6. Machinery security deposit labeling honesty (labeled as deposit record, no false escrow claims).
"""

import os
import hmac
import hashlib
import json
import re
import unittest
from typing import Dict, Any

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__)))
SCHEMA_FILE = os.path.join(ROOT_DIR, "supabase", "migrations", "20250101000000_init_upajo_schema.sql")
CREATE_ORDER_FN = os.path.join(ROOT_DIR, "supabase", "functions", "create-razorpay-order", "index.ts")
VERIFY_PAY_FN = os.path.join(ROOT_DIR, "supabase", "functions", "verify-razorpay-payment", "index.ts")
WEBHOOK_FN = os.path.join(ROOT_DIR, "supabase", "functions", "razorpay-webhook", "index.ts")

class TestStep5PaymentsAndMoneyLogic(unittest.TestCase):

    def test_01_create_razorpay_order_computes_amount_server_side(self):
        """Confirm create-razorpay-order queries DB orders/products and does NOT trust client amount"""
        with open(CREATE_ORDER_FN, "r", encoding="utf-8") as f:
            code = f.read()

        # Must NOT extract amount_in_rupees from client body
        self.assertNotIn("amount_in_rupees", code, "Edge function still reads amount_in_rupees from client!")
        
        # Must query database for order and order_items
        self.assertIn('.from("orders")', code)
        self.assertIn('.from("products")', code)
        self.assertIn('calculatedSubtotal', code)
        self.assertIn('calculatedTotal', code)
        self.assertIn('amountInPaise', code)

        # Must NOT have mock order_sim_ fallback
        self.assertNotIn("order_sim_", code, "Edge function contains mock order_sim_ fallback!")

    def test_02_verify_payment_removes_simulation_backdoor_and_verifies_hmac(self):
        """Confirm verify-razorpay-payment enforces strict HMAC-SHA256 and has no bypass"""
        with open(VERIFY_PAY_FN, "r", encoding="utf-8") as f:
            code = f.read()

        # Check simulation bypass order_sim_ was eradicated
        self.assertNotIn("order_sim_", code, "Bypass backdoor order_sim_ still exists in verify function!")
        
        # Check HMAC SHA-256 verification logic
        self.assertIn('"HMAC"', code)
        self.assertIn('"SHA-256"', code)
        self.assertIn("generatedSignature !== razorpay_signature", code)

        # Check deduplication & replay protection
        self.assertIn('existingPayment.order_id === order_id', code)
        self.assertIn('Payment ID already utilized for another order', code)

        # Check atomic stock deduction is invoked
        self.assertIn('.rpc("deduct_order_stock"', code)

    def test_03_webhook_function_signature_verification_and_idempotency(self):
        """Confirm razorpay-webhook verifies x-razorpay-signature and deduplicates events"""
        self.assertTrue(os.path.exists(WEBHOOK_FN), "Missing razorpay-webhook Edge Function")
        with open(WEBHOOK_FN, "r", encoding="utf-8") as f:
            code = f.read()

        self.assertIn("x-razorpay-signature", code)
        self.assertIn("RAZORPAY_WEBHOOK_SECRET", code)
        self.assertIn("deduct_order_stock", code)
        self.assertIn("already_processed", code)

    def test_04_atomic_stock_deduction_in_schema_uses_row_locks(self):
        """Confirm deduct_order_stock uses FOR UPDATE to prevent race conditions and overselling"""
        with open(SCHEMA_FILE, "r", encoding="utf-8") as f:
            sql = f.read()

        self.assertIn("CREATE OR REPLACE FUNCTION public.deduct_order_stock", sql)
        self.assertIn("FOR UPDATE", sql)
        self.assertIn("ORDER BY product_id", sql, "Needs ORDER BY product_id to prevent deadlocks")
        self.assertIn("Insufficient stock", sql)
        self.assertIn("CREATE OR REPLACE FUNCTION public.restore_order_stock", sql)
        self.assertIn("idx_payments_razorpay_payment_id", sql, "Needs unique index on razorpay_payment_id")

    def test_05_machinery_deposit_label_honesty_no_unlicensed_escrow_claims(self):
        """Confirm machinery screens label deposit as 'deposit record' without false escrow refund guarantees"""
        detail_screen = os.path.join(ROOT_DIR, "lib", "features", "machinery", "presentation", "screens", "machinery_detail_screen.dart")
        with open(detail_screen, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertNotIn("तुरंत आपके खाते में वापस", content, "Claims instant automated refund without escrow provider!")
        self.assertIn("जमानत रिकॉर्ड", content)
        self.assertIn("भौतिक निरीक्षण व सत्यापन के बाद", content)

    def test_06_marketing_claims_removed_and_price_suggestions_labeled_as_estimates(self):
        """Confirm '100% ICAR certified' removed and price suggestions clearly labeled as estimates"""
        store_catalog = os.path.join(ROOT_DIR, "lib", "features", "agri_store", "presentation", "screens", "store_catalog_screen.dart")
        with open(store_catalog, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertNotIn("100% सरकारी व ICAR प्रमाणित", content)
        self.assertIn("गुणवत्ता जांचे गए कृषि इनपुट", content)

        # Check mandi router
        mandi_py = os.path.join(ROOT_DIR, "ml_service", "routers", "mandi.py")
        with open(mandi_py, "r", encoding="utf-8") as f:
            mandi_code = f.read()

        self.assertNotIn("30-45% higher realization", mandi_code)
        self.assertIn('"is_estimate": True', mandi_code)
        self.assertIn("अनुमानित दर", mandi_code)

if __name__ == "__main__":
    unittest.main(verbosity=2)
