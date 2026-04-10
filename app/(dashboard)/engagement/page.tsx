"use client";

import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Heart,
  MessageCircle,
  Bookmark,
  Trash2,
  RefreshCw,
  LayoutGrid,
  List,
  Clock,
  Loader2,
  Sparkles,
  X,
  Undo2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { EngagementPost, ReplyType } from "@/types";

const REPLY_TYPES: { type: ReplyType; label: string; icon: string; description: string }[] = [
  { type: "add-value", label: "Add Value", icon: "💡", description: "Add genuine value with experience or facts" },
  { type: "bold-take", label: "Bold Take", icon: "🔥", description: "Controversial but well-founded perspective" },
  { type: "question", label: "Question", icon: "❓", description: "Deep follow-up question to expand discussion" },
  { type: "data-point", label: "Data Point", icon: "📊", description: "Relevant statistic or case study" },
  { type: "witty", label: "Witty", icon: "😄", description: "Humorous but professional" },
  { type: "agree-extend", label: "Agree & Extend", icon: "🤝", description: "Agreement plus your own insight" },
];

// Fallback data used when the API is unavailable
const FALLBACK_POSTS: EngagementPost[] = [
  {
    id: "e1",
    user_id: "u1",
    threads_post_id: "t1",
    author_handle: "marketingexamples",
    content: "The best marketing doesn't feel like marketing.\n\nApple doesn't sell phones. They sell status.\nNike doesn't sell shoes. They sell motivation.\nTesla doesn't sell cars. They sell the future.\n\nWhat does your brand sell beyond the product?",
    likes: 2847,
    replies: 342,
    permalink: null,
    saved: false,
    trashed: false,
    liked_by_user: false,
    refreshed_at: new Date(Date.now() - 3600000).toISOString(),
    expires_at: new Date(Date.now() + 172800000).toISOString(),
  },
  {
    id: "e2",
    user_id: "u1",
    threads_post_id: "t2",
    author_handle: "neuralnetworksnerd",
    content: "Hot take: 90% of businesses using AI for marketing are just creating more noise.\n\nThe winners will be those who use AI to understand their audience better, not just produce content faster.\n\nQuality > quantity. Always.",
    likes: 1523,
    replies: 198,
    permalink: null,
    saved: false,
    trashed: false,
    liked_by_user: false,
    refreshed_at: new Date(Date.now() - 7200000).toISOString(),
    expires_at: new Date(Date.now() + 172800000).toISOString(),
  },
  {
    id: "e3",
    user_id: "u1",
    threads_post_id: "t3",
    author_handle: "seotweets",
    content: "I analyzed 10,000 pages that rank #1 on Google.\n\nThe average word count? 1,447.\nThe average number of backlinks? 38.\nThe average Domain Rating? 62.\n\nBut here's what actually surprised me:\n78% had ZERO schema markup.\n\nSEO is simpler than you think.",
    likes: 4201,
    replies: 567,
    permalink: null,
    saved: true,
    trashed: false,
    liked_by_user: false,
    refreshed_at: new Date(Date.now() - 1800000).toISOString(),
    expires_at: new Date(Date.now() + 172800000).toISOString(),
  },
  {
    id: "e4",
    user_id: "u1",
    threads_post_id: "t4",
    author_handle: "growthbylenny",
    content: "I spent €200k on Google Ads last year.\n\nMy top 3 lessons:\n\n1. Broad match with smart bidding beats exact match\n2. Landing page speed > ad copy (always)\n3. The best performing campaigns are the most boring ones\n\nStop trying to be creative. Be effective.",
    likes: 987,
    replies: 145,
    permalink: null,
    saved: false,
    trashed: false,
    liked_by_user: true,
    refreshed_at: new Date(Date.now() - 5400000).toISOString(),
    expires_at: new Date(Date.now() + 172800000).toISOString(),
  },
];

function formatCount(n: number): string {
  if (n >= 1000) return `${(n / 1000).toFixed(1)}k`;
  return String(n);
}

