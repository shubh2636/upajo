'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import {
  TrendingUp,
  Users,
  ShoppingBag,
  Headphones,
  CheckCircle2,
  Clock,
  ArrowUpRight,
  ArrowDownRight,
  DollarSign,
  AlertTriangle,
} from 'lucide-react';

export default function DashboardPage() {
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleRefresh = () => {
    setIsRefreshing(true);
    setTimeout(() => setIsRefreshing(false), 800);
  };

  const kpis = [
    {
      title: 'सकल व्यापार मूल्य (GMV)',
      value: '₹14,82,450',
      change: '+18.4%',
      isPositive: true,
      icon: DollarSign,
      color: 'bg-primary-50 text-primary-600 border-primary-200',
    },
    {
      title: 'सक्रिय किसान साथी (Active Farmers)',
      value: '342',
      change: '+12 इस सप्ताह',
      isPositive: true,
      icon: Users,
      color: 'bg-wheat-50 text-wheat-600 border-wheat-200',
    },
    {
      title: 'कुल पूर्ण ऑर्डर (Fulfilled Orders)',
      value: '1,289',
      change: '+24% माह-दर-माह',
      isPositive: true,
      icon: ShoppingBag,
      color: 'bg-emerald-50 text-emerald-600 border-emerald-200',
    },
    {
      title: 'समीक्षाधीन KYC (Pending KYC)',
      value: '8',
      change: 'त्वरित समीक्षा आवश्यक',
      isPositive: false,
      icon: AlertTriangle,
      color: 'bg-clay-50 text-clay-600 border-clay-200',
    },
  ];

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="कमांड डैशबोर्ड (Platform Overview)"
        subtitle="उपजो प्लेटफ़ॉर्म के वास्तविक समय आंकड़े व मुख्य मीट्रिक्स"
        onRefresh={handleRefresh}
        isRefreshing={isRefreshing}
      />

      <main className="p-8 space-y-8 flex-1">
        {/* KPI Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {kpis.map((kpi, idx) => {
            const Icon = kpi.icon;
            return (
              <div
                key={idx}
                className="bg-white p-6 rounded-2xl border border-soil-200 shadow-sm flex flex-col justify-between"
              >
                <div className="flex items-center justify-between mb-4">
                  <span className="text-xs font-bold text-soil-500 uppercase tracking-wider">
                    {kpi.title}
                  </span>
                  <div className={`p-2 rounded-xl border ${kpi.color}`}>
                    <Icon className="w-5 h-5" />
                  </div>
                </div>
                <div>
                  <div className="text-3xl font-black text-soil-900 tracking-tight mb-2">
                    {kpi.value}
                  </div>
                  <div className="flex items-center gap-1.5 text-xs font-semibold">
                    {kpi.isPositive ? (
                      <ArrowUpRight className="w-4 h-4 text-primary-600" />
                    ) : (
                      <ArrowDownRight className="w-4 h-4 text-clay-500" />
                    )}
                    <span className={kpi.isPositive ? 'text-primary-700' : 'text-clay-600'}>
                      {kpi.change}
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Live Operational Status & Quick Queues */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Recent Orders Overview */}
          <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-soil-200 shadow-sm">
            <div className="flex items-center justify-between mb-5">
              <div>
                <h3 className="text-base font-bold text-soil-900">हालिया ऑर्डर गतिविधि (Recent Orders)</h3>
                <p className="text-xs text-soil-500">सीधे खेत से घर डिलीवरी मॉनिटर</p>
              </div>
              <span className="px-2.5 py-1 bg-primary-100 text-primary-800 text-[11px] font-bold rounded-lg">
                लाइव सिंक
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead>
                  <tr className="border-b border-soil-200 text-soil-500 font-bold">
                    <th className="pb-3">ऑर्डर आईडी</th>
                    <th className="pb-3">किसान साथी</th>
                    <th className="pb-3">ग्राहक</th>
                    <th className="pb-3">राशि</th>
                    <th className="pb-3">स्थिति</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-soil-100 font-medium">
                  <tr>
                    <td className="py-3 font-mono font-bold text-soil-900">UPJ-2026-0812</td>
                    <td>बलदेव सिंह (सीहोर)</td>
                    <td>अमित शर्मा (भोपाल)</td>
                    <td className="font-bold text-primary-700">₹3,500</td>
                    <td>
                      <span className="px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded-md text-[10px] font-bold">
                        वितरित (Delivered)
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td className="py-3 font-mono font-bold text-soil-900">UPJ-2026-0813</td>
                    <td>रामगोपाल पाटीदार (उज्जैन)</td>
                    <td>सुनीता वर्मा (इंदौर)</td>
                    <td className="font-bold text-primary-700">₹1,850</td>
                    <td>
                      <span className="px-2 py-0.5 bg-primary-100 text-primary-800 rounded-md text-[10px] font-bold">
                        रवाना (Out for Delivery)
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <td className="py-3 font-mono font-bold text-soil-900">UPJ-2026-0814</td>
                    <td>मोहन लाल (विदिशा)</td>
                    <td>राजेश गुप्ता (भोपाल)</td>
                    <td className="font-bold text-primary-700">₹2,400</td>
                    <td>
                      <span className="px-2 py-0.5 bg-wheat-100 text-wheat-800 rounded-md text-[10px] font-bold">
                        पैक हो चुका (Packed)
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* Quick Action Queue */}
          <div className="bg-white p-6 rounded-2xl border border-soil-200 shadow-sm flex flex-col justify-between">
            <div>
              <h3 className="text-base font-bold text-soil-900 mb-1">त्वरित प्रशासनिक कार्य</h3>
              <p className="text-xs text-soil-500 mb-4">समीक्षा व अनुमोदन कतारें</p>

              <div className="space-y-3">
                <a
                  href="/kyc"
                  className="flex items-center justify-between p-3.5 bg-soil-50 hover:bg-soil-100 rounded-xl border border-soil-200 transition"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-2.5 h-2.5 rounded-full bg-clay-500" />
                    <div>
                      <p className="text-xs font-bold text-soil-900">KYC सत्यापन आवेदन</p>
                      <p className="text-[11px] text-soil-500">8 किसान समीक्षा की प्रतीक्षा में</p>
                    </div>
                  </div>
                  <span className="text-xs font-black text-clay-600 bg-clay-100 px-2 py-0.5 rounded-md">8</span>
                </a>

                <a
                  href="/tickets"
                  className="flex items-center justify-between p-3.5 bg-soil-50 hover:bg-soil-100 rounded-xl border border-soil-200 transition"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-2.5 h-2.5 rounded-full bg-wheat-500" />
                    <div>
                      <p className="text-xs font-bold text-soil-900">खुले सहायता टिकट</p>
                      <p className="text-[11px] text-soil-500">3 लंबित शिकायतें</p>
                    </div>
                  </div>
                  <span className="text-xs font-black text-wheat-700 bg-wheat-100 px-2 py-0.5 rounded-md">3</span>
                </a>

                <a
                  href="/payments"
                  className="flex items-center justify-between p-3.5 bg-soil-50 hover:bg-soil-100 rounded-xl border border-soil-200 transition"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-2.5 h-2.5 rounded-full bg-primary-500" />
                    <div>
                      <p className="text-xs font-bold text-soil-900">पेआउट अनुमोदन</p>
                      <p className="text-[11px] text-soil-500">₹45,200 किसान बैंक खाते हेतु</p>
                    </div>
                  </div>
                  <span className="text-xs font-black text-primary-700 bg-primary-100 px-2 py-0.5 rounded-md">
                    तैयार
                  </span>
                </a>
              </div>
            </div>

            <div className="pt-4 border-t border-soil-100 mt-4 flex items-center justify-between text-xs text-soil-500">
              <span>सर्वर अपटाइम: 99.98%</span>
              <span className="text-primary-700 font-bold">हेल्दी ✓</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

