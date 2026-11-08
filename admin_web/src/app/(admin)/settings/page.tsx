'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Settings, Download, ShieldCheck, History, Sliders, Save, CheckCircle2 } from 'lucide-react';

interface AuditLog {
  id: string;
  adminEmail: string;
  action: string;
  resource: string;
  targetId: string;
  ipAddress: string;
  timestamp: string;
}

const INITIAL_LOGS: AuditLog[] = [
  {
    id: 'aud_001',
    adminEmail: 'admin@upajo.in',
    action: 'KYC_APPROVE',
    resource: 'farmer_profiles',
    targetId: 'usr_001 (बलदेव सिंह)',
    ipAddress: '103.21.244.2',
    timestamp: '2026-02-15 11:42 AM',
  },
  {
    id: 'aud_002',
    adminEmail: 'admin@upajo.in',
    action: 'ORDER_OVERRIDE_STATUS',
    resource: 'orders',
    targetId: 'UPJ-2026-0812',
    ipAddress: '103.21.244.2',
    timestamp: '2026-02-15 10:15 AM',
  },
  {
    id: 'aud_003',
    adminEmail: 'admin@upajo.in',
    action: 'PAYOUT_SETTLE',
    resource: 'payments',
    targetId: 'pay_003 (दिलीप मीणा)',
    ipAddress: '103.21.244.2',
    timestamp: '2026-02-14 05:20 PM',
  },
];

