"use client";

import { cn } from "@/lib/utils";
import type { ToneType } from "@/types";
import {
  Briefcase,
  Coffee,
  Flame,
  Sparkles,
  Heart,
  BarChart3,
} from "lucide-react";

interface ToneSelectorProps {
  value: ToneType;
  onChange: (tone: ToneType) => void;
}

const tones: { value: ToneType; label: string; icon: React.ReactNode }[] = [
  { value: "professional", label: "Professional", icon: <Briefcase className="h-3.5 w-3.5" /> },
  { value: "casual", label: "Casual", icon: <Coffee className="h-3.5 w-3.5" /> },
  { value: "bold", label: "Bold", icon: <Flame className="h-3.5 w-3.5" /> },
  { value: "witty", label: "Witty", icon: <Sparkles className="h-3.5 w-3.5" /> },
  { value: "inspiring", label: "Inspiring", icon: <Heart className="h-3.5 w-3.5" /> },
  { value: "data-driven", label: "Data-Driven", icon: <BarChart3 className="h-3.5 w-3.5" /> },
];

export default function ToneSelector({ value, onChange }: ToneSelectorProps) {
  return (
    <div className="flex flex-wrap gap-2">
      {tones.map((tone) => {
        const isActive = value === tone.value;
        return (
          <button
            key={tone.value}
            type="button"
            onClick={() => onChange(tone.value)}
            className={cn(
              "inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium border transition-all duration-200",
              isActive
                ? "bg-[#16E1C4]/20 text-[#16E1C4] border-[#16E1C4]/40 shadow-[0_0_12px_rgba(22,225,196,0.2)]"
                : "bg-white/5 text-[#94A3B8] border-white/10 hover:bg-white/10 hover:text-white"
            )}
          >
            {tone.icon}
            {tone.label}
          </button>
        );
      })}
    </div>
  );
}
