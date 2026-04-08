"use client";

import React, { useState } from "react";
import { motion } from "framer-motion";
import {
  Clock,
  Edit3,
  Trash2,
  Send,
  CalendarClock,
  AtSign,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { Post, Platform, PostStatus } from "@/types";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";

const statusColors: Record<PostStatus, string> = {
  scheduled: "bg-[#4CC9F0]",
  published: "bg-[#16E1C4]",
  failed: "bg-red-500",
  draft: "bg-[#94A3B8]",
};

const statusBorderColors: Record<PostStatus, string> = {
  scheduled: "border-l-[#4CC9F0]",
  published: "border-l-[#16E1C4]",
  failed: "border-l-red-500",
  draft: "border-l-[#94A3B8]",
};

function LinkedInIcon({ className }: { className?: string }) {
  return <span className={className}>in</span>;
}

function PlatformIcon({ platform }: { platform: Platform }) {
  switch (platform) {
    case "threads":
      return <AtSign className="h-3 w-3" />;
    case "linkedin":
      return <LinkedInIcon className="h-3 w-3 font-bold" />;
    case "both":
      return (
        <span className="flex items-center gap-0.5">
          <AtSign className="h-3 w-3" />
          <LinkedInIcon className="h-3 w-3 font-bold" />
        </span>
      );
  }
}

interface PostCardProps {
  post: Post;
  compact?: boolean;
  onEdit?: (post: Post) => void;
  onReschedule?: (post: Post) => void;
  onPublishNow?: (post: Post) => void;
  onDelete?: (post: Post) => void;
}

export default function PostCard({
  post,
  compact = false,
  onEdit,
  onReschedule,
  onPublishNow,
  onDelete,
}: PostCardProps) {
  const [detailOpen, setDetailOpen] = useState(false);

  const content = post.content_threads || post.content_linkedin || "";
  const platform = post.platforms[0] || "threads";
  const time = post.scheduled_at
    ? new Date(post.scheduled_at).toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      })
    : "";

  return (
    <>
      <motion.div
        layout
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        whileHover={{ scale: 1.02 }}
        onClick={() => setDetailOpen(true)}
        className={cn(
          "cursor-pointer rounded-lg border-l-2 bg-white/5 backdrop-blur-sm border border-white/5 px-2 py-1.5 transition-all hover:bg-white/8 hover:border-white/10",
          statusBorderColors[post.status],
          compact && "px-1.5 py-1"
        )}
      >
        <div className="flex items-center gap-1.5 mb-0.5">
          <Badge
            variant="outline"
            className="px-1 py-0 text-[10px] gap-0.5 h-4"
          >
            <PlatformIcon platform={platform} />
          </Badge>
          <span
            className={cn("h-1.5 w-1.5 rounded-full", statusColors[post.status])}
          />
          {time && (
            <span className="text-[10px] text-text-secondary ml-auto">
              {time}
            </span>
          )}
        </div>
        {!compact && (
          <p className="text-[11px] text-white/80 leading-tight line-clamp-2">
            {content}
          </p>
        )}
      </motion.div>

      {/* Detail popup */}
      <Dialog open={detailOpen} onOpenChange={setDetailOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-3">
              <Badge
                variant={platform === "linkedin" ? "ice" : "secondary"}
                className="gap-1"
              >
                <PlatformIcon platform={platform} />
                {platform}
              </Badge>
              <span
                className={cn(
                  "inline-flex items-center gap-1.5 text-xs font-normal",
                  post.status === "scheduled" && "text-[#4CC9F0]",
                  post.status === "published" && "text-[#16E1C4]",
                  post.status === "failed" && "text-red-400",
                  post.status === "draft" && "text-text-secondary"
                )}
              >
                <span
                  className={cn(
                    "h-2 w-2 rounded-full",
                    statusColors[post.status]
                  )}
                />
                {post.status}
              </span>
            </DialogTitle>
          </DialogHeader>

          {post.scheduled_at && (
            <div className="flex items-center gap-2 text-sm text-text-secondary">
              <Clock className="h-4 w-4" />
              {new Date(post.scheduled_at).toLocaleString([], {
                weekday: "short",
                month: "short",
                day: "numeric",
                hour: "2-digit",
                minute: "2-digit",
              })}
            </div>
          )}

          <div className="rounded-lg bg-white/5 border border-white/5 p-4">
            <p className="text-sm text-white/90 whitespace-pre-wrap leading-relaxed">
              {content}
            </p>
          </div>

          <DialogFooter className="grid grid-cols-2 gap-2 sm:flex">
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                onEdit?.(post);
                setDetailOpen(false);
              }}
              className="gap-1.5"
            >
              <Edit3 className="h-3.5 w-3.5" />
              Edit
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                onReschedule?.(post);
                setDetailOpen(false);
              }}
              className="gap-1.5"
            >
              <CalendarClock className="h-3.5 w-3.5" />
              Reschedule
            </Button>
            <Button
              variant="secondary"
              size="sm"
              onClick={() => {
                onPublishNow?.(post);
                setDetailOpen(false);
              }}
              className="gap-1.5"
            >
              <Send className="h-3.5 w-3.5" />
              Publish Now
            </Button>
            <Button
              variant="destructive"
              size="sm"
              onClick={() => {
                onDelete?.(post);
                setDetailOpen(false);
              }}
              className="gap-1.5"
            >
              <Trash2 className="h-3.5 w-3.5" />
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
