"use client";

import { cn } from "@/lib/utils";
import type { Platform } from "@/types";

interface PlatformSelectorProps {
  value: Platform;
  onChange: (platform: Platform) => void;
}

const platforms: { value: Platform; label: string }[] = [
  { value: "threads", label: "Threads" },
  { value: "linkedin", label: "LinkedIn" },
  { value: "both", label: "Both" },
];

export default function PlatformSelector({
  value,
  onChange,
}: PlatformSelectorProps) {
  return (
    <div className="inline-flex items-center gap-1 rounded-xl bg-white/5 border border-white/10 p-1 backdrop-blur-sm">
      {platforms.map((p) => {
        const isActive = value === p.value;

        const activeStyles: Record<Platform, string> = {
          threads:
            "bg-[#FF006E] text-white shadow-[0_0_16px_rgba(255,0,110,0.35)]",
          linkedin:
            "bg-[#4CC9F0] text-[#0C1222] shadow-[0_0_16px_rgba(76,201,240,0.35)]",
          both: "bg-gradient-to-r from-[#FF006E] to-[#4CC9F0] text-white shadow-[0_0_16px_rgba(255,0,110,0.25)]",
        };

        return (
          <button
            key={p.value}
            type="button"
            onClick={() => onChange(p.value)}
            className={cn(
              "rounded-lg px-4 py-1.5 text-sm font-medium transition-all duration-200",
              isActive
                ? activeStyles[p.value]
                : "text-[#94A3B8] hover:text-white hover:bg-white/5"
            )}
          >
            {p.label}
          </button>
        );
      })}
    </div>
  );
}
