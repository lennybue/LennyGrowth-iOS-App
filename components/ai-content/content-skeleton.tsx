"use client";

import { cn } from "@/lib/utils";

export default function ContentSkeleton({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "rounded-xl border border-white/10 bg-[#111827]/80 backdrop-blur-md p-5 space-y-4 animate-pulse",
        className
      )}
    >
      {/* Badge row */}
      <div className="flex items-center gap-2">
        <div className="h-5 w-20 rounded-full bg-white/10" />
        <div className="h-5 w-16 rounded-full bg-white/10" />
        <div className="ml-auto h-4 w-12 rounded bg-white/5" />
      </div>

      {/* Hook + tone badges */}
      <div className="flex items-center gap-2">
        <div className="h-5 w-24 rounded-full bg-white/10" />
        <div className="h-5 w-20 rounded-full bg-white/10" />
      </div>

      {/* Content lines */}
      <div className="space-y-2.5">
        <div className="h-4 w-full rounded bg-white/10" />
        <div className="h-4 w-full rounded bg-white/10" />
        <div className="h-4 w-5/6 rounded bg-white/10" />
        <div className="h-4 w-4/6 rounded bg-white/10" />
        <div className="h-4 w-3/4 rounded bg-white/10" />
      </div>

      {/* Char count */}
      <div className="h-3 w-16 rounded bg-white/5" />

      {/* Action buttons */}
      <div className="flex items-center gap-2 pt-2 border-t border-white/5">
        <div className="h-8 w-16 rounded-lg bg-white/10" />
        <div className="h-8 w-24 rounded-lg bg-white/10" />
        <div className="h-8 w-20 rounded-lg bg-white/10" />
        <div className="h-8 w-24 rounded-lg bg-white/10" />
        <div className="ml-auto h-8 w-8 rounded-lg bg-white/10" />
      </div>
    </div>
  );
}
