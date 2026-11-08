'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { FileCheck, CheckCircle2, XCircle, Eye, ExternalLink, AlertCircle, Building2 } from 'lucide-react';

interface KycSubmission {
  id: string;
  farmerId: string;
  farmerName: string;
  phone: string;
  village: string;
  district: string;
  farmName: string;
  totalAcres: number;
  soilType: string;
  bankName: string;
  bankAccount: string;
  ifsc: string;
  upi: string;
  docUrl: string;
  status: 'pending' | 'approved' | 'rejected';
  submittedAt: string;
  notes?: string;
}

const INITIAL_QUEUE: KycSubmission[] = [
  {
    id: 'kyc_001',
    farmerId: 'usr_002',
    farmerName: 'रामगोपाल पाटीदार',
    phone: '+91 9826112233',
    village: 'तराना',
    district: 'उज्जैन',
    farmName: 'श्री राम कृषि फार्म',
    totalAcres: 5.0,
    soilType: 'काली मिट्टी (Black Soil)',
    bankName: 'State Bank of India',
    bankAccount: '••••••••8912',
    ifsc: 'SBIN0001234',
    upi: 'ramgopal@sbi',
    docUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80',
    status: 'pending',
    submittedAt: '2026-02-15 11:30 AM',
  },
  {
    id: 'kyc_002',
    farmerId: 'usr_005',
    farmerName: 'दिलीप मीणा',
    phone: '+91 9425123456',
    village: 'नसरुल्लागंज',
    district: 'सीहोर',
    farmName: 'मीणा ब्रदर्स फार्म',
    totalAcres: 8.5,
    soilType: 'जलोढ़ मिट्टी (Alluvial)',
    bankName: 'Punjab National Bank',
    bankAccount: '••••••••4521',
    ifsc: 'PUNB0123400',
    upi: 'dilip@pnb',
    docUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80',
    status: 'pending',
    submittedAt: '2026-02-15 02:15 PM',
  },
  {
    id: 'kyc_003',
    farmerId: 'usr_001',
    farmerName: 'बलदेव सिंह पटेल',
    phone: '+91 9425098765',
    village: 'श्यामपुर',
    district: 'सीहोर',
    farmName: 'श्यामपुर ऑर्गेनिक फार्म',
    totalAcres: 12.0,
    soilType: 'काली मिट्टी (Black Soil)',
    bankName: 'Bank of India',
    bankAccount: '••••••••1102',
    ifsc: 'BKID0009876',
    upi: 'baldev@boi',
    docUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80',
    status: 'approved',
    submittedAt: '2026-01-15',
    notes: 'भूमि रिकॉर्ड व आधार कार्ड पूर्णतः सत्यापित।',
  },
];

