'use client';

import React from 'react';
import { Bell, ShieldCheck, RefreshCw } from 'lucide-react';

interface HeaderProps {
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
  isRefreshing?: boolean;
}

export default function Header({ title, subtitle, onRefresh, isRefreshing }: HeaderProps) {
  return (
    <header className="bg-white border-b border-soil-200 px-8 py-5 flex items-center justify-between sticky top-0 z-10">
      <div>
        <h2 className="text-2xl font-black text-soil-900 tracking-tight">{title}</h2>
        {subtitle && <p className="text-xs text-soil-500 font-medium mt-0.5">{subtitle}</p>}
      </div>

      <div className="flex items-center gap-4">
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isRefreshing}
            className="flex items-center gap-2 px-3.5 py-2 text-xs font-semibold text-soil-700 bg-soil-100 hover:bg-soil-200 rounded-lg transition disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
            रिफ्रेश
          </button>
        )}

        <div className="flex items-center gap-2 px-3 py-1.5 bg-primary-50 border border-primary-200 text-primary-800 rounded-full text-xs font-bold">
          <ShieldCheck className="w-4 h-4 text-primary-600" />
          TOTP 2FA सत्यापित
        </div>
      </div>
    </header>
  );
}

