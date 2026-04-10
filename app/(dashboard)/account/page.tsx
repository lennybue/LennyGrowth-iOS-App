"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { User, Mail, Key, LogOut, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";

export default function AccountPage() {
  const router = useRouter();
  const supabase = createClient();
  const [saving, setSaving] = useState(false);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");

  useEffect(() => {
    async function loadUser() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        setEmail(user.email || "");
        const { data } = await supabase.from("users").select("*").eq("id", user.id).single();
        if (data) {
          setName(data.linkedin_name || user.email?.split("@")[0] || "");
        }
      }
    }
    loadUser();
  }, [supabase]);

  return (
    <div className="max-w-2xl mx-auto space-y-8">
      <h1 className="text-xl font-bold text-white flex items-center gap-2">
        <User className="w-6 h-6" />
        Account
      </h1>

      {/* Profile */}
      <section className="glass-card p-6 space-y-6">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-neon-magenta to-purple-600 flex items-center justify-center text-white text-xl font-bold">
            LB
          </div>
          <div>
            <p className="text-white font-semibold">{name}</p>
            <p className="text-sm text-text-secondary">{email}</p>
            <p className="text-xs text-neon-teal mt-1">Pro Plan</p>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm text-text-secondary mb-1.5">Full Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-text-secondary/50 focus:outline-none focus:border-neon-magenta/40 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm text-text-secondary mb-1.5">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-text-secondary/50 focus:outline-none focus:border-neon-magenta/40 text-sm"
            />
          </div>
          <button
            onClick={async () => {
              setSaving(true);
              const { data: { user } } = await supabase.auth.getUser();
              if (user) {
                await supabase.from("users").update({ linkedin_name: name }).eq("id", user.id);
              }
              setSaving(false);
            }}
            disabled={saving}
            className="px-4 py-2 rounded-xl bg-neon-magenta text-white text-sm font-medium hover:bg-neon-magenta/90 glow-magenta transition-smooth disabled:opacity-50"
          >
            {saving ? "Saving..." : "Save Changes"}
          </button>
        </div>
      </section>

      {/* Password */}
      <section className="glass-card p-6 space-y-4">
        <h2 className="text-base font-semibold text-white flex items-center gap-2">
          <Key className="w-5 h-5 text-ice-blue" />
          Change Password
        </h2>
        <div className="space-y-3">
          <input
            type="password"
            placeholder="Current password"
            className="w-full px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-text-secondary/50 focus:outline-none focus:border-neon-magenta/40 text-sm"
          />
          <input
            type="password"
            placeholder="New password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            className="w-full px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-text-secondary/50 focus:outline-none focus:border-neon-magenta/40 text-sm"
          />
          <input
            type="password"
            placeholder="Confirm new password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            className="w-full px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.08] text-white placeholder:text-text-secondary/50 focus:outline-none focus:border-neon-magenta/40 text-sm"
          />
          <button
            onClick={async () => {
              if (newPassword !== confirmPassword) return alert("Passwords don't match");
              if (newPassword.length < 6) return alert("Password must be at least 6 characters");
              const { error } = await supabase.auth.updateUser({ password: newPassword });
              if (error) alert(error.message);
              else { setNewPassword(""); setConfirmPassword(""); alert("Password updated!"); }
            }}
            className="px-4 py-2 rounded-xl glass-card text-sm font-medium text-white hover:bg-white/10 transition-smooth"
          >
            Update Password
          </button>
        </div>
      </section>

      {/* Usage Stats */}
      <section className="glass-card p-6 space-y-4">
        <h2 className="text-base font-semibold text-white">Usage This Month</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="p-3 rounded-xl bg-white/[0.02]">
            <p className="text-2xl font-bold text-white font-mono">47</p>
            <p className="text-xs text-text-secondary">Posts Published</p>
          </div>
          <div className="p-3 rounded-xl bg-white/[0.02]">
            <p className="text-2xl font-bold text-white font-mono">128</p>
            <p className="text-xs text-text-secondary">AI Generations</p>
          </div>
          <div className="p-3 rounded-xl bg-white/[0.02]">
            <p className="text-2xl font-bold text-white font-mono">23</p>
            <p className="text-xs text-text-secondary">Engagement Actions</p>
          </div>
          <div className="p-3 rounded-xl bg-white/[0.02]">
            <p className="text-2xl font-bold text-neon-teal font-mono">Pro</p>
            <p className="text-xs text-text-secondary">Current Plan</p>
          </div>
        </div>
      </section>

      {/* Danger Zone */}
      <section className="glass-card p-6 space-y-4 border-red-500/20">
        <h2 className="text-base font-semibold text-red-400">Danger Zone</h2>
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-white">Sign Out</p>
            <p className="text-xs text-text-secondary">Sign out of your account</p>
          </div>
          <button
            onClick={async () => {
              await supabase.auth.signOut();
              router.push("/login");
              router.refresh();
            }}
            className="flex items-center gap-2 px-4 py-2 rounded-xl glass-card text-sm text-text-secondary hover:text-white transition-smooth"
          >
            <LogOut className="w-4 h-4" /> Sign Out
          </button>
        </div>
        <div className="flex items-center justify-between pt-3 border-t border-white/5">
          <div>
            <p className="text-sm text-red-400">Delete Account</p>
            <p className="text-xs text-text-secondary">Permanently delete your account and all data</p>
          </div>
          <button
            onClick={async () => {
              if (!confirm("Are you sure? This action cannot be undone.")) return;
              const { data: { user } } = await supabase.auth.getUser();
              if (user) {
                await supabase.from("posts").delete().eq("user_id", user.id);
                await supabase.from("users").delete().eq("id", user.id);
                await supabase.auth.signOut();
                router.push("/login");
              }
            }}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-red-500/10 text-sm text-red-400 hover:bg-red-500/20 transition-smooth"
          >
            <Trash2 className="w-4 h-4" /> Delete
          </button>
        </div>
      </section>
    </div>
  );
}
