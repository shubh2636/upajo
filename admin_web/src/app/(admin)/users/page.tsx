'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Search, ShieldAlert, ShieldCheck, UserCheck, UserX, Filter } from 'lucide-react';

interface UserItem {
  id: string;
  fullName: string;
  phone: string;
  role: 'farmer' | 'consumer' | 'admin';
  village: string;
  district: string;
  kycStatus: 'pending' | 'verified' | 'rejected' | 'none';
  isBanned: boolean;
  createdAt: string;
}

const INITIAL_USERS: UserItem[] = [
  {
    id: 'usr_001',
    fullName: 'बलदेव सिंह पटेल',
    phone: '+91 9425098765',
    role: 'farmer',
    village: 'श्यामपुर',
    district: 'सीहोर',
    kycStatus: 'verified',
    isBanned: false,
    createdAt: '2026-01-15',
  },
  {
    id: 'usr_002',
    fullName: 'रामगोपाल पाटीदार',
    phone: '+91 9826112233',
    role: 'farmer',
    village: 'तराना',
    district: 'उज्जैन',
    kycStatus: 'pending',
    isBanned: false,
    createdAt: '2026-02-01',
  },
  {
    id: 'usr_003',
    fullName: 'अमित शर्मा',
    phone: '+91 9826011223',
    role: 'consumer',
    village: 'अरेरा कॉलोनी',
    district: 'भोपाल',
    kycStatus: 'none',
    isBanned: false,
    createdAt: '2026-02-10',
  },
  {
    id: 'usr_004',
    fullName: 'सुनीता वर्मा',
    phone: '+91 9111223344',
    role: 'consumer',
    village: 'विजय नगर',
    district: 'इंदौर',
    kycStatus: 'none',
    isBanned: false,
    createdAt: '2026-02-12',
  },
];

export default function UsersPage() {
  const [users, setUsers] = useState<UserItem[]>(INITIAL_USERS);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'farmer' | 'consumer' | 'admin'>('all');

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      u.fullName.toLowerCase().includes(search.toLowerCase()) ||
      u.phone.includes(search) ||
      u.district.toLowerCase().includes(search.toLowerCase());
    const matchesRole = roleFilter === 'all' || u.role === roleFilter;
    return matchesSearch && matchesRole;
  });

  const toggleBan = (id: string) => {
    setUsers((prev) =>
      prev.map((u) => (u.id === id ? { ...u, isBanned: !u.isBanned } : u))
    );
  };

  const changeRole = (id: string, newRole: 'farmer' | 'consumer' | 'admin') => {
    setUsers((prev) =>
      prev.map((u) => (u.id === id ? { ...u, role: newRole } : u))
    );
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="उपयोगकर्ता प्रबंधन (Users Management)"
        subtitle="किसान साथी, उपभोक्ता व प्रशासनिक भूमिका नियंत्रण"
      />

      <main className="p-8 space-y-6 flex-1">
        {/* Controls Bar */}
        <div className="bg-white p-4 rounded-2xl border border-soil-200 shadow-sm flex flex-col sm:flex-row gap-4 items-center justify-between">
          <div className="relative w-full sm:w-80">
            <Search className="w-4 h-4 text-soil-400 absolute left-3.5 top-3.5" />
            <input
              type="text"
              placeholder="नाम, फ़ोन या जिला खोजें..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium focus:outline-none focus:ring-2 focus:ring-primary-500"
            />
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto">
            <Filter className="w-4 h-4 text-soil-500" />
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value as any)}
              className="px-3 py-2 bg-soil-50 border border-soil-300 rounded-xl text-xs font-semibold focus:outline-none focus:ring-2 focus:ring-primary-500"
            >
              <option value="all">सभी भूमिकाएं (All Roles)</option>
              <option value="farmer">किसान (Farmer)</option>
              <option value="consumer">उपभोक्ता (Consumer)</option>
              <option value="admin">एडमिन (Admin)</option>
            </select>
          </div>
        </div>

        {/* Users Table */}
        <div className="bg-white rounded-2xl border border-soil-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-soil-100/70 border-b border-soil-200 text-soil-600 uppercase tracking-wider font-bold">
                <tr>
                  <th className="py-3.5 px-6">नाम व फ़ोन</th>
                  <th className="py-3.5 px-4">भूमिका (Role)</th>
                  <th className="py-3.5 px-4">स्थान (Location)</th>
                  <th className="py-3.5 px-4">KYC स्थिति</th>
                  <th className="py-3.5 px-4">अकाउंट स्थिति</th>
                  <th className="py-3.5 px-6 text-right">कार्य (Actions)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-soil-100 font-medium">
                {filteredUsers.map((u) => (
                  <tr key={u.id} className="hover:bg-soil-50/80 transition">
                    <td className="py-4 px-6">
                      <div className="font-bold text-soil-900 text-sm">{u.fullName}</div>
                      <div className="text-soil-500 font-mono text-[11px]">{u.phone}</div>
                    </td>
                    <td className="py-4 px-4">
                      <select
                        value={u.role}
                        onChange={(e) => changeRole(u.id, e.target.value as any)}
                        className="px-2.5 py-1 bg-soil-100 border border-soil-300 rounded-lg text-xs font-bold text-soil-800 focus:outline-none focus:ring-2 focus:ring-primary-500"
                      >
                        <option value="farmer">किसान (Farmer)</option>
                        <option value="consumer">उपभोक्ता (Consumer)</option>
                        <option value="admin">एडमिन (Admin)</option>
                      </select>
                    </td>
                    <td className="py-4 px-4 text-soil-700">
                      {u.village}, {u.district}
                    </td>
                    <td className="py-4 px-4">
                      {u.kycStatus === 'verified' && (
                        <span className="px-2 py-0.5 bg-primary-100 text-primary-800 rounded-md text-[10px] font-bold inline-flex items-center gap-1">
                          <ShieldCheck className="w-3 h-3" /> स्वीकृत ✓
                        </span>
                      )}
                      {u.kycStatus === 'pending' && (
                        <span className="px-2 py-0.5 bg-wheat-100 text-wheat-800 rounded-md text-[10px] font-bold">
                          समीक्षाधीन (Pending)
                        </span>
                      )}
                      {u.kycStatus === 'rejected' && (
                        <span className="px-2 py-0.5 bg-clay-100 text-clay-800 rounded-md text-[10px] font-bold">
                          अस्वीकृत (Rejected)
                        </span>
                      )}
                      {u.kycStatus === 'none' && (
                        <span className="text-soil-400 text-[11px]">लागू नहीं</span>
                      )}
                    </td>
                    <td className="py-4 px-4">
                      {u.isBanned ? (
                        <span className="px-2 py-0.5 bg-clay-100 text-clay-800 rounded-md text-[10px] font-bold inline-flex items-center gap-1">
                          <UserX className="w-3 h-3" /> प्रतिबंधित (Banned)
                        </span>
                      ) : (
                        <span className="px-2 py-0.5 bg-emerald-100 text-emerald-800 rounded-md text-[10px] font-bold inline-flex items-center gap-1">
                          <UserCheck className="w-3 h-3" /> सक्रिय (Active)
                        </span>
                      )}
                    </td>
                    <td className="py-4 px-6 text-right">
                      <button
                        onClick={() => toggleBan(u.id)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                          u.isBanned
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-300 hover:bg-emerald-100'
                            : 'bg-clay-50 text-clay-700 border border-clay-300 hover:bg-clay-100'
                        }`}
                      >
                        {u.isBanned ? 'बैन हटाएं' : 'प्रतिबंधित करें'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}

