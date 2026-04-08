"use client";

import { useState, useRef } from "react";
import { cn } from "@/lib/utils";
import type { RefinementAction, Platform, ToneType } from "@/types";
import {
  Sparkles,
  ArrowUpRight,
  Target,
  Minimize2,
  Maximize2,
  Scissors,
  RefreshCw,
  Plus,
  MessageCircle,
  Award,
  Zap,
  SplitSquareHorizontal,
  Undo2,
  GitCompare,
} from "lucide-react";

interface AIToolbarProps {
  content: string;
  platform: Platform;
  tone: ToneType;
  onContentUpdate: (content: string) => void;
}

interface ActionButton {
  action: RefinementAction;
  label: string;
  icon: React.ReactNode;
}

const actions: ActionButton[] = [
  { action: "auto-refine", label: "Auto Refine", icon: <Sparkles className="h-3.5 w-3.5" /> },
  { action: "stronger-hook", label: "Stronger Hook", icon: <ArrowUpRight className="h-3.5 w-3.5" /> },
  { action: "stronger-cta", label: "Stronger CTA", icon: <Target className="h-3.5 w-3.5" /> },
  { action: "shorten", label: "Shorten", icon: <Minimize2 className="h-3.5 w-3.5" /> },
  { action: "expand", label: "Expand", icon: <Maximize2 className="h-3.5 w-3.5" /> },
  { action: "tighten", label: "Tighten", icon: <Scissors className="h-3.5 w-3.5" /> },
  { action: "rewrite", label: "Rewrite", icon: <RefreshCw className="h-3.5 w-3.5" /> },
  { action: "add-value", label: "Add Value", icon: <Plus className="h-3.5 w-3.5" /> },
  { action: "more-casual", label: "More Casual", icon: <MessageCircle className="h-3.5 w-3.5" /> },
  { action: "more-professional", label: "More Professional", icon: <Award className="h-3.5 w-3.5" /> },
  { action: "make-viral", label: "Make it Viral", icon: <Zap className="h-3.5 w-3.5" /> },
  { action: "split-thread", label: "Split into Thread", icon: <SplitSquareHorizontal className="h-3.5 w-3.5" /> },
];

export default function AIToolbar({
  content,
  platform,
  tone,
  onContentUpdate,
}: AIToolbarProps) {
  const [loadingAction, setLoadingAction] = useState<RefinementAction | null>(null);
  const [previousContent, setPreviousContent] = useState<string | null>(null);
  const [showDiff, setShowDiff] = useState(false);
  const [diffContent, setDiffContent] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  const handleAction = async (action: RefinementAction) => {
    if (!content.trim() || loadingAction) return;

    setLoadingAction(action);
    setPreviousContent(content);
    setDiffContent(null);

    try {
      const res = await fetch("/api/ai/refine", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          content,
          action,
          platform,
          tone,
        }),
      });

      if (!res.ok) throw new Error("Refinement failed");

      if (res.headers.get("content-type")?.includes("text/event-stream")) {
        const reader = res.body?.getReader();
        const decoder = new TextDecoder();
        let result = "";

        if (reader) {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            const chunk = decoder.decode(value);
            const lines = chunk.split("\n");
            for (const line of lines) {
              if (line.startsWith("data: ")) {
                const data = line.slice(6);
                if (data === "[DONE]") break;
                try {
                  const parsed = JSON.parse(data);
                  result += parsed.text || "";
                  onContentUpdate(result);
                } catch {
                  result += data;
                  onContentUpdate(result);
                }
              }
            }
          }
        }
        setDiffContent(result);
      } else {
        const data = await res.json();
        const refined = data.content || data.result || content;
        setDiffContent(refined);
        onContentUpdate(refined);
      }
    } catch {
      // Silently handle - content stays unchanged
    } finally {
      setLoadingAction(null);
    }
  };

  const handleUndo = () => {
    if (previousContent !== null) {
      onContentUpdate(previousContent);
      setPreviousContent(null);
      setDiffContent(null);
      setShowDiff(false);
    }
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-[#94A3B8] uppercase tracking-wider">
          AI Refinement
        </span>
        <div className="flex items-center gap-1">
          {diffContent && previousContent && (
            <button
              type="button"
              onClick={() => setShowDiff(!showDiff)}
              className={cn(
                "inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs transition-colors",
                showDiff
                  ? "bg-[#4CC9F0]/20 text-[#4CC9F0]"
                  : "text-[#94A3B8] hover:text-white hover:bg-white/5"
              )}
            >
              <GitCompare className="h-3 w-3" />
              Diff
            </button>
          )}
          {previousContent !== null && (
            <button
              type="button"
              onClick={handleUndo}
              className="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs text-[#94A3B8] hover:text-white hover:bg-white/5 transition-colors"
            >
              <Undo2 className="h-3 w-3" />
              Undo
            </button>
          )}
        </div>
      </div>

      {showDiff && previousContent && diffContent && (
        <div className="rounded-lg border border-white/10 bg-white/5 p-3 text-xs space-y-2 max-h-40 overflow-y-auto">
          <div className="text-red-400/80">
            <span className="font-mono text-red-500 mr-1">-</span>
            {previousContent}
          </div>
          <div className="text-[#16E1C4]/80">
            <span className="font-mono text-[#16E1C4] mr-1">+</span>
            {diffContent}
          </div>
        </div>
      )}

      <div
        ref={scrollRef}
        className="flex gap-2 overflow-x-auto pb-1 scrollbar-thin scrollbar-track-transparent scrollbar-thumb-white/10"
      >
        {actions.map((a) => {
          const isLoading = loadingAction === a.action;
          return (
            <button
              key={a.action}
              type="button"
              onClick={() => handleAction(a.action)}
              disabled={!content.trim() || loadingAction !== null}
              className={cn(
                "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full border px-3 py-1.5 text-xs font-medium transition-all duration-200 shrink-0",
                isLoading
                  ? "bg-[#FF006E]/20 text-[#FF006E] border-[#FF006E]/40"
                  : "bg-white/5 text-[#94A3B8] border-white/10 hover:bg-white/10 hover:text-white hover:border-white/20 disabled:opacity-40 disabled:cursor-not-allowed"
              )}
            >
              {isLoading ? (
                <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-[#FF006E]/30 border-t-[#FF006E]" />
              ) : (
                a.icon
              )}
              {a.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
