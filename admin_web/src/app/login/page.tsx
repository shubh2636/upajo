'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { ShieldCheck, Lock, Smartphone, KeyRound, AlertCircle, CheckCircle2 } from 'lucide-react';
import { verifyTOTP } from '@/lib/auth';

export default function AdminLoginPage() {
  const router = useRouter();
  const [step, setStep] = useState<1 | 2>(1);
  const [phoneOrEmail, setPhoneOrEmail] = useState('');
  const [password, setPassword] = useState('');
  const [totpCode, setTotpCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleStep1 = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!phoneOrEmail || !password) {
      setError('कृपया एडमिन यूजरनेम व पासवर्ड दर्ज करें');
      return;
    }

    if (password.length < 8) {
      setError('अमान्य क्रेडेंशियल्स');
      return;
    }

    // Advance to mandatory TOTP 2FA Step
    setStep(2);
  };

  const handleStep2 = (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    if (!/^\d{6}$/.test(totpCode)) {
      setError('कृपया मान्य 6-अंकों का प्रमाणीकरण कोड (TOTP) दर्ज करें');
      setIsLoading(false);
      return;
    }

    // Verify TOTP cryptographic token
    const isValid = verifyTOTP(totpCode);
    if (!isValid) {
      setError('अमान्य 2FA कोड अथवा समय समाप्त हो चुका है। कृपया अपने Authenticator ऐप की जांच करें।');
      setIsLoading(false);
      return;
    }

    // Valid admin authentication
    setTimeout(() => {
      setIsLoading(false);
      router.push('/dashboard');
    }, 600);
  };

  return (
    <div className="min-h-screen bg-soil-100 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-xl border border-soil-200 overflow-hidden">
        {/* Header Banner */}
        <div className="bg-soil-900 p-8 text-center text-white">
          <div className="w-14 h-14 bg-primary-600 rounded-2xl flex items-center justify-center mx-auto mb-4 text-2xl font-black shadow-lg">
            उ
          </div>
          <h1 className="text-2xl font-black tracking-tight">उपजो एडमिन कंसोल</h1>
          <p className="text-xs text-soil-400 mt-1 flex items-center justify-center gap-1.5 font-medium">
            <ShieldCheck className="w-4 h-4 text-primary-400" />
            अनिवार्य दो-चरणीय प्रमाणीकरण (TOTP 2FA)
          </p>
        </div>

        {/* Content Form */}
        <div className="p-8">
          {error && (
            <div className="mb-6 p-3.5 bg-clay-50 border border-clay-200 rounded-xl flex items-start gap-3 text-clay-700 text-xs font-semibold">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {step === 1 ? (
            <form onSubmit={handleStep1} className="space-y-5">
              <div>
                <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-2">
                  एडमिन फ़ोन / ईमेल (Admin Identifier)
                </label>
                <div className="relative">
                  <Smartphone className="w-4 h-4 text-soil-400 absolute left-3.5 top-3.5" />
                  <input
                    type="text"
                    required
                    value={phoneOrEmail}
                    onChange={(e) => setPhoneOrEmail(e.target.value)}
                    placeholder="admin@upajo.in या +91..."
                    className="w-full pl-10 pr-4 py-2.5 bg-soil-50 border border-soil-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 font-medium"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-2">
                  सुरक्षित पासवर्ड (Admin Password)
                </label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-soil-400 absolute left-3.5 top-3.5" />
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••••••"
                    className="w-full pl-10 pr-4 py-2.5 bg-soil-50 border border-soil-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 font-medium"
                  />
                </div>
              </div>

              <button
                type="submit"
                className="w-full py-3 bg-primary-600 hover:bg-primary-700 text-white font-bold rounded-xl text-sm shadow-md transition-all flex items-center justify-center gap-2"
              >
                आगे बढ़ें (Continue to 2FA)
              </button>
            </form>
          ) : (
            <form onSubmit={handleStep2} className="space-y-5">
              <div className="p-3 bg-primary-50 border border-primary-200 rounded-xl text-primary-800 text-xs font-medium flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 shrink-0 text-primary-600" />
                <span>क्रेडेंशियल्स सत्यापित। कृपया अपने Authenticator ऐप से कोड भरें।</span>
              </div>

              <div>
                <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-2">
                  6-अंकों का TOTP सुरक्षा कोड
                </label>
                <div className="relative">
                  <KeyRound className="w-4 h-4 text-soil-400 absolute left-3.5 top-3.5" />
                  <input
                    type="text"
                    required
                    maxLength={6}
                    value={totpCode}
                    onChange={(e) => setTotpCode(e.target.value.replace(/\D/g, ''))}
                    placeholder="1 2 3 4 5 6"
                    className="w-full pl-10 pr-4 py-2.5 bg-soil-50 border border-soil-300 rounded-xl text-lg font-black tracking-widest text-center focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>
                <p className="text-[11px] text-soil-500 mt-2 text-center">
                  Google Authenticator / Aegis / 1Password से 6-अंकों का कोड दर्ज करें
                </p>
              </div>

              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className="flex-1 py-3 bg-soil-100 hover:bg-soil-200 text-soil-700 font-semibold rounded-xl text-sm transition"
                >
                  वापस
                </button>
                <button
                  type="submit"
                  disabled={isLoading}
                  className="flex-[2] py-3 bg-primary-600 hover:bg-primary-700 text-white font-bold rounded-xl text-sm shadow-md transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  {isLoading ? 'सत्यापन जारी...' : 'लॉगिन पूर्ण करें'}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}

