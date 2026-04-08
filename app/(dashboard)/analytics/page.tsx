"use client";

import { useState, useMemo } from "react";
import { motion } from "framer-motion";
import {
  Eye,
  Heart,
  MessageCircle,
  Repeat2,
  TrendingUp,
  TrendingDown,
  Users,
  BarChart3,
  RefreshCw,
  ExternalLink,
  ArrowUpRight,
  ArrowDownRight,
  Copy,
  Clock,
  Info,
} from "lucide-react";
import { cn } from "@/lib/utils";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import type { Platform, MetricWidget, TopPost } from "@/types";

type DateRange = "7d" | "30d" | "90d";
type MetricType = "views" | "likes" | "comments" | "engagement" | "followers";

// Mock analytics data
const MOCK_METRICS: MetricWidget[] = [
  { label: "Total Views", value: 24830, change: 2760, changePercent: 12.4, trend: "up", icon: "eye" },
  { label: "Total Likes", value: 1847, change: 243, changePercent: 15.1, trend: "up", icon: "heart" },
  { label: "Total Comments", value: 342, change: -18, changePercent: -5.0, trend: "down", icon: "message" },
  { label: "Total Reposts", value: 198, change: 34, changePercent: 20.7, trend: "up", icon: "repeat" },
  { label: "Engagement Rate", value: 4.8, change: 0.6, changePercent: 14.3, trend: "up", icon: "trending" },
  { label: "Follower Growth", value: 156, change: 156, changePercent: 0, trend: "up", icon: "users" },
];

const MOCK_CHART_DATA = Array.from({ length: 30 }, (_, i) => ({
  date: new Date(Date.now() - (29 - i) * 86400000).toLocaleDateString("en-US", { month: "short", day: "numeric" }),
  threads: Math.floor(Math.random() * 1200 + 400),
  linkedin: Math.floor(Math.random() * 800 + 200),
}));

const MOCK_TOP_POSTS: TopPost[] = [
  {
    id: "tp1",
    content: "I stopped using hashtags on Threads 3 months ago. Result: +340% more impressions...",
    platform: "threads",
    date: "2026-03-28",
    views: 8420,
    likes: 634,
    comments: 89,
    engagementRate: 8.6,
  },
  {
    id: "tp2",
    content: "The #1 Google Ads mistake costing you money right now? You're optimizing for clicks...",
    platform: "threads",
    date: "2026-03-25",
    views: 6210,
    likes: 478,
    comments: 67,
    engagementRate: 8.8,
  },
  {
    id: "tp3",
    content: "3 years ago, I was burning €50k/month on Google Ads with a 0.8% CTR...",
    platform: "linkedin",
    date: "2026-03-22",
    views: 4890,
    likes: 312,
    comments: 54,
    engagementRate: 7.5,
  },
  {
    id: "tp4",
    content: "AI won't replace marketers. But marketers who use AI will replace those who don't...",
    platform: "threads",
    date: "2026-03-20",
    views: 3750,
    likes: 289,
    comments: 41,
    engagementRate: 8.8,
  },
  {
    id: "tp5",
    content: "Every marketer should learn to code. Not to become a developer...",
    platform: "threads",
    date: "2026-03-18",
    views: 3200,
    likes: 198,
    comments: 36,
    engagementRate: 7.3,
  },
];

// Posting heatmap data (hour x day)
const HEATMAP_DATA = Array.from({ length: 7 }, (_, day) =>
  Array.from({ length: 24 }, (_, hour) => ({
    day,
    hour,
    value: Math.random() * (hour >= 7 && hour <= 21 ? 10 : 2),
  }))
).flat();

const ICON_MAP: Record<string, React.ReactNode> = {
  eye: <Eye className="w-5 h-5" />,
  heart: <Heart className="w-5 h-5" />,
  message: <MessageCircle className="w-5 h-5" />,
  repeat: <Repeat2 className="w-5 h-5" />,
  trending: <TrendingUp className="w-5 h-5" />,
  users: <Users className="w-5 h-5" />,
};