function timeAgo(date: string): string {
  const diff = Date.now() - new Date(date).getTime();
  const hours = Math.floor(diff / 3600000);
  if (hours < 1) return `${Math.floor(diff / 60000)}m ago`;
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

function ReplyComposerModal({
  post,
  onClose,
}: {
  post: EngagementPost;
  onClose: () => void;
}) {
  const [replyType, setReplyType] = useState<ReplyType>("add-value");
  const [reply, setReply] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);
  const [isPosting, setIsPosting] = useState(false);

  const handleGenerate = async () => {
    setIsGenerating(true);
    try {
      const res = await fetch("/api/ai/engage", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          originalContent: post.content,
          authorHandle: post.author_handle,
          replyType,
        }),
      });
      if (!res.ok) throw new Error();
      const reader = res.body?.getReader();
      if (!reader) return;
      let result = "";
      const decoder = new TextDecoder();
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        result += decoder.decode(value, { stream: true });
        setReply(result);
      }
    } catch {
      setReply("Failed to generate reply. Please try again.");
    } finally {
      setIsGenerating(false);
    }
  };

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
        className="relative glass-card p-6 w-full max-w-lg space-y-4"
      >
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white flex items-center gap-2">
            <MessageCircle className="w-5 h-5 text-ice-blue" />
            Reply to @{post.author_handle}
          </h2>
          <button onClick={onClose} className="text-text-secondary hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Original Post */}
        <div className="p-3 rounded-xl bg-white/[0.03] border border-white/[0.05]">
          <p className="text-xs text-text-secondary line-clamp-3">{post.content}</p>
        </div>

        {/* Reply Type Selection */}
        <div className="space-y-2">
          <span className="text-sm text-text-secondary">Reply Type:</span>
          <div className="grid grid-cols-3 gap-2">
            {REPLY_TYPES.map(({ type, label, icon }) => (
              <button
                key={type}
                onClick={() => setReplyType(type)}
                className={cn(
                  "px-3 py-2 rounded-xl text-xs font-medium transition-smooth text-left",
                  replyType === type
                    ? "bg-neon-teal/20 text-neon-teal border border-neon-teal/30"
                    : "glass-card text-text-secondary hover:text-white"
                )}
              >
                <span className="mr-1">{icon}</span> {label}
              </button>
            ))}
          </div>
        </div>

        {/* Generate Button */}
        <button
          onClick={handleGenerate}
          disabled={isGenerating}
          className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-neon-magenta/80 to-purple-600/80 text-white text-sm font-medium hover:from-neon-magenta hover:to-purple-600 transition-smooth disabled:opacity-50"
        >
          {isGenerating ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Sparkles className="w-4 h-4" />
          )}
          {isGenerating ? "Generating..." : "AI Draft Reply"}
        </button>

        {/* Reply Editor */}
        <div className="relative">
          <textarea
            value={reply}
            onChange={(e) => setReply(e.target.value.slice(0, 500))}
            placeholder="Your reply will appear here..."
            className={cn(
              "w-full h-32 resize-none rounded-xl p-3",
              "bg-white/[0.04] border border-white/[0.08]",
              "text-white placeholder:text-text-secondary/50",
              "focus:outline-none focus:border-neon-teal/40 text-sm",
              isGenerating && "cursor-blink"
            )}
          />
          <span className="absolute bottom-3 right-3 text-xs text-text-secondary font-mono">
            {reply.length}/500
          </span>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3">
          <button
            onClick={handleGenerate}
            disabled={isGenerating}
            className="px-3 py-1.5 rounded-lg glass-card text-xs text-text-secondary hover:text-white transition-smooth"
          >
            <RefreshCw className="w-3 h-3 inline mr-1" />
            Regenerate
          </button>
          <div className="flex-1" />
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-xl glass-card text-sm font-medium text-text-secondary hover:text-white transition-smooth"
          >
            Cancel
          </button>
          <button
            disabled={!reply.trim() || isPosting}
            className="px-4 py-2 rounded-xl bg-neon-teal text-bg-primary text-sm font-medium hover:bg-neon-teal/90 glow-teal transition-smooth disabled:opacity-40"
          >
            {isPosting ? <Loader2 className="w-4 h-4 animate-spin" /> : "Post Reply"}
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}

