'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Headphones, CheckCircle2, Clock, MessageSquare, UserCheck } from 'lucide-react';

interface TicketItem {
  id: string;
  ticketNumber: string;
  userName: string;
  userPhone: string;
  userRole: 'farmer' | 'consumer';
  subject: string;
  description: string;
  status: 'open' | 'in_progress' | 'resolved';
  priority: 'low' | 'medium' | 'high';
  assignedTo?: string;
  createdAt: string;
  adminReply?: string;
}

const INITIAL_TICKETS: TicketItem[] = [
  {
    id: 'tkt_001',
    ticketNumber: 'TKT-2026-0042',
    userName: 'रामगोपाल पाटीदार',
    userPhone: '+91 9826112233',
    userRole: 'farmer',
    subject: 'KYC दस्तावेज़ अपलोड में सहायता',
    description: 'मेरा आधार कार्ड अपलोड करते समय नेटवर्क त्रुटि आ रही है। कृपया सहायता करें।',
    status: 'open',
    priority: 'high',
    createdAt: '2026-02-15 10:00 AM',
  },
  {
    id: 'tkt_002',
    ticketNumber: 'TKT-2026-0041',
    userName: 'अमित शर्मा',
    userPhone: '+91 9826011223',
    userRole: 'consumer',
    subject: 'डिलीवरी का समय बदलना',
    description: 'ऑर्डर UPJ-2026-0812 को दोपहर 3 बजे के बाद डिलीवर करने का अनुरोध।',
    status: 'in_progress',
    priority: 'medium',
    assignedTo: 'एडमिन टीम',
    createdAt: '2026-02-14 04:30 PM',
  },
  {
    id: 'tkt_003',
    ticketNumber: 'TKT-2026-0038',
    userName: 'सुनीता वर्मा',
    userPhone: '+91 9111223344',
    userRole: 'consumer',
    subject: 'ऑनलाइन पेमेंट रसीद',
    description: 'Razorpay UPI से पैसे कट गए पर रसीद डाउनलोड नहीं हो रही थी।',
    status: 'resolved',
    priority: 'medium',
    assignedTo: 'एडमिन टीम',
    createdAt: '2026-02-12',
    adminReply: 'रसीद आपके पंजीकृत नंबर पर WhatsApp द्वारा भेज दी गई है।',
  },
];

