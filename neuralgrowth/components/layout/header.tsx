"use client";

import React from "react";
import { usePathname } from "next/navigation";
import { Bell, FileText, Menu } from "lucide-react";
import { cn } from "@/lib/utils";

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

  const pageTitle =
    routeTitles[pathname] ??
    Object.entries(routeTitles).find(([key]) =>
      pathname.startsWith(key)
    )?.[1] ??
    "Dashboard";

  return (
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
  );
}
