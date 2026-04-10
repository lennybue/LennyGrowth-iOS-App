"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { X, FileText, Clock, Edit3 } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import { createClient } from "@/lib/supabase/client";
import type { Post } from "@/types";

interface DraftsPanelProps {
  open: boolean;
  onClose: () => void;
}

export default function DraftsPanel({ open, onClose }: DraftsPanelProps) {
  const router = useRouter();
  const [drafts, setDrafts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchDrafts = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/posts?status=draft");
      if (res.ok) {
        const data = await res.json();
        setDrafts(data.posts ?? []);
      }
    } catch (err) {
      console.error("Failed to fetch drafts:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (open) {
      fetchDrafts();
    }
  }, [open, fetchDrafts]);

  function getContentPreview(draft: Post): string {
    const content = draft.content_threads || draft.content_linkedin || "";
    if (content.length <= 100) return content;
    return content.slice(0, 100).trimEnd() + "...";
  }

  function getPlatformBadges(draft: Post) {
    return draft.platforms.map((platform) => (
      <span
        key={platform}
        className={cn(
          "inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide",
          platform === "threads" && "bg-neon-magenta/15 text-neon-magenta",
          platform === "linkedin" && "bg-ice-blue/15 text-ice-blue",
          platform === "both" && "bg-neon-teal/15 text-neon-teal"
        )}
      >
        {platform}
      </span>
    ));
  }

  return (
    <AnimatePresence>
      {open && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
            onClick={onClose}
          />

          {/* Panel */}
          <motion.div
            initial={{ x: "100%" }}
            animate={{ x: 0 }}
            exit={{ x: "100%" }}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
            className={cn(
              "fixed right-0 top-0 z-50 h-screen w-full sm:w-[380px]",
              "flex flex-col",
              "border-l border-white/[0.08]",
              "bg-bg-surface/95 backdrop-blur-xl"
            )}
          >
            {/* Header */}
            <div className="flex items-center justify-between border-b border-white/[0.08] px-5 py-4">
              <div className="flex items-center gap-2.5">
                <FileText className="h-5 w-5 text-neon-magenta" />
                <h2 className="text-lg font-semibold text-white">Drafts</h2>
              </div>
              <button
                onClick={onClose}
                className="rounded-lg p-1.5 text-text-secondary hover:text-white hover:bg-white/[0.06] transition-colors"
                aria-label="Close drafts panel"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto">
              {loading ? (
                /* Loading state */
                <div className="flex flex-col items-center justify-center py-20">
                  <div className="h-8 w-8 animate-spin rounded-full border-2 border-white/10 border-t-neon-magenta" />
                  <p className="mt-3 text-sm text-text-secondary">
                    Loading drafts...
                  </p>
                </div>
              ) : drafts.length === 0 ? (
                /* Empty state */
                <div className="flex flex-col items-center justify-center px-6 py-20 text-center">
                  <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/[0.06]">
                    <FileText className="h-6 w-6 text-text-secondary" />
                  </div>
                  <p className="mt-4 text-sm font-medium text-white">
                    No drafts yet
                  </p>
                  <p className="mt-1 text-xs text-text-secondary">
                    Your saved drafts will appear here.
                  </p>
                </div>
              ) : (
                /* Draft list */
                <div className="space-y-1 p-3">
                  {drafts.map((draft) => (
                    <div
                      key={draft.id}
                      className={cn(
                        "group rounded-lg border border-white/[0.06] p-4",
                        "bg-white/[0.03] hover:bg-white/[0.06]",
                        "transition-colors duration-200"
                      )}
                    >
                      {/* Platform badges */}
                      <div className="flex items-center gap-1.5">
                        {getPlatformBadges(draft)}
                      </div>

                      {/* Content preview */}
                      <p className="mt-2 text-sm leading-relaxed text-white/80">
                        {getContentPreview(draft)}
                      </p>

                      {/* Footer */}
                      <div className="mt-3 flex items-center justify-between">
                        <div className="flex items-center gap-1.5 text-text-secondary">
                          <Clock className="h-3.5 w-3.5" />
                          <span className="text-xs">
                            {format(new Date(draft.created_at), "MMM d, yyyy")}
                          </span>
                        </div>

                        <button
                          onClick={() => {
                            onClose();
                            router.push(`/compose?draft=${draft.id}`);
                          }}
                          className={cn(
                            "flex items-center gap-1.5 rounded-md px-2.5 py-1.5",
                            "text-xs font-medium text-text-secondary",
                            "hover:text-white hover:bg-white/[0.08]",
                            "opacity-0 group-hover:opacity-100",
                            "transition-all duration-200"
                          )}
                        >
                          <Edit3 className="h-3.5 w-3.5" />
                          Edit
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
