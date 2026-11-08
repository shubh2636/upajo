'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { FileText, Trash2, Save, RefreshCw, CheckCircle2, ShieldCheck } from 'lucide-react';

export default function ContentCmsPage() {
  const [mandiCacheStatus, setMandiCacheStatus] = useState('सक्रिय (TTL: 30 मिनट • 48 कमोडिटी प्रविष्टियां)');
  const [isPurging, setIsPurging] = useState(false);
  const [wheatRule, setWheatRule] = useState(
    'काली गहरी मिट्टी एवं 3-4 सिंचाई के लिए शरबती गेहूं अत्यधिक उपयुक्त है। बाजार में इसके दाने की चमक और मिठास के कारण गुणवत्ता आधारित प्रीमियम दर प्राप्त हो सकती है।'
  );
  const [gramRule, setGramRule] = useState(
    'मध्यम से हल्की मिट्टी के लिए देसी चना (JG-11) सर्वोत्तम है। 1-2 हल्की सिंचाई से प्रति एकड़ 8-10 क्विंटल उपज प्राप्त की जा सकती है।'
  );
  const [isSaved, setIsSaved] = useState(false);

  const purgeCache = () => {
    setIsPurging(true);
    setTimeout(() => {
      setIsPurging(false);
      setMandiCacheStatus('कैश सफलतापूर्वक रिक्त की गई! नया Agmarknet फेच सक्रिय होगा।');
      alert('मंडी मूल्य कैश सफलतापूर्वक साफ़ कर दिया गया!');
    }, 600);
  };

  const saveRules = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaved(true);
    setTimeout(() => setIsSaved(false), 2000);
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="कंटेंट CMS व मंडी कैश (Content CMS & Cache Purge)"
        subtitle="ICAR फसल सलाह टेक्स्ट संपादन एवं Agmarknet मंडी कैश प्रबंधन"
      />

      <main className="p-8 space-y-6 flex-1">
        {/* Mandi Cache Purge Card */}
        <div className="bg-white p-6 rounded-2xl border border-soil-200 shadow-sm flex items-center justify-between">
          <div>
            <h3 className="font-extrabold text-base text-soil-900 flex items-center gap-2">
              <RefreshCw className="w-4 h-4 text-primary-600" />
              Agmarknet मंडी भाव कैश प्रबंधन
            </h3>
            <p className="text-xs text-soil-500 mt-1">{mandiCacheStatus}</p>
          </div>
          <button
            onClick={purgeCache}
            disabled={isPurging}
            className="px-4 py-2.5 bg-clay-50 hover:bg-clay-100 text-clay-700 border border-clay-300 rounded-xl text-xs font-bold transition flex items-center gap-2 disabled:opacity-50"
          >
            <Trash2 className="w-4 h-4" />
            {isPurging ? 'कैश खाली हो रहा है...' : 'मंडी कैश तत्काल Purge करें'}
          </button>
        </div>

        {/* Advisory Rules Editor */}
        <div className="bg-white p-6 rounded-2xl border border-soil-200 shadow-sm">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="font-extrabold text-base text-soil-900 flex items-center gap-2">
                <FileText className="w-4 h-4 text-primary-600" />
                ICAR फसल एडवाइजरी नियम संपादक
              </h3>
              <p className="text-xs text-soil-500">
                किसानों को ऐप में दिखने वाली तकनीकी सलाह व वैज्ञानिक अनुशंसाएं
              </p>
            </div>
            {isSaved && (
              <span className="px-3 py-1 bg-emerald-100 text-emerald-800 text-xs font-bold rounded-lg flex items-center gap-1.5 animate-bounce">
                <CheckCircle2 className="w-4 h-4" /> सहेजा गया!
              </span>
            )}
          </div>

          <form onSubmit={saveRules} className="space-y-5">
            <div>
              <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-2">
                शरबती गेहूं (C-306 / HI-617) मुख्य सलाह:
              </label>
              <textarea
                rows={3}
                value={wheatRule}
                onChange={(e) => setWheatRule(e.target.value)}
                className="w-full p-3 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium focus:ring-2 focus:ring-primary-500"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-soil-700 uppercase tracking-wider mb-2">
                देसी चना (JG-11 / काबुली) मुख्य सलाह:
              </label>
              <textarea
                rows={3}
                value={gramRule}
                onChange={(e) => setGramRule(e.target.value)}
                className="w-full p-3 bg-soil-50 border border-soil-300 rounded-xl text-xs font-medium focus:ring-2 focus:ring-primary-500"
              />
            </div>

            <button
              type="submit"
              className="px-6 py-2.5 bg-primary-600 hover:bg-primary-700 text-white rounded-xl text-xs font-bold transition shadow-sm flex items-center gap-2"
            >
              <Save className="w-4 h-4" />
              सलाह नियम सुरक्षित करें (Save Changes)
            </button>
          </form>
        </div>
      </main>
    </div>
  );
}