export default function KycQueuePage() {
  const [queue, setQueue] = useState<KycSubmission[]>(INITIAL_QUEUE);
  const [selectedKyc, setSelectedKyc] = useState<KycSubmission | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [activeTab, setActiveTab] = useState<'pending' | 'approved' | 'rejected'>('pending');

  const filtered = queue.filter((k) => k.status === activeTab);

  const handleApprove = (id: string) => {
    setQueue((prev) =>
      prev.map((k) => (k.id === id ? { ...k, status: 'approved', notes: 'एडमिन द्वारा स्वीकृत' } : k))
    );
    setSelectedKyc(null);
  };

  const handleReject = (id: string) => {
    if (!rejectReason) {
      alert('कृपया अस्वीकृति का कारण लिखें (Rejection Reason Required)');
      return;
    }
    setQueue((prev) =>
      prev.map((k) => (k.id === id ? { ...k, status: 'rejected', notes: rejectReason } : k))
    );
    setRejectReason('');
    setSelectedKyc(null);
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="किसान KYC सत्यापन कतार (KYC Queue)"
        subtitle="निजी बकेट दस्तावेज़ सत्यापन व बैंक खाता अनुमोदन"
      />

      <main className="p-8 space-y-6 flex-1">
        {/* Filter Tabs */}
        <div className="flex gap-2">
          <button
            onClick={() => setActiveTab('pending')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
              activeTab === 'pending'
                ? 'bg-primary-600 text-white shadow-sm'
                : 'bg-white text-soil-700 border border-soil-200 hover:bg-soil-100'
            }`}
          >
            <span>लंबित समीक्षा (Pending)</span>
            <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-wheat-400 text-soil-900 font-black">
              {queue.filter((k) => k.status === 'pending').length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('approved')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
              activeTab === 'approved'
                ? 'bg-primary-600 text-white shadow-sm'
                : 'bg-white text-soil-700 border border-soil-200 hover:bg-soil-100'
            }`}
          >
            <span>स्वीकृत किसान (Approved)</span>
            <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-emerald-100 text-emerald-800 font-black">
              {queue.filter((k) => k.status === 'approved').length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab('rejected')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-2 ${
              activeTab === 'rejected'
                ? 'bg-primary-600 text-white shadow-sm'
                : 'bg-white text-soil-700 border border-soil-200 hover:bg-soil-100'
            }`}
          >
            <span>अस्वीकृत (Rejected)</span>
            <span className="px-1.5 py-0.5 rounded-full text-[10px] bg-clay-100 text-clay-800 font-black">
              {queue.filter((k) => k.status === 'rejected').length}
            </span>
          </button>
        </div>

        {/* KYC Cards List */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {filtered.map((k) => (
            <div
              key={k.id}
              className="bg-white p-6 rounded-2xl border border-soil-200 shadow-sm flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-base font-extrabold text-soil-900">{k.farmerName}</h3>
                    <p className="text-xs text-soil-500 font-mono">{k.phone} • {k.village}, {k.district}</p>
                  </div>
                  <span className={`px-2.5 py-1 rounded-lg text-[11px] font-bold ${
                    k.status === 'approved'
                      ? 'bg-emerald-100 text-emerald-800'
                      : k.status === 'rejected'
                      ? 'bg-clay-100 text-clay-800'
                      : 'bg-wheat-100 text-wheat-800'
                  }`}>
                    {k.status === 'approved' ? 'स्वीकृत ✓' : k.status === 'rejected' ? 'अस्वीकृत' : 'समीक्षाधीन'}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-3 p-3.5 bg-soil-50 rounded-xl border border-soil-200 text-xs mb-4">
                  <div>
                    <span className="text-soil-500 font-medium">फार्म का नाम:</span>
                    <p className="font-bold text-soil-800">{k.farmName}</p>
                  </div>
                  <div>
                    <span className="text-soil-500 font-medium">भूमि (एकड़):</span>
                    <p className="font-bold text-soil-800">{k.totalAcres} एकड़ ({k.soilType})</p>
                  </div>
                  <div>
                    <span className="text-soil-500 font-medium">बैंक खाता:</span>
                    <p className="font-bold text-soil-800">{k.bankAccount} ({k.ifsc})</p>
                  </div>
                  <div>
                    <span className="text-soil-500 font-medium">UPI VPA:</span>
                    <p className="font-bold text-soil-800">{k.upi}</p>
                  </div>
                </div>

                {k.notes && (
                  <div className="mb-4 p-2.5 bg-soil-100 text-soil-700 text-xs rounded-lg font-medium">
                    टिप्पणी: {k.notes}
                  </div>
                )}
              </div>

              <div className="flex items-center gap-3 pt-3 border-t border-soil-100">
                <button
                  onClick={() => setSelectedKyc(k)}
                  className="flex-1 py-2 bg-soil-100 hover:bg-soil-200 text-soil-800 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5"
                >
                  <Eye className="w-4 h-4 text-soil-600" />
                  दस्तावेज़ देखें (Signed URL)
                </button>

                {k.status === 'pending' && (
                  <>
                    <button
                      onClick={() => handleApprove(k.id)}
                      className="px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-xl text-xs font-bold transition flex items-center gap-1"
                    >
                      <CheckCircle2 className="w-4 h-4" />
                      स्वीकृत करें
                    </button>
                    <button
                      onClick={() => {
                        setSelectedKyc(k);
                      }}
                      className="px-4 py-2 bg-clay-50 hover:bg-clay-100 text-clay-700 border border-clay-300 rounded-xl text-xs font-bold transition flex items-center gap-1"
                    >
                      <XCircle className="w-4 h-4" />
                      अस्वीकार
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Modal Document Viewer & Action Dialog */}
        {selectedKyc && (
          <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
            <div className="bg-white rounded-2xl max-w-lg w-full p-6 space-y-5 shadow-2xl">
              <div className="flex items-center justify-between border-b border-soil-200 pb-3">
                <h4 className="font-extrabold text-base text-soil-900">
                  पहचान पत्र समीक्षा: {selectedKyc.farmerName}
                </h4>
                <button
                  onClick={() => setSelectedKyc(null)}
                  className="text-soil-400 hover:text-soil-700 font-bold"
                >
                  ✕
                </button>
              </div>

              <div>
                <p className="text-xs text-soil-500 mb-2 font-medium">
                  निजी बकेट <code className="bg-soil-100 px-1 py-0.5 rounded font-mono">kyc-docs</code> से अल्पकालिक हस्ताक्षरित URL:
                </p>
                <div className="h-48 rounded-xl bg-soil-100 border border-soil-300 overflow-hidden flex items-center justify-center relative group">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={selectedKyc.docUrl}
                    alt="Farmer ID Document"
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition flex items-center justify-center">
                    <a
                      href={selectedKyc.docUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="px-3.5 py-2 bg-white text-soil-900 text-xs font-bold rounded-lg flex items-center gap-1.5 shadow"
                    >
                      पूर्ण आकार में खोलें <ExternalLink className="w-3.5 h-3.5" />
                    </a>
                  </div>
                </div>
              </div>

              {selectedKyc.status === 'pending' && (
                <div className="space-y-3">
                  <div>
                    <label className="block text-xs font-bold text-soil-700 mb-1">
                      अस्वीकृति टिप्पणी (कारण दर्ज करें यदि अस्वीकार कर रहे हैं):
                    </label>
                    <textarea
                      rows={2}
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      placeholder="उदा. आधार कार्ड की फोटो स्पष्ट नहीं है..."
                      className="w-full p-2.5 bg-soil-50 border border-soil-300 rounded-xl text-xs focus:ring-2 focus:ring-primary-500 font-medium"
                    />
                  </div>

                  <div className="flex gap-3">
                    <button
                      onClick={() => handleReject(selectedKyc.id)}
                      className="flex-1 py-2.5 bg-clay-50 hover:bg-clay-100 text-clay-700 border border-clay-300 rounded-xl text-xs font-bold transition"
                    >
                      अस्वीकृत करें (Reject)
                    </button>
                    <button
                      onClick={() => handleApprove(selectedKyc.id)}
                      className="flex-1 py-2.5 bg-primary-600 hover:bg-primary-700 text-white rounded-xl text-xs font-bold shadow transition"
                    >
                      स्वीकृत करें (Approve)
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

