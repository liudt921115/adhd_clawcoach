#!/bin/bash

# ClawCoach Setup Script
# Initialises a new user workspace from the template

set -e

OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
WORKSPACE_NAME="${1:-clawcoach}"
WORKSPACE_DIR="$OPENCLAW_DIR/workspaces/$WORKSPACE_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../workspace_template"

echo ""
echo "🧠 ClawCoach Setup"
echo "=================="
echo ""

# Check OpenClaw is installed
if ! command -v openclaw &> /dev/null; then
  echo "❌ OpenClaw not found. Install it first: https://openclaw.ai"
  exit 1
fi

echo "✓ OpenClaw found"

# Create workspace directory
if [ -d "$WORKSPACE_DIR" ]; then
  echo ""
  echo "⚠️  Workspace already exists at: $WORKSPACE_DIR"
  read -p "Overwrite? This will reset all state files. (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

mkdir -p "$WORKSPACE_DIR"
echo "✓ Created workspace: $WORKSPACE_DIR"

# Copy template files
cp "$TEMPLATE_DIR/HEARTBEAT.md" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/memory.md" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/state.json" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/today.md" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/routine.md" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/calendar.md" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/energy_log.json" "$WORKSPACE_DIR/"
cp "$TEMPLATE_DIR/RULES.md" "$WORKSPACE_DIR/"

echo "✓ Workspace files initialised"

# Install skill
SKILL_DIR="$OPENCLAW_DIR/skills/clawcoach"
mkdir -p "$SKILL_DIR"
cp "$SCRIPT_DIR/../skills/clawcoach/SKILL.md" "$SKILL_DIR/"
echo "✓ ClawCoach skill installed"

# Stamp creation time in state.json
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Use python for reliable JSON editing if available
if command -v python3 &> /dev/null; then
  python3 -c "
import json, sys
with open('$WORKSPACE_DIR/state.json', 'r') as f:
    state = json.load(f)
state['created_at'] = '$CREATED_AT'
with open('$WORKSPACE_DIR/state.json', 'w') as f:
    json.dump(state, f, indent=2)
"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ClawCoach is ready!"
echo ""
echo "Next steps:"
echo ""
echo "1. Add your credentials to openclaw.json:"
echo "   - Telegram bot token (from @BotFather)"
echo "   - Anthropic API key"
echo "   - Workspace path: $WORKSPACE_DIR"
echo ""
echo "2. Start the gateway:"
echo "   openclaw gateway"
echo ""
echo "3. Message your Telegram bot:"
echo "   /start"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
