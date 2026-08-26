import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Golden Next.js Frontend",
  description: "Malware-hardened Next.js starter template",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
