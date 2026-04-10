"use client";

import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Send,
  Save,
  CalendarDays,
  Trash2,
  Sparkles,
  Target,
  Megaphone,
  Scissors,
  BookOpen,
  RefreshCw,
  Lightbulb,
  Smile,
  Building2,
  Flame,
  SplitSquareHorizontal,
  Undo2,
  ImagePlus,
  X,
  Loader2,
  ChevronDown,
  AlertTriangle,
  Info,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { Platform, ToneType, RefinementAction } from "@/types";

const PLATFORM_LIMITS = { threads: 500, linkedin: 3000 };

const REFINEMENT_ACTIONS: { action: RefinementAction; label: string; icon: React.ReactNode }[] = [
  { action: "auto-refine", label: "Auto Refine", icon: <Sparkles className="w-3.5 h-3.5" /> },
  { action: "stronger-hook", label: "Stronger Hook", icon: <Target className="w-3.5 h-3.5" /> },
  { action: "stronger-cta", label: "Stronger CTA", icon: <Megaphone className="w-3.5 h-3.5" /> },
  { action: "shorten", label: "Shorten", icon: <Scissors className="w-3.5 h-3.5" /> },
  { action: "expand", label: "Expand", icon: <BookOpen className="w-3.5 h-3.5" /> },
  { action: "tighten", label: "Tighten", icon: <Target className="w-3.5 h-3.5" /> },
  { action: "rewrite", label: "Rewrite", icon: <RefreshCw className="w-3.5 h-3.5" /> },
  { action: "add-value", label: "Add Value", icon: <Lightbulb className="w-3.5 h-3.5" /> },
  { action: "more-casual", label: "More Casual", icon: <Smile className="w-3.5 h-3.5" /> },
  { action: "more-professional", label: "More Professional", icon: <Building2 className="w-3.5 h-3.5" /> },
  { action: "make-viral", label: "Make it Viral", icon: <Flame className="w-3.5 h-3.5" /> },
  { action: "split-thread", label: "Split into Thread", icon: <SplitSquareHorizontal className="w-3.5 h-3.5" /> },
];

const TONES: { value: ToneType; label: string }[] = [
  { value: "professional", label: "Professional" },
  { value: "casual", label: "Casual" },
  { value: "bold", label: "Bold" },
  { value: "witty", label: "Witty" },
  { value: "inspiring", label: "Inspiring" },
  { value: "data-driven", label: "Data-Driven" },
];

function ThreadsPreview({ content }: { content: string }) {
  return (
    <div className="glass-card p-4 space-y-3">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-neon-magenta to-purple-600 flex items-center justify-center text-white font-bold text-sm">
          LB
        </div>
        <div>
          <p className="text-white font-semibold text-sm">growthbylenny</p>
          <p className="text-text-secondary text-xs">Just now</p>
        </div>
      </div>
      <p className="text-white text-sm whitespace-pre-wrap leading-relaxed">
        {content || <span className="text-text-secondary italic">Your post preview will appear here...</span>}
      </p>
      <div className="flex items-center gap-6 text-text-secondary text-xs pt-2 border-t border-white/5">
        <span>♡ 0</span>
        <span>💬 0</span>
        <span>⟳ 0</span>
        <span>✉ 0</span>
      </div>
    </div>
  );
}

function LinkedInPreview({ content }: { content: string }) {
  return (
    <div className="glass-card p-4 space-y-3">
      <div className="flex items-center gap-3">
        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-ice-blue to-blue-600 flex items-center justify-center text-white font-bold text-sm">
          LB
        </div>
        <div>
          <p className="text-white font-semibold text-sm">Lennard Büssow</p>
          <p className="text-text-secondary text-xs">Digital Marketing Specialist · IT-Consultant</p>
          <p className="text-text-secondary text-xs">Just now · 🌐</p>
        </div>
      </div>
      <p className="text-white text-sm whitespace-pre-wrap leading-relaxed">
        {content || <span className="text-text-secondary italic">Your LinkedIn post preview will appear here...</span>}
      </p>
      <div className="flex items-center gap-4 text-text-secondary text-xs pt-3 border-t border-white/5">
        <span>👍 Like</span>
        <span>💬 Comment</span>
        <span>⟳ Repost</span>
        <span>✉ Send</span>
      </div>
    </div>
  );
}

