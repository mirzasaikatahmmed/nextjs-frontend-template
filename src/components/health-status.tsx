import { getHealth } from "@/lib/api";

export async function HealthStatus() {
  try {
    const health = await getHealth();
    return (
      <p className="text-sm text-emerald-400">
        API <span className="font-semibold">{health.status}</span> · {health.timestamp}
      </p>
    );
  } catch {
    return (
      <p className="text-sm text-amber-400">
        API unreachable. Start the Nest golden backend or set{" "}
        <code className="text-violet-300">NEXT_PUBLIC_API_URL</code>.
      </p>
    );
  }
}
