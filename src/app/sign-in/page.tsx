import { headers } from "next/headers";
import { redirect } from "next/navigation";
import { auth, isGoogleAuthConfigured } from "@/lib/auth";
import { GoogleSignInButton } from "./sign-in-button";

function safeCallbackUrl(callbackUrl: string | string[] | undefined) {
  if (typeof callbackUrl !== "string" || !callbackUrl.startsWith("/")) {
    return "/";
  }

  try {
    const url = new URL(callbackUrl, "http://closedai.local");

    if (url.origin !== "http://closedai.local") {
      return "/";
    }

    return `${url.pathname}${url.search}${url.hash}`;
  } catch {
    return "/";
  }
}

export default async function SignInPage({
  searchParams,
}: {
  searchParams: Promise<{ callbackUrl?: string | string[] }>;
}) {
  const callbackUrl = safeCallbackUrl((await searchParams).callbackUrl);
  const session = await auth.api.getSession({ headers: await headers() });

  if (session) {
    redirect(callbackUrl);
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-neutral-950 px-6 text-neutral-100">
      <section className="w-full max-w-sm rounded-2xl border border-neutral-800 bg-neutral-900 p-8 shadow-2xl">
        <p className="text-sm font-medium tracking-wide text-neutral-400">
          CLOSEDAI
        </p>
        <h1 className="mt-3 text-2xl font-semibold">Sign in to continue</h1>
        <p className="mt-2 text-sm leading-6 text-neutral-400">
          Every application page requires an authenticated account.
        </p>
        <div className="mt-8">
          <GoogleSignInButton
            callbackUrl={callbackUrl}
            enabled={isGoogleAuthConfigured}
          />
        </div>
      </section>
    </main>
  );
}
