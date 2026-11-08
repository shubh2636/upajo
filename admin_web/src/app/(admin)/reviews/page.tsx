'use client';

import React, { useState } from 'react';
import Header from '@/components/Header';
import { Star, Trash2, ShieldAlert, CheckCircle2, Filter } from 'lucide-react';

interface ReviewItem {
  id: string;
  orderNumber: string;
  cropName: string;
  farmerName: string;
  consumerName: string;
  rating: number;
  comment: string;
  createdAt: string;
  isFlagged: boolean;
}

const INITIAL_REVIEWS: ReviewItem[] = [
  {
    id: 'rev_001',
    orderNumber: 'UPJ-2026-0812',
    cropName: 'शरबती गेहूं (C-306)',
    farmerName: 'बलदेव सिंह पटेल',
    consumerName: 'अमित शर्मा',
    rating: 5,
    comment: 'गेहूं बहुत ही साफ और दानेदार है। रोटियां बहुत मुलायम बनी हैं। किसान साथी को धन्यवाद!',
    createdAt: '2026-02-14',
    isFlagged: false,
  },
  {
    id: 'rev_002',
    orderNumber: 'UPJ-2026-0808',
    cropName: 'देसी चना',
    farmerName: 'रामगोपाल पाटीदार',
    consumerName: 'अनिल कपूर',
    rating: 1,
    comment: 'spam link http://malicious-site.com fake review',
    createdAt: '2026-02-13',
    isFlagged: true,
  },
  {
    id: 'rev_003',
    orderNumber: 'UPJ-2026-0805',
    cropName: 'सोयाबीन बीज',
    farmerName: 'दिलीप मीणा',
    consumerName: 'राजेश चौहान',
    rating: 4,
    comment: 'पैकिंग अच्छी थी, डिलीवरी 1 दिन देर से हुई पर बीज की गुणवत्ता उत्तम है।',
    createdAt: '2026-02-11',
    isFlagged: false,
  },
];

export default function ReviewsAdminPage() {
  const [reviews, setReviews] = useState<ReviewItem[]>(INITIAL_REVIEWS);
  const [ratingFilter, setRatingFilter] = useState<number | 'all'>('all');

  const filtered = reviews.filter(
    (r) => ratingFilter === 'all' || r.rating === ratingFilter
  );

  const deleteReview = (id: string) => {
    if (confirm('क्या आप इस समीक्षा को हटाना चाहते हैं?')) {
      setReviews((prev) => prev.filter((r) => r.id !== id));
    }
  };

  return (
    <div className="flex-1 flex flex-col min-h-screen">
      <Header
        title="रेटिंग व समीक्षा मॉडरेशन (Reviews Moderation)"
        subtitle="उपभोक्ता समीक्षाओं की जांच, अनुचित टिप्पणी व स्पैम हटाना"
      />

      <main className="p-8 space-y-6 flex-1">
        {/* Filter Bar */}
        <div className="bg-white p-4 rounded-2xl border border-soil-200 shadow-sm flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Filter className="w-4 h-4 text-soil-500" />
            <select
              value={ratingFilter}
              onChange={(e) => setRatingFilter(e.target.value === 'all' ? 'all' : Number(e.target.value))}
              className="px-3 py-2 bg-soil-50 border border-soil-300 rounded-xl text-xs font-semibold focus:ring-2 focus:ring-primary-500"
            >
              <option value="all">सभी रेटिंग (All Stars)</option>
              <option value="5">⭐⭐⭐⭐⭐ (5 Star)</option>
              <option value="4">⭐⭐⭐⭐ (4 Star)</option>
              <option value="3">⭐⭐⭐ (3 Star)</option>
              <option value="2">⭐⭐ (2 Star)</option>
              <option value="1">⭐ (1 Star)</option>
            </select>
          </div>

          <span className="text-xs text-soil-500 font-bold">
            कुल समीक्षाएं: {reviews.length}
          </span>
        </div>

        {/* Reviews Grid */}
        <div className="space-y-4">
          {filtered.map((r) => (
            <div
              key={r.id}
              className={`bg-white p-5 rounded-2xl border shadow-sm flex items-start justify-between ${
                r.isFlagged ? 'border-clay-300 bg-clay-50/20' : 'border-soil-200'
              }`}
            >
              <div className="space-y-2 flex-1">
                <div className="flex items-center gap-3">
                  <div className="flex items-center text-wheat-500">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <Star
                        key={i}
                        className={`w-4 h-4 ${
                          i < r.rating ? 'fill-wheat-500 text-wheat-500' : 'text-soil-200'
                        }`}
                      />
                    ))}
                  </div>
                  <span className="text-xs font-bold text-soil-900">{r.cropName}</span>
                  <span className="text-[11px] text-soil-400 font-mono">({r.orderNumber})</span>
                  {r.isFlagged && (
                    <span className="px-2 py-0.5 bg-clay-100 text-clay-800 text-[10px] font-bold rounded flex items-center gap-1">
                      <ShieldAlert className="w-3 h-3" /> स्पैम / अनुचित चिन्हित
                    </span>
                  )}
                </div>

                <p className="text-xs text-soil-800 font-medium leading-relaxed bg-soil-50 p-3 rounded-xl border border-soil-200">
                  {r.comment}
                </p>

                <div className="text-[11px] text-soil-500 flex items-center gap-3">
                  <span>ग्राहक: <strong className="text-soil-800">{r.consumerName}</strong></span>
                  <span>•</span>
                  <span>किसान साथी: <strong className="text-soil-800">{r.farmerName}</strong></span>
                  <span>•</span>
                  <span>{r.createdAt}</span>
                </div>
              </div>

              <div className="ml-4">
                <button
                  onClick={() => deleteReview(r.id)}
                  title="समीक्षा हटाएं"
                  className="p-2 text-clay-600 hover:bg-clay-100 rounded-lg transition"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}

