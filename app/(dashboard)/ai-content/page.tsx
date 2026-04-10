"use client";

import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Bot,
  Settings,
  Edit3,
  RefreshCw,
  CalendarDays,
  Send,
  Trash2,
  Loader2,
  X,
  Sparkles,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { AIContentItem, NicheTag, ToneType, HookFormat, Language } from "@/types";

const NICHE_TAGS: { value: NicheTag; label: string }[] = [
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

const HOOK_FORMATS: { value: HookFormat; label: string }[] = [
  { value: "confession", label: "Confession" },
  { value: "number", label: "Number" },
  { value: "hot-take", label: "Hot Take" },
  { value: "contrarian", label: "Contrarian" },
  { value: "story", label: "Story" },
  { value: "data", label: "Data" },
  { value: "question", label: "Question" },
];

// Fallback content pool (used when API is unavailable)
const FALLBACK_POOL: AIContentItem[] = [
  {
    id: "ai1", user_id: "u1",
    content: "I stopped using hashtags on Threads 3 months ago.\n\nResult: +340% more impressions.\n\nHashtags don't boost discovery here. The algorithm promotes content based on engagement, not tags.\n\nFocus on the hook. Focus on the value.\n\nStop decorating your posts. Start writing them.",
    platform: "threads", status: "draft",
    hook_type: "confession", topic: "social-media-growth", tone: "bold",
    generated_at: new Date(Date.now() - 3600000).toISOString(), used_at: null,
  },
  {
    id: "ai2", user_id: "u1",
    content: "The #1 Google Ads mistake costing you money right now?\n\nYou're optimizing for clicks.\n\nClicks mean nothing without conversions.\n\nHere's what I changed for a client last week:\n→ Switched to tCPA bidding\n→ Removed 60% of keywords\n→ Added negative keyword lists\n\nResult: -40% CPA, +2.1x conversions.\n\nLess is more.",
    platform: "threads", status: "draft",
    hook_type: "question", topic: "google-ads", tone: "data-driven",
    generated_at: new Date(Date.now() - 7200000).toISOString(), used_at: null,
  },
  {
    id: "ai3", user_id: "u1",
    content: "Every marketer should learn to code.\n\nNot to become a developer.\nBut to understand what's possible.\n\nI learned basic Python in 2 weeks.\nNow I automate reports that used to take 4 hours.\n\nThe best marketers in 2026 aren't just creative.\nThey're technical.",
    platform: "threads", status: "draft",
    hook_type: "hot-take", topic: "personal-brand", tone: "professional",
    generated_at: new Date(Date.now() - 10800000).toISOString(), used_at: null,
  },
  {
    id: "ai4", user_id: "u1",
    content: "I analyzed 200 top-performing Threads posts in the marketing niche.\n\n5 patterns that appeared in 80%+ of them:\n\n1. First line under 8 words\n2. Uses a number or percentage\n3. Has line breaks every 1-2 sentences\n4. Ends with a question\n5. Zero hashtags\n\nSimplicity wins. Every time.",
    platform: "threads", status: "draft",
    hook_type: "data", topic: "content-marketing", tone: "data-driven",
    generated_at: new Date(Date.now() - 14400000).toISOString(), used_at: null,
  },
  {
    id: "ai5", user_id: "u1",
    content: "Unpopular opinion: You don't need a content calendar.\n\nYou need a content system.\n\nCalendars create pressure to post.\nSystems create quality content consistently.\n\nMy system:\n→ 30 min research daily\n→ 3 drafts per session\n→ Publish the best one\n→ Repurpose weekly\n\nStress-free. Consistent. Effective.",
    platform: "threads", status: "draft",
    hook_type: "contrarian", topic: "content-marketing", tone: "casual",
    generated_at: new Date(Date.now() - 18000000).toISOString(), used_at: null,
  },
  {
    id: "ai6", user_id: "u1",
    content: "AI won't replace marketers.\n\nBut marketers who use AI will replace those who don't.\n\nI use AI for:\n→ First drafts (saves 2h/day)\n→ Data analysis (instant insights)\n→ A/B test variations (10x faster)\n→ Competitor research (automated)\n\nThe tool is free. The advantage is priceless.",
    platform: "threads", status: "draft",
    hook_type: "hot-take", topic: "ai-marketing", tone: "bold",
    generated_at: new Date(Date.now() - 21600000).toISOString(), used_at: null,
  },
  {
    id: "ai7", user_id: "u1",
    content: "SEO in 2026 is not what you think.\n\nForget keyword stuffing.\nForget building 100 backlinks.\n\nHere's what actually moves the needle:\n\n→ Topical authority (cover topics deeply)\n→ User signals (dwell time > word count)\n→ AI optimization (your content needs to answer AI)\n\nAdapt or get buried on page 5.",
    platform: "threads", status: "draft",
    hook_type: "contrarian", topic: "seo", tone: "bold",
    generated_at: new Date(Date.now() - 25200000).toISOString(), used_at: null,
  },
  {
    id: "ai8", user_id: "u1",
    content: "3 years in freelance digital marketing.\n\nBiggest lesson?\n\nCharging more attracts better clients.\n\nWhen I charged €50/h: endless revisions, scope creep, late payments.\nAt €150/h: clear briefs, fast decisions, respect.\n\nYour price is your filter. Set it accordingly.",
    platform: "threads", status: "draft",
    hook_type: "story", topic: "freelancing", tone: "casual",
    generated_at: new Date(Date.now() - 28800000).toISOString(), used_at: null,
  },
];

function NicheSettingsModal({
  onClose,
}: {
  onClose: () => void;
}) {
  const [selectedTags, setSelectedTags] = useState<NicheTag[]>(["seo", "google-ads", "ai-marketing"]);
  const [selectedTone, setSelectedTone] = useState<ToneType>("bold");
  const [selectedLanguage, setSelectedLanguage] = useState<Language>("english");
  const [selectedHooks, setSelectedHooks] = useState<HookFormat[]>(["confession", "hot-take", "data"]);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      onClick={onClose}
    >
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
      <motion.div
        initial={{ scale: 0.95 }}
        animate={{ scale: 1 }}
        exit={{ scale: 0.95 }}
        onClick={(e) => e.stopPropagation()}
        className="relative glass-card p-6 w-full max-w-lg space-y-5 max-h-[90vh] overflow-y-auto"
      >
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <Settings className="w-5 h-5 text-ice-blue" />
            Content Niche Settings
          </h2>
          <button onClick={onClose} className="text-text-secondary hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Topics */}
        <div className="space-y-2">
          <span className="text-sm text-text-secondary">Topics</span>
          <div className="flex flex-wrap gap-2">
            {NICHE_TAGS.map(({ value, label }) => (
              <button
                key={value}
                onClick={() =>
                  setSelectedTags((prev) =>
                    prev.includes(value)
                      ? prev.filter((t) => t !== value)
                      : [...prev, value]
                  )
                }
                className={cn(
                  "px-3 py-1.5 rounded-full text-xs font-medium transition-smooth",
                  selectedTags.includes(value)
                    ? "bg-neon-teal/20 text-neon-teal border border-neon-teal/30"
                    : "glass-card text-text-secondary hover:text-white"
                )}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Tone */}
        <div className="space-y-2">
          <span className="text-sm text-text-secondary">Tone Preference</span>
          <div className="flex flex-wrap gap-2">
            {(["casual", "professional", "bold", "witty"] as ToneType[]).map((t) => (
              <button
                key={t}
                onClick={() => setSelectedTone(t)}
                className={cn(
                  "px-3 py-1.5 rounded-full text-xs font-medium capitalize transition-smooth",
                  selectedTone === t
                    ? "bg-neon-magenta/20 text-neon-magenta border border-neon-magenta/30"
                    : "glass-card text-text-secondary hover:text-white"
                )}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        {/* Language */}
        <div className="space-y-2">
          <span className="text-sm text-text-secondary">Language</span>
          <div className="flex gap-2">
            {([
              { value: "german" as Language, label: "German 🇩🇪" },
              { value: "english" as Language, label: "English 🇬🇧" },
              { value: "mixed" as Language, label: "Mixed" },
            ]).map(({ value, label }) => (
              <button
                key={value}
                onClick={() => setSelectedLanguage(value)}
                className={cn(
                  "px-3 py-1.5 rounded-full text-xs font-medium transition-smooth",
                  selectedLanguage === value
                    ? "bg-ice-blue/20 text-ice-blue border border-ice-blue/30"
                    : "glass-card text-text-secondary hover:text-white"
                )}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Hook Formats */}
        <div className="space-y-2">
          <span className="text-sm text-text-secondary">Preferred Hook Formats</span>
          <div className="flex flex-wrap gap-2">
            {HOOK_FORMATS.map(({ value, label }) => (
              <button
                key={value}
                onClick={() =>
                  setSelectedHooks((prev) =>
                    prev.includes(value)
                      ? prev.filter((h) => h !== value)
                      : [...prev, value]
                  )
                }
                className={cn(
                  "px-3 py-1.5 rounded-full text-xs font-medium transition-smooth",
                  selectedHooks.includes(value)
                    ? "bg-neon-teal/20 text-neon-teal border border-neon-teal/30"
                    : "glass-card text-text-secondary hover:text-white"
                )}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        <button
          onClick={onClose}
          className="w-full px-4 py-2.5 rounded-xl bg-neon-magenta text-white text-sm font-medium hover:bg-neon-magenta/90 glow-magenta transition-smooth"
        >
          Save Settings
        </button>
      </motion.div>
    </motion.div>
  );
}

export default function AIContentPage() {
  const [pool, setPool] = useState<AIContentItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showSettings, setShowSettings] = useState(false);
  const [regeneratingId, setRegeneratingId] = useState<string | null>(null);
  const [publishingId, setPublishingId] = useState<string | null>(null);

  useEffect(() => {
    async function loadPool() {
      try {
        const res = await fetch("/api/posts?status=draft&limit=10");
        if (res.ok) {
          const data = await res.json();
          if (data.posts?.length > 0) {
            setPool(data.posts.map((p: any) => ({
              id: p.id,
              user_id: p.user_id,
              content: p.content_threads || p.content_linkedin || "",
              platform: p.platforms?.[0] || "threads",
              status: "draft" as const,
              hook_type: "confession" as HookFormat,
              topic: "content-marketing",
              tone: "bold" as ToneType,
              generated_at: p.created_at,
              used_at: null,
            })));
          } else {
            setPool(FALLBACK_POOL);
          }
        } else {
          setPool(FALLBACK_POOL);
        }
      } catch {
        setPool(FALLBACK_POOL);
      } finally {
        setIsLoading(false);
      }
    }
    loadPool();
  }, []);

  const activePool = pool.filter((p) => p.status === "draft");
  const poolSize = activePool.length;
  const maxPool = 10;

  const handleTrash = useCallback((id: string) => {
    setPool((prev) => prev.map((p) => (p.id === id ? { ...p, status: "trashed" as const } : p)));
  }, []);

  const handleRegenerate = useCallback(async (id: string) => {
    setRegeneratingId(id);
    try {
      const res = await fetch("/api/ai/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          platform: "threads",
          tone: "bold",
          count: 1,
          niche_tags: ["content-marketing"],
        }),
      });
      if (!res.ok) throw new Error();
      const reader = res.body?.getReader();
      if (!reader) throw new Error();
      let result = "";
      const decoder = new TextDecoder();
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        result += decoder.decode(value, { stream: true });
      }
      setPool((prev) =>
        prev.map((p) =>
          p.id === id
            ? { ...p, content: result.trim(), generated_at: new Date().toISOString() }
            : p
        )
      );
    } catch {
      // Keep existing content on failure
    } finally {
      setRegeneratingId(null);
    }
  }, []);

  const handlePublishNow = useCallback(async (id: string) => {
    if (!confirm("Post this now to Threads?")) return;
    setPublishingId(id);
    try {
      const item = pool.find((p) => p.id === id);
      if (!item) return;
      // Create post then publish
      const createRes = await fetch("/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          content_threads: item.content,
          platforms: ["threads"],
          status: "draft",
        }),
      });
      if (createRes.ok) {
        const { post } = await createRes.json();
        await fetch("/api/posts/publish", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ postId: post.id }),
        });
      }
      setPool((prev) => prev.filter((p) => p.id !== id));
    } catch {
      // Keep in pool on failure
    } finally {
      setPublishingId(null);
    }
  }, [pool]);

  return (
    <div className="h-full flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-white flex items-center gap-2">
            <Bot className="w-6 h-6 text-neon-teal" />
            AI Ready Content
          </h1>
          <p className="text-sm text-text-secondary mt-1">
            {poolSize} posts, ready to go — curated by AI for your niche
          </p>
        </div>
        <button
          onClick={() => setShowSettings(true)}
          className="flex items-center gap-2 px-3 py-1.5 rounded-lg glass-card text-xs text-text-secondary hover:text-white transition-smooth"
        >
          <Settings className="w-3.5 h-3.5" />
          Configure Niche
        </button>
      </div>

      {/* Pool Status */}
      <div className="glass-card p-4">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-white font-medium">Content Pool</span>
          <span className="text-xs text-text-secondary font-mono">
            {poolSize}/{maxPool} posts available
          </span>
        </div>
        <div className="h-2 bg-white/5 rounded-full overflow-hidden">
          <motion.div
            className="h-full rounded-full bg-gradient-to-r from-neon-teal to-ice-blue"
            initial={{ width: 0 }}
            animate={{ width: `${(poolSize / maxPool) * 100}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
        {poolSize < 5 && (
          <p className="text-xs text-neon-teal mt-2 flex items-center gap-1 animate-pulse-glow">
            <Sparkles className="w-3 h-3" />
            Generating {maxPool - poolSize} new posts...
          </p>
        )}
      </div>

      {/* Content Grid */}
      <div className="flex-1 overflow-y-auto">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <AnimatePresence>
            {activePool.map((item) => (
              <motion.div
                key={item.id}
                layout
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9, height: 0 }}
                className="glass-card overflow-hidden"
              >
                {/* Card Header */}
                <div className="px-4 pt-4 pb-2 flex items-center justify-between">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-xs px-2 py-0.5 rounded-full bg-neon-teal/20 text-neon-teal">
                      🤖 AI Generated
                    </span>
                    <span className="text-xs px-2 py-0.5 rounded-full bg-white/5 text-text-secondary capitalize">
                      {item.topic}
                    </span>
                  </div>
                  <span className="text-xs text-text-secondary">
                    {new Date(item.generated_at).toLocaleDateString()}
                  </span>
                </div>

                {/* Hook & Tone tags */}
                <div className="px-4 pb-2 flex items-center gap-2">
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-neon-magenta/10 text-neon-magenta capitalize">
                    {item.hook_type}
                  </span>
                  <span className="text-[10px] px-2 py-0.5 rounded-full bg-ice-blue/10 text-ice-blue capitalize">
                    {item.tone}
                  </span>
                </div>

                {/* Content */}
                <div className="px-4 pb-3">
                  {regeneratingId === item.id ? (
                    <div className="space-y-2 py-4">
                      <div className="h-3 bg-white/5 rounded animate-pulse w-full" />
                      <div className="h-3 bg-white/5 rounded animate-pulse w-4/5" />
                      <div className="h-3 bg-white/5 rounded animate-pulse w-3/5" />
                      <div className="h-3 bg-white/5 rounded animate-pulse w-4/5" />
                    </div>
                  ) : (
                    <p className="text-sm text-white/90 whitespace-pre-wrap leading-relaxed">
                      {item.content}
                    </p>
                  )}
                </div>

                {/* Char count */}
                <div className="px-4 pb-2">
                  <span className="text-xs text-text-secondary font-mono">
                    {item.content.length}/500
                  </span>
                </div>

                {/* Edit / Regenerate Row */}
                <div className="px-4 py-2 border-t border-white/5 flex items-center gap-2">
                  <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg glass-card text-xs text-text-secondary hover:text-white transition-smooth">
                    <Edit3 className="w-3 h-3" /> Edit
                  </button>
                  <button
                    onClick={() => handleRegenerate(item.id)}
                    disabled={regeneratingId !== null}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg glass-card text-xs text-text-secondary hover:text-ice-blue transition-smooth disabled:opacity-40"
                  >
                    {regeneratingId === item.id ? (
                      <Loader2 className="w-3 h-3 animate-spin" />
                    ) : (
                      <RefreshCw className="w-3 h-3" />
                    )}
                    Regenerate
                  </button>
                </div>

                {/* Action Row */}
                <div className="px-4 py-3 border-t border-white/5 flex items-center gap-2">
                  <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-ice-blue/10 text-xs text-ice-blue hover:bg-ice-blue/20 transition-smooth">
                    <CalendarDays className="w-3 h-3" /> Schedule
                  </button>
                  <button
                    onClick={() => handlePublishNow(item.id)}
                    disabled={publishingId !== null}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-neon-magenta/20 text-xs text-neon-magenta hover:bg-neon-magenta/30 transition-smooth disabled:opacity-40"
                  >
                    {publishingId === item.id ? (
                      <Loader2 className="w-3 h-3 animate-spin" />
                    ) : (
                      <Send className="w-3 h-3" />
                    )}
                    Publish Now
                  </button>
                  <button
                    onClick={() => handleTrash(item.id)}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs text-text-secondary hover:text-red-400 transition-smooth ml-auto"
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </div>

      {/* Niche Settings Modal */}
      <AnimatePresence>
        {showSettings && <NicheSettingsModal onClose={() => setShowSettings(false)} />}
      </AnimatePresence>
    </div>
  );
}
