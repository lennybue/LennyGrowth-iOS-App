"use client";

import { useState, useEffect } from "react";
import { createClient } from "@/lib/supabase/client";
import {
  Settings,
  Link2,
  Bot,
  Bell,
  Shield,
  CheckCircle2,
  XCircle,
  ExternalLink,
} from "lucide-react";
import { cn } from "@/lib/utils";
import type { ToneType, Language, UserSettings } from "@/types";

function Toggle({
  checked,
  onChange,
}: {
  checked: boolean;
  onChange: (val: boolean) => void;
}) {
  return (
    <button
      onClick={() => onChange(!checked)}
      className={cn(
        "relative w-11 h-6 rounded-full transition-smooth",
        checked ? "bg-neon-teal" : "bg-white/10"
      )}
    >
      <div
        className={cn(
          "absolute top-0.5 w-5 h-5 rounded-full bg-white transition-smooth",
          checked ? "left-[22px]" : "left-0.5"
        )}
      />
    </button>
  );
}

export default function SettingsPage() {
  const supabase = createClient();
  const [threadsHandle, setThreadsHandle] = useState<string | null>(null);
  const [linkedinName, setLinkedinName] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    async function loadProfile() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const { data } = await supabase.from("users").select("*").eq("id", user.id).single();
      if (data) {
        setThreadsHandle(data.threads_handle);
        setLinkedinName(data.linkedin_name);
        if (data.tone_preference) setDefaultTone(data.tone_preference);
        if (data.language_preference) setDefaultLanguage(data.language_preference);
      }
    }
    loadProfile();
  }, [supabase]);

  const [settings, setSettings] = useState<UserSettings>({
    remind_linkedin_comment: true,
    warn_threads_hashtags: true,
    warn_threads_urls: true,
    show_optimal_times: true,
    notify_published: true,
    notify_failed: true,
    notify_pool_refilled: true,
    notify_engagement_refreshed: true,
    notify_weekly_digest: true,
  });

  const [defaultTone, setDefaultTone] = useState<ToneType>("professional");
  const [defaultLanguage, setDefaultLanguage] = useState<Language>("english");

  const updateSetting = (key: keyof UserSettings, value: boolean) => {
    setSettings((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <div className="max-w-3xl mx-auto space-y-8">
      <h1 className="text-xl font-bold text-white flex items-center gap-2">
        <Settings className="w-6 h-6" />
        Settings
      </h1>

      {/* Connected Accounts */}
      <section className="glass-card p-6 space-y-4">
        <h2 className="text-base font-semibold text-white flex items-center gap-2">
          <Link2 className="w-5 h-5 text-ice-blue" />
          Connected Accounts
        </h2>
        <div className="space-y-3">
          <div className="flex items-center justify-between p-4 rounded-xl bg-white/[0.02] border border-white/[0.05]">
            <div className="flex items-center gap-3">
              <span className="text-lg">🧵</span>
              <div>
                <p className="text-sm font-medium text-white">Threads</p>
                {threadsHandle ? (
                  <p className="text-xs text-neon-teal flex items-center gap-1">
                    <CheckCircle2 className="w-3 h-3" /> Connected: {threadsHandle}
                  </p>
                ) : (
                  <p className="text-xs text-text-secondary flex items-center gap-1">
                    <XCircle className="w-3 h-3" /> Not connected
                  </p>
                )}
              </div>
            </div>
            {threadsHandle ? (
              <button
                onClick={async () => {
                  const { data: { user } } = await supabase.auth.getUser();
                  if (user) {
                    await supabase.from("users").update({ threads_token: null, threads_handle: null }).eq("id", user.id);
                    setThreadsHandle(null);
                  }
                }}
                className="px-3 py-1.5 rounded-lg text-xs text-red-400 hover:bg-red-500/10 transition-smooth"
              >
                Disconnect
              </button>
            ) : (
              <button
                onClick={() => {
                  const params = new URLSearchParams({
                    client_id: process.env.NEXT_PUBLIC_THREADS_APP_ID || "",
                    redirect_uri: `${window.location.origin}/api/auth/threads/callback`,
                    scope: "threads_basic,threads_content_publish,threads_manage_insights",
                    response_type: "code",
                  });
                  window.location.href = `https://threads.net/oauth/authorize?${params}`;
                }}
                className="px-3 py-1.5 rounded-lg text-xs text-neon-teal hover:bg-neon-teal/10 transition-smooth"
              >
                Connect
              </button>
            )}
          </div>
          <div className="flex items-center justify-between p-4 rounded-xl bg-white/[0.02] border border-white/[0.05]">
            <div className="flex items-center gap-3">
              <span className="text-lg">💼</span>
              <div>
                <p className="text-sm font-medium text-white">LinkedIn</p>
                {linkedinName ? (
                  <p className="text-xs text-neon-teal flex items-center gap-1">
                    <CheckCircle2 className="w-3 h-3" /> Connected: {linkedinName}
                  </p>
                ) : (
                  <p className="text-xs text-text-secondary flex items-center gap-1">
                    <XCircle className="w-3 h-3" /> Not connected
                  </p>
                )}
              </div>
            </div>
            {linkedinName ? (
              <button
                onClick={async () => {
                  const { data: { user } } = await supabase.auth.getUser();
                  if (user) {
                    await supabase.from("users").update({ linkedin_token: null, linkedin_name: null }).eq("id", user.id);
                    setLinkedinName(null);
                  }
                }}
                className="px-3 py-1.5 rounded-lg text-xs text-red-400 hover:bg-red-500/10 transition-smooth"
              >
                Disconnect
              </button>
            ) : (
              <button
                onClick={() => {
                  const params = new URLSearchParams({
                    response_type: "code",
                    client_id: process.env.NEXT_PUBLIC_LINKEDIN_CLIENT_ID || "",
                    redirect_uri: `${window.location.origin}/api/auth/linkedin/callback`,
                    scope: "openid profile w_member_social",
                  });
                  window.location.href = `https://www.linkedin.com/oauth/v2/authorization?${params}`;
                }}
                className="px-3 py-1.5 rounded-lg text-xs text-neon-teal hover:bg-neon-teal/10 transition-smooth"
              >
                Connect
              </button>
            )}
          </div>
        </div>
      </section>

      {/* AI Configuration */}
      <section className="glass-card p-6 space-y-4">
        <h2 className="text-base font-semibold text-white flex items-center gap-2">
          <Bot className="w-5 h-5 text-neon-teal" />
          AI Configuration
        </h2>
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm text-text-secondary">API Status</span>
            <span className="text-xs text-neon-teal flex items-center gap-1">
              <CheckCircle2 className="w-3 h-3" /> Claude API: Connected
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-text-secondary">Daily Generation Limit</span>
            <span className="text-xs text-white font-mono">20 / 20 remaining</span>
          </div>
          <div>
            <span className="text-sm text-text-secondary block mb-2">Default Tone</span>
            <div className="flex flex-wrap gap-2">
              {(["professional", "casual", "bold", "witty", "inspiring", "data-driven"] as ToneType[]).map(
                (t) => (
                  <button
                    key={t}
                    onClick={() => setDefaultTone(t)}
                    className={cn(
                      "px-3 py-1 rounded-full text-xs font-medium capitalize transition-smooth",
                      defaultTone === t
                        ? "bg-neon-magenta/20 text-neon-magenta border border-neon-magenta/30"
                        : "glass-card text-text-secondary hover:text-white"
                    )}
                  >
                    {t}
                  </button>
                )
              )}
            </div>
          </div>
          <div>
            <span className="text-sm text-text-secondary block mb-2">Default Language</span>
            <div className="flex gap-2">
              {([
                { value: "german" as Language, label: "German 🇩🇪" },
                { value: "english" as Language, label: "English 🇬🇧" },
                { value: "mixed" as Language, label: "Mixed" },
              ]).map(({ value, label }) => (
                <button
                  key={value}
                  onClick={() => setDefaultLanguage(value)}
                  className={cn(
                    "px-3 py-1.5 rounded-full text-xs font-medium transition-smooth",
                    defaultLanguage === value
                      ? "bg-ice-blue/20 text-ice-blue border border-ice-blue/30"
                      : "glass-card text-text-secondary hover:text-white"
                  )}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Posting Rules */}
      <section className="glass-card p-6 space-y-4">
        <h2 className="text-base font-semibold text-white flex items-center gap-2">
          <Shield className="w-5 h-5 text-neon-magenta" />
          Posting Rule Reminders
        </h2>
        <div className="space-y-3">
          {[
            { key: "remind_linkedin_comment" as const, label: "Remind me to add LinkedIn link as first comment" },
            { key: "warn_threads_hashtags" as const, label: "Warn me about hashtags on Threads" },
            { key: "warn_threads_urls" as const, label: "Warn me about URLs in Threads posts" },
            { key: "show_optimal_times" as const, label: "Show optimal posting time suggestions" },
          ].map(({ key, label }) => (
            <div key={key} className="flex items-center justify-between">
              <span className="text-sm text-text-secondary">{label}</span>
              <Toggle checked={settings[key]} onChange={(v) => updateSetting(key, v)} />
            </div>
          ))}
        </div>
      </section>

      {/* Notifications */}
      <section className="glass-card p-6 space-y-4">
        <h2 className="text-base font-semibold text-white flex items-center gap-2">
          <Bell className="w-5 h-5 text-ice-blue" />
          Notification Preferences
        </h2>
        <div className="space-y-3">
          {[
            { key: "notify_published" as const, label: "Post published successfully" },
            { key: "notify_failed" as const, label: "Post failed to publish → retry option" },
            { key: "notify_pool_refilled" as const, label: "AI content pool refilled" },
            { key: "notify_engagement_refreshed" as const, label: "Engagement feed refreshed (48h)" },
            { key: "notify_weekly_digest" as const, label: "Analytics weekly digest" },
          ].map(({ key, label }) => (
            <div key={key} className="flex items-center justify-between">
              <span className="text-sm text-text-secondary">{label}</span>
              <Toggle checked={settings[key]} onChange={(v) => updateSetting(key, v)} />
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
