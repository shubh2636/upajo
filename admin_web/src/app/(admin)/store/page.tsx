'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Store, Plus, Edit2, CheckCircle2 } from 'lucide-react';

interface StoreItem {
  id: string;
  name: string;
  category: string;
  brand: string;
  vendor: string;
  mrp: number;
  price: number;
  stock: number;
  unit: string;
  isAvailable: boolean;
}

const INITIAL_STORE: StoreItem[] = [
  {
    id: 'st_001',
    name: 'इफको नैनो यूरिया (Liquid)',
    category: 'उर्वरक (Fertilizer)',
    brand: 'IFFCO',
    vendor: 'इफको ई-बाजार सीहोर',
    mrp: 240,
    price: 225,
    stock: 500,
    unit: '500 ml बोतल',
    isAvailable: true,
  },
  {
    id: 'st_002',
    name: 'शरबती गेहूं प्रमाणित बीज HI-617',
    category: 'बीज (Certified Seeds)',
    brand: 'ICAR-IARI',
    vendor: 'म.प्र. राज्य बीज निगम',
    mrp: 2200,
    price: 1950,
    stock: 120,
    unit: '40 kg बैग',
    isAvailable: true,
  },
  {
    id: 'st_003',
    name: 'ट्राइकोडर्मा विरिडी जैव कवकनाशी',
    category: 'जैविक पौध संरक्षण',
    brand: 'KRIBHCO',
    vendor: 'कृभको कृषि केंद्र',
    mrp: 350,
    price: 310,
    stock: 80,
    unit: '1 kg पैकेट',
    isAvailable: true,
  },
];

export default function StoreAdminPage() {
  const [storeItems, setStoreItems] = useState<StoreItem[]>(INITIAL_STORE);

  const toggleAvailability = (id: string) => {
    setStoreItems((prev) =>
      prev.map((i) => (i.id === id ? { ...i, isAvailable: !i.isAvailable } : i))
    );
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="प्रमाणित इनपुट भंडार (Agri Input Store)"
        subtitle="सत्यापित बीज, खाद, जैव उर्वरक इन्वेंट्री व विक्रेता प्रबंधन"
      />

      <main className="p-8 space-y-6 flex-1">
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <div className="p-5 border-b border-soil-200 flex items-center justify-between">
            <h3 className="font-extrabold text-base text-soil-900">इन्वेंटरी स्टॉक तालिका</h3>
            <button
              onClick={() => alert('नया प्रमाणित उत्पाद जोड़ने का फॉर्म खोलें')}
              className="px-3.5 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-xl text-xs font-bold transition flex items-center gap-1.5"
            >
              <Plus className="w-4 h-4" />
              नया उत्पाद जोड़ें
            </button>
          </div>

          <table className="w-full text-left text-xs">
            <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
              <tr>
                <th className="py-3.5 px-6">उत्पाद नाम व ब्रांड</th>
                <th className="py-3.5 px-4">श्रेणी</th>
                <th className="py-3.5 px-4">विक्रेता (Vendor)</th>
                <th className="py-3.5 px-4">मूल्य (MRP / विक्रय)</th>
                <th className="py-3.5 px-4">स्टॉक यूनिट</th>
                <th className="py-3.5 px-4">स्थिति</th>
                <th className="py-3.5 px-6 text-right">कार्य</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-soil-100 font-medium">
              {storeItems.map((item) => (
                <tr key={item.id} className="hover:bg-soil-50/80 transition">
                  <td className="py-4 px-6">
                    <div className="font-bold text-soil-900 text-sm">{item.name}</div>
                    <div className="text-[11px] text-soil-500 font-semibold">{item.brand}</div>
                  </td>
                  <td className="py-4 px-4 text-soil-700">{item.category}</td>
                  <td className="py-4 px-4 text-soil-800 font-medium">{item.vendor}</td>
                  <td className="py-4 px-4">
                    <span className="font-bold text-primary-700 text-sm">₹{item.price}</span>
                    <span className="text-soil-400 line-through text-[11px] ml-1.5">₹{item.mrp}</span>
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-bold text-soil-800">{item.stock} उपलब्ध</div>
                    <div className="text-[11px] text-soil-500">{item.unit}</div>
                  </td>
                  <td className="py-4 px-4">
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${
                        item.isAvailable
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-clay-100 text-clay-800'
                      }`}
                    >
                      {item.isAvailable ? 'उपलब्ध (In Stock)' : 'आउट ऑफ स्टॉक'}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    <button
                      onClick={() => toggleAvailability(item.id)}
                      className="px-3 py-1.5 bg-soil-100 hover:bg-soil-200 text-soil-800 rounded-lg text-xs font-bold transition ml-auto"
                    >
                      {item.isAvailable ? 'रोकें' : 'सक्रिय करें'}
                    </button>
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

