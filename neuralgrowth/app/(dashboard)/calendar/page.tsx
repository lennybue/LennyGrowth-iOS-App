"use client";

import { useState, useMemo, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  ChevronLeft,
  ChevronRight,
  Plus,
  CalendarDays,
  LayoutGrid,
  Clock,
  Edit3,
  Trash2,
  Send,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import {
  format,
  addDays,
  startOfWeek,
  addWeeks,
  subWeeks,
  isSameDay,
  isToday,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
  addMonths,
  subMonths,
} from "date-fns";
import { useRealtimePosts } from "@/hooks/use-realtime-posts";
import type { Post, PostStatus } from "@/types";

const STATUS_COLORS: Record<PostStatus, string> = {
  scheduled: "bg-ice-blue",
  published: "bg-neon-teal",
  failed: "bg-neon-magenta",
  draft: "bg-text-secondary",
};

const HOURS = Array.from({ length: 15 }, (_, i) => i + 8); // 8:00 - 22:00

const OPTIMAL_TIMES: Record<string, number[]> = {
  threads: [7, 9, 12, 15, 18, 20],
  linkedin: [8, 9, 10],
};

// Fallback posts shown when API is unavailable
const FALLBACK_POSTS: Post[] = [
  {
    id: "1",
    user_id: "u1",
    content_threads: "The biggest SEO mistake I see in 2026? Ignoring AI-generated search results. Here's what to do instead...",
    content_linkedin: null,
    platforms: ["threads"],
    status: "scheduled",
    post_type: "text",
    scheduled_at: new Date(Date.now() + 86400000).toISOString(),
    published_at: null,
    threads_post_id: null,
    linkedin_post_id: null,
    media_urls: [],
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: "2",
    user_id: "u1",
    content_threads: null,
    content_linkedin: "3 years ago, I was burning \u20ac50k/month on Google Ads with a 0.8% CTR.\n\nToday: same budget, 3.2x conversion rate.\n\nThe difference? Not a magic trick \u2014 just 3 systematic changes...",
    platforms: ["linkedin"],
    status: "published",
    post_type: "text",
    scheduled_at: new Date(Date.now() - 86400000).toISOString(),
    published_at: new Date(Date.now() - 86400000).toISOString(),
    threads_post_id: null,
    linkedin_post_id: null,
    media_urls: [],
    created_at: new Date(Date.now() - 172800000).toISOString(),
    updated_at: new Date(Date.now() - 86400000).toISOString(),
  },
];

function PostCard({ post, onClick }: { post: Post; onClick: () => void }) {
  const content = post.content_threads || post.content_linkedin || "";
  const platformBadge = post.platforms.includes("threads") ? "🧵" : "💼";

  return (
    <motion.div
      layoutId={post.id}
      onClick={onClick}
      className="glass-card glass-card-hover p-2 cursor-pointer transition-smooth group text-left w-full"
    >
      <div className="flex items-center gap-1.5 mb-1">
        <span className="text-xs">{platformBadge}</span>
        <div className={cn("w-1.5 h-1.5 rounded-full", STATUS_COLORS[post.status])} />
        <span className="text-[10px] text-text-secondary capitalize">{post.status}</span>
      </div>
      <p className="text-xs text-white/80 line-clamp-2 leading-snug">{content}</p>
    </motion.div>
  );
}

function PostDetailPopup({
  post,
  onClose,
}: {
  post: Post;
  onClose: () => void;
}) {
  const content = post.content_threads || post.content_linkedin || "";
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
        className="relative glass-card p-6 w-full max-w-lg space-y-4"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span>{post.platforms.includes("threads") ? "🧵" : "💼"}</span>
            <div className={cn("px-2 py-0.5 rounded-full text-xs", STATUS_COLORS[post.status], "text-black font-medium")} >
              {post.status}
            </div>
          </div>
          <button onClick={onClose} className="text-text-secondary hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>
        <p className="text-white text-sm whitespace-pre-wrap">{content}</p>
        {post.scheduled_at && (
          <p className="text-xs text-text-secondary">
            <Clock className="w-3 h-3 inline mr-1" />
            {format(new Date(post.scheduled_at), "EEE, MMM d, yyyy 'at' HH:mm")}
          </p>
        )}
        <div className="flex items-center gap-2 pt-2 border-t border-white/5">
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg glass-card text-xs text-white hover:bg-white/10">
            <Edit3 className="w-3 h-3" /> Edit
          </button>
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg glass-card text-xs text-ice-blue hover:bg-ice-blue/10">
            <CalendarDays className="w-3 h-3" /> Reschedule
          </button>
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-neon-magenta/20 text-xs text-neon-magenta hover:bg-neon-magenta/30">
            <Send className="w-3 h-3" /> Publish Now
          </button>
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs text-red-400 hover:bg-red-500/10 ml-auto">
            <Trash2 className="w-3 h-3" /> Delete
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}

export default function CalendarPage() {
  const [view, setView] = useState<"week" | "month">("week");
  const [currentDate, setCurrentDate] = useState(new Date());
  const [selectedPost, setSelectedPost] = useState<Post | null>(null);
  const [posts, setPosts] = useState<Post[]>(FALLBACK_POSTS);

  // Fetch real posts from API
  const fetchPosts = useCallback(async () => {
    try {
      const res = await fetch("/api/posts?limit=100");
      if (res.ok) {
        const data = await res.json();
        if (data.posts && data.posts.length > 0) {
          setPosts(data.posts);
        }
      }
    } catch {
      // Keep fallback data
    }
  }, []);

  useEffect(() => {
    fetchPosts();
  }, [fetchPosts]);

  // Subscribe to Realtime post status changes
  useRealtimePosts({
    onPostChange({ eventType, new: newPost }) {
      if (eventType === "INSERT" && newPost.id) {
        setPosts((prev) => [newPost as Post, ...prev]);
      } else if (eventType === "UPDATE" && newPost.id) {
        setPosts((prev) =>
          prev.map((p) => (p.id === newPost.id ? { ...p, ...newPost } : p))
        );
      } else if (eventType === "DELETE" && newPost.id) {
        setPosts((prev) => prev.filter((p) => p.id !== newPost.id));
      }
    },
  });

  const weekStart = startOfWeek(currentDate, { weekStartsOn: 1 });
  const weekDays = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));

  const monthStart = startOfMonth(currentDate);
  const monthEnd = endOfMonth(currentDate);
  const monthDays = eachDayOfInterval({ start: monthStart, end: monthEnd });

  const getPostsForDay = (day: Date) =>
    posts.filter((p) => p.scheduled_at && isSameDay(new Date(p.scheduled_at), day));

  const getPostsForHour = (day: Date, hour: number) =>
    posts.filter((p) => {
      if (!p.scheduled_at) return false;
      const d = new Date(p.scheduled_at);
      return isSameDay(d, day) && d.getHours() === hour;
    });

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() =>
              setCurrentDate(view === "week" ? subWeeks(currentDate, 1) : subMonths(currentDate, 1))
            }
            className="p-2 rounded-lg glass-card glass-card-hover text-text-secondary hover:text-white transition-smooth"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <h2 className="text-white font-semibold">
            {view === "week"
              ? `${format(weekDays[0], "MMM d")} — ${format(weekDays[6], "MMM d, yyyy")}`
              : format(currentDate, "MMMM yyyy")}
          </h2>
          <button
            onClick={() =>
              setCurrentDate(view === "week" ? addWeeks(currentDate, 1) : addMonths(currentDate, 1))
            }
            className="p-2 rounded-lg glass-card glass-card-hover text-text-secondary hover:text-white transition-smooth"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
          <button
            onClick={() => setCurrentDate(new Date())}
            className="px-3 py-1.5 rounded-lg glass-card text-xs text-ice-blue hover:bg-ice-blue/10 transition-smooth"
          >
            Today
          </button>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setView("week")}
            className={cn(
              "px-3 py-1.5 rounded-lg text-xs font-medium transition-smooth",
              view === "week" ? "bg-neon-magenta text-white" : "glass-card text-text-secondary"
            )}
          >
            <CalendarDays className="w-3.5 h-3.5 inline mr-1" /> Week
          </button>
          <button
            onClick={() => setView("month")}
            className={cn(
              "px-3 py-1.5 rounded-lg text-xs font-medium transition-smooth",
              view === "month" ? "bg-neon-magenta text-white" : "glass-card text-text-secondary"
            )}
          >
            <LayoutGrid className="w-3.5 h-3.5 inline mr-1" /> Month
          </button>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="flex-1 overflow-auto">
        {view === "week" ? (
          /* Week View */
          <div className="min-w-[700px]">
            {/* Day Headers */}
            <div className="grid grid-cols-8 gap-px mb-1">
              <div className="w-16" />
              {weekDays.map((day) => (
                <div
                  key={day.toISOString()}
                  className={cn(
                    "text-center py-2 rounded-t-lg",
                    isToday(day) ? "bg-neon-magenta/10" : ""
                  )}
                >
                  <div className="text-xs text-text-secondary">
                    {format(day, "EEE")}
                  </div>
                  <div
                    className={cn(
                      "text-lg font-semibold",
                      isToday(day) ? "text-neon-magenta" : "text-white"
                    )}
                  >
                    {format(day, "d")}
                  </div>
                </div>
              ))}
            </div>

            {/* Time Grid */}
            <div className="relative">
              {HOURS.map((hour) => (
                <div key={hour} className="grid grid-cols-8 gap-px min-h-[60px]">
                  <div className="w-16 pr-2 text-right">
                    <span className="text-xs text-text-secondary font-mono">
                      {String(hour).padStart(2, "0")}:00
                    </span>
                  </div>
                  {weekDays.map((day) => {
                    const dayPosts = getPostsForHour(day, hour);
                    const isOptimalThreads = OPTIMAL_TIMES.threads.includes(hour);
                    const isOptimalLinkedIn =
                      OPTIMAL_TIMES.linkedin.includes(hour) &&
                      [2, 3, 4].includes(day.getDay());

                    return (
                      <div
                        key={day.toISOString() + hour}
                        className={cn(
                          "border border-white/[0.03] rounded-lg p-1 min-h-[60px] transition-smooth hover:bg-white/[0.02] group relative",
                          (isOptimalThreads || isOptimalLinkedIn) && "border-neon-teal/10"
                        )}
                      >
                        {(isOptimalThreads || isOptimalLinkedIn) && (
                          <div className="absolute top-0.5 right-0.5 w-1 h-1 rounded-full bg-neon-teal/40" />
                        )}
                        {dayPosts.map((post) => (
                          <PostCard
                            key={post.id}
                            post={post}
                            onClick={() => setSelectedPost(post)}
                          />
                        ))}
                        <button className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                          <Plus className="w-4 h-4 text-text-secondary" />
                        </button>
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        ) : (
          /* Month View */
          <div>
            <div className="grid grid-cols-7 gap-1 mb-1">
              {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((d) => (
                <div key={d} className="text-center text-xs text-text-secondary py-2 font-medium">
                  {d}
                </div>
              ))}
            </div>
            <div className="grid grid-cols-7 gap-1">
              {/* Padding for first week */}
              {Array.from({
                length: (monthStart.getDay() === 0 ? 6 : monthStart.getDay() - 1),
              }).map((_, i) => (
                <div key={`pad-${i}`} className="min-h-[100px]" />
              ))}
              {monthDays.map((day) => {
                const dayPosts = getPostsForDay(day);
                return (
                  <div
                    key={day.toISOString()}
                    className={cn(
                      "min-h-[100px] p-2 rounded-lg border border-white/[0.03] hover:bg-white/[0.02] transition-smooth",
                      isToday(day) && "border-neon-magenta/30 bg-neon-magenta/5"
                    )}
                  >
                    <span
                      className={cn(
                        "text-xs font-medium",
                        isToday(day) ? "text-neon-magenta" : "text-text-secondary"
                      )}
                    >
                      {format(day, "d")}
                    </span>
                    <div className="mt-1 space-y-1">
                      {dayPosts.map((post) => (
                        <PostCard
                          key={post.id}
                          post={post}
                          onClick={() => setSelectedPost(post)}
                        />
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* Queue Sidebar indicator */}
      <div className="glass-card p-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Clock className="w-4 h-4 text-ice-blue" />
          <span className="text-sm text-white font-medium">
            Upcoming: {posts.filter((p) => p.status === "scheduled").length} posts scheduled
          </span>
        </div>
        <div className="flex items-center gap-1">
          {posts
            .filter((p) => p.status === "scheduled")
            .slice(0, 3)
            .map((p) => (
              <div key={p.id} className="w-2 h-2 rounded-full bg-ice-blue" />
            ))}
        </div>
      </div>

      {/* Post Detail Popup */}
      <AnimatePresence>
        {selectedPost && (
          <PostDetailPopup
            post={selectedPost}
            onClose={() => setSelectedPost(null)}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
