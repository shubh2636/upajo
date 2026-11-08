'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Search, ShoppingBag, AlertCircle, Edit3, CheckCircle2 } from 'lucide-react';

interface OrderItem {
  id: string;
  orderNumber: string;
  farmerName: string;
  consumerName: string;
  consumerPhone: string;
  deliveryMode: string;
  totalAmount: number;
  paymentMethod: string;
  status: 'placed' | 'confirmed' | 'harvesting_packed' | 'ready_for_pickup' | 'out_for_delivery' | 'delivered' | 'cancelled';
  createdAt: string;
  overrideReason?: string;
}

const INITIAL_ORDERS: OrderItem[] = [
  {
    id: 'ord_001',
    orderNumber: 'UPJ-2026-0812',
    farmerName: 'बलदेव सिंह (सीहोर)',
    consumerName: 'अमित शर्मा',
    consumerPhone: '+91 9826011223',
    deliveryMode: 'self_delivery',
    totalAmount: 3500,
    paymentMethod: 'upi_razorpay',
    status: 'delivered',
    createdAt: '2026-02-14 10:15 AM',
  },
  {
    id: 'ord_002',
    orderNumber: 'UPJ-2026-0813',
    farmerName: 'रामगोपाल पाटीदार (उज्जैन)',
    consumerName: 'सुनीता वर्मा',
    consumerPhone: '+91 9111223344',
    deliveryMode: 'self_delivery',
    totalAmount: 1850,
    paymentMethod: 'upi_razorpay',
    status: 'out_for_delivery',
    createdAt: '2026-02-15 08:30 AM',
  },
  {
    id: 'ord_003',
    orderNumber: 'UPJ-2026-0814',
    farmerName: 'मोहन लाल (विदिशा)',
    consumerName: 'राजेश गुप्ता',
    consumerPhone: '+91 9425001122',
    deliveryMode: 'pickup',
    totalAmount: 2400,
    paymentMethod: 'cod',
    status: 'harvesting_packed',
    createdAt: '2026-02-15 01:45 PM',
  },
];

