import { HealthStatus } from "@/components/health-status";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center gap-8 px-6 py-16">
      <div className="space-y-3">
        <p className="text-sm font-semibold tracking-[0.2em] text-violet-400 uppercase">
          Golden template
        </p>
        <h1 className="text-4xl font-bold tracking-tight text-white sm:text-5xl">
          Next.js frontend starter
        </h1>
        <p className="max-w-xl text-lg text-slate-300">
          Clean App Router + Tailwind scaffold with a built-in config malware
          scanner. Clone this — never copy configs from old client folders.
        </p>
      </div>

      <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
        <h2 className="mb-3 text-sm font-semibold tracking-wide text-slate-200 uppercase">
          Backend health
        </h2>
        <HealthStatus />
      </div>

      <ul className="space-y-2 text-sm text-slate-400">
        <li>Run <code className="text-violet-300">npm run security:scan</code> before install on untrusted clones</li>
        <li>CI fails if ESLint / PostCSS / Tailwind configs look infected</li>
        <li>Point <code className="text-violet-300">NEXT_PUBLIC_API_URL</code> at your Nest API</li>
      </ul>
    </main>
  );
}