export default function TicketsAdminPage() {
  const [tickets, setTickets] = useState<TicketItem[]>(INITIAL_TICKETS);
  const [selectedTicket, setSelectedTicket] = useState<TicketItem | null>(null);
  const [replyText, setReplyText] = useState('');

  const resolveTicket = (id: string) => {
    if (!replyText.trim()) {
      alert('कृपया समाधान या उत्तर संदेश लिखें');
      return;
    }
    setTickets((prev) =>
      prev.map((t) =>
        t.id === id ? { ...t, status: 'resolved', adminReply: replyText } : t
      )
    );
    setSelectedTicket(null);
    setReplyText('');
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="ग्राहक एवं किसान सहायता (Support Tickets)"
        subtitle="प्राप्त शिकायतें, पूछताछ, असाइनमेंट एवं प्रत्यक्ष उत्तर पोर्टल"
      />

      <main className="p-8 space-y-6 flex-1">
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <table className="w-full text-left text-xs">
            <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
              <tr>
                <th className="py-3.5 px-6">टिकट संख्या</th>
                <th className="py-3.5 px-4">उपयोगकर्ता</th>
                <th className="py-3.5 px-4">विषय व विवरण</th>
                <th className="py-3.5 px-4">प्राथमिकता</th>
                <th className="py-3.5 px-4">स्थिति</th>
                <th className="py-3.5 px-6 text-right">कार्य</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-soil-100 font-medium">
              {tickets.map((t) => (
                <tr key={t.id} className="hover:bg-soil-50/80 transition">
                  <td className="py-4 px-6">
                    <div className="font-mono font-bold text-soil-900">{t.ticketNumber}</div>
                    <div className="text-[11px] text-soil-400">{t.createdAt}</div>
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-bold text-soil-900">{t.userName}</div>
                    <div className="text-[11px] text-soil-500 font-mono">{t.userPhone}</div>
                    <span className="text-[10px] font-bold text-soil-600 bg-soil-100 px-1 py-0.5 rounded">
                      {t.userRole === 'farmer' ? 'किसान' : 'उपभोक्ता'}
                    </span>
                  </td>
                  <td className="py-4 px-4 max-w-xs">
                    <div className="font-bold text-soil-900">{t.subject}</div>
                    <p className="text-soil-600 text-[11px] truncate mt-0.5">{t.description}</p>
                    {t.adminReply && (
                      <p className="text-[10px] text-emerald-800 bg-emerald-50 p-1 rounded mt-1 border border-emerald-200">
                        समाधान: {t.adminReply}
                      </p>
                    )}
                  </td>
                  <td className="py-4 px-4">
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${
                        t.priority === 'high'
                          ? 'bg-clay-100 text-clay-800'
                          : 'bg-wheat-100 text-wheat-800'
                      }`}
                    >
                      {t.priority === 'high' ? 'उच्च (High)' : 'मध्यम (Med)'}
                    </span>
                  </td>
                  <td className="py-4 px-4">
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${
                        t.status === 'resolved'
                          ? 'bg-emerald-100 text-emerald-800'
                          : t.status === 'in_progress'
                          ? 'bg-primary-100 text-primary-800'
                          : 'bg-clay-100 text-clay-800'
                      }`}
                    >
                      {t.status === 'resolved'
                        ? 'हल हुआ ✓'
                        : t.status === 'in_progress'
                        ? 'प्रगतिरत'
                        : 'खुला (Open)'}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    <button
                      onClick={() => {
                        setSelectedTicket(t);
                        setReplyText(t.adminReply || '');
                      }}
                      className="px-3 py-1.5 bg-primary-600 hover:bg-primary-700 text-white rounded-lg text-xs font-bold transition ml-auto"
                    >
                      उत्तर दें
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Reply Modal */}
        {selectedTicket && (
          <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
            <div className="bg-white rounded-2xl max-w-lg w-full p-6 space-y-4 shadow-2xl">
              <div className="flex items-center justify-between border-b border-soil-200 pb-3">
                <h4 className="font-extrabold text-base text-soil-900">
                  टिकट समाधान: {selectedTicket.ticketNumber}
                </h4>
                <button onClick={() => setSelectedTicket(null)} className="text-soil-400 font-bold">
                  ✕
                </button>
              </div>

              <div className="p-3 bg-soil-50 rounded-xl border border-soil-200 text-xs">
                <div className="font-bold text-soil-900">{selectedTicket.subject}</div>
                <p className="text-soil-600 mt-1">{selectedTicket.description}</p>
                <div className="text-[11px] text-soil-400 mt-2 font-mono">
                  प्रेषक: {selectedTicket.userName} ({selectedTicket.userPhone})
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-soil-700 mb-1">
                  उपयोगकर्ता को भेजा जाने वाला उत्तर / समाधान:
                </label>
                <textarea
                  rows={4}
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  placeholder="नमस्ते! आपकी समस्या का समाधान..."
                  className="w-full p-2.5 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium focus:ring-2 focus:ring-primary-500"
                />
              </div>

              <div className="flex gap-3">
                <button
                  onClick={() => setSelectedTicket(null)}
                  className="flex-1 py-2.5 bg-soil-100 hover:bg-soil-200 text-soil-700 font-bold rounded-xl text-xs"
                >
                  रद्द करें
                </button>
                <button
                  onClick={() => resolveTicket(selectedTicket.id)}
                  className="flex-1 py-2.5 bg-primary-600 hover:bg-primary-700 text-white font-bold rounded-xl text-xs shadow"
                >
                  उत्तर भेजें व टिकट बंद करें
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

