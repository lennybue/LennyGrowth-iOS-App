"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";
import { Mail, Lock, ArrowRight, Sparkles } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const supabase = createClient();

  // Sign-in form state
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSigningIn, setIsSigningIn] = useState(false);

  // Magic link form state
  const [magicEmail, setMagicEmail] = useState("");
  const [magicSent, setMagicSent] = useState(false);
  const [isSendingMagic, setIsSendingMagic] = useState(false);

  const [showMagicLink, setShowMagicLink] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSigningIn(true);
    setError(null);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      setError(error.message);
      setIsSigningIn(false);
    } else {
      router.push("/compose");
      router.refresh();
    }
  };

  const handleMagicLink = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSendingMagic(true);
    setError(null);
    const { error } = await supabase.auth.signInWithOtp({
      email: magicEmail,
      options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
    });
    if (error) {
      setError(error.message);
      setIsSendingMagic(false);
    } else {
      setIsSendingMagic(false);
      setMagicSent(true);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-bg-primary px-4">
      {/* Ambient glow */}
      <div className="pointer-events-none fixed inset-0 overflow-hidden">
        <div className="absolute -top-40 -left-40 h-80 w-80 rounded-full bg-neon-magenta/10 blur-[120px]" />
        <div className="absolute -bottom-40 -right-40 h-80 w-80 rounded-full bg-neon-teal/10 blur-[120px]" />
      </div>

      <div className="relative w-full max-w-md">
        {/* Logo */}
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold tracking-tight">
            <span className="bg-gradient-to-r from-neon-magenta via-ice-blue to-neon-teal bg-clip-text text-transparent">
              NeuralGrowth
            </span>
          </h1>
          <p className="mt-2 text-sm text-text-secondary">
            AI Social Media Command Center
          </p>
        </div>

        {/* Card */}
        <div className="glass-card p-6 sm:p-8">
          {error && (
            <div className="mb-4 rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-2.5 text-sm text-red-400">
              {error}
            </div>
          )}
          {!showMagicLink ? (
            <>
              <form onSubmit={handleSignIn} className="space-y-4">
                {/* Email */}
                <div>
                  <label
                    htmlFor="email"
                    className="mb-1.5 block text-sm font-medium text-text-secondary"
                  >
                    Email
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
                    <input
                      id="email"
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      className={cn(
                        "w-full rounded-xl bg-white/[0.04] border border-white/[0.08] py-2.5 pl-10 pr-4 text-sm text-white",
                        "placeholder:text-text-secondary/60",
                        "focus:outline-none focus:ring-2 focus:ring-neon-magenta/40 focus:border-neon-magenta/50",
                        "transition-all"
                      )}
                    />
                  </div>
                </div>

                {/* Password */}
                <div>
                  <label
                    htmlFor="password"
                    className="mb-1.5 block text-sm font-medium text-text-secondary"
                  >
                    Password
                  </label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
                    <input
                      id="password"
                      type="password"
                      required
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Enter your password"
                      className={cn(
                        "w-full rounded-xl bg-white/[0.04] border border-white/[0.08] py-2.5 pl-10 pr-4 text-sm text-white",
                        "placeholder:text-text-secondary/60",
                        "focus:outline-none focus:ring-2 focus:ring-neon-magenta/40 focus:border-neon-magenta/50",
                        "transition-all"
                      )}
                    />
                  </div>
                </div>

                {/* Sign In button */}
                <button
                  type="submit"
                  disabled={isSigningIn}
                  className={cn(
                    "flex w-full items-center justify-center gap-2 rounded-xl bg-neon-magenta py-2.5 text-sm font-semibold text-white",
                    "hover:bg-neon-magenta/90 active:scale-[0.98]",
                    "disabled:opacity-60 disabled:cursor-not-allowed",
                    "transition-all duration-200"
                  )}
                >
                  {isSigningIn ? (
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                  ) : (
                    <>
                      Sign In
                      <ArrowRight className="h-4 w-4" />
                    </>
                  )}
                </button>
              </form>

              {/* Divider */}
              <div className="my-6 flex items-center gap-3">
                <div className="h-px flex-1 bg-white/[0.08]" />
                <span className="text-xs text-text-secondary">or</span>
                <div className="h-px flex-1 bg-white/[0.08]" />
              </div>

              {/* Magic link toggle */}
              <button
                onClick={() => setShowMagicLink(true)}
                className={cn(
                  "flex w-full items-center justify-center gap-2 rounded-xl border border-white/[0.12] py-2.5 text-sm font-medium text-text-secondary",
                  "hover:border-neon-teal/40 hover:text-neon-teal",
                  "transition-all duration-200"
                )}
              >
                <Sparkles className="h-4 w-4" />
                Sign in with magic link
              </button>
            </>
          ) : (
            <>
              {!magicSent ? (
                <form onSubmit={handleMagicLink} className="space-y-4">
                  <p className="text-sm text-text-secondary">
                    Enter your email and we will send you a magic sign-in link.
                  </p>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
                    <input
                      type="email"
                      required
                      value={magicEmail}
                      onChange={(e) => setMagicEmail(e.target.value)}
                      placeholder="you@example.com"
                      className={cn(
                        "w-full rounded-xl bg-white/[0.04] border border-white/[0.08] py-2.5 pl-10 pr-4 text-sm text-white",
                        "placeholder:text-text-secondary/60",
                        "focus:outline-none focus:ring-2 focus:ring-neon-teal/40 focus:border-neon-teal/50",
                        "transition-all"
                      )}
                    />
                  </div>
                  <button
                    type="submit"
                    disabled={isSendingMagic}
                    className={cn(
                      "flex w-full items-center justify-center gap-2 rounded-xl border border-neon-teal/50 bg-neon-teal/10 py-2.5 text-sm font-semibold text-neon-teal",
                      "hover:bg-neon-teal/20 active:scale-[0.98]",
                      "disabled:opacity-60 disabled:cursor-not-allowed",
                      "transition-all duration-200"
                    )}
                  >
                    {isSendingMagic ? (
                      <div className="h-4 w-4 animate-spin rounded-full border-2 border-neon-teal/30 border-t-neon-teal" />
                    ) : (
                      <>
                        Send Magic Link
                        <Sparkles className="h-4 w-4" />
                      </>
                    )}
                  </button>
                </form>
              ) : (
                <div className="py-4 text-center">
                  <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-neon-teal/20">
                    <Mail className="h-6 w-6 text-neon-teal" />
                  </div>
                  <p className="text-sm font-medium text-white">
                    Check your email
                  </p>
                  <p className="mt-1 text-xs text-text-secondary">
                    We sent a magic link to {magicEmail}
                  </p>
                </div>
              )}

              {/* Back to password */}
              <button
                onClick={() => {
                  setShowMagicLink(false);
                  setMagicSent(false);
                }}
                className="mt-4 w-full text-center text-xs text-text-secondary hover:text-white transition-colors"
              >
                Back to password sign in
              </button>
            </>
          )}

          {/* Create account link */}
          <p className="mt-6 text-center text-sm text-text-secondary">
            Don&apos;t have an account?{" "}
            <Link
              href="/onboarding"
              className="font-medium text-neon-magenta hover:text-neon-magenta/80 transition-colors"
            >
              Create Account
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