export default function EngagementPage() {
  const [view, setView] = useState<"grid" | "list">("grid");
  const [tab, setTab] = useState<"feed" | "saved">("feed");
  const [isLoading, setIsLoading] = useState(true);
  const [posts, setPosts] = useState<EngagementPost[]>([]);
  const [replyPost, setReplyPost] = useState<EngagementPost | null>(null);
  const [trashedUndo, setTrashedUndo] = useState<{ post: EngagementPost; timeout: NodeJS.Timeout } | null>(null);

  useEffect(() => {
    async function fetchFeed() {
      try {
        const res = await fetch("/api/threads/feed");
        if (res.ok) {
          const data = await res.json();
          if (data.posts && data.posts.length > 0) {
            setPosts(data.posts);
          } else {
            setPosts(FALLBACK_POSTS);
          }
        } else {
          setPosts(FALLBACK_POSTS);
        }
      } catch {
        setPosts(FALLBACK_POSTS);
      } finally {
        setIsLoading(false);
      }
    }
    fetchFeed();
  }, []);

  const nextRefresh = new Date(Date.now() + 82800000); // ~23h from now
  const refreshHours = Math.floor((nextRefresh.getTime() - Date.now()) / 3600000);
  const refreshMinutes = Math.floor(
    ((nextRefresh.getTime() - Date.now()) % 3600000) / 60000
  );

  const filteredPosts = posts.filter((p) => {
    if (p.trashed) return false;
    if (tab === "saved") return p.saved;
    return true;
  });

  const handleLike = useCallback(
    (postId: string) => {
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId
            ? { ...p, liked_by_user: !p.liked_by_user, likes: p.liked_by_user ? p.likes - 1 : p.likes + 1 }
            : p
        )
      );
    },
    []
  );

  const handleSave = useCallback((postId: string) => {
    setPosts((prev) =>
      prev.map((p) => (p.id === postId ? { ...p, saved: !p.saved } : p))
    );
  }, []);

  const handleTrash = useCallback(
    (postId: string) => {
      const post = posts.find((p) => p.id === postId);
      if (!post) return;

      if (trashedUndo) clearTimeout(trashedUndo.timeout);

      setPosts((prev) =>
        prev.map((p) => (p.id === postId ? { ...p, trashed: true } : p))
      );

      const timeout = setTimeout(() => {
        setTrashedUndo(null);
      }, 5000);

      setTrashedUndo({ post, timeout });
    },
    [posts, trashedUndo]
  );

  const handleUndoTrash = useCallback(() => {
    if (!trashedUndo) return;
    clearTimeout(trashedUndo.timeout);
    setPosts((prev) =>
      prev.map((p) =>
        p.id === trashedUndo.post.id ? { ...p, trashed: false } : p
      )
    );
    setTrashedUndo(null);
  }, [trashedUndo]);

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-white">Engagement Feed</h1>
          <p className="text-xs text-text-secondary flex items-center gap-1.5 mt-1">
            <Clock className="w-3 h-3" />
            Last refreshed: {timeAgo(posts[0]?.refreshed_at || new Date().toISOString())}
            <span className="text-white/30 mx-1">·</span>
            Next refresh in: {refreshHours}h {refreshMinutes}m
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={async () => {
              setIsLoading(true);
              try {
                const res = await fetch("/api/threads/feed", { cache: "no-store" });
                if (res.ok) {
                  const data = await res.json();
                  if (data.posts?.length > 0) setPosts(data.posts);
                }
              } catch {} finally {
                setIsLoading(false);
              }
            }}
            disabled={isLoading}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg glass-card text-xs text-text-secondary hover:text-white transition-smooth disabled:opacity-50"
          >
            <RefreshCw className={cn("w-3 h-3", isLoading && "animate-spin")} />
            Refresh
          </button>
          <div className="flex items-center gap-1 glass-card rounded-lg p-0.5">
            <button
              onClick={() => setView("grid")}
              className={cn(
                "p-1.5 rounded-md transition-smooth",
                view === "grid" ? "bg-neon-magenta text-white" : "text-text-secondary hover:text-white"
              )}
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
            <button
              onClick={() => setView("list")}
              className={cn(
                "p-1.5 rounded-md transition-smooth",
                view === "list" ? "bg-neon-magenta text-white" : "text-text-secondary hover:text-white"
              )}
            >
              <List className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Sub-tabs: Feed / Saved */}
      <div className="flex items-center gap-2">
        {(["feed", "saved"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              "px-4 py-2 rounded-full text-sm font-medium transition-smooth capitalize",
              tab === t
                ? "bg-neon-magenta text-white"
                : "glass-card text-text-secondary hover:text-white"
            )}
          >
            {t === "saved" && <Bookmark className="w-3.5 h-3.5 inline mr-1" />}
            {t}
          </button>
        ))}
      </div>

      {/* Feed Grid/List */}
      <div
        className={cn(
          "flex-1 overflow-y-auto",
          view === "grid"
            ? "grid grid-cols-1 md:grid-cols-2 gap-4 auto-rows-max"
            : "space-y-3"
        )}
      >
        {isLoading && (
          <div className="col-span-full flex items-center justify-center py-20">
            <Loader2 className="w-8 h-8 animate-spin text-neon-teal" />
          </div>
        )}
        <AnimatePresence>
          {filteredPosts.map((post) => (
            <motion.div
              key={post.id}
              layout
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95, height: 0 }}
              className="glass-card glass-card-hover overflow-hidden"
            >
              {/* Post Header */}
              <div className="p-4 pb-0">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-neon-magenta to-purple-600 flex items-center justify-center text-white font-bold text-xs">
                      {post.author_handle[0].toUpperCase()}
                    </div>
                    <div>
                      <span className="text-sm font-semibold text-white">
                        @{post.author_handle}
                      </span>
                      <span className="text-xs text-text-secondary ml-2">
                        {timeAgo(post.refreshed_at)}
                      </span>
                    </div>
                  </div>
                  <span className="text-xs px-2 py-0.5 rounded-full bg-purple-500/20 text-purple-300">
                    Threads
                  </span>
                </div>
              </div>

              {/* Content */}
              <div className="px-4 pb-3">
                <p className="text-sm text-white/90 whitespace-pre-wrap leading-relaxed">
                  {post.content}
                </p>
              </div>

              {/* Stats */}
              <div className="px-4 pb-3 flex items-center gap-4 text-xs text-text-secondary">
                <span>❤️ {formatCount(post.likes)}</span>
                <span>💬 {formatCount(post.replies)}</span>
              </div>

              {/* Actions */}
              <div className="px-4 py-3 border-t border-white/5 flex items-center gap-2">
                <button
                  onClick={() => handleLike(post.id)}
                  className={cn(
                    "flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-smooth",
                    post.liked_by_user
                      ? "bg-neon-magenta/20 text-neon-magenta"
                      : "glass-card text-text-secondary hover:text-neon-magenta"
                  )}
                >
                  <Heart
                    className={cn("w-3.5 h-3.5", post.liked_by_user && "fill-current")}
                  />
                  Like
                </button>
                <button
                  onClick={() => setReplyPost(post)}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium glass-card text-text-secondary hover:text-ice-blue transition-smooth"
                >
                  <MessageCircle className="w-3.5 h-3.5" />
                  Comment
                </button>
                <button
                  onClick={() => handleSave(post.id)}
                  className={cn(
                    "flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-smooth",
                    post.saved
                      ? "bg-neon-teal/20 text-neon-teal"
                      : "glass-card text-text-secondary hover:text-neon-teal"
                  )}
                >
                  <Bookmark
                    className={cn("w-3.5 h-3.5", post.saved && "fill-current")}
                  />
                  Save
                </button>
                <button
                  onClick={() => handleTrash(post.id)}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-text-secondary hover:text-red-400 transition-smooth ml-auto"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>

              {/* Saved badge */}
              {post.saved && (
                <div className="absolute top-3 right-3">
                  <Bookmark className="w-4 h-4 text-neon-teal fill-current" />
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>

        {filteredPosts.length === 0 && (
          <div className="col-span-full flex flex-col items-center justify-center py-20 text-text-secondary">
            <Bookmark className="w-12 h-12 mb-4 opacity-30" />
            <p className="text-sm">
              {tab === "saved" ? "No saved posts yet" : "No posts in your feed"}
            </p>
          </div>
        )}
      </div>

      {/* Undo Toast */}
      <AnimatePresence>
        {trashedUndo && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            className="fixed bottom-6 right-6 glass-card p-4 flex items-center gap-3 z-50"
          >
            <span className="text-sm text-white">Post trashed</span>
            <button
              onClick={handleUndoTrash}
              className="flex items-center gap-1 px-3 py-1 rounded-lg bg-neon-teal/20 text-neon-teal text-xs font-medium"
            >
              <Undo2 className="w-3 h-3" />
              Undo
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Reply Composer Modal */}
      <AnimatePresence>
        {replyPost && (
          <ReplyComposerModal
            post={replyPost}
            onClose={() => setReplyPost(null)}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
