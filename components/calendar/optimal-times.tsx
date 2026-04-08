"use client";

import React from "react";
import { cn } from "@/lib/utils";
import type { Platform } from "@/types";

export interface OptimalTimeSlot {
  platform: Platform;
  hour: number;
  minute: number;
  daysOfWeek?: number[]; // 0=Sun, 1=Mon, etc.
  durationMinutes?: number;
}

export const OPTIMAL_TIMES: OptimalTimeSlot[] = [
  // Threads optimal posting times
  { platform: "threads", hour: 7, minute: 0 },
  { platform: "threads", hour: 9, minute: 30 },
  { platform: "threads", hour: 12, minute: 0 },
  { platform: "threads", hour: 15, minute: 0 },
  { platform: "threads", hour: 18, minute: 0 },
  { platform: "threads", hour: 20, minute: 30 },
  // LinkedIn optimal: Tue-Thu 08:00-10:00
  {
    platform: "linkedin",
    hour: 8,
    minute: 0,
    daysOfWeek: [2, 3, 4],
    durationMinutes: 120,
  },
];

/**
 * Check if a given hour falls within an optimal time slot.
 */
export function isOptimalHour(
  hour: number,
  dayOfWeek: number,
  platform?: Platform
): { isOptimal: boolean; platforms: Platform[] } {
  const matchingPlatforms: Platform[] = [];

  for (const slot of OPTIMAL_TIMES) {
    if (platform && slot.platform !== platform) continue;

    const dur = slot.durationMinutes || 30;
    const startMin = slot.hour * 60 + slot.minute;
    const endMin = startMin + dur;
    const checkMin = hour * 60;

    if (checkMin >= startMin && checkMin < endMin) {
      if (slot.daysOfWeek && !slot.daysOfWeek.includes(dayOfWeek)) continue;
      if (!matchingPlatforms.includes(slot.platform)) {
        matchingPlatforms.push(slot.platform);
      }
    }
  }

  return { isOptimal: matchingPlatforms.length > 0, platforms: matchingPlatforms };
}

interface OptimalTimeStripProps {
  hour: number;
  dayOfWeek: number;
  className?: string;
}

export function OptimalTimeStrip({
  hour,
  dayOfWeek,
  className,
}: OptimalTimeStripProps) {
  const { isOptimal, platforms } = isOptimalHour(hour, dayOfWeek);

  if (!isOptimal) return null;

  const hasThreads = platforms.includes("threads");
  const hasLinkedin = platforms.includes("linkedin");

  return (
    <div
      className={cn(
        "absolute inset-0 pointer-events-none rounded-sm",
        hasThreads && hasLinkedin
          ? "bg-gradient-to-r from-[#16E1C4]/8 to-[#4CC9F0]/8"
          : hasLinkedin
            ? "bg-[#4CC9F0]/8"
            : "bg-[#16E1C4]/8",
        className
      )}
    >
      <div
        className={cn(
          "absolute left-0 top-0 bottom-0 w-0.5 rounded-full",
          hasThreads && hasLinkedin
            ? "bg-gradient-to-b from-[#16E1C4] to-[#4CC9F0]"
            : hasLinkedin
              ? "bg-[#4CC9F0]"
              : "bg-[#16E1C4]"
        )}
      />
    </div>
  );
}
