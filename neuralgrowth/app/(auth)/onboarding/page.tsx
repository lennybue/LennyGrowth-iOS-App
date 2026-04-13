"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowLeft,
  ArrowRight,
  Check,
  ChevronRight,
  Rocket,
  Sparkles,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { NicheTag, ToneType, Language } from "@/types";

const TOTAL_STEPS = 5;

const NICHE_OPTIONS: { value: NicheTag; label: string }[] = [
  { value: "seo", label: "SEO" },
  { value: "google-ads", label: "Google Ads" },
  { value: "ai-marketing", label: "AI Marketing" },
  { value: "content-marketing", label: "Content Marketing" },
  { value: "personal-brand", label: "Personal Brand" },
  { value: "social-media-growth", label: "Social Media Growth" },
  { value: "analytics", label: "Analytics" },
  { value: "conversion-rate", label: "Conversion Rate" },
  { value: "email-marketing", label: "Email Marketing" },
  { value: "freelancing", label: "Freelancing" },
];

const TONE_OPTIONS: { value: ToneType; label: string; emoji: string }[] = [
  { value: "professional", label: "Professional", emoji: "💼" },
  { value: "casual", label: "Casual", emoji: "😎" },
  { value: "bold", label: "Bold", emoji: "🔥" },
  { value: "witty", label: "Witty", emoji: "⚡" },
  { value: "inspiring", label: "Inspiring", emoji: "✨" },
  { value: "data-driven", label: "Data-Driven", emoji: "📊" },
];

const LANGUAGE_OPTIONS: { value: Language; label: string }[] = [
  { value: "english", label: "English" },
  { value: "german", label: "Deutsch" },
  { value: "mixed", label: "Mixed" },
];

const slideVariants = {
  enter: (direction: number) => ({
    x: direction > 0 ? 300 : -300,
    opacity: 0,
  }),
  center: {
    x: 0,
    opacity: 1,
  },
  exit: (direction: number) => ({
    x: direction > 0 ? -300 : 300,
    opacity: 0,
  }),
};

