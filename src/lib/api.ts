const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3000/api";

export async function getHealth(): Promise<{ status: string; timestamp: string }> {
  const res = await fetch(`${API_URL}/health`, {
    next: { revalidate: 0 },
  });
  if (!res.ok) {
    throw new Error(`Health check failed (${res.status})`);
  }
  return res.json();
}
