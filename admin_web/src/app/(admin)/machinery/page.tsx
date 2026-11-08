'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Tractor, Eye, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';

interface MachineryAdminItem {
  id: string;
  name: string;
  category: string;
  ownerName: string;
  district: string;
  hourlyRate: number;
  dailyRate: number;
  depositAmount: number;
  status: 'active' | 'pending_verification' | 'disputed';
  disputeNotes?: string;
}

const INITIAL_MACHINERY: MachineryAdminItem[] = [
  {
    id: 'mac_001',
    name: 'महिंद्रा 575 DI (45 HP ट्रैक्टर)',
    category: 'ट्रैक्टर (Tractor)',
    ownerName: 'बलदेव सिंह पटेल',
    district: 'सीहोर',
    hourlyRate: 650,
    dailyRate: 3500,
    depositAmount: 5000,
    status: 'active',
  },
  {
    id: 'mac_002',
    name: 'शक्तिमान रोटावेटर 7 फीट',
    category: 'जुताई उपकरण (Tillage)',
    ownerName: 'रामगोपाल पाटीदार',
    district: 'उज्जैन',
    hourlyRate: 400,
    dailyRate: 2000,
    depositAmount: 3000,
    status: 'pending_verification',
  },
  {
    id: 'mac_003',
    name: 'जॉन डियर कंबाइन हार्वेस्टर',
    category: 'कटाई यंत्र (Harvester)',
    ownerName: 'हरप्रीत सिंह',
    district: 'होशंगाबाद',
    hourlyRate: 1800,
    dailyRate: 9000,
    depositAmount: 15000,
    status: 'disputed',
    disputeNotes: 'उपकरण समय पर वापस न करने को लेकर किरायेदार व मालिक में विवाद',
  },
];

export default function MachineryAdminPage() {
  const [items, setItems] = useState<MachineryAdminItem[]>(INITIAL_MACHINERY);

  const resolveDispute = (id: string) => {
    setItems((prev) =>
      prev.map((m) =>
        m.id === id ? { ...m, status: 'active', disputeNotes: 'विवाद हल किया गया' } : m
      )
    );
  };

  const approveListing = (id: string) => {
    setItems((prev) =>
      prev.map((m) => (m.id === id ? { ...m, status: 'active' } : m))
    );
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="कृषि यंत्र किराया प्रबंधन (Machinery Rentals)"
        subtitle="ट्रैक्टर व भारी कृषि यंत्र लिस्टिंग समीक्षा एवं रेंटल विवाद निपटान"
      />

      <main className="p-8 space-y-6 flex-1">
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <table className="w-full text-left text-xs">
            <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
              <tr>
                <th className="py-3.5 px-6">यंत्र का नाम</th>
                <th className="py-3.5 px-4">मालिक (Owner)</th>
                <th className="py-3.5 px-4">किराया दरें</th>
                <th className="py-3.5 px-4">सुरक्षा जमा (Deposit)</th>
                <th className="py-3.5 px-4">स्थिति</th>
                <th className="py-3.5 px-6 text-right">कार्य</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-soil-100 font-medium">
              {items.map((m) => (
                <tr key={m.id} className="hover:bg-soil-50/80 transition">
                  <td className="py-4 px-6">
                    <div className="font-extrabold text-soil-900 text-sm">{m.name}</div>
                    <div className="text-soil-500">{m.category}</div>
                    {m.disputeNotes && (
                      <p className="text-[10px] text-clay-700 bg-clay-50 p-1.5 rounded mt-1 border border-clay-200 font-semibold">
                        विवाद: {m.disputeNotes}
                      </p>
                    )}
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-bold text-soil-800">{m.ownerName}</div>
                    <div className="text-soil-500 text-[11px]">{m.district}</div>
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-bold text-primary-700">₹{m.hourlyRate}/घंटा</div>
                    <div className="text-soil-500 text-[11px]">₹{m.dailyRate}/दिन</div>
                  </td>
                  <td className="py-4 px-4 font-mono font-bold text-soil-800">
                    ₹{m.depositAmount.toLocaleString()}
                  </td>
                  <td className="py-4 px-4">
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${m.status === 'active'
                          ? 'bg-emerald-100 text-emerald-800'
                          : m.status === 'disputed'
                            ? 'bg-clay-100 text-clay-800'
                            : 'bg-wheat-100 text-wheat-800'
                        }`}
                    >
                      {m.status === 'active'
                        ? 'सक्रिय (Live)'
                        : m.status === 'disputed'
                          ? 'विवादित (Disputed)'
                          : 'सत्यापन लंबित'}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    {m.status === 'disputed' && (
                      <button
                        onClick={() => resolveDispute(m.id)}
                        className="px-3 py-1.5 bg-clay-600 hover:bg-clay-700 text-white rounded-lg text-xs font-bold transition ml-auto"
                      >
                        विवाद हल करें
                      </button>
                    )}
                    {m.status === 'pending_verification' && (
                      <button
                        onClick={() => approveListing(m.id)}
                        className="px-3 py-1.5 bg-primary-600 hover:bg-primary-700 text-white rounded-lg text-xs font-bold transition ml-auto"
                      >
                        अनुमोदन करें
                      </button>
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


