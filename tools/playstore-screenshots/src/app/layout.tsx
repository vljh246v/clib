import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Clib Google Play Screenshots",
  description: "Clib Google Play screenshot generator",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
