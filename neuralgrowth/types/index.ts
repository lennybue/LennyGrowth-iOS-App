// ============================================================
// NeuralGrowth Type Definitions
// ============================================================

export type Platform = "threads" | "linkedin" | "both";

export type PostStatus = "draft" | "scheduled" | "published" | "failed";

export type PostType = "text" | "image" | "carousel" | "thread";

export type ToneType =
  | "professional"
  | "casual"
  | "bold"
  | "witty"
  | "inspiring"
  | "data-driven";

export type HookFormat =
  | "confession"
  | "number"
  | "hot-take"
  | "contrarian"
  | "story"
  | "data"
  | "question";

export type ReplyType =
  | "add-value"
  | "bold-take"
  | "question"
  | "data-point"
  | "witty"
  | "agree-extend";

export type ContentPoolStatus = "draft" | "scheduled" | "trashed";

export type NicheTag =
  | "seo"
  | "google-ads"
  | "ai-marketing"
  | "content-marketing"
  | "personal-brand"
  | "social-media-growth"
  | "analytics"
  | "conversion-rate"
  | "email-marketing"
  | "freelancing";

export type Language = "german" | "english" | "mixed";

// Database Models
export interface User {
  id: string;
  email: string;
  threads_token: string | null;
  linkedin_token: string | null;
  threads_handle: string | null;
  linkedin_name: string | null;
  niche_tags: NicheTag[];
  tone_preference: ToneType;
  language_preference: Language;
  hook_formats: HookFormat[];
  created_at: string;
}

export interface Post {
  id: string;
  user_id: string;
  content_threads: string | null;
  content_linkedin: string | null;
  platforms: Platform[];
  status: PostStatus;
  post_type: PostType;
  scheduled_at: string | null;
  published_at: string | null;
  threads_post_id: string | null;
  linkedin_post_id: string | null;
  media_urls: string[];
  created_at: string;
  updated_at: string;
}

export interface EngagementPost {
  id: string;
  user_id: string;
  threads_post_id: string;
  author_handle: string;
  content: string;
  likes: number;
  replies: number;
  permalink: string | null;
  saved: boolean;
  trashed: boolean;
  liked_by_user: boolean;
  refreshed_at: string;
  expires_at: string;
}

export interface AIContentItem {
  id: string;
  user_id: string;
  content: string;
  platform: Platform;
  status: ContentPoolStatus;
  hook_type: HookFormat;
  topic: string;
  tone: ToneType;
  generated_at: string;
  used_at: string | null;
}

export interface AnalyticsCache {
  id: string;
  user_id: string;
  platform: Platform;
  metric_type: string;
  value: number;
  period: string;
  fetched_at: string;
}

// API Types
export interface AIGenerateRequest {
  prompt?: string;
  platform: Platform;
  tone: ToneType;
  count?: number;
  niche_tags?: NicheTag[];
  language?: Language;
  hook_formats?: HookFormat[];
  used_hooks?: HookFormat[];
}

export interface AIRefineRequest {
  content: string;
  action: RefinementAction;
  platform: Platform;
  tone: ToneType;
  customInstruction?: string;
}

export type RefinementAction =
  | "auto-refine"
  | "stronger-hook"
  | "stronger-cta"
  | "shorten"
  | "expand"
  | "tighten"
  | "rewrite"
  | "add-value"
  | "more-casual"
  | "more-professional"
  | "make-viral"
  | "split-thread";

export interface AIEngageRequest {
  originalContent: string;
  authorHandle: string;
  replyType: ReplyType;
}

export interface SchedulePostRequest {
  postId: string;
  scheduledAt: string;
  platforms: Platform[];
}

// Analytics Types
export interface MetricWidget {
  label: string;
  value: number;
  change: number;
  changePercent: number;
  trend: "up" | "down" | "flat";
  icon: string;
}

export interface ChartDataPoint {
  date: string;
  threads?: number;
  linkedin?: number;
}

export interface TopPost {
  id: string;
  content: string;
  platform: Platform;
  date: string;
  views: number;
  likes: number;
  comments: number;
  engagementRate: number;
}

// Settings
export interface UserSettings {
  remind_linkedin_comment: boolean;
  warn_threads_hashtags: boolean;
  warn_threads_urls: boolean;
  show_optimal_times: boolean;
  notify_published: boolean;
  notify_failed: boolean;
  notify_pool_refilled: boolean;
  notify_engagement_refreshed: boolean;
  notify_weekly_digest: boolean;
}
