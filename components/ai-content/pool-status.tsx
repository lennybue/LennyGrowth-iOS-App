"use client";

import { motion } from "framer-motion";
import { Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";

interface PoolStatusProps {
  available: number;
  total: number;
  generating: number;
}

export default function PoolStatus({
  available,
  total,
  generating,
}: PoolStatusProps) {
  const percentage = (available / total) * 100;
  const isGenerating = generating > 0;

  return (
    <div className="rounded-xl border border-white/10 bg-[#111827]/80 backdrop-blur-md p-4">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Sparkles className="h-4 w-4 text-neon-teal" />
          <span className="text-sm font-medium text-white">Content Pool</span>
        </div>
        <span className="text-sm text-text-secondary">
          {available}/{total} posts available
        </span>
      </div>

      {/* Progress bar */}
      <div className="relative h-2.5 w-full rounded-full bg-white/10 overflow-hidden">
        <motion.div
          className={cn(
            "h-full rounded-full",
            isGenerating ? "bg-neon-teal/70" : "bg-neon-teal"
          )}
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        />
        {isGenerating && (
          <motion.div
            className="absolute inset-0 h-full rounded-full bg-gradient-to-r from-transparent via-white/20 to-transparent"
            animate={{ x: ["-100%", "200%"] }}
            transition={{ duration: 1.5, repeat: Infinity, ease: "linear" }}
          />
        )}
      </div>

      {/* Generating status */}
      {isGenerating && (
        <motion.div
          className="flex items-center gap-2 mt-2"
          initial={{ opacity: 0, y: -4 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <motion.div
            className="h-2 w-2 rounded-full bg-neon-teal"
            animate={{ opacity: [1, 0.3, 1] }}
            transition={{ duration: 1.2, repeat: Infinity }}
          />
          <span className="text-xs text-neon-teal">
            Generating {generating} new post{generating > 1 ? "s" : ""}...
          </span>
        </motion.div>
      )}
    </div>
  );
}
