import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css"; // Votre ancien CSS global
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Providers } from "@/components/providers";

// Configuration des polices par défaut si nécessaire
const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Tili Cash Hub",
  description: "Logiciel de caisse nouvelle génération",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>
          {children}
          <Toaster />
          <Sonner />
        </Providers>
      </body>
    </html>
  );
}