"use client";

import React, { useCallback } from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import type { Post, PostStatus } from "@/types";

const statusColors: Record<PostStatus, string> = {
  scheduled: "bg-[#4CC9F0]",
  published: "bg-[#16E1C4]",
  failed: "bg-red-500",
  draft: "bg-[#94A3B8]",
};

function isSameDay(a: Date, b: Date) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function isSameMonth(a: Date, b: Date) {
  return (
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth()
  );
}

function getMonthGrid(date: Date): Date[][] {
  const year = date.getFullYear();
  const month = date.getMonth();
  const firstDay = new Date(year, month, 1);
  const startDay = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1; // Monday start
  const start = new Date(firstDay);
  start.setDate(start.getDate() - startDay);

  const weeks: Date[][] = [];
  const current = new Date(start);

  for (let w = 0; w < 6; w++) {
    const week: Date[] = [];
    for (let d = 0; d < 7; d++) {
      week.push(new Date(current));
      current.setDate(current.getDate() + 1);
    }
    weeks.push(week);
  }

  return weeks;
}

interface MonthViewProps {
  currentDate: Date;
  posts: Post[];
  onDayClick?: (date: Date) => void;
}

export default function MonthView({
  currentDate,
  posts,
  onDayClick,
}: MonthViewProps) {
  const weeks = getMonthGrid(currentDate);
  const today = new Date();

  const getPostsForDay = useCallback(
    (date: Date) => {
      return posts.filter((post) => {
        if (!post.scheduled_at) return false;
        return isSameDay(new Date(post.scheduled_at), date);
      });
    },
    [posts]
  );

  const getStatusCounts = (dayPosts: Post[]) => {
    const counts: Partial<Record<PostStatus, number>> = {};
    for (const post of dayPosts) {
      counts[post.status] = (counts[post.status] || 0) + 1;
    }
    return counts;
  };

  const weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  return (
    <div className="flex flex-col h-full">
      {/* Weekday headers */}
      <div className="grid grid-cols-7 border-b border-white/5">
        {weekdayLabels.map((label) => (
          <div
            key={label}
            className="py-2 text-center text-xs font-medium text-text-secondary"
          >
            {label}
          </div>
        ))}
      </div>

      {/* Month grid */}
      <div className="flex-1 grid grid-rows-6">
        {weeks.map((week, weekIndex) => (
          <div
            key={weekIndex}
            className="grid grid-cols-7 border-b border-white/5"
          >
            {week.map((date, dayIndex) => {
              const dayPosts = getPostsForDay(date);
              const counts = getStatusCounts(dayPosts);
              const isCurrentMonth = isSameMonth(date, currentDate);
              const isToday = isSameDay(date, today);

              return (
                <motion.div
                  key={dayIndex}
                  whileHover={{ backgroundColor: "rgba(255,255,255,0.03)" }}
                  onClick={() => onDayClick?.(date)}
                  className={cn(
                    "min-h-[80px] p-1.5 border-r border-white/5 cursor-pointer transition-colors relative",
                    !isCurrentMonth && "opacity-30"
                  )}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span
                      className={cn(
                        "text-sm font-medium w-7 h-7 flex items-center justify-center rounded-full",
                        isToday
                          ? "bg-[#FF006E] text-white"
                          : "text-white/80"
                      )}
                    >
                      {date.getDate()}
                    </span>
                    {dayPosts.length > 0 && (
                      <span className="text-[10px] text-text-secondary font-mono">
                        {dayPosts.length}
                      </span>
                    )}
                  </div>

                  {/* Post status indicators */}
                  <div className="space-y-0.5">
                    {Object.entries(counts).map(([status, count]) => (
                      <div
                        key={status}
                        className="flex items-center gap-1"
                      >
                        <span
                          className={cn(
                            "h-1.5 w-1.5 rounded-full shrink-0",
                            statusColors[status as PostStatus]
                          )}
                        />
                        <span className="text-[10px] text-white/60 truncate">
                          {count} {status}
                        </span>
                      </div>
                    ))}
                  </div>

                  {/* Compact post bars */}
                  {dayPosts.length > 0 && (
                    <div className="mt-1 flex flex-wrap gap-0.5">
                      {dayPosts.slice(0, 5).map((post) => (
                        <div
                          key={post.id}
                          className={cn(
                            "h-1 w-3 rounded-full",
                            statusColors[post.status]
                          )}
                        />
                      ))}
                      {dayPosts.length > 5 && (
                        <span className="text-[9px] text-text-secondary">
                          +{dayPosts.length - 5}
                        </span>
                      )}
                    </div>
                  )}
                </motion.div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}
