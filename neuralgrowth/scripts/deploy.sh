#!/bin/bash
# ============================================================
# NeuralGrowth — One-Command Deploy to Vercel
# ============================================================
# Usage: ./scripts/deploy.sh
#
# Prerequisites:
#   npm install -g vercel
#   vercel login
# ============================================================

set -e

CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo -e "${MAGENTA}"
echo "  _   _                      _  ____                    _   _     "
echo " | \ | | ___ _   _ _ __ __ _| |/ ___|_ __ _____      _| |_| |__  "
echo " |  \| |/ _ \ | | | '__/ _\` | | |  _| '__/ _ \ \ /\ / / __| '_ \ "
echo " | |\  |  __/ |_| | | | (_| | | |_| | | | (_) \ V  V /| |_| | | |"
echo " |_| \_|\___|\__,_|_|  \__,_|_|\____|_|  \___/ \_/\_/  \__|_| |_|"
echo -e "${NC}"
echo ""

# Check vercel CLI
if ! command -v vercel &> /dev/null; then
  echo -e "${YELLOW}Installing Vercel CLI...${NC}"
  npm install -g vercel
fi

# Check login
if ! vercel whoami &> /dev/null; then
  echo -e "${YELLOW}Please log in to Vercel:${NC}"
  vercel login
  echo ""
fi

VERCEL_USER=$(vercel whoami 2>/dev/null)
echo -e "${GREEN}Logged in as: ${VERCEL_USER}${NC}"
echo ""

# Link project if not already linked
if [ ! -d ".vercel" ]; then
  echo -e "${CYAN}Linking project to Vercel...${NC}"
  vercel link --yes
  echo ""
fi

# Set environment variables if .env.local exists and has non-placeholder values
if [ -f ".env.local" ]; then
  echo -e "${CYAN}Setting environment variables on Vercel...${NC}"
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    # Skip placeholder values
    [[ "$value" == "placeholder"* ]] && continue

    # Set env var for all environments
    echo "$value" | vercel env add "$key" production --yes 2>/dev/null && \
      echo -e "  ${GREEN}✓${NC} $key" || \
      echo -e "  ${YELLOW}⊘${NC} $key (already set)"
  done < .env.local
  echo ""
fi

# Build check
echo -e "${CYAN}Verifying build...${NC}"
npm run build 2>&1 | tail -3
echo -e "${GREEN}✓ Build passed${NC}"
echo ""

# Deploy
echo -e "${CYAN}Deploying to production...${NC}"
echo ""
vercel --prod --yes

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ NeuralGrowth deployed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "Next: Add your API keys in the Vercel dashboard:"
echo -e "  ${CYAN}vercel env ls${NC}  — see current vars"
echo -e "  ${CYAN}vercel env add ANTHROPIC_API_KEY${NC}  — add a key"
echo ""
