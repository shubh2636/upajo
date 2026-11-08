import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'उपजो (Upajo) - एडमिन कंसोल',
  description: 'Enterprise Administrative Console for Upajo Agritech Platform',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="hi">
      <body className="antialiased min-h-screen bg-soil-50 text-soil-900">
        {children}
      </body>
    </html>
  );
}

