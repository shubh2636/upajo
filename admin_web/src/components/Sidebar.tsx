'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  FileCheck,
  Wheat,
  ShoppingBag,
  CreditCard,
  Tractor,
  Store,
  Star,
  Headphones,
  Bell,
  Activity,
  FileText,
  Settings,
  LogOut,
  ShieldAlert,
} from 'lucide-react';

const NAV_ITEMS = [
  { href: '/dashboard', label: 'डैशबोर्ड (Dashboard)', icon: LayoutDashboard },
  { href: '/users', label: 'उपयोगकर्ता (Users)', icon: Users },
  { href: '/kyc', label: 'KYC सत्यापन कतार (KYC Queue)', icon: FileCheck },
  { href: '/products', label: 'फसल सूची (Products)', icon: Wheat },
  { href: '/orders', label: 'ऑर्डर प्रबंधन (Orders)', icon: ShoppingBag },
  { href: '/payments', label: 'भुगतान व पेआउट (Payments)', icon: CreditCard },
  { href: '/machinery', label: 'कृषि यंत्र किराया (Machinery)', icon: Tractor },
  { href: '/store', label: 'प्रमाणित भंडार (Agri Store)', icon: Store },
  { href: '/reviews', label: 'रेटिंग व समीक्षा (Reviews)', icon: Star },
  { href: '/tickets', label: 'सहायता टिकट (Tickets)', icon: Headphones },
  { href: '/fcm', label: 'FCM ब्रॉडकास्ट (Notifications)', icon: Bell },
  { href: '/health', label: 'सर्विस हेल्थ (Health Status)', icon: Activity },
  { href: '/content', label: 'कंटेंट CMS (Advisory & Mandi)', icon: FileText },
  { href: '/settings', label: 'सेटिंग्स व ऑडिट लॉग (Settings)', icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-72 bg-soil-900 text-soil-100 flex flex-col h-screen sticky top-0 border-r border-soil-800 select-none">
      {/* Brand Header */}
      <div className="p-5 border-b border-soil-800 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary-600 flex items-center justify-center text-white font-bold text-xl shadow-md">
            उ
          </div>
          <div>
            <h1 className="font-extrabold text-lg text-white tracking-wide">उपजो (Upajo)</h1>
            <p className="text-xs text-wheat-500 font-semibold flex items-center gap-1">
              <ShieldAlert className="w-3.5 h-3.5" /> एडमिनिस्ट्रेटर कंसोल
            </p>
          </div>
        </div>
      </div>

      {/* Nav List */}
      <nav className="flex-1 overflow-y-auto p-3 space-y-1">
        {NAV_ITEMS.map((item) => {
          const Icon = item.icon;
          const isActive = pathname.startsWith(item.href);

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                isActive
                  ? 'bg-primary-600 text-white shadow-sm'
                  : 'text-soil-300 hover:bg-soil-800 hover:text-white'
              }`}
            >
              <Icon className={`w-5 h-5 shrink-0 ${isActive ? 'text-white' : 'text-soil-400'}`} />
              <span className="truncate">{item.label}</span>
            </Link>
          );
        })}
      </nav>

      {/* Footer / Session */}
      <div className="p-4 border-t border-soil-800 bg-soil-950/40">
        <div className="flex items-center justify-between text-xs text-soil-400">
          <div>
            <p className="font-bold text-soil-200">एडमिन (TOTP सक्रिय)</p>
            <p className="text-[11px] text-soil-500">2FA सुरक्षित सत्र</p>
          </div>
          <Link
            href="/login"
            className="p-2 text-soil-400 hover:text-clay-500 hover:bg-soil-800 rounded-lg transition"
            title="लॉगआउट करें"
          >
            <LogOut className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </aside>
  );
}

