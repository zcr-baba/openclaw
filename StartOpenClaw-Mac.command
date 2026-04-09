#!/bin/zsh
# OpenClaw Gateway - macOS Version
# A convenient startup script for OpenClaw Gateway on macOS

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo "${BLUE}[$1]${NC} $2"
}

print_ok() {
    echo "${GREEN}[OK]${NC} $1"
}

print_warn() {
    echo "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo "${RED}[ERROR]${NC} $1"
}

NODE_PATH="/usr/local/bin:/opt/homebrew/bin"
if [[ -d "$HOME/.npm-global/bin" ]]; then
    NODE_PATH="$HOME/.npm-global/bin:$NODE_PATH"
fi
export PATH="$NODE_PATH:$PATH"

cd "$(dirname "$0")"

echo ""
echo "========================================"
echo "  OpenClaw Gateway - macOS Version"
echo "========================================"
echo ""

print_step "1/5" "Checking environment..."
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Please install Node.js first."
    exit 1
fi
node --version
echo ""

print_step "2/5" "Checking dependencies..."
if [[ ! -d "node_modules" ]]; then
    print_warn "Dependencies not found, installing..."
    npm install
    if [[ $? -ne 0 ]]; then
        print_error "Dependency installation failed"
        exit 1
    fi
else
    print_ok "Dependencies ready"
fi
echo ""

print_step "3/5" "Checking UI assets..."
if [[ -f "dist/control-ui/index.html" ]]; then
    print_ok "UI assets ready"
else
    print_warn "Building UI assets..."
    pnpm ui:build
    if [[ $? -ne 0 ]]; then
        print_error "UI build failed"
        exit 1
    fi
    print_ok "UI built successfully"
fi
echo ""

print_step "4/5" "Getting Token..."
TOKEN_FILE="$HOME/.openclaw/openclaw.json"
TOKEN=""
if [[ -f "$TOKEN_FILE" ]]; then
    TOKEN=$(grep -E '"token"' "$TOKEN_FILE" 2>/dev/null | head -1 | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr -d '[:space:]')
fi

if [[ -n "$TOKEN" ]]; then
    print_ok "Token found"
    echo "   Token: ${TOKEN}"
else
    print_warn "Token not found"
fi
echo ""

print_step "5/5" "Cleaning up previous processes..."
if lsof -ti:18789 &>/dev/null; then
    print_warn "Port 18789 is in use, killing existing process..."
    lsof -ti:18789 | xargs kill -9 2>/dev/null || true
    sleep 1
fi
pkill -9 -f "openclaw.*gateway" 2>/dev/null || true
print_ok "Processes cleaned"
echo ""

GATEWAY_URL="http://127.0.0.1:18789"
if [[ -n "$TOKEN" ]]; then
    GATEWAY_URL="${GATEWAY_URL}/#token=${TOKEN}"
fi

echo "========================================"
echo ""
print_ok "Access URL: ${GATEWAY_URL}"
echo "$GATEWAY_URL" | pbcopy
print_ok "URL copied to clipboard"
echo ""
echo "${YELLOW}[TIP]${NC} Browser will open in 3 seconds..."
echo ""
echo "${YELLOW}IMPORTANT:${NC} Keep this window OPEN"
echo "Closing this window will STOP the server."
echo "Press Ctrl+C to stop."
echo ""
echo "========================================"
echo ""

sleep 3
open "$GATEWAY_URL"

echo "[Starting] OpenClaw Gateway..."
echo ""

node openclaw.mjs gateway run

echo ""
echo "[INFO] Server stopped."