export default function ComposePage() {
  const [platform, setPlatform] = useState<Platform>("threads");
  const [content, setContent] = useState("");
  const [tone, setTone] = useState<ToneType>("professional");
  const [isRefining, setIsRefining] = useState<RefinementAction | null>(null);
  const [undoStack, setUndoStack] = useState<string[]>([]);
  const [showCustomPrompt, setShowCustomPrompt] = useState(false);
  const [customInstruction, setCustomInstruction] = useState("");
  const [mediaFiles, setMediaFiles] = useState<string[]>([]);
  const [showScheduleModal, setShowScheduleModal] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);

  const charLimit = platform === "linkedin" ? PLATFORM_LIMITS.linkedin : PLATFORM_LIMITS.threads;
  const charCount = content.length;
  const isNearLimit = platform === "threads" ? charCount >= 450 : charCount >= 2800;
  const isOverLimit = charCount > charLimit;

  // Detect hashtags in threads mode
  const hasHashtag = platform !== "linkedin" && content.includes("#");
  // Detect URLs
  const hasUrl = platform !== "linkedin" && /https?:\/\/[^\s]+/.test(content);

  const handleRefine = useCallback(
    async (action: RefinementAction) => {
      if (!content.trim()) return;
      setIsRefining(action);
      setUndoStack((prev) => [...prev.slice(-9), content]);

      try {
        const res = await fetch("/api/ai/refine", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ content, action, platform, tone }),
        });

        if (!res.ok) throw new Error("Refinement failed");

        const reader = res.body?.getReader();
        if (!reader) throw new Error("No stream");

        let result = "";
        const decoder = new TextDecoder();
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          result += decoder.decode(value, { stream: true });
          setContent(result);
        }
      } catch {
        // Restore on error
      } finally {
        setIsRefining(null);
      }
    },
    [content, platform, tone]
  );

  const handleUndo = useCallback(() => {
    if (undoStack.length === 0) return;
    const prev = undoStack[undoStack.length - 1];
    setUndoStack((s) => s.slice(0, -1));
    setContent(prev);
  }, [undoStack]);

  const handleSaveDraft = async () => {
    setIsSaving(true);
    try {
      await fetch("/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          content_threads: platform !== "linkedin" ? content : null,
          content_linkedin: platform !== "threads" ? content : null,
          platforms: platform === "both" ? ["threads", "linkedin"] : [platform],
          status: "draft",
        }),
      });
    } finally {
      setIsSaving(false);
    }
  };

  const handlePublish = async () => {
    if (!confirm("Publish this post now?")) return;
    setIsPublishing(true);
    try {
      const postRes = await fetch("/api/posts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          content_threads: platform !== "linkedin" ? content : null,
          content_linkedin: platform !== "threads" ? content : null,
          platforms: platform === "both" ? ["threads", "linkedin"] : [platform],
          status: "draft",
        }),
      });
      const post = await postRes.json();
      await fetch("/api/posts/publish", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ postId: post.id }),
      });
      setContent("");
    } finally {
      setIsPublishing(false);
    }
  };

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
        e.preventDefault();
        handlePublish();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === "s") {
        e.preventDefault();
        handleSaveDraft();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === "z" && undoStack.length > 0) {
        e.preventDefault();
        handleUndo();
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  });

  return (
    <div className="h-full flex flex-col">
      {/* Platform Selector */}
      <div className="flex items-center gap-2 mb-6">
        {(["threads", "linkedin", "both"] as Platform[]).map((p) => (
          <button
            key={p}
            onClick={() => setPlatform(p)}
            className={cn(
              "px-4 py-2 rounded-full text-sm font-medium transition-smooth",
              platform === p
                ? "bg-neon-magenta text-white glow-magenta"
                : "glass-card text-text-secondary hover:text-white"
            )}
          >
            {p === "threads" && "🧵 Threads"}
            {p === "linkedin" && "💼 LinkedIn"}
            {p === "both" && "⚡ Both"}
          </button>
        ))}
      </div>

      {/* Main Grid: Editor + Preview */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-5 gap-6 min-h-0">
        {/* Editor Column */}
        <div className="lg:col-span-3 flex flex-col gap-4 min-h-0">
          {/* Warnings */}
          <AnimatePresence>
            {hasHashtag && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-neon-magenta/10 border border-neon-magenta/20 text-sm"
              >
                <AlertTriangle className="w-4 h-4 text-neon-magenta shrink-0" />
                <span className="text-neon-magenta">Hashtags reduce reach on Threads. Remove them for better performance.</span>
              </motion.div>
            )}
            {hasUrl && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-yellow-500/10 border border-yellow-500/20 text-sm"
              >
                <AlertTriangle className="w-4 h-4 text-yellow-500 shrink-0" />
                <span className="text-yellow-500">Links hurt reach on Threads. Use &quot;link in bio&quot; instead.</span>
              </motion.div>
            )}
            {platform === "linkedin" && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                className="flex items-center gap-2 px-4 py-2 rounded-lg bg-ice-blue/10 border border-ice-blue/20 text-sm"
              >
                <Info className="w-4 h-4 text-ice-blue shrink-0" />
                <span className="text-ice-blue">Tip: Add your link as the first comment within 60 seconds of posting.</span>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Textarea */}
          <div className="relative flex-1 min-h-[200px]">
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder={
                platform === "linkedin"
                  ? "Write your LinkedIn post..."
                  : "Write your Threads post..."
              }
              className={cn(
                "w-full h-full min-h-[200px] resize-none rounded-2xl p-4 pb-8",
                "bg-white/[0.04] border border-white/[0.08] backdrop-blur-xl",
                "text-white placeholder:text-text-secondary/50",
                "focus:outline-none focus:border-neon-magenta/40 focus:ring-1 focus:ring-neon-magenta/20",
                "transition-smooth text-sm leading-relaxed"
              )}
            />
            <div
              className={cn(
                "absolute bottom-3 right-4 text-xs font-mono",
                isOverLimit
                  ? "text-red-500"
                  : isNearLimit
                  ? "text-neon-magenta"
                  : "text-text-secondary"
              )}
            >
              {charCount}/{charLimit}
            </div>
          </div>

          {/* Media Upload */}
          <div className="flex items-center gap-2">
            <label className="flex items-center gap-2 px-3 py-2 rounded-lg glass-card glass-card-hover cursor-pointer text-sm text-text-secondary hover:text-white transition-smooth">
              <ImagePlus className="w-4 h-4" />
              Add Image
              <input
                type="file"
                accept="image/*"
                multiple={platform !== "linkedin"}
                className="hidden"
                onChange={async (e) => {
                  const files = Array.from(e.target.files || []);
                  for (const file of files) {
                    const formData = new FormData();
                    formData.append("file", file);
                    try {
                      const res = await fetch("/api/upload", { method: "POST", body: formData });
                      if (res.ok) {
                        const { url } = await res.json();
                        setMediaFiles((prev) => [...prev, url].slice(0, platform === "linkedin" ? 1 : 4));
                      }
                    } catch {
                      // Fallback to local blob URL
                      setMediaFiles((prev) => [...prev, URL.createObjectURL(file)].slice(0, platform === "linkedin" ? 1 : 4));
                    }
                  }
                }}
              />
            </label>
            {mediaFiles.map((url, i) => (
              <div key={i} className="relative w-12 h-12 rounded-lg overflow-hidden">
                <img src={url} alt="" className="w-full h-full object-cover" />
                <button
                  onClick={() => setMediaFiles((prev) => prev.filter((_, j) => j !== i))}
                  className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center"
                >
                  <X className="w-3 h-3 text-white" />
                </button>
              </div>
            ))}
          </div>

          {/* AI Refinement Toolbar */}
          <div className="space-y-3">
            <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-thin">
              {REFINEMENT_ACTIONS.filter(
                (a) => a.action !== "split-thread" || platform !== "linkedin"
              ).map(({ action, label, icon }) => (
                <button
                  key={action}
                  onClick={() => handleRefine(action)}
                  disabled={isRefining !== null || !content.trim()}
                  className={cn(
                    "flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap",
                    "glass-card glass-card-hover transition-smooth",
                    "disabled:opacity-40 disabled:cursor-not-allowed",
                    isRefining === action
                      ? "border-neon-magenta/40 text-neon-magenta"
                      : "text-text-secondary hover:text-white"
                  )}
                >
                  {isRefining === action ? (
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    icon
                  )}
                  {label}
                </button>
              ))}
            </div>

            {/* Undo button */}
            {undoStack.length > 0 && (
              <button
                onClick={handleUndo}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium text-neon-teal glass-card hover:bg-neon-teal/10 transition-smooth"
              >
                <Undo2 className="w-3.5 h-3.5" />
                Undo ({undoStack.length})
              </button>
            )}
          </div>

          {/* Tone Selector */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs text-text-secondary">Tone:</span>
            {TONES.map(({ value, label }) => (
              <button
                key={value}
                onClick={() => setTone(value)}
                className={cn(
                  "px-3 py-1 rounded-full text-xs font-medium transition-smooth",
                  tone === value
                    ? "bg-neon-teal/20 text-neon-teal border border-neon-teal/30"
                    : "glass-card text-text-secondary hover:text-white"
                )}
              >
                {label}
              </button>
            ))}
          </div>

          {/* Custom AI Prompt */}
          <div>
            <button
              onClick={() => setShowCustomPrompt(!showCustomPrompt)}
              className="flex items-center gap-2 text-xs text-text-secondary hover:text-white transition-smooth"
            >
              <ChevronDown
                className={cn("w-3.5 h-3.5 transition-transform", showCustomPrompt && "rotate-180")}
              />
              Custom AI Instruction
            </button>
            <AnimatePresence>
              {showCustomPrompt && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: "auto" }}
                  exit={{ opacity: 0, height: 0 }}
                  className="mt-2 space-y-2"
                >
                  <textarea
                    value={customInstruction}
                    onChange={(e) => setCustomInstruction(e.target.value.slice(0, 200))}
                    placeholder="What should the AI do?"
                    className="w-full h-20 resize-none rounded-xl p-3 bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-text-secondary/50 focus:outline-none focus:border-neon-magenta/40 text-sm"
                  />
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-text-secondary">{customInstruction.length}/200</span>
                    <button
                      onClick={() => handleRefine("auto-refine")}
                      disabled={!customInstruction.trim() || !content.trim()}
                      className="px-3 py-1.5 rounded-lg bg-neon-magenta text-white text-xs font-medium disabled:opacity-40"
                    >
                      Generate with this instruction
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Post Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-white/5">
            <button
              onClick={handleSaveDraft}
              disabled={!content.trim() || isSaving}
              className="flex items-center gap-2 px-4 py-2 rounded-xl glass-card glass-card-hover text-sm font-medium text-text-secondary hover:text-white transition-smooth disabled:opacity-40"
            >
              {isSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
              Save Draft
            </button>
            <button
              onClick={() => setShowScheduleModal(true)}
              disabled={!content.trim()}
              className="flex items-center gap-2 px-4 py-2 rounded-xl glass-card glass-card-hover text-sm font-medium text-ice-blue hover:text-white transition-smooth disabled:opacity-40"
            >
              <CalendarDays className="w-4 h-4" />
              Schedule
            </button>
            <button
              onClick={handlePublish}
              disabled={!content.trim() || isPublishing || isOverLimit}
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-neon-magenta text-white text-sm font-medium hover:bg-neon-magenta/90 glow-magenta transition-smooth disabled:opacity-40"
            >
              {isPublishing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
              Publish Now
            </button>
            <button
              onClick={() => {
                if (content.trim() && confirm("Discard this post?")) {
                  setContent("");
                  setUndoStack([]);
                }
              }}
              className="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium text-text-secondary hover:text-red-400 transition-smooth ml-auto"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Preview Column */}
        <div className="lg:col-span-2 space-y-4 min-h-0 overflow-y-auto">
          <h3 className="text-sm font-semibold text-text-secondary uppercase tracking-wider">Preview</h3>
          {(platform === "threads" || platform === "both") && (
            <div>
              {platform === "both" && (
                <span className="text-xs text-text-secondary mb-2 block">🧵 Threads</span>
              )}
              <ThreadsPreview content={content} />
            </div>
          )}
          {(platform === "linkedin" || platform === "both") && (
            <div>
              {platform === "both" && (
                <span className="text-xs text-text-secondary mb-2 block">💼 LinkedIn</span>
              )}
              <LinkedInPreview content={content} />
            </div>
          )}
        </div>
      </div>

      {/* Schedule Modal */}
      <AnimatePresence>
        {showScheduleModal && (
          <ScheduleModal
            platform={platform}
            onClose={() => setShowScheduleModal(false)}
            onSchedule={async (date) => {
              await fetch("/api/posts", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  content_threads: platform !== "linkedin" ? content : null,
                  content_linkedin: platform !== "threads" ? content : null,
                  platforms: platform === "both" ? ["threads", "linkedin"] : [platform],
                  status: "scheduled",
                  scheduled_at: date.toISOString(),
                }),
              });
              setContent("");
              setShowScheduleModal(false);
            }}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

