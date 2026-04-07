"use client";

import React, { useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Plus } from "lucide-react";
import { cn } from "@/lib/utils";
import type { Post } from "@/types";
import PostCard from "./post-card";
import { OptimalTimeStrip } from "./optimal-times";

const HOURS = Array.from({ length: 15 }, (_, i) => i + 8); // 08:00 - 22:00

function formatHour(hour: number) {
  return `${hour.toString().padStart(2, "0")}:00`;
}

function getDayLabel(date: Date) {
  return {
    short: date.toLocaleDateString([], { weekday: "short" }),
    day: date.getDate(),
    isToday: isSameDay(date, new Date()),
    date,
  };
}

function isSameDay(a: Date, b: Date) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function getWeekDays(currentDate: Date): Date[] {
  const start = new Date(currentDate);
  const day = start.getDay();
  const diff = start.getDate() - day + (day === 0 ? -6 : 1); // Monday start
  start.setDate(diff);
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    return d;
  });
}

interface WeekViewProps {
  currentDate: Date;
  posts: Post[];
  onSlotClick?: (date: Date) => void;
  onPostEdit?: (post: Post) => void;
  onPostReschedule?: (post: Post) => void;
  onPostPublishNow?: (post: Post) => void;
  onPostDelete?: (post: Post) => void;
  onPostDrop?: (post: Post, newDate: Date) => void;
}

export default function WeekView({
  currentDate,
  posts,
  onSlotClick,
  onPostEdit,
  onPostReschedule,
  onPostPublishNow,
  onPostDelete,
  onPostDrop,
}: WeekViewProps) {
  const [dragOverSlot, setDragOverSlot] = useState<string | null>(null);
  const weekDays = getWeekDays(currentDate);

  const getPostsForSlot = useCallback(
    (date: Date, hour: number) => {
      return posts.filter((post) => {
        if (!post.scheduled_at) return false;
        const postDate = new Date(post.scheduled_at);
        return isSameDay(postDate, date) && postDate.getHours() === hour;
      });
    },
    [posts]
  );

  const handleDragStart = (e: React.DragEvent, post: Post) => {
    e.dataTransfer.setData("postId", post.id);
    e.dataTransfer.effectAllowed = "move";
  };

  const handleDragOver = (e: React.DragEvent, slotKey: string) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = "move";
    setDragOverSlot(slotKey);
  };

  const handleDragLeave = () => {
    setDragOverSlot(null);
  };

  const handleDrop = (e: React.DragEvent, date: Date, hour: number) => {
    e.preventDefault();
    setDragOverSlot(null);
    const postId = e.dataTransfer.getData("postId");
    const post = posts.find((p) => p.id === postId);
    if (post && onPostDrop) {
      const newDate = new Date(date);
      newDate.setHours(hour, 0, 0, 0);
      onPostDrop(post, newDate);
    }
  };

  return (
    <div className="flex flex-col h-full">
      {/* Day headers */}
      <div className="flex border-b border-white/5 sticky top-0 z-10 bg-bg-primary/95 backdrop-blur-md">
        <div className="w-16 shrink-0" />
        {weekDays.map((date, i) => {
          const info = getDayLabel(date);
          return (
            <div
              key={i}
              className={cn(
                "flex-1 text-center py-3 border-l border-white/5",
                info.isToday && "bg-[#FF006E]/5"
              )}
            >
              <span className="text-xs text-text-secondary block">
                {info.short}
              </span>
              <span
                className={cn(
                  "text-lg font-semibold",
                  info.isToday
                    ? "text-[#FF006E] bg-[#FF006E]/10 rounded-full w-8 h-8 inline-flex items-center justify-center"
                    : "text-white"
                )}
              >
                {info.day}
              </span>
            </div>
          );
        })}
      </div>

      {/* Time grid */}
      <div className="flex-1 overflow-y-auto">
        <div className="flex">
          {/* Time labels */}
          <div className="w-16 shrink-0">
            {HOURS.map((hour) => (
              <div
                key={hour}
                className="h-16 flex items-start justify-end pr-2 pt-0.5"
              >
                <span className="text-[10px] text-text-secondary font-mono">
                  {formatHour(hour)}
                </span>
              </div>
            ))}
          </div>

          {/* Day columns */}
          {weekDays.map((date, dayIndex) => {
            const dayLabel = getDayLabel(date);
            return (
              <div key={dayIndex} className="flex-1 border-l border-white/5">
                {HOURS.map((hour) => {
                  const slotKey = `${dayIndex}-${hour}`;
                  const slotPosts = getPostsForSlot(date, hour);
                  const isDragOver = dragOverSlot === slotKey;

                  return (
                    <div
                      key={hour}
                      className={cn(
                        "h-16 border-b border-white/5 relative group transition-colors",
                        dayLabel.isToday && "bg-[#FF006E]/[0.02]",
                        isDragOver && "bg-[#4CC9F0]/10 border-[#4CC9F0]/30"
                      )}
                      onDragOver={(e) => handleDragOver(e, slotKey)}
                      onDragLeave={handleDragLeave}
                      onDrop={(e) => handleDrop(e, date, hour)}
                      onClick={() => {
                        if (slotPosts.length === 0 && onSlotClick) {
                          const slotDate = new Date(date);
                          slotDate.setHours(hour, 0, 0, 0);
                          onSlotClick(slotDate);
                        }
                      }}
                    >
                      <OptimalTimeStrip
                        hour={hour}
                        dayOfWeek={date.getDay()}
                      />

                      {/* Empty slot hover indicator */}
                      {slotPosts.length === 0 && (
                        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer">
                          <div className="flex items-center gap-1 text-text-secondary text-[10px]">
                            <Plus className="h-3 w-3" />
                          </div>
                        </div>
                      )}

                      {/* Posts */}
                      <div className="relative z-10 p-0.5 space-y-0.5">
                        <AnimatePresence>
                          {slotPosts.map((post) => (
                            <div
                              key={post.id}
                              draggable
                              onDragStart={(e) => handleDragStart(e, post)}
                              className="cursor-grab active:cursor-grabbing"
                            >
                              <PostCard
                                post={post}
                                compact
                                onEdit={onPostEdit}
                                onReschedule={onPostReschedule}
                                onPublishNow={onPostPublishNow}
                                onDelete={onPostDelete}
                              />
                            </div>
                          ))}
                        </AnimatePresence>
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