export default function OnboardingPage() {
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [direction, setDirection] = useState(1);

  // Step 1 & 2
  const [threadsConnected, setThreadsConnected] = useState(false);
  const [linkedinConnected, setLinkedinConnected] = useState(false);

  // Step 3
  const [selectedNiches, setSelectedNiches] = useState<NicheTag[]>([]);
  const [selectedTone, setSelectedTone] = useState<ToneType>("professional");
  const [selectedLanguage, setSelectedLanguage] = useState<Language>("english");

  const goNext = () => {
    if (step < TOTAL_STEPS) {
      setDirection(1);
      setStep((s) => s + 1);
    }
  };

  const goBack = () => {
    if (step > 1) {
      setDirection(-1);
      setStep((s) => s - 1);
    }
  };

  const toggleNiche = (niche: NicheTag) => {
    setSelectedNiches((prev) =>
      prev.includes(niche)
        ? prev.filter((n) => n !== niche)
        : [...prev, niche]
    );
  };

  const handleConnectThreads = () => {
    // TODO: Wire up Threads OAuth
    setTimeout(() => setThreadsConnected(true), 800);
  };

  const handleConnectLinkedIn = () => {
    // TODO: Wire up LinkedIn OAuth
    setTimeout(() => setLinkedinConnected(true), 800);
  };

  const canProceed = () => {
    switch (step) {
      case 1:
        return isAuthenticated;
      case 2:
        return threadsConnected;
      case 3:
        return true; // LinkedIn is optional
      case 4:
        return selectedNiches.length > 0;
      case 5:
        return true;
      default:
        return false;
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-bg-primary px-4 py-8">
      {/* Ambient glow */}
      <div className="pointer-events-none fixed inset-0 overflow-hidden">
        <div className="absolute -top-40 -left-40 h-80 w-80 rounded-full bg-neon-magenta/10 blur-[120px]" />
        <div className="absolute -bottom-40 -right-40 h-80 w-80 rounded-full bg-neon-teal/10 blur-[120px]" />
      </div>

      {/* Logo */}
      <div className="relative mb-8 text-center">
        <h1 className="text-2xl font-bold tracking-tight">
          <span className="bg-gradient-to-r from-neon-magenta via-ice-blue to-neon-teal bg-clip-text text-transparent">
            NeuralGrowth
          </span>
        </h1>
      </div>

      {/* Progress bar */}
      <div className="relative mb-8 flex w-full max-w-md items-center justify-between">
        {Array.from({ length: TOTAL_STEPS }, (_, i) => {
          const stepNum = i + 1;
          const isComplete = step > stepNum;
          const isCurrent = step === stepNum;

          return (
            <React.Fragment key={stepNum}>
              <div className="flex flex-col items-center gap-1.5">
                <div
                  className={cn(
                    "flex h-9 w-9 items-center justify-center rounded-full text-sm font-semibold transition-all duration-300",
                    isComplete &&
                      "bg-neon-teal text-bg-primary",
                    isCurrent &&
                      "bg-neon-magenta text-white shadow-[0_0_16px_rgba(255,0,110,0.4)]",
                    !isComplete &&
                      !isCurrent &&
                      "bg-white/[0.06] text-text-secondary border border-white/[0.1]"
                  )}
                >
                  {isComplete ? (
                    <Check className="h-4 w-4" />
                  ) : (
                    stepNum
                  )}
                </div>
              </div>
              {stepNum < TOTAL_STEPS && (
                <div className="mx-1 h-px flex-1">
                  <div
                    className={cn(
                      "h-full rounded-full transition-all duration-500",
                      step > stepNum
                        ? "bg-neon-teal"
                        : "bg-white/[0.08]"
                    )}
                  />
                </div>
              )}
            </React.Fragment>
          );
        })}
      </div>

      {/* Step content */}
      <div className="relative w-full max-w-md overflow-hidden" style={{ minHeight: 380 }}>
        <AnimatePresence mode="wait" custom={direction}>
          <motion.div
            key={step}
            custom={direction}
            variants={slideVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
            className="w-full"
          >
            {/* Step 1: Create Account */}
            {step === 1 && (
              <div className="glass-card p-6 sm:p-8">
                <div className="mb-6 text-center">
                  <h2 className="text-xl font-semibold text-white">
                    Create your account
                  </h2>
                  <p className="mt-2 text-sm text-text-secondary">
                    Sign up to start using NeuralGrowth.
                  </p>
                </div>

                {authError && (
                  <div className="mb-4 rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-2.5 text-sm text-red-400">
                    {authError}
                  </div>
                )}

                {isAuthenticated ? (
                  <div className="flex items-center justify-center gap-2 rounded-xl bg-neon-teal/10 border border-neon-teal/30 py-3 text-sm font-medium text-neon-teal">
                    <Check className="h-4 w-4" />
                    Account created
                  </div>
                ) : (
                  <form onSubmit={handleCreateAccount} className="space-y-4">
                    <div>
                      <label className="mb-1.5 block text-sm font-medium text-text-secondary">
                        Email
                      </label>
                      <input
                        type="email"
                        required
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        placeholder="you@example.com"
                        className={cn(
                          "w-full rounded-xl bg-white/[0.04] border border-white/[0.08] py-2.5 px-4 text-sm text-white",
                          "placeholder:text-text-secondary/60",
                          "focus:outline-none focus:ring-2 focus:ring-neon-magenta/40 focus:border-neon-magenta/50",
                          "transition-all"
                        )}
                      />
                    </div>
                    <div>
                      <label className="mb-1.5 block text-sm font-medium text-text-secondary">
                        Password
                      </label>
                      <input
                        type="password"
                        required
                        minLength={6}
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="Minimum 6 characters"
                        className={cn(
                          "w-full rounded-xl bg-white/[0.04] border border-white/[0.08] py-2.5 px-4 text-sm text-white",
                          "placeholder:text-text-secondary/60",
                          "focus:outline-none focus:ring-2 focus:ring-neon-magenta/40 focus:border-neon-magenta/50",
                          "transition-all"
                        )}
                      />
                    </div>
                    <button
                      type="submit"
                      disabled={isCreating}
                      className={cn(
                        "flex w-full items-center justify-center gap-2 rounded-xl bg-neon-magenta py-2.5 text-sm font-semibold text-white",
                        "hover:bg-neon-magenta/90 active:scale-[0.98]",
                        "disabled:opacity-60 disabled:cursor-not-allowed",
                        "transition-all duration-200"
                      )}
                    >
                      {isCreating ? (
                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                      ) : (
                        <>
                          Create Account
                          <ArrowRight className="h-4 w-4" />
                        </>
                      )}
                    </button>
                  </form>
                )}
              </div>
            )}

            {/* Step 2: Connect Threads */}
            {step === 2 && (
              <div className="glass-card p-6 sm:p-8">
                <div className="mb-6 text-center">
                  <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-white/[0.06]">
                    <svg
                      viewBox="0 0 24 24"
                      className="h-7 w-7 text-white"
                      fill="currentColor"
                    >
                      <path d="M12.186 24h-.007c-3.581-.024-6.334-1.205-8.184-3.509C2.35 18.44 1.5 15.586 1.472 12.01v-.017c.03-3.579.879-6.43 2.525-8.482C5.845 1.205 8.6.024 12.18 0h.014c2.746.02 5.043.725 6.826 2.098 1.677 1.29 2.858 3.13 3.509 5.467l-2.04.569c-1.104-3.96-3.898-5.984-8.304-6.015-2.91.022-5.11.936-6.54 2.717C4.307 6.504 3.616 8.914 3.59 12c.025 3.083.718 5.496 2.057 7.164 1.432 1.784 3.631 2.698 6.54 2.717 2.623-.02 4.358-.631 5.8-2.045 1.647-1.613 1.618-3.593 1.09-4.798-.31-.71-.873-1.3-1.634-1.706-.163 1.7-.678 3.033-1.534 3.97-1.04 1.139-2.552 1.715-4.496 1.715h-.105c-1.311-.015-2.442-.454-3.267-1.27-.857-.847-1.314-2.018-1.314-3.384 0-2.727 1.88-5.57 5.022-5.57 1.248 0 2.27.393 3.04 1.168.648.654 1.074 1.544 1.265 2.628.488-.254.948-.59 1.354-1.003 1.155-1.173 1.62-2.877 1.382-5.072l2.018-.222c.307 2.81-.35 5.078-1.955 6.698-.523.529-1.12.952-1.77 1.264.043.595.012 1.2-.095 1.793-.297 1.647-1.13 3.063-2.402 4.093-1.564 1.266-3.637 1.91-6.164 1.916h-.006c-.22 0-.445-.003-.671-.01zm1.37-7.66c.702 0 1.258-.196 1.652-.583.452-.443.756-1.154.9-2.112-.235-.068-.49-.106-.764-.106-1.724 0-2.905 1.52-2.905 3.452 0 .653.177 1.155.513 1.453.28.25.656.378 1.09.39.175-.004.346-.02.514-.044v-.45z" />
                    </svg>
                  </div>
                  <h2 className="text-xl font-semibold text-white">
                    Connect Threads
                  </h2>
                  <p className="mt-2 text-sm text-text-secondary">
                    Link your Threads account to publish posts and track
                    engagement.
                  </p>
                </div>

                {threadsConnected ? (
                  <div className="flex items-center justify-center gap-2 rounded-xl bg-neon-teal/10 border border-neon-teal/30 py-3 text-sm font-medium text-neon-teal">
                    <Check className="h-4 w-4" />
                    Threads connected
                  </div>
                ) : (
                  <button
                    onClick={handleConnectThreads}
                    className={cn(
                      "flex w-full items-center justify-center gap-2 rounded-xl bg-white py-3 text-sm font-semibold text-black",
                      "hover:bg-white/90 active:scale-[0.98]",
                      "transition-all duration-200"
                    )}
                  >
                    Connect Threads
                    <ChevronRight className="h-4 w-4" />
                  </button>
                )}
              </div>
            )}

            {/* Step 3: Connect LinkedIn */}
            {step === 3 && (
              <div className="glass-card p-6 sm:p-8">
                <div className="mb-6 text-center">
                  <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#0A66C2]/20">
                    <svg
                      viewBox="0 0 24 24"
                      className="h-7 w-7 text-[#0A66C2]"
                      fill="currentColor"
                    >
                      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 01-2.063-2.065 2.064 2.064 0 112.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
                    </svg>
                  </div>
                  <h2 className="text-xl font-semibold text-white">
                    Connect LinkedIn
                  </h2>
                  <p className="mt-2 text-sm text-text-secondary">
                    Cross-post your content to LinkedIn for maximum reach.
                  </p>
                </div>

                {linkedinConnected ? (
                  <div className="flex items-center justify-center gap-2 rounded-xl bg-neon-teal/10 border border-neon-teal/30 py-3 text-sm font-medium text-neon-teal">
                    <Check className="h-4 w-4" />
                    LinkedIn connected
                  </div>
                ) : (
                  <div className="space-y-3">
                    <button
                      onClick={handleConnectLinkedIn}
                      className={cn(
                        "flex w-full items-center justify-center gap-2 rounded-xl bg-[#0A66C2] py-3 text-sm font-semibold text-white",
                        "hover:bg-[#0A66C2]/90 active:scale-[0.98]",
                        "transition-all duration-200"
                      )}
                    >
                      Connect LinkedIn
                      <ChevronRight className="h-4 w-4" />
                    </button>
                    <button
                      onClick={goNext}
                      className="w-full text-center text-sm text-text-secondary hover:text-white transition-colors"
                    >
                      Skip for now
                    </button>
                  </div>
                )}
              </div>
            )}

            {/* Step 4: Niche topics + tone + language */}
            {step === 4 && (
              <div className="glass-card p-6 sm:p-8">
                <div className="mb-5 text-center">
                  <h2 className="text-xl font-semibold text-white">
                    Set your niche topics
                  </h2>
                  <p className="mt-2 text-sm text-text-secondary">
                    Help AI generate content tailored to your audience.
                  </p>
                </div>

                {/* Niche pills */}
                <div className="mb-6">
                  <label className="mb-2 block text-xs font-medium uppercase tracking-wider text-text-secondary">
                    Topics
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {NICHE_OPTIONS.map((niche) => {
                      const selected = selectedNiches.includes(niche.value);
                      return (
                        <button
                          key={niche.value}
                          onClick={() => toggleNiche(niche.value)}
                          className={cn(
                            "rounded-full px-3.5 py-1.5 text-sm font-medium transition-all duration-200",
                            selected
                              ? "bg-neon-magenta/20 border border-neon-magenta/50 text-neon-magenta"
                              : "bg-white/[0.04] border border-white/[0.1] text-text-secondary hover:border-white/[0.2] hover:text-white"
                          )}
                        >
                          {niche.label}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Tone preference */}
                <div className="mb-6">
                  <label className="mb-2 block text-xs font-medium uppercase tracking-wider text-text-secondary">
                    Tone preference
                  </label>
                  <div className="grid grid-cols-3 gap-2">
                    {TONE_OPTIONS.map((tone) => (
                      <button
                        key={tone.value}
                        onClick={() => setSelectedTone(tone.value)}
                        className={cn(
                          "flex items-center justify-center gap-1.5 rounded-xl px-3 py-2 text-sm font-medium transition-all duration-200",
                          selectedTone === tone.value
                            ? "bg-ice-blue/20 border border-ice-blue/50 text-ice-blue"
                            : "bg-white/[0.04] border border-white/[0.1] text-text-secondary hover:border-white/[0.2] hover:text-white"
                        )}
                      >
                        <span>{tone.emoji}</span>
                        <span>{tone.label}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Language */}
                <div>
                  <label className="mb-2 block text-xs font-medium uppercase tracking-wider text-text-secondary">
                    Language
                  </label>
                  <div className="flex gap-2">
                    {LANGUAGE_OPTIONS.map((lang) => (
                      <button
                        key={lang.value}
                        onClick={() => setSelectedLanguage(lang.value)}
                        className={cn(
                          "flex-1 rounded-xl px-3 py-2 text-sm font-medium transition-all duration-200",
                          selectedLanguage === lang.value
                            ? "bg-neon-teal/20 border border-neon-teal/50 text-neon-teal"
                            : "bg-white/[0.04] border border-white/[0.1] text-text-secondary hover:border-white/[0.2] hover:text-white"
                        )}
                      >
                        {lang.label}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Step 5: Success */}
            {step === 5 && (
              <div className="glass-card p-6 sm:p-8 text-center">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{
                    type: "spring",
                    stiffness: 200,
                    damping: 15,
                    delay: 0.1,
                  }}
                  className="mx-auto mb-6 flex h-20 w-20 items-center justify-center rounded-full bg-gradient-to-br from-neon-magenta to-neon-teal"
                >
                  <Rocket className="h-10 w-10 text-white" />
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                >
                  <h2 className="text-2xl font-bold text-white">
                    Your AI pool is ready!
                  </h2>
                  <p className="mt-3 text-sm text-text-secondary">
                    NeuralGrowth will generate content tailored to your niche,
                    tone, and audience. Let&apos;s start creating.
                  </p>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5 }}
                  className="mt-8"
                >
                  <button
                    onClick={() => router.push("/ai-content")}
                    className={cn(
                      "flex w-full items-center justify-center gap-2 rounded-xl bg-neon-magenta py-3 text-sm font-semibold text-white",
                      "hover:bg-neon-magenta/90 active:scale-[0.98]",
                      "shadow-[0_0_24px_rgba(255,0,110,0.3)]",
                      "transition-all duration-200"
                    )}
                  >
                    <Sparkles className="h-4 w-4" />
                    Go to AI Content
                  </button>
                </motion.div>

                {/* Animated particles */}
                <div className="pointer-events-none absolute inset-0 overflow-hidden rounded-2xl">
                  {Array.from({ length: 6 }, (_, i) => (
                    <motion.div
                      key={i}
                      className="absolute h-1 w-1 rounded-full bg-neon-teal"
                      initial={{
                        x: "50%",
                        y: "40%",
                        scale: 0,
                        opacity: 1,
                      }}
                      animate={{
                        x: `${20 + Math.random() * 60}%`,
                        y: `${10 + Math.random() * 80}%`,
                        scale: [0, 1.5, 0],
                        opacity: [1, 1, 0],
                      }}
                      transition={{
                        duration: 1.5,
                        delay: 0.2 + i * 0.15,
                        ease: "easeOut",
                      }}
                    />
                  ))}
                </div>
              </div>
            )}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Navigation buttons */}
      {step < TOTAL_STEPS && (
        <div className="relative mt-6 flex w-full max-w-md items-center justify-between">
          <button
            onClick={goBack}
            disabled={step === 1}
            className={cn(
              "flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-medium text-text-secondary transition-colors",
              step === 1
                ? "invisible"
                : "hover:text-white"
            )}
          >
            <ArrowLeft className="h-4 w-4" />
            Back
          </button>

          <button
            onClick={goNext}
            disabled={!canProceed()}
            className={cn(
              "flex items-center gap-1.5 rounded-xl bg-neon-magenta px-6 py-2.5 text-sm font-semibold text-white",
              "hover:bg-neon-magenta/90 active:scale-[0.98]",
              "disabled:opacity-40 disabled:cursor-not-allowed",
              "transition-all duration-200"
            )}
          >
            Next
            <ArrowRight className="h-4 w-4" />
          </button>
        </div>
      )}
    </div>
  );
}
