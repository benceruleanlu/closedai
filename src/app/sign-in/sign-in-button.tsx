"use client";

import { useState } from "react";
import { authClient } from "@/lib/auth-client";

export function GoogleSignInButton({
  callbackUrl,
  enabled,
}: {
  callbackUrl: string;
  enabled: boolean;
}) {
  const [error, setError] = useState<string>();
  const [isPending, setIsPending] = useState(false);

  async function signIn() {
    setError(undefined);
    setIsPending(true);

    const result = await authClient.signIn.social({
      provider: "google",
      callbackURL: callbackUrl,
    });

    if (result.error) {
      setError(result.error.message ?? "Unable to start Google sign-in.");
      setIsPending(false);
    }
  }

  return (
    <div>
      <button
        type="button"
        className="w-full rounded-lg bg-white px-4 py-3 font-medium text-neutral-950 transition hover:bg-neutral-200 disabled:cursor-not-allowed disabled:bg-neutral-700 disabled:text-neutral-400"
        disabled={!enabled || isPending}
        onClick={signIn}
      >
        {isPending ? "Opening Google…" : "Continue with Google"}
      </button>
      {!enabled && (
        <p className="mt-3 text-sm leading-5 text-amber-300">
          Google OAuth is not configured for this environment.
        </p>
      )}
      {error && (
        <p className="mt-3 text-sm leading-5 text-red-300" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