function ScheduleModal({
  platform,
  onClose,
  onSchedule,
}: {
  platform: Platform;
  onClose: () => void;
  onSchedule: (date: Date) => void;
}) {
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [selectedHour, setSelectedHour] = useState(9);
  const [selectedMinute, setSelectedMinute] = useState(0);
  const [currentMonth, setCurrentMonth] = useState(new Date());

  const daysInMonth = new Date(
    currentMonth.getFullYear(),
    currentMonth.getMonth() + 1,
    0
  ).getDate();
  const firstDay = new Date(
    currentMonth.getFullYear(),
    currentMonth.getMonth(),
    1
  ).getDay();
  const adjustedFirstDay = firstDay === 0 ? 6 : firstDay - 1;

  const optimalTimes = [
    { label: "Tue 9:00", hour: 9, minute: 0, recommended: true },
    { label: "Wed 8:30", hour: 8, minute: 30, recommended: true },
    { label: "Thu 10:00", hour: 10, minute: 0, recommended: false },
  ];

  const scheduledDate = new Date(selectedDate);
  scheduledDate.setHours(selectedHour, selectedMinute, 0, 0);

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
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
        onClick={(e) => e.stopPropagation()}
        className="relative glass-card p-6 w-full max-w-md space-y-5"
      >
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <CalendarDays className="w-5 h-5 text-ice-blue" />
            Schedule Post
          </h2>
          <button onClick={onClose} className="text-text-secondary hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Calendar */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <button
              onClick={() =>
                setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1))
              }
              className="text-text-secondary hover:text-white text-sm"
            >
              ‹
            </button>
            <span className="text-white text-sm font-medium">
              {currentMonth.toLocaleDateString("en-US", { month: "long", year: "numeric" })}
            </span>
            <button
              onClick={() =>
                setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1))
              }
              className="text-text-secondary hover:text-white text-sm"
            >
              ›
            </button>
          </div>
          <div className="grid grid-cols-7 gap-1 text-center">
            {["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map((d) => (
              <div key={d} className="text-xs text-text-secondary py-1">
                {d}
              </div>
            ))}
            {Array.from({ length: adjustedFirstDay }).map((_, i) => (
              <div key={`empty-${i}`} />
            ))}
            {Array.from({ length: daysInMonth }).map((_, i) => {
              const day = i + 1;
              const date = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), day);
              const isSelected =
                selectedDate.toDateString() === date.toDateString();
              const isToday = new Date().toDateString() === date.toDateString();
              return (
                <button
                  key={day}
                  onClick={() => setSelectedDate(date)}
                  className={cn(
                    "w-8 h-8 rounded-lg text-xs font-medium transition-smooth mx-auto",
                    isSelected
                      ? "bg-neon-magenta text-white"
                      : isToday
                      ? "bg-white/10 text-white"
                      : "text-text-secondary hover:text-white hover:bg-white/5"
                  )}
                >
                  {day}
                </button>
              );
            })}
          </div>
        </div>

        {/* Time Picker */}
        <div className="space-y-2">
          <span className="text-sm text-text-secondary">Time</span>
          <div className="flex items-center gap-3">
            <select
              value={selectedHour}
              onChange={(e) => setSelectedHour(Number(e.target.value))}
              className="glass-card px-3 py-2 rounded-lg text-white text-sm bg-transparent focus:outline-none"
            >
              {Array.from({ length: 24 }).map((_, h) => (
                <option key={h} value={h} className="bg-bg-surface">
                  {String(h).padStart(2, "0")}
                </option>
              ))}
            </select>
            <span className="text-white font-bold">:</span>
            <select
              value={selectedMinute}
              onChange={(e) => setSelectedMinute(Number(e.target.value))}
              className="glass-card px-3 py-2 rounded-lg text-white text-sm bg-transparent focus:outline-none"
            >
              {[0, 15, 30, 45].map((m) => (
                <option key={m} value={m} className="bg-bg-surface">
                  {String(m).padStart(2, "0")}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Optimal Times */}
        <div className="space-y-2">
          <span className="text-xs text-text-secondary">Optimal Time Suggestions</span>
          <div className="flex gap-2">
            {optimalTimes.map((t) => (
              <button
                key={t.label}
                onClick={() => {
                  setSelectedHour(t.hour);
                  setSelectedMinute(t.minute);
                }}
                className={cn(
                  "px-3 py-1 rounded-full text-xs font-medium transition-smooth",
                  t.recommended
                    ? "bg-neon-teal/20 text-neon-teal border border-neon-teal/30"
                    : "glass-card text-text-secondary"
                )}
              >
                {t.label} {t.recommended && "✓"}
              </button>
            ))}
          </div>
        </div>

        {/* Preview */}
        <p className="text-sm text-text-secondary">
          {scheduledDate.toLocaleDateString("en-US", {
            weekday: "short",
            month: "short",
            day: "numeric",
            year: "numeric",
          })}{" "}
          at {String(selectedHour).padStart(2, "0")}:{String(selectedMinute).padStart(2, "0")}
        </p>

        {/* Actions */}
        <div className="flex items-center gap-3 pt-2">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 rounded-xl glass-card text-sm font-medium text-text-secondary hover:text-white transition-smooth"
          >
            Cancel
          </button>
          <button
            onClick={() => onSchedule(scheduledDate)}
            className="flex-1 px-4 py-2 rounded-xl bg-neon-magenta text-white text-sm font-medium hover:bg-neon-magenta/90 glow-magenta transition-smooth"
          >
            Schedule Post 📅
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}
