#!/bin/bash
# ============================================================
# NeuralGrowth — Automated Setup & Deploy Script
# ============================================================
# This script will:
# 1. Install dependencies
# 2. Verify the build works
# 3. Deploy to Vercel
# 4. Print next steps for connecting services
# ============================================================

set -e

CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════╗"
echo "║     NeuralGrowth — Setup & Deploy             ║"
echo "║     AI Social Media Command Center            ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo -e "${CYAN}[1/4]${NC} Installing dependencies..."
npm install --silent 2>&1 | tail -3
echo -e "${GREEN}  ✓ Dependencies installed${NC}"

echo ""
echo -e "${CYAN}[2/4]${NC} Building project..."
if npm run build 2>&1 | tail -5 | grep -q "Compiled successfully\|prerendered"; then
  echo -e "${GREEN}  ✓ Build successful${NC}"
else
  echo -e "${RED}  ✗ Build failed. Check errors above.${NC}"
  exit 1
fi

echo ""
echo -e "${CYAN}[3/4]${NC} Deploying to Vercel..."
echo ""

# Check if vercel is installed
if ! command -v vercel &> /dev/null; then
  echo "  Installing Vercel CLI..."
  npm install -g vercel
fi

# Check if logged in
if ! vercel whoami 2>/dev/null; then
  echo -e "${YELLOW}  You need to log in to Vercel first.${NC}"
  echo "  Run: vercel login"
  echo "  Then re-run this script."
  exit 1
fi

# Deploy
echo "  Deploying to Vercel (production)..."
DEPLOY_URL=$(vercel --prod --yes 2>&1 | tail -1)
echo -e "${GREEN}  ✓ Deployed to: ${DEPLOY_URL}${NC}"

echo ""
echo -e "${CYAN}[4/4]${NC} Post-deployment setup"
echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}NEXT STEPS — Connect your services:${NC}"
echo ""
echo "1. SUPABASE (Database + Auth)"
echo "   → Go to https://supabase.com → New Project"
echo "   → SQL Editor → paste contents of lib/supabase/schema.sql"
echo "   → Settings → API → copy URL + anon key + service key"
echo "   → Add to Vercel: vercel env add NEXT_PUBLIC_SUPABASE_URL"
echo ""
echo "2. ANTHROPIC (AI)"
echo "   → Go to https://console.anthropic.com → API Keys"
echo "   → Add to Vercel: vercel env add ANTHROPIC_API_KEY"
echo ""
echo "3. THREADS (Meta)"
echo "   → Go to https://developers.facebook.com"
echo "   → Create App → Add Threads API"
echo "   → Add redirect: ${DEPLOY_URL}/api/auth/threads/callback"
echo ""
echo "4. UPSTASH (Redis + QStash)"
echo "   → Go to https://upstash.com → Create Redis + QStash"
echo "   → Add env vars to Vercel dashboard"
echo ""
echo -e "${GREEN}Your app is live at: ${DEPLOY_URL}${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════${NC}"
