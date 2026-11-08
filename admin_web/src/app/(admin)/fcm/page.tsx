'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Bell, Send, Smartphone, Users, CheckCircle2 } from 'lucide-react';

export default function FcmBroadcastPage() {
  const [targetAudience, setTargetAudience] = useState<'all' | 'farmers' | 'consumers'>('all');
  const [title, setTitle] = useState('🌾 ताज़ा मंडी भाव अपडेट');
  const [body, setBody] = useState('सीहोर मंडी में आज शरबती गेहूं ₹3,500/क्विंटल पर खुला। ताज़ा दरें ऐप में देखें।');
  const [isSending, setIsSending] = useState(false);
  const [sentHistory, setSentHistory] = useState([
    {
      title: 'मौसम चेतावनी: अगले 24 घंटे में भारी वर्षा की संभावना',
      audience: 'किसान साथी (Sehore/Bhopal)',
      sentAt: '2026-02-14 06:00 AM',
      delivered: 342,
    },
    {
      title: 'ताज़ा शरबती गेहूं व दालों का नया स्टॉक उपलब्ध',
      audience: 'सभी उपभोक्ता',
      sentAt: '2026-02-13 11:30 AM',
      delivered: 1205,
    },
  ]);

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !body) return;

    setIsSending(true);
    setTimeout(() => {
      setSentHistory([
        {
          title,
          audience:
            targetAudience === 'all'
              ? 'सभी उपयोगकर्ता'
              : targetAudience === 'farmers'
              ? 'केवल किसान साथी'
              : 'केवल उपभोक्ता',
          sentAt: 'अभी-अभी (Just now)',
          delivered: targetAudience === 'all' ? 1547 : targetAudience === 'farmers' ? 342 : 1205,
        },
        ...sentHistory,
      ]);
      setIsSending(false);
      alert('FCM पुश नोटिफिकेशन सफलतापूर्वक प्रसारित किया गया!');
    }, 800);
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="FCM पुश ब्रॉडकास्ट (Push Notifications)"
        subtitle="फ़ायरबेस क्लाउड मैसेजिंग द्वारा सभी अथवा चयनित उपयोगकर्ताओं को लाइव अलर्ट"
      />

      <main className="p-8 space-y-6 flex-1">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Notification Form */}
          <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-soil-200 shadow-sm">
            <h3 className="font-extrabold text-base text-soil-900 mb-4 flex items-center gap-2">
              <Bell className="w-5 h-5 text-primary-600" />
              नया प्रसारण संदेश बनाएं
            </h3>

            <form onSubmit={handleSend} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-1.5">
                  लक्षित दर्शक (Target Audience)
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {[
                    { id: 'all', label: 'सभी (All Users)' },
                    { id: 'farmers', label: 'केवल किसान (Farmers)' },
                    { id: 'consumers', label: 'केवल उपभोक्ता (Consumers)' },
                  ].map((aud) => (
                    <button
                      key={aud.id}
                      type="button"
                      onClick={() => setTargetAudience(aud.id as any)}
                      className={`p-2.5 rounded-xl border text-xs font-bold transition text-center ${
                        targetAudience === aud.id
                          ? 'bg-primary-600 text-white border-primary-600 shadow-sm'
                          : 'bg-soil-50 text-soil-700 border-soil-200 hover:bg-soil-100'
                      }`}
                    >
                      {aud.label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-1.5">
                  संदेश शीर्षक (Notification Title)
                </label>
                <input
                  type="text"
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="उदा. मौसम अलर्ट या मंडी भाव..."
                  className="w-full p-2.5 bg-soil-50 border border-soil-300 rounded-xl text-xs font-semibold focus:ring-2 focus:ring-primary-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-1.5">
                  संदेश विवरण (Notification Body)
                </label>
                <textarea
                  rows={4}
                  required
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="संदेश का पूरा विवरण..."
                  className="w-full p-2.5 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium focus:ring-2 focus:ring-primary-500"
                />
              </div>

              <button
                type="submit"
                disabled={isSending}
                className="w-full py-3 bg-primary-600 hover:bg-primary-700 text-white font-bold rounded-xl text-xs shadow-md transition flex items-center justify-center gap-2 disabled:opacity-50"
              >
                <Send className="w-4 h-4" />
                {isSending ? 'प्रसारण जारी...' : 'सूचना तुरंत भेजें (Send Broadcast)'}
              </button>
            </form>
          </div>

          {/* Live Mobile Device Preview */}
          <div className="bg-soil-900 p-6 rounded-2xl text-white shadow-xl flex flex-col items-center justify-between">
            <div className="w-full">
              <div className="flex items-center justify-between text-soil-400 text-xs mb-4">
                <span className="flex items-center gap-1 font-bold">
                  <Smartphone className="w-4 h-4" /> लाइव मोबाइल पूर्वावलोकन
                </span>
                <span>Android OS</span>
              </div>

              {/* Notification Banner Simulator */}
              <div className="bg-soil-800 border border-soil-700 rounded-2xl p-4 shadow-lg w-full">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-5 h-5 rounded-md bg-primary-600 flex items-center justify-center text-[10px] font-black">
                      उ
                    </div>
                    <span className="text-[11px] font-bold text-soil-200">उपजो • अब</span>
                  </div>
                </div>
                <h4 className="text-xs font-extrabold text-white leading-snug">{title || 'शीर्षक'}</h4>
                <p className="text-[11px] text-soil-300 mt-1 leading-relaxed">
                  {body || 'संदेश विवरण यहां दिखेगा...'}
                </p>
              </div>
            </div>

            <p className="text-[10px] text-soil-400 text-center mt-6">
              FCM टोकन युक्त सभी सक्रिय डिवाइस पर तत्काल पुश डिलीवर होगा
            </p>
          </div>
        </div>

        {/* Broadcast History */}
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden p-5">
          <h3 className="font-extrabold text-sm text-soil-900 mb-3">हालिया प्रसारित अलर्ट इतिहास</h3>
          <div className="divide-y divide-soil-100 text-xs">
            {sentHistory.map((s, idx) => (
              <div key={idx} className="py-3 flex items-center justify-between">
                <div>
                  <div className="font-bold text-soil-900">{s.title}</div>
                  <div className="text-soil-500 text-[11px]">
                    दर्शक: {s.audience} • समय: {s.sentAt}
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-primary-700 font-extrabold text-xs">
                    {s.delivered} डिलीवर
                  </span>
                  <div className="text-soil-400 text-[10px]">सफलतापूर्वक संपन्न</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}

