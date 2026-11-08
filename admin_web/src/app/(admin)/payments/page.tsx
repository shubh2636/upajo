'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { CreditCard, CheckCircle2, RotateCcw, AlertTriangle, ArrowUpRight, DollarSign } from 'lucide-react';

interface PayoutItem {
  id: string;
  farmerName: string;
  bankAccount: string;
  ifsc: string;
  upi: string;
  amount: number;
  ordersCount: number;
  status: 'pending_approval' | 'processing' | 'settled';
  requestedAt: string;
}

const INITIAL_PAYOUTS: PayoutItem[] = [
  {
    id: 'pay_001',
    farmerName: 'बलदेव सिंह पटेल',
    bankAccount: '••••••••1102',
    ifsc: 'BKID0009876',
    upi: 'baldev@boi',
    amount: 14500,
    ordersCount: 4,
    status: 'pending_approval',
    requestedAt: '2026-02-15 09:30 AM',
  },
  {
    id: 'pay_002',
    farmerName: 'रामगोपाल पाटीदार',
    bankAccount: '••••••••8912',
    ifsc: 'SBIN0001234',
    upi: 'ramgopal@sbi',
    amount: 8200,
    ordersCount: 2,
    status: 'pending_approval',
    requestedAt: '2026-02-15 11:45 AM',
  },
  {
    id: 'pay_003',
    farmerName: 'दिलीप मीणा',
    bankAccount: '••••••••4521',
    ifsc: 'PUNB0123400',
    upi: 'dilip@pnb',
    amount: 22500,
    ordersCount: 7,
    status: 'settled',
    requestedAt: '2026-02-12',
  },
];

export default function PaymentsAdminPage() {
  const [payouts, setPayouts] = useState<PayoutItem[]>(INITIAL_PAYOUTS);

  const approvePayout = (id: string) => {
    setPayouts((prev) =>
      prev.map((p) => (p.id === id ? { ...p, status: 'settled' } : p))
    );
  };

  const triggerRefund = (orderNumber: string) => {
    const reason = prompt(`ऑर्डर ${orderNumber} हेतु रिफंड जारी करने का कारण दर्ज करें:`);
    if (reason) {
      alert(`Razorpay रिफंड ट्रिगर किया गया। कारण: ${reason}`);
    }
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="भुगतान व पेआउट निपटान (Payments & Payouts)"
        subtitle="Razorpay PG ट्रैकिंग, किसान बैंक पेआउट अनुमोदन एवं रिफंड प्रबंधन"
      />

      <main className="p-8 space-y-6 flex-1">
        {/* PG Settlement Status Banner */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          <div className="bg-white p-5 rounded-2xl border border-soil-200 shadow-sm">
            <span className="text-xs font-bold text-soil-500 uppercase">Razorpay PG बैलेंस</span>
            <div className="text-2xl font-black text-primary-700 mt-2">₹1,84,200.00</div>
            <p className="text-[11px] text-soil-500 mt-1">अगला बैंक सेटलमेंट: कल सुबह 08:00 AM</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-soil-200 shadow-sm">
            <span className="text-xs font-bold text-soil-500 uppercase">लंबित किसान पेआउट</span>
            <div className="text-2xl font-black text-wheat-600 mt-2">₹22,700.00</div>
            <p className="text-[11px] text-soil-500 mt-1">2 आवेदन अनुमोदन की प्रतीक्षा में</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-soil-200 shadow-sm">
            <span className="text-xs font-bold text-soil-500 uppercase">कुल संसाधित रिफंड</span>
            <div className="text-2xl font-black text-soil-800 mt-2">₹4,200.00</div>
            <p className="text-[11px] text-emerald-600 font-bold mt-1">0 विवाद लंबित ✓</p>
          </div>
        </div>

        {/* Payout Approvals Table */}
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <div className="p-5 border-b border-soil-200 flex items-center justify-between">
            <div>
              <h3 className="font-extrabold text-base text-soil-900">किसान पेआउट अनुमोदन कतार</h3>
              <p className="text-xs text-soil-500">डिलीवर हो चुके ऑर्डर का शुद्ध भुगतान अनुमोदन</p>
            </div>
            <button
              onClick={() => triggerRefund('UPJ-SAMPLE-REFUND')}
              className="px-3.5 py-1.5 bg-soil-100 hover:bg-soil-200 text-soil-800 rounded-xl text-xs font-bold transition flex items-center gap-1.5"
            >
              <RotateCcw className="w-3.5 h-3.5 text-clay-500" />
              मैनुअल रिफंड ट्रिगर
            </button>
          </div>

          <table className="w-full text-left text-xs">
            <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
              <tr>
                <th className="py-3.5 px-6">किसान विवरण</th>
                <th className="py-3.5 px-4">बैंक खाता व IFSC</th>
                <th className="py-3.5 px-4">UPI VPA</th>
                <th className="py-3.5 px-4">ऑर्डर संख्या</th>
                <th className="py-3.5 px-4">राशि (Net Payout)</th>
                <th className="py-3.5 px-4">स्थिति</th>
                <th className="py-3.5 px-6 text-right">कार्य</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-soil-100 font-medium">
              {payouts.map((p) => (
                <tr key={p.id} className="hover:bg-soil-50/80 transition">
                  <td className="py-4 px-6 font-bold text-soil-900">
                    <div>{p.farmerName}</div>
                    <div className="text-[11px] text-soil-400">{p.requestedAt}</div>
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-mono text-soil-800">{p.bankAccount}</div>
                    <div className="text-[11px] text-soil-500 font-mono">{p.ifsc}</div>
                  </td>
                  <td className="py-4 px-4 font-mono text-soil-700">{p.upi}</td>
                  <td className="py-4 px-4 font-bold text-soil-800">{p.ordersCount} ऑर्डर</td>
                  <td className="py-4 px-4">
                    <span className="font-black text-primary-700 text-sm">
                      ₹{p.amount.toLocaleString()}
                    </span>
                  </td>
                  <td className="py-4 px-4">
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${
                        p.status === 'settled'
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-wheat-100 text-wheat-800'
                      }`}
                    >
                      {p.status === 'settled' ? 'भुगतान पूर्ण ✓' : 'अनुमोदन लंबित'}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    {p.status === 'pending_approval' ? (
                      <button
                        onClick={() => approvePayout(p.id)}
                        className="px-3.5 py-1.5 bg-primary-600 hover:bg-primary-700 text-white rounded-lg text-xs font-bold shadow transition flex items-center gap-1 ml-auto"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5" /> पेआउट भेजें
                      </button>
                    ) : (
                      <span className="text-soil-400 text-xs font-semibold">निपटान संपन्न</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}

