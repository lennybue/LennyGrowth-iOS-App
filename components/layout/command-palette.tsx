"use client";

import React, { useState, useEffect, useCallback, useRef } from "react";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import {
  Search,
  PenSquare,
  CalendarDays,
  Zap,
  Bot,
  BarChart3,
  Settings,
  User,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface CommandPaletteProps {
  open: boolean;
  onClose: () => void;
}

const COMMANDS = [
  { id: "compose", label: "New Post", shortcut: "C", icon: PenSquare, href: "/compose" },
  { id: "calendar", label: "Calendar", shortcut: "L", icon: CalendarDays, href: "/calendar" },
  { id: "engagement", label: "Engagement Hub", shortcut: "E", icon: Zap, href: "/engagement" },
  { id: "ai-content", label: "AI Content Pool", shortcut: "A", icon: Bot, href: "/ai-content" },
  { id: "analytics", label: "Analytics", shortcut: "N", icon: BarChart3, href: "/analytics" },
  { id: "settings", label: "Settings", shortcut: "S", icon: Settings, href: "/settings" },
  { id: "account", label: "Account", shortcut: "U", icon: User, href: "/account" },
];

export default function CommandPalette({ open, onClose }: CommandPaletteProps) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [activeIndex, setActiveIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  const filtered = COMMANDS.filter((cmd) =>
    cmd.label.toLowerCase().includes(query.toLowerCase())
  );

  // Reset state when opened/closed
  useEffect(() => {
    if (open) {
      setQuery("");
      setActiveIndex(0);
      // Focus input after animation frame so the element is rendered
      requestAnimationFrame(() => {
        inputRef.current?.focus();
      });
    }
  }, [open]);

  // Clamp activeIndex when filtered results change
  useEffect(() => {
    setActiveIndex((prev) => Math.min(prev, Math.max(filtered.length - 1, 0)));
  }, [filtered.length]);

  // Scroll active item into view
  useEffect(() => {
    if (!listRef.current) return;
    const active = listRef.current.children[activeIndex] as HTMLElement | undefined;
    active?.scrollIntoView({ block: "nearest" });
  }, [activeIndex]);

  const navigate = useCallback(
    (href: string) => {
      onClose();
      router.push(href);
    },
    [onClose, router]
  );

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      switch (e.key) {
        case "ArrowDown":
          e.preventDefault();
          setActiveIndex((prev) => (prev + 1) % filtered.length);
          break;
        case "ArrowUp":
          e.preventDefault();
          setActiveIndex((prev) => (prev - 1 + filtered.length) % filtered.length);
          break;
        case "Enter":
          e.preventDefault();
          if (filtered[activeIndex]) {
            navigate(filtered[activeIndex].href);
          }
          break;
        case "Escape":
          e.preventDefault();
          onClose();
          break;
      }
    },
    [filtered, activeIndex, navigate, onClose]
  );

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          className="fixed inset-0 z-50 flex items-start justify-center pt-[20vh]"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}
        >
          {/* Backdrop */}
          <motion.div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={onClose}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          />

          {/* Modal */}
          <motion.div
            className="relative w-full max-w-lg mx-4 rounded-2xl border border-white/10 bg-[#111827]/95 backdrop-blur-md shadow-2xl overflow-hidden"
            initial={{ opacity: 0, scale: 0.95, y: -10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: -10 }}
            transition={{ duration: 0.15 }}
            onKeyDown={handleKeyDown}
          >
            {/* Search input */}
            <div className="flex items-center gap-3 border-b border-white/10 px-4 py-3">
              <Search className="h-5 w-5 shrink-0 text-text-secondary" />
              <input
                ref={inputRef}
                type="text"
                placeholder="Type a command..."
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setActiveIndex(0);
                }}
                className="flex-1 bg-transparent text-sm text-white placeholder-text-secondary outline-none"
              />
              <button
                onClick={onClose}
                className="rounded-lg p-1 text-text-secondary hover:bg-white/10 hover:text-white transition-smooth"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Command list */}
            <div ref={listRef} className="max-h-72 overflow-y-auto p-2">
              {filtered.length === 0 && (
                <p className="px-3 py-6 text-center text-sm text-text-secondary">
                  No commands found.
                </p>
              )}
              {filtered.map((cmd, i) => {
                const Icon = cmd.icon;
                const isActive = i === activeIndex;
                return (
                  <button
                    key={cmd.id}
                    onClick={() => navigate(cmd.href)}
                    onMouseEnter={() => setActiveIndex(i)}
                    className={cn(
                      "flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-smooth",
                      isActive
                        ? "bg-neon-magenta/20 text-neon-magenta"
                        : "text-text-secondary hover:text-white"
                    )}
                  >
                    <Icon className="h-4 w-4 shrink-0" />
                    <span className="flex-1 text-left font-medium">{cmd.label}</span>
                    <kbd
                      className={cn(
                        "hidden sm:inline-flex min-w-[24px] items-center justify-center rounded-md border px-1.5 py-0.5 text-[11px] font-mono",
                        isActive
                          ? "border-neon-magenta/30 text-neon-magenta"
                          : "border-white/10 text-text-secondary"
                      )}
                    >
                      {cmd.shortcut}
                    </kbd>
                  </button>
                );
              })}
            </div>

            {/* Footer hint */}
            <div className="flex items-center gap-4 border-t border-white/10 px-4 py-2.5 text-[11px] text-text-secondary">
              <span className="flex items-center gap-1">
                <kbd className="rounded border border-white/10 px-1 py-0.5 font-mono">↑↓</kbd>
                navigate
              </span>
              <span className="flex items-center gap-1">
                <kbd className="rounded border border-white/10 px-1 py-0.5 font-mono">↵</kbd>
                select
              </span>
              <span className="flex items-center gap-1">
                <kbd className="rounded border border-white/10 px-1 py-0.5 font-mono">esc</kbd>
                close
              </span>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
