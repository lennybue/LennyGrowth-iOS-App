"use client";

import React, { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import {
  PenSquare,
  CalendarDays,
  Zap,
  Bot,
  BarChart3,
  Settings,
  User,
  ChevronsLeft,
  ChevronsRight,
  Menu,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface NavItem {
  label: string;
  href: string;
  icon: React.ElementType;
}

const mainNav: NavItem[] = [
  { label: "Compose", href: "/compose", icon: PenSquare },
  { label: "Calendar", href: "/calendar", icon: CalendarDays },
  { label: "Engagement", href: "/engagement", icon: Zap },
  { label: "AI Content", href: "/ai-content", icon: Bot },
  { label: "Analytics", href: "/analytics", icon: BarChart3 },
];

const bottomNav: NavItem[] = [
  { label: "Settings", href: "/settings", icon: Settings },
  { label: "Account", href: "/account", icon: User },
];

function NavLink({
  item,
  collapsed,
  isActive,
}: {
  item: NavItem;
  collapsed: boolean;
  isActive: boolean;
}) {
  const Icon = item.icon;

  return (
    <Link
      href={item.href}
      className={cn(
        "group relative flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-200",
        isActive
          ? "text-white"
          : "text-text-secondary hover:text-white"
      )}
    >
      {/* Active indicator */}
      {isActive && (
        <motion.div
          layoutId="sidebar-active"
          className="absolute left-0 top-0 h-full w-[3px] rounded-r-full bg-neon-magenta"
          transition={{ type: "spring", stiffness: 350, damping: 30 }}
        />
      )}

      {/* Active glow background */}
      {isActive && (
        <div className="absolute inset-0 rounded-lg bg-neon-magenta/10" />
      )}

      <Icon className={cn("relative h-5 w-5 shrink-0", isActive && "text-neon-magenta")} />
      <AnimatePresence>
        {!collapsed && (
          <motion.span
            initial={{ opacity: 0, width: 0 }}
            animate={{ opacity: 1, width: "auto" }}
            exit={{ opacity: 0, width: 0 }}
            className="relative overflow-hidden whitespace-nowrap"
          >
            {item.label}
          </motion.span>
        )}
      </AnimatePresence>
    </Link>
  );
}

export default function Sidebar() {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  const isActive = (href: string) =>
    pathname === href || pathname.startsWith(href + "/");

  const sidebarContent = (
    <div className="flex h-full flex-col">
      {/* Logo */}
      <div className="flex h-16 items-center px-4">
        {collapsed ? (
          <span className="mx-auto text-lg font-bold">
            <span className="bg-gradient-to-r from-neon-magenta to-neon-teal bg-clip-text text-transparent">
              LB
            </span>
          </span>
        ) : (
          <span className="text-lg font-bold tracking-tight">
            <span className="bg-gradient-to-r from-neon-magenta via-ice-blue to-neon-teal bg-clip-text text-transparent">
              NeuralGrowth
            </span>
          </span>
        )}
      </div>

      {/* Main nav */}
      <nav className="mt-4 flex-1 space-y-1 px-3">
        {mainNav.map((item) => (
          <NavLink
            key={item.href}
            item={item}
            collapsed={collapsed}
            isActive={isActive(item.href)}
          />
        ))}
      </nav>

      {/* Bottom nav */}
      <div className="space-y-1 px-3 pb-4">
        {bottomNav.map((item) => (
          <NavLink
            key={item.href}
            item={item}
            collapsed={collapsed}
            isActive={isActive(item.href)}
          />
        ))}

        {/* Collapse toggle - desktop only */}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="hidden md:flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm text-text-secondary hover:text-white transition-colors"
        >
          {collapsed ? (
            <ChevronsRight className="h-5 w-5 shrink-0 mx-auto" />
          ) : (
            <>
              <ChevronsLeft className="h-5 w-5 shrink-0" />
              <span>Collapse</span>
            </>
          )}
        </button>
      </div>
    </div>
  );

  return (
    <>
      {/* Desktop sidebar */}
      <motion.aside
        animate={{ width: collapsed ? 72 : 256 }}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        className={cn(
          "hidden md:flex flex-col shrink-0 h-screen sticky top-0",
          "border-r border-white/[0.08]",
          "bg-bg-surface/80 backdrop-blur-xl"
        )}
      >
        {sidebarContent}
      </motion.aside>

      {/* Mobile hamburger button */}
      <button
        onClick={() => setMobileOpen(true)}
        className="fixed top-4 left-4 z-50 md:hidden rounded-lg p-2 text-text-secondary hover:text-white bg-bg-surface/80 backdrop-blur-md border border-white/[0.08]"
        aria-label="Open menu"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* Mobile drawer overlay */}
      <AnimatePresence>
        {mobileOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm md:hidden"
              onClick={() => setMobileOpen(false)}
            />
            <motion.aside
              initial={{ x: -280 }}
              animate={{ x: 0 }}
              exit={{ x: -280 }}
              transition={{ type: "spring", stiffness: 300, damping: 30 }}
              className={cn(
                "fixed left-0 top-0 z-50 h-screen w-[280px] md:hidden",
                "border-r border-white/[0.08]",
                "bg-bg-surface/95 backdrop-blur-xl"
              )}
            >
              <button
                onClick={() => setMobileOpen(false)}
                className="absolute right-3 top-4 rounded-lg p-1.5 text-text-secondary hover:text-white"
                aria-label="Close menu"
              >
                <X className="h-5 w-5" />
              </button>
              {sidebarContent}
            </motion.aside>
          </>
        )}
      </AnimatePresence>
    </>
  );
}
