"use client";

import { useState } from "react";
import { cn } from "@/lib/utils";
import { ChevronDown, Wand2 } from "lucide-react";
import { Button } from "@/components/ui/button";

interface CustomPromptProps {
  onGenerate: (instruction: string) => void;
  isLoading?: boolean;
}

export default function CustomPrompt({
  onGenerate,
  isLoading = false,
}: CustomPromptProps) {
  const [expanded, setExpanded] = useState(false);
  const [instruction, setInstruction] = useState("");

  return (
    <div className="rounded-xl border border-white/10 bg-white/5 backdrop-blur-sm overflow-hidden">
      <button
        type="button"
        onClick={() => setExpanded(!expanded)}
        className="flex w-full items-center justify-between px-4 py-3 text-sm font-medium text-white hover:bg-white/5 transition-colors"
      >
        <span className="flex items-center gap-2">
          <Wand2 className="h-4 w-4 text-[#FF006E]" />
          Custom AI Instruction
        </span>
        <ChevronDown
          className={cn(
            "h-4 w-4 text-[#94A3B8] transition-transform duration-200",
            expanded && "rotate-180"
          )}
        />
      </button>

      {expanded && (
        <div className="px-4 pb-4 space-y-3">
          <div className="relative">
            <textarea
              value={instruction}
              onChange={(e) => {
                if (e.target.value.length <= 200) {
                  setInstruction(e.target.value);
                }
              }}
              placeholder="e.g. Make it sound like a TED talk opening..."
              className="flex min-h-[72px] w-full rounded-lg border border-white/10 bg-white/5 backdrop-blur-sm px-3 py-2 text-sm text-white placeholder:text-[#94A3B8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#4CC9F0]/50 focus-visible:border-[#4CC9F0]/50 transition-colors duration-200 resize-none"
            />
            <span
              className={cn(
                "absolute bottom-2 right-2 text-xs",
                instruction.length >= 180 ? "text-red-400" : "text-[#94A3B8]"
              )}
            >
              {instruction.length}/200
            </span>
          </div>

          <Button
            size="sm"
            onClick={() => {
              if (instruction.trim()) {
                onGenerate(instruction.trim());
              }
            }}
            disabled={!instruction.trim() || isLoading}
            className="w-full"
          >
            {isLoading ? (
              <span className="flex items-center gap-2">
                <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                Generating...
              </span>
            ) : (
              <span className="flex items-center gap-2">
                <Wand2 className="h-3.5 w-3.5" />
                Generate
              </span>
            )}
          </Button>
        </div>
      )}
    </div>
  );
}
