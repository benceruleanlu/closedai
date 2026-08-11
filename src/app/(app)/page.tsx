import { headers } from "next/headers";
import { auth } from "@/lib/auth";
import { SignOutButton } from "./sign-out-button";

export default async function Home() {
  const session = await auth.api.getSession({ headers: await headers() });

  return (
    <main className="min-h-screen bg-neutral-950 px-6 py-10 text-neutral-100">
      <div className="mx-auto flex max-w-5xl items-center justify-between">
        <div>
          <p className="text-sm text-neutral-400">Signed in as</p>
          <p className="font-medium">
            {session?.user.name ?? session?.user.email}
          </p>
        </div>
        <SignOutButton />
      </div>
    </main>
  );
}
