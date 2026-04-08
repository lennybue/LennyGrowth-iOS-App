"use client";

import { useState } from "react";
import { X, Plus, Check } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import type { NicheTag, ToneType, Language, HookFormat } from "@/types";

const NICHE_TAGS: { value: NicheTag; label: string }[] = [
  { value: "seo", label: "SEO" },
  { value: "google-ads", label: "Google Ads" },
  { value: "ai-marketing", label: "AI Marketing" },
  { value: "content-marketing", label: "Content Marketing" },
  { value: "personal-brand", label: "Personal Brand" },
  { value: "social-media-growth", label: "Social Media Growth" },
  { value: "analytics", label: "Analytics" },
  { value: "conversion-rate", label: "Conversion Rate" },
  { value: "email-marketing", label: "Email Marketing" },
  { value: "freelancing", label: "Freelancing" },
];

const TONES: { value: ToneType; label: string }[] = [
  { value: "casual", label: "Casual" },
  { value: "professional", label: "Professional" },
  { value: "bold", label: "Bold" },
  { value: "witty", label: "Witty" },
];

const LANGUAGES: { value: Language; label: string }[] = [
  { value: "german", label: "German" },
  { value: "english", label: "English" },
  { value: "mixed", label: "Mixed" },
];

const HOOK_FORMATS: { value: HookFormat; label: string }[] = [
  { value: "confession", label: "Confession" },
  { value: "number", label: "Number" },
  { value: "hot-take", label: "Hot Take" },
  { value: "contrarian", label: "Contrarian" },
  { value: "story", label: "Story" },
  { value: "data", label: "Data" },
  { value: "question", label: "Question" },
];

interface NicheSettingsProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initialTags?: NicheTag[];
  initialTone?: ToneType;
  initialLanguage?: Language;
  initialHooks?: HookFormat[];
  onSave?: (settings: {
    tags: (NicheTag | string)[];
    tone: ToneType;
    language: Language;
    hooks: HookFormat[];
  }) => void;
}

export default function NicheSettings({
  open,
  onOpenChange,
  initialTags = ["seo", "ai-marketing"],
  initialTone = "professional",
  initialLanguage = "english",
  initialHooks = ["confession", "hot-take", "number"],
  onSave,
}: NicheSettingsProps) {
  const [selectedTags, setSelectedTags] = useState<(NicheTag | string)[]>(initialTags);
  const [selectedTone, setSelectedTone] = useState<ToneType>(initialTone);
  const [selectedLanguage, setSelectedLanguage] = useState<Language>(initialLanguage);
  const [selectedHooks, setSelectedHooks] = useState<HookFormat[]>(initialHooks);
  const [customTag, setCustomTag] = useState("");

  const toggleTag = (tag: NicheTag | string) => {
    setSelectedTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const addCustomTag = () => {
    const trimmed = customTag.trim().toLowerCase();
    if (trimmed && !selectedTags.includes(trimmed)) {
      setSelectedTags((prev) => [...prev, trimmed]);
      setCustomTag("");
    }
  };

  const toggleHook = (hook: HookFormat) => {
    setSelectedHooks((prev) =>
      prev.includes(hook) ? prev.filter((h) => h !== hook) : [...prev, hook]
    );
  };

  const handleSave = () => {
    onSave?.({
      tags: selectedTags,
      tone: selectedTone,
      language: selectedLanguage,
      hooks: selectedHooks,
    });
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Configure Content Preferences</DialogTitle>
          <DialogDescription>
            Set your niche, tone, and preferred hook formats for AI content
            generation.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Topic Tags */}
          <div>
            <label className="text-sm font-medium text-white mb-2 block">
              Topic Tags
            </label>
            <div className="flex flex-wrap gap-2 mb-3">
              {NICHE_TAGS.map((tag) => (
                <button
                  key={tag.value}
                  onClick={() => toggleTag(tag.value)}
                  className={cn(
                    "inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium transition-all duration-200 border",
                    selectedTags.includes(tag.value)
                      ? "bg-neon-teal/20 text-neon-teal border-neon-teal/30"
                      : "bg-white/5 text-text-secondary border-white/10 hover:border-white/20"
                  )}
                >
                  {selectedTags.includes(tag.value) && (
                    <Check className="h-3 w-3" />
                  )}
                  {tag.label}
                </button>
              ))}
              {/* Custom tags */}
              {selectedTags
                .filter(
                  (t) => !NICHE_TAGS.some((nt) => nt.value === t)
                )
                .map((tag) => (
                  <button
                    key={tag}
                    onClick={() => toggleTag(tag)}
                    className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium bg-ice-blue/20 text-ice-blue border border-ice-blue/30 transition-all duration-200"
                  >
                    <Check className="h-3 w-3" />
                    {tag}
                    <X className="h-3 w-3 ml-0.5" />
                  </button>
                ))}
            </div>
            <div className="flex gap-2">
              <Input
                placeholder="Add custom tag..."
                value={customTag}
                onChange={(e) => setCustomTag(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && addCustomTag()}
                className="h-8 text-xs"
              />
              <Button
                variant="outline"
                size="sm"
                onClick={addCustomTag}
                disabled={!customTag.trim()}
              >
                <Plus className="h-3 w-3" />
              </Button>
            </div>
          </div>

          {/* Tone Preference */}
          <div>
            <label className="text-sm font-medium text-white mb-2 block">
              Tone Preference
            </label>
            <div className="flex flex-wrap gap-2">
              {TONES.map((tone) => (
                <button
                  key={tone.value}
                  onClick={() => setSelectedTone(tone.value)}
                  className={cn(
                    "rounded-full px-4 py-1.5 text-xs font-medium transition-all duration-200 border",
                    selectedTone === tone.value
                      ? "bg-neon-magenta/20 text-neon-magenta border-neon-magenta/30"
                      : "bg-white/5 text-text-secondary border-white/10 hover:border-white/20"
                  )}
                >
                  {tone.label}
                </button>
              ))}
            </div>
          </div>

          {/* Language */}
          <div>
            <label className="text-sm font-medium text-white mb-2 block">
              Language
            </label>
            <div className="flex flex-wrap gap-2">
              {LANGUAGES.map((lang) => (
                <button
                  key={lang.value}
                  onClick={() => setSelectedLanguage(lang.value)}
                  className={cn(
                    "rounded-full px-4 py-1.5 text-xs font-medium transition-all duration-200 border",
                    selectedLanguage === lang.value
                      ? "bg-ice-blue/20 text-ice-blue border-ice-blue/30"
                      : "bg-white/5 text-text-secondary border-white/10 hover:border-white/20"
                  )}
                >
                  {lang.label}
                </button>
              ))}
            </div>
          </div>

          {/* Preferred Hook Formats */}
          <div>
            <label className="text-sm font-medium text-white mb-2 block">
              Preferred Hook Formats
            </label>
            <div className="flex flex-wrap gap-2">
              {HOOK_FORMATS.map((hook) => (
                <button
                  key={hook.value}
                  onClick={() => toggleHook(hook.value)}
                  className={cn(
                    "inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium transition-all duration-200 border",
                    selectedHooks.includes(hook.value)
                      ? "bg-neon-teal/20 text-neon-teal border-neon-teal/30"
                      : "bg-white/5 text-text-secondary border-white/10 hover:border-white/20"
                  )}
                >
                  {selectedHooks.includes(hook.value) && (
                    <Check className="h-3 w-3" />
                  )}
                  {hook.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button onClick={handleSave}>Save Preferences</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