function formatNumber(n: number): string {
  if (n >= 10000) return `${(n / 1000).toFixed(1)}k`;
  if (n >= 1000) return `${(n / 1000).toFixed(1)}k`;
  return n.toFixed(n % 1 === 0 ? 0 : 1);
}

const DAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

function CustomTooltip({ active, payload, label }: { active?: boolean; payload?: Array<{ value: number; dataKey: string; color: string }>; label?: string }) {
  if (!active || !payload) return null;
  return (
    <div className="glass-card p-3 text-xs space-y-1">
      <p className="text-white font-medium">{label}</p>
      {payload.map((p) => (
        <p key={p.dataKey} style={{ color: p.color }}>
          {p.dataKey}: {formatNumber(p.value)}
        </p>
      ))}
    </div>
  );
}

export default function AnalyticsPage() {
  const [platformFilter, setPlatformFilter] = useState<Platform | "both">("both");
  const [dateRange, setDateRange] = useState<DateRange>("30d");
  const [activeMetric, setActiveMetric] = useState<MetricType>("views");
  const [sortColumn, setSortColumn] = useState<string>("views");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("desc");

  const sortedPosts = useMemo(() => {
    return [...MOCK_TOP_POSTS].sort((a, b) => {
      const aVal = a[sortColumn as keyof TopPost] as number;
      const bVal = b[sortColumn as keyof TopPost] as number;
      return sortDir === "desc" ? bVal - aVal : aVal - bVal;
    });
  }, [sortColumn, sortDir]);

  return (
    <div className="h-full flex flex-col gap-6 overflow-y-auto">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3">
          {/* Platform Toggle */}
          {(["threads", "linkedin", "both"] as const).map((p) => (
            <button
              key={p}
              onClick={() => setPlatformFilter(p)}
              className={cn(
                "px-3 py-1.5 rounded-full text-xs font-medium transition-smooth capitalize",
                platformFilter === p
                  ? "bg-neon-magenta text-white"
                  : "glass-card text-text-secondary hover:text-white"
              )}
            >
              {p === "threads" ? "🧵 Threads" : p === "linkedin" ? "💼 LinkedIn" : "⚡ Both"}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          {(["7d", "30d", "90d"] as DateRange[]).map((range) => (
            <button
              key={range}
              onClick={() => setDateRange(range)}
              className={cn(
                "px-3 py-1.5 rounded-lg text-xs font-medium transition-smooth",
                dateRange === range
                  ? "bg-white/10 text-white"
                  : "text-text-secondary hover:text-white"
              )}
            >
              {range === "7d" ? "7 Days" : range === "30d" ? "30 Days" : "90 Days"}
            </button>
          ))}
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg glass-card text-xs text-text-secondary hover:text-white transition-smooth">
            <RefreshCw className="w-3 h-3" /> Refresh
          </button>
        </div>
      </div>

      {/* LinkedIn disclaimer */}
      {(platformFilter === "linkedin" || platformFilter === "both") && (
        <div className="flex items-center gap-2 px-4 py-2 rounded-lg bg-ice-blue/10 border border-ice-blue/20 text-xs text-ice-blue">
          <Info className="w-4 h-4 shrink-0" />
          LinkedIn data limited to post-level metrics. For full analytics, visit LinkedIn Analytics.
        </div>
      )}

      {/* KPI Widgets */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {MOCK_METRICS.map((metric) => (
          <motion.div
            key={metric.label}
            whileHover={{ scale: 1.02 }}
            className="glass-card p-4 space-y-2"
          >
            <div className="flex items-center justify-between">
              <span className={cn(
                "opacity-60",
                metric.trend === "up" ? "text-neon-teal" : "text-neon-magenta"
              )}>
                {ICON_MAP[metric.icon]}
              </span>
              {metric.trend === "up" ? (
                <ArrowUpRight className="w-4 h-4 text-neon-teal" />
              ) : (
                <ArrowDownRight className="w-4 h-4 text-neon-magenta" />
              )}
            </div>
            <div>
              <p className="text-2xl font-bold text-white font-mono">
                {formatNumber(metric.value)}
                {metric.icon === "trending" && "%"}
              </p>
              <p className="text-xs text-text-secondary mt-0.5">{metric.label}</p>
            </div>
            <p
              className={cn(
                "text-xs font-medium",
                metric.trend === "up" ? "text-neon-teal" : "text-neon-magenta"
              )}
            >
              {metric.trend === "up" ? "↑" : "↓"} {Math.abs(metric.changePercent)}%
              <span className="text-text-secondary font-normal ml-1">vs. last period</span>
            </p>
          </motion.div>
        ))}
      </div>

      {/* Main Chart */}
      <div className="glass-card p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-sm font-semibold text-white">Performance Over Time</h3>
          <div className="flex items-center gap-2">
            {(["views", "likes", "comments", "engagement", "followers"] as MetricType[]).map((m) => (
              <button
                key={m}
                onClick={() => setActiveMetric(m)}
                className={cn(
                  "px-3 py-1 rounded-full text-xs font-medium capitalize transition-smooth",
                  activeMetric === m
                    ? "bg-neon-magenta/20 text-neon-magenta"
                    : "text-text-secondary hover:text-white"
                )}
              >
                {m}
              </button>
            ))}
          </div>
        </div>
        <div className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={MOCK_CHART_DATA}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
              <XAxis
                dataKey="date"
                tick={{ fill: "#94A3B8", fontSize: 11 }}
                axisLine={{ stroke: "rgba(255,255,255,0.1)" }}
                tickLine={false}
              />
              <YAxis
                tick={{ fill: "#94A3B8", fontSize: 11 }}
                axisLine={false}
                tickLine={false}
                tickFormatter={(v) => formatNumber(v)}
              />
              <Tooltip content={<CustomTooltip />} />
              <Legend
                wrapperStyle={{ fontSize: 12, paddingTop: 8 }}
              />
              {(platformFilter === "threads" || platformFilter === "both") && (
                <Line
                  type="monotone"
                  dataKey="threads"
                  stroke="#16E1C4"
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 4, fill: "#16E1C4" }}
                />
              )}
              {(platformFilter === "linkedin" || platformFilter === "both") && (
                <Line
                  type="monotone"
                  dataKey="linkedin"
                  stroke="#FF006E"
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 4, fill: "#FF006E" }}
                />
              )}
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Top Posts Table + Best Time Heatmap side by side */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Top Posts */}
        <div className="lg:col-span-2 glass-card p-4 overflow-x-auto">
          <h3 className="text-sm font-semibold text-white mb-4">Top Performing Posts</h3>
          <table className="w-full text-xs">
            <thead>
              <tr className="text-left text-text-secondary border-b border-white/5">
                <th className="pb-3 pr-4">Content</th>
                <th className="pb-3 pr-3">Platform</th>
                <th className="pb-3 pr-3 cursor-pointer hover:text-white" onClick={() => { setSortColumn("views"); setSortDir(sortDir === "desc" ? "asc" : "desc"); }}>
                  Views {sortColumn === "views" && (sortDir === "desc" ? "↓" : "↑")}
                </th>
                <th className="pb-3 pr-3 cursor-pointer hover:text-white" onClick={() => { setSortColumn("likes"); setSortDir(sortDir === "desc" ? "asc" : "desc"); }}>
                  Likes {sortColumn === "likes" && (sortDir === "desc" ? "↓" : "↑")}
                </th>
                <th className="pb-3 pr-3 cursor-pointer hover:text-white" onClick={() => { setSortColumn("comments"); setSortDir(sortDir === "desc" ? "asc" : "desc"); }}>
                  Comments {sortColumn === "comments" && (sortDir === "desc" ? "↓" : "↑")}
                </th>
                <th className="pb-3 pr-3 cursor-pointer hover:text-white" onClick={() => { setSortColumn("engagementRate"); setSortDir(sortDir === "desc" ? "asc" : "desc"); }}>
                  Eng% {sortColumn === "engagementRate" && (sortDir === "desc" ? "↓" : "↑")}
                </th>
                <th className="pb-3">Actions</th>
              </tr>
            </thead>
            <tbody>
              {sortedPosts.map((post) => (
                <tr key={post.id} className="border-b border-white/[0.03] hover:bg-white/[0.02]">
                  <td className="py-3 pr-4 max-w-[200px]">
                    <p className="text-white/80 truncate">{post.content}</p>
                    <p className="text-text-secondary mt-0.5">{post.date}</p>
                  </td>
                  <td className="py-3 pr-3">
                    <span className="px-2 py-0.5 rounded-full bg-white/5 capitalize">
                      {post.platform === "threads" ? "🧵" : "💼"} {post.platform}
                    </span>
                  </td>
                  <td className="py-3 pr-3 text-white font-mono">{formatNumber(post.views)}</td>
                  <td className="py-3 pr-3 text-white font-mono">{formatNumber(post.likes)}</td>
                  <td className="py-3 pr-3 text-white font-mono">{post.comments}</td>
                  <td className="py-3 pr-3">
                    <span className="text-neon-teal font-mono">{post.engagementRate}%</span>
                  </td>
                  <td className="py-3">
                    <div className="flex items-center gap-1">
                      <button className="p-1 rounded hover:bg-white/5 text-text-secondary hover:text-white transition-smooth" title="View">
                        <ExternalLink className="w-3 h-3" />
                      </button>
                      <button className="p-1 rounded hover:bg-white/5 text-text-secondary hover:text-ice-blue transition-smooth" title="Reuse">
                        <Copy className="w-3 h-3" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Best Time Heatmap */}
        <div className="glass-card p-4">
          <h3 className="text-sm font-semibold text-white mb-4">Best Time to Post</h3>
          <div className="space-y-1">
            {DAY_LABELS.map((day, dayIdx) => (
              <div key={day} className="flex items-center gap-1">
                <span className="text-[10px] text-text-secondary w-8 shrink-0">{day}</span>
                <div className="flex gap-px flex-1">
                  {Array.from({ length: 24 }, (_, hour) => {
                    const dataPoint = HEATMAP_DATA.find(
                      (d) => d.day === dayIdx && d.hour === hour
                    );
                    const intensity = dataPoint ? dataPoint.value / 10 : 0;
                    return (
                      <div
                        key={hour}
                        className="flex-1 h-4 rounded-sm transition-smooth"
                        style={{
                          backgroundColor: `rgba(22, 225, 196, ${intensity * 0.8})`,
                        }}
                        title={`${day} ${hour}:00 — Score: ${dataPoint?.value.toFixed(1)}`}
                      />
                    );
                  })}
                </div>
              </div>
            ))}
            <div className="flex items-center justify-between mt-2">
              <span className="text-[10px] text-text-secondary">0:00</span>
              <span className="text-[10px] text-text-secondary">12:00</span>
              <span className="text-[10px] text-text-secondary">23:00</span>
            </div>
          </div>
          <div className="flex items-center gap-2 mt-3 text-[10px] text-text-secondary">
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 rounded-sm" style={{ backgroundColor: "rgba(22, 225, 196, 0.1)" }} />
              Low
            </div>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 rounded-sm" style={{ backgroundColor: "rgba(22, 225, 196, 0.4)" }} />
              Med
            </div>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 rounded-sm" style={{ backgroundColor: "rgba(22, 225, 196, 0.8)" }} />
              High
            </div>
          </div>
        </div>
      </div>

      {/* Last updated */}
      <div className="flex items-center gap-2 text-xs text-text-secondary pb-4">
        <Clock className="w-3 h-3" />
        Last updated: 23 minutes ago
      </div>
    </div>
  );
}
