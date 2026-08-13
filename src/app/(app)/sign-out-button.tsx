"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { authClient } from "@/lib/auth-client";

export function SignOutButton() {
  const router = useRouter();
  const [isPending, setIsPending] = useState(false);

  async function signOut() {
    setIsPending(true);
    await authClient.signOut();
    router.push("/sign-in");
    router.refresh();
  }

  return (
    <button
      type="button"
      className="rounded-md border border-neutral-700 px-3 py-2 text-sm transition hover:border-neutral-500 disabled:cursor-not-allowed disabled:opacity-50"
      disabled={isPending}
      onClick={signOut}
    >
      {isPending ? "Signing out…" : "Sign out"}
    </button>
  );
}