export default function OrdersAdminPage() {
  const [orders, setOrders] = useState<OrderItem[]>(INITIAL_ORDERS);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [overrideModal, setOverrideModal] = useState<OrderItem | null>(null);
  const [newStatus, setNewStatus] = useState<OrderItem['status']>('delivered');
  const [overrideReason, setOverrideReason] = useState('');

  const filtered = orders.filter((o) => {
    const matchesSearch =
      o.orderNumber.toLowerCase().includes(search.toLowerCase()) ||
      o.farmerName.toLowerCase().includes(search.toLowerCase()) ||
      o.consumerName.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || o.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const handleApplyOverride = () => {
    if (!overrideReason.trim()) {
      alert('स्थिति बदलने के लिए ऑडिट लॉग हेतु अनिवार्य कारण दर्ज करें (Mandatory Reason Required)');
      return;
    }
    if (!overrideModal) return;

    setOrders((prev) =>
      prev.map((o) =>
        o.id === overrideModal.id
          ? { ...o, status: newStatus, overrideReason: `[Admin Override]: ${overrideReason}` }
          : o
      )
    );
    setOverrideModal(null);
    setOverrideReason('');
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="ऑर्डर प्रबंधन व ऑडिट (Orders Management)"
        subtitle="सभी ऑर्डर स्थितियां, विवाद निपटान व अनिवार्य कारण सहित एडमिन ओवरराइड"
      />

      <main className="p-8 space-y-6 flex-1">
        {/* Controls */}
        <div className="bg-white p-4 rounded-2xl border border-soil-200 shadow-sm flex items-center justify-between">
          <div className="relative w-80">
            <Search className="w-4 h-4 text-soil-400 absolute left-3.5 top-3.5" />
            <input
              type="text"
              placeholder="ऑर्डर आईडी, किसान या ग्राहक..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 bg-soil-50 border border-soil-300 rounded-xl text-xs font-semibold focus:ring-2 focus:ring-primary-500"
          >
            <option value="all">सभी स्थितियां (All Statuses)</option>
            <option value="placed">नया (Placed)</option>
            <option value="confirmed">स्वीकृत (Confirmed)</option>
            <option value="harvesting_packed">पैक हो चुका (Packed)</option>
            <option value="out_for_delivery">रवाना (Out for Delivery)</option>
            <option value="delivered">वितरित (Delivered)</option>
            <option value="cancelled">रद्द (Cancelled)</option>
          </select>
        </div>

        {/* Orders Table */}
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <table className="w-full text-left text-xs">
            <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
              <tr>
                <th className="py-3.5 px-6">ऑर्डर संख्या</th>
                <th className="py-3.5 px-4">किसान साथी</th>
                <th className="py-3.5 px-4">ग्राहक विवरण</th>
                <th className="py-3.5 px-4">कुल राशि / भुगतान</th>
                <th className="py-3.5 px-4">डिलीवरी मोड</th>
                <th className="py-3.5 px-4">स्थिति (Status)</th>
                <th className="py-3.5 px-6 text-right">एडमिन कार्य</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-soil-100 font-medium">
              {filtered.map((o) => (
                <tr key={o.id} className="hover:bg-soil-50/80 transition">
                  <td className="py-4 px-6">
                    <div className="font-mono font-bold text-soil-900 text-sm">{o.orderNumber}</div>
                    <div className="text-[11px] text-soil-400">{o.createdAt}</div>
                    {o.overrideReason && (
                      <p className="text-[10px] text-wheat-700 bg-wheat-50 p-1 rounded mt-1 border border-wheat-200">
                        {o.overrideReason}
                      </p>
                    )}
                  </td>
                  <td className="py-4 px-4 font-bold text-soil-800">{o.farmerName}</td>
                  <td className="py-4 px-4 text-soil-800">
                    <div className="font-bold">{o.consumerName}</div>
                    <div className="text-soil-500 font-mono text-[11px]">{o.consumerPhone}</div>
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-extrabold text-primary-700 text-sm">₹{o.totalAmount}</div>
                    <div className="text-soil-500 text-[11px] font-mono uppercase">{o.paymentMethod}</div>
                  </td>
                  <td className="py-4 px-4 text-soil-700">
                    {o.deliveryMode === 'pickup' ? 'खेत से उठाना (Pickup)' : 'होम डिलीवरी'}
                  </td>
                  <td className="py-4 px-4">
                    <span
                      className={`px-2.5 py-1 rounded-md text-[10.5px] font-bold ${
                        o.status === 'delivered'
                          ? 'bg-emerald-100 text-emerald-800'
                          : o.status === 'cancelled'
                          ? 'bg-clay-100 text-clay-800'
                          : 'bg-wheat-100 text-wheat-800'
                      }`}
                    >
                      {o.status}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    <button
                      onClick={() => {
                        setOverrideModal(o);
                        setNewStatus(o.status);
                      }}
                      className="px-3 py-1.5 bg-soil-100 hover:bg-soil-200 text-soil-800 rounded-lg text-xs font-bold transition flex items-center gap-1 ml-auto"
                    >
                      <Edit3 className="w-3.5 h-3.5" /> ओवरराइड
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Admin Override Modal */}
        {overrideModal && (
          <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
            <div className="bg-white rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
              <div className="flex items-center justify-between border-b border-soil-200 pb-3">
                <h4 className="font-extrabold text-base text-soil-900">
                  ऑर्डर स्थिति ओवरराइड ({overrideModal.orderNumber})
                </h4>
                <button onClick={() => setOverrideModal(null)} className="text-soil-400 font-bold">
                  ✕
                </button>
              </div>

              <div>
                <label className="block text-xs font-bold text-soil-700 mb-1">नई स्थिति चुनें:</label>
                <select
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value as any)}
                  className="w-full p-2.5 bg-soil-50 border border-soil-300 rounded-xl text-xs font-bold"
                >
                  <option value="confirmed">स्वीकृत (Confirmed)</option>
                  <option value="harvesting_packed">पैक हो चुका (Packed)</option>
                  <option value="out_for_delivery">रवाना (Out for Delivery)</option>
                  <option value="delivered">वितरित (Delivered)</option>
                  <option value="cancelled">रद्द (Cancelled)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-soil-700 mb-1">
                  अनिवार्य ऑडिट कारण (Mandatory Reason):
                </label>
                <textarea
                  rows={3}
                  required
                  value={overrideReason}
                  onChange={(e) => setOverrideReason(e.target.value)}
                  placeholder="उदा. ग्राहक के लिखित अनुरोध पर ऑर्डर रद्द किया गया..."
                  className="w-full p-2.5 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium"
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  onClick={() => setOverrideModal(null)}
                  className="flex-1 py-2.5 bg-soil-100 hover:bg-soil-200 text-soil-700 font-bold rounded-xl text-xs"
                >
                  रद्द करें
                </button>
                <button
                  onClick={handleApplyOverride}
                  className="flex-1 py-2.5 bg-primary-600 hover:bg-primary-700 text-white font-bold rounded-xl text-xs shadow"
                >
                  लागू करें (Save Override)
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

