"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

// Re-renders the current Server Component page every few seconds while mounted.
export function AutoRefresh({ intervalMs = 5_000 }: { intervalMs?: number }) {
  const router = useRouter();

  useEffect(() => {
    const timer = setInterval(() => router.refresh(), intervalMs);
    return () => clearInterval(timer);
  }, [router, intervalMs]);

  return null;
}