export default function SettingsAdminPage() {
  const [platformFeePercent, setPlatformFeePercent] = useState<number>(0); // 0% promo
  const [isSaved, setIsSaved] = useState(false);
  const [logs] = useState<AuditLog[]>(INITIAL_LOGS);

  const handleSaveFee = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaved(true);
    setTimeout(() => setIsSaved(false), 2000);
  };

  const exportCsv = (type: string) => {
    const csvContent =
      'data:text/csv;charset=utf-8,ID,Timestamp,Resource,Action,Admin\n' +
      logs.map((l) => `${l.id},${l.timestamp},${l.resource},${l.action},${l.adminEmail}`).join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `upajo_${type}_export_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="प्लेटफ़ॉर्म सेटिंग्स व ऑडिट लॉग (Settings & Audit Logs)"
        subtitle="प्लेटफ़ॉर्म शुल्क कॉन्फ़िगरेशन, डेटा CSV निर्यात एवं प्रशासनिक गतिविधियों का रिकॉर्ड"
      />

      <main className="p-8 space-y-8 flex-1">
        {/* Settings Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Platform Fee Control */}
          <div className="bg-white p-6 rounded-2xl border border-soil-200 shadow-sm flex flex-col justify-between">
            <div>
              <h3 className="font-extrabold text-base text-soil-900 flex items-center gap-2 mb-1">
                <Sliders className="w-5 h-5 text-primary-600" />
                किसान प्लेटफ़ॉर्म कमीशन शुल्क (%)
              </h3>
              <p className="text-xs text-soil-500 mb-5">
                वर्तमान में 0% प्रारंभिक प्रचार दर सक्रिय है। परिवर्तन करने पर सभी नए ऑर्डरों पर लागू होगा।
              </p>

              <form onSubmit={handleSaveFee} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-2">
                    कमीशन दर प्रतिशत (Platform Fee %)
                  </label>
                  <div className="flex items-center gap-3">
                    <input
                      type="number"
                      min={0}
                      max={15}
                      step={0.5}
                      value={platformFeePercent}
                      onChange={(e) => setPlatformFeePercent(Number(e.target.value))}
                      className="w-32 p-2.5 bg-soil-50 border border-soil-300 rounded-xl text-base font-black text-center focus:ring-2 focus:ring-primary-500"
                    />
                    <span className="text-sm font-bold text-soil-700">%</span>
                  </div>
                </div>

                <div className="pt-2 flex items-center gap-3">
                  <button
                    type="submit"
                    className="px-5 py-2.5 bg-primary-600 hover:bg-primary-700 text-white rounded-xl text-xs font-bold shadow-sm transition flex items-center gap-2"
                  >
                    <Save className="w-4 h-4" />
                    दर सुरक्षित करें
                  </button>
                  {isSaved && (
                    <span className="text-xs text-emerald-700 font-bold flex items-center gap-1">
                      <CheckCircle2 className="w-4 h-4" /> सहेजा गया!
                    </span>
                  )}
                </div>
              </form>
            </div>
          </div>

          {/* Data Export Center */}
          <div className="bg-white p-6 rounded-2xl border border-soil-200 shadow-sm flex flex-col justify-between">
            <div>
              <h3 className="font-extrabold text-base text-soil-900 flex items-center gap-2 mb-1">
                <Download className="w-5 h-5 text-primary-600" />
                डेटा CSV निर्यात केंद्र (Export Center)
              </h3>
              <p className="text-xs text-soil-500 mb-5">
                सुरक्षित लेखा-परीक्षण व कर अनुपालन हेतु वित्तीय व परिचालन डेटा डाउनलोड
              </p>

              <div className="space-y-2.5">
                <button
                  onClick={() => exportCsv('orders')}
                  className="w-full p-3 bg-soil-50 hover:bg-soil-100 rounded-xl border border-soil-200 text-xs font-bold text-soil-800 transition flex items-center justify-between"
                >
                  <span>ऑर्डर व जीएसटी विवरण रिपोर्ट (.CSV)</span>
                  <Download className="w-4 h-4 text-soil-500" />
                </button>
                <button
                  onClick={() => exportCsv('farmers')}
                  className="w-full p-3 bg-soil-50 hover:bg-soil-100 rounded-xl border border-soil-200 text-xs font-bold text-soil-800 transition flex items-center justify-between"
                >
                  <span>सत्यापित किसान साथी सूची (.CSV)</span>
                  <Download className="w-4 h-4 text-soil-500" />
                </button>
                <button
                  onClick={() => exportCsv('audit_logs')}
                  className="w-full p-3 bg-soil-50 hover:bg-soil-100 rounded-xl border border-soil-200 text-xs font-bold text-soil-800 transition flex items-center justify-between"
                >
                  <span>एडमिन ऑडिट लॉग्स (.CSV)</span>
                  <Download className="w-4 h-4 text-soil-500" />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Audit Logs Table */}
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <div className="p-5 border-b border-soil-200 flex items-center justify-between">
            <div>
              <h3 className="font-extrabold text-base text-soil-900 flex items-center gap-2">
                <History className="w-5 h-5 text-primary-600" />
                अपरिवर्तनीय एडमिन ऑडिट लॉग (Immutable Audit Trail)
              </h3>
              <p className="text-xs text-soil-500">
                प्रत्येक प्रशासनिक निर्णय, स्थिति बदलाव व पेआउट अनुमोदन का स्थायी लॉग
              </p>
            </div>
            <span className="px-2.5 py-1 bg-primary-100 text-primary-800 text-[11px] font-bold rounded-lg flex items-center gap-1">
              <ShieldCheck className="w-3.5 h-3.5" /> छेड़छाड़-मुक्त (Append Only)
            </span>
          </div>

          <table className="w-full text-left text-xs">
            <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
              <tr>
                <th className="py-3.5 px-6">समय व प्रविष्टि</th>
                <th className="py-3.5 px-4">प्रशासक (Admin)</th>
                <th className="py-3.5 px-4">क्रिया (Action)</th>
                <th className="py-3.5 px-4">लक्ष्य रिसोर्स (Target)</th>
                <th className="py-3.5 px-6 text-right">IP पता</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-soil-100 font-medium font-mono text-[11.5px]">
              {logs.map((log) => (
                <tr key={log.id} className="hover:bg-soil-50/80 transition">
                  <td className="py-3.5 px-6 font-sans">
                    <div className="font-bold text-soil-900">{log.id}</div>
                    <div className="text-[11px] text-soil-400">{log.timestamp}</div>
                  </td>
                  <td className="py-3.5 px-4 text-soil-800 font-sans font-semibold">
                    {log.adminEmail}
                  </td>
                  <td className="py-3.5 px-4 font-bold text-primary-700">{log.action}</td>
                  <td className="py-3.5 px-4 text-soil-700 font-sans">
                    {log.targetId} ({log.resource})
                  </td>
                  <td className="py-3.5 px-6 text-right text-soil-500">{log.ipAddress}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}

