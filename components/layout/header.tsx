"use client";

import React, { useState, useEffect } from "react";
import { usePathname } from "next/navigation";
import { Bell, FileText, Command } from "lucide-react";
import { cn } from "@/lib/utils";
import DraftsPanel from "@/components/layout/drafts-panel";
import CommandPalette from "@/components/layout/command-palette";

const routeTitles: Record<string, string> = {
  "/compose": "Compose",
  "/calendar": "Calendar",
  "/engagement": "Engagement Hub",
  "/ai-content": "AI Content Pool",
  "/analytics": "Analytics",
  "/settings": "Settings",
  "/account": "Account",
};

export default function Header() {
  const pathname = usePathname();
  const [draftsOpen, setDraftsOpen] = useState(false);
  const [commandOpen, setCommandOpen] = useState(false);

  // Cmd+K shortcut
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setCommandOpen((prev) => !prev);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const pageTitle =
    routeTitles[pathname] ??
    Object.entries(routeTitles).find(([key]) =>
      pathname.startsWith(key)
    )?.[1] ??
    "Dashboard";

  return (
    <>
      <header
        className={cn(
          "sticky top-0 z-30 flex h-16 items-center justify-between gap-4 px-4 md:px-6",
          "border-b border-white/[0.08]",
          "bg-bg-primary/80 backdrop-blur-xl"
        )}
      >
        {/* Left side */}
        <div className="flex items-center gap-3">
          {/* Spacer for mobile hamburger */}
          <div className="w-10 md:hidden" />
          <h1 className="text-lg font-semibold text-white">{pageTitle}</h1>
        </div>

        {/* Right side */}
        <div className="flex items-center gap-2">
          {/* Command palette trigger */}
          <button
            onClick={() => setCommandOpen(true)}
            className="hidden md:flex items-center gap-2 rounded-lg px-3 py-1.5 text-xs text-text-secondary hover:text-white hover:bg-white/[0.06] transition-colors border border-white/[0.08]"
            aria-label="Command palette"
          >
            <Command className="h-3 w-3" />
            <span>Search</span>
            <kbd className="ml-1 rounded bg-white/[0.06] px-1.5 py-0.5 text-[10px] font-mono">K</kbd>
          </button>

          {/* Notification bell */}
          <button
            className="relative rounded-lg p-2 text-text-secondary hover:text-white hover:bg-white/[0.06] transition-colors"
            aria-label="Notifications"
          >
            <Bell className="h-5 w-5" />
            {/* Notification dot */}
            <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-neon-magenta" />
          </button>

          {/* Drafts button */}
          <button
            onClick={() => setDraftsOpen(true)}
            className="hidden sm:flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-text-secondary hover:text-white hover:bg-white/[0.06] transition-colors"
            aria-label="View drafts"
          >
            <FileText className="h-4 w-4" />
            <span>Drafts</span>
          </button>

          {/* User avatar */}
          <button
            className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-neon-magenta to-ice-blue text-xs font-bold text-white"
            aria-label="User menu"
          >
            LB
          </button>
        </div>
      </header>

      {/* Drafts Panel */}
      <DraftsPanel open={draftsOpen} onClose={() => setDraftsOpen(false)} />

      {/* Command Palette */}
      <CommandPalette open={commandOpen} onClose={() => setCommandOpen(false)} />
    </>
  );
}
