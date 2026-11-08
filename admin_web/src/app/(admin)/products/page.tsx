'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Search, Wheat, Eye, EyeOff, Trash2, Star, ShieldAlert } from 'lucide-react';

interface ProductAdminItem {
  id: string;
  titleHi: string;
  category: string;
  farmerName: string;
  district: string;
  pricePerKg: number;
  stockKg: number;
  packSizes: number[];
  isOrganic: boolean;
  isActive: boolean;
  isFeatured: boolean;
  isFlagged: boolean;
  flagReason?: string;
}

const INITIAL_PRODUCTS: ProductAdminItem[] = [
  {
    id: 'prod_001',
    titleHi: 'शरबती गेहूं (C-306)',
    category: 'अनाज (Cereals)',
    farmerName: 'बलदेव सिंह पटेल',
    district: 'सीहोर',
    pricePerKg: 35.0,
    stockKg: 1200.0,
    packSizes: [10, 20, 50],
    isOrganic: true,
    isActive: true,
    isFeatured: true,
    isFlagged: false,
  },
  {
    id: 'prod_002',
    titleHi: 'देसी चना (JG-11)',
    category: 'दालें (Pulses)',
    farmerName: 'रामगोपाल पाटीदार',
    district: 'उज्जैन',
    pricePerKg: 68.0,
    stockKg: 450.0,
    packSizes: [10, 20],
    isOrganic: true,
    isActive: true,
    isFeatured: false,
    isFlagged: false,
  },
  {
    id: 'prod_003',
    titleHi: 'सोयाबीन बीज (JS-335)',
    category: 'तिलहन (Oilseeds)',
    farmerName: 'दिलीप मीणा',
    district: 'सीहोर',
    pricePerKg: 52.0,
    stockKg: 800.0,
    packSizes: [20, 50],
    isOrganic: false,
    isActive: false,
    isFeatured: false,
    isFlagged: true,
    flagReason: 'कीमत अत्यधिक ऊंची दर्ज की गई है',
  },
];

export default function ProductsAdminPage() {
  const [products, setProducts] = useState<ProductAdminItem[]>(INITIAL_PRODUCTS);
  const [search, setSearch] = useState('');

  const filtered = products.filter(
    (p) =>
      p.titleHi.toLowerCase().includes(search.toLowerCase()) ||
      p.farmerName.toLowerCase().includes(search.toLowerCase()) ||
      p.district.toLowerCase().includes(search.toLowerCase())
  );

  const toggleVisibility = (id: string) => {
    setProducts((prev) =>
      prev.map((p) => (p.id === id ? { ...p, isActive: !p.isActive } : p))
    );
  };

  const toggleFeatured = (id: string) => {
    setProducts((prev) =>
      prev.map((p) => (p.id === id ? { ...p, isFeatured: !p.isFeatured } : p))
    );
  };

  const deleteProduct = (id: string) => {
    if (confirm('क्या आप वाकई इस उत्पाद को हटाना चाहते हैं?')) {
      setProducts((prev) => prev.filter((p) => p.id !== id));
    }
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="फसल व उत्पाद मॉडरेशन (Products Moderation)"
        subtitle="लिस्टिंग समीक्षा, सक्रिय/रोकें टॉगल एवं फ़ीचर्ड स्टेटस प्रबंधन"
      />

      <main className="p-8 space-y-6 flex-1">
        {/* Controls */}
        <div className="bg-white p-4 rounded-2xl border border-soil-200 shadow-sm flex items-center justify-between">
          <div className="relative w-80">
            <Search className="w-4 h-4 text-soil-400 absolute left-3.5 top-3.5" />
            <input
              type="text"
              placeholder="फसल, किसान या जिला खोजें..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium focus:ring-2 focus:ring-primary-500"
            />
          </div>
          <div className="text-xs text-soil-500 font-semibold">
            कुल फसलें: <span className="text-soil-900 font-bold">{products.length}</span>
          </div>
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <table className="w-full text-left text-xs">
            <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
              <tr>
                <th className="py-3.5 px-6">फसल नाम</th>
                <th className="py-3.5 px-4">श्रेणी</th>
                <th className="py-3.5 px-4">किसान साथी</th>
                <th className="py-3.5 px-4">दर / स्टॉक</th>
                <th className="py-3.5 px-4">पैक आकार</th>
                <th className="py-3.5 px-4">स्थिति</th>
                <th className="py-3.5 px-6 text-right">कार्य</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-soil-100 font-medium">
              {filtered.map((p) => (
                <tr key={p.id} className="hover:bg-soil-50/80 transition">
                  <td className="py-4 px-6">
                    <div className="font-extrabold text-soil-900 text-sm flex items-center gap-1.5">
                      {p.titleHi}
                      {p.isFeatured && (
                        <Star className="w-3.5 h-3.5 text-wheat-500 fill-wheat-500" />
                      )}
                    </div>
                    {p.isOrganic && (
                      <span className="text-[10px] font-bold text-primary-700 bg-primary-100 px-1.5 py-0.5 rounded">
                        प्रमाणित जैविक
                      </span>
                    )}
                    {p.isFlagged && (
                      <p className="text-[11px] text-clay-600 font-semibold mt-1 flex items-center gap-1">
                        <ShieldAlert className="w-3 h-3" /> {p.flagReason}
                      </p>
                    )}
                  </td>
                  <td className="py-4 px-4 text-soil-700">{p.category}</td>
                  <td className="py-4 px-4 text-soil-800">
                    <div className="font-bold">{p.farmerName}</div>
                    <div className="text-[11px] text-soil-500">{p.district}</div>
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-extrabold text-primary-700">₹{p.pricePerKg} / किग्रा</div>
                    <div className="text-soil-500 text-[11px]">स्टॉक: {p.stockKg} किग्रा</div>
                  </td>
                  <td className="py-4 px-4 font-mono text-[11px] text-soil-700">
                    {p.packSizes.join(', ')} kg
                  </td>
                  <td className="py-4 px-4">
                    <span
                      className={`px-2 py-0.5 rounded-md text-[10px] font-bold ${
                        p.isActive
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-soil-200 text-soil-700'
                      }`}
                    >
                      {p.isActive ? 'सक्रिय (Live)' : 'रुकी हुई (Paused)'}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => toggleFeatured(p.id)}
                        title={p.isFeatured ? 'फ़ीचर हटाएं' : 'होमपेज पर फ़ीचर करें'}
                        className={`p-1.5 rounded-lg border transition ${
                          p.isFeatured
                            ? 'bg-wheat-100 border-wheat-300 text-wheat-700'
                            : 'bg-soil-50 border-soil-200 text-soil-500 hover:bg-soil-100'
                        }`}
                      >
                        <Star className="w-4 h-4" />
                      </button>

                      <button
                        onClick={() => toggleVisibility(p.id)}
                        title={p.isActive ? 'रोकें (Pause)' : 'सक्रिय करें'}
                        className={`p-1.5 rounded-lg border transition ${
                          p.isActive
                            ? 'bg-soil-50 border-soil-200 text-soil-700 hover:bg-soil-100'
                            : 'bg-primary-50 border-primary-200 text-primary-700 hover:bg-primary-100'
                        }`}
                      >
                        {p.isActive ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>

                      <button
                        onClick={() => deleteProduct(p.id)}
                        title="हटाएं"
                        className="p-1.5 rounded-lg border border-clay-200 bg-clay-50 text-clay-600 hover:bg-clay-100 transition"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
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

