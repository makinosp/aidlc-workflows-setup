#!/bin/bash

set -e  # Exit immediately on error

# --------------------------------------------------
# Resolve script directory and project root
# (Supports execution from a file or via a pipe, e.g. curl ... | bash)
# --------------------------------------------------

# When the script is piped (no real file), BASH_SOURCE[0] is "bash".
# In that case we assume the current working directory is the project root.
if [[ -z "${BASH_SOURCE[0]}" || "${BASH_SOURCE[0]}" == "bash" ]]; then
    SCRIPT_DIR="$(pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Determine the git top‑level directory if we are inside a repo.
if git -C "$SCRIPT_DIR" rev-parse --show-toplevel > /dev/null 2>&1; then
    PROJECT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
else
    # Fallback: assume the script lives directly under the project root.
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# Color output constants
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to create symlinks with error handling
create_symlink() {
    local source=$1
    local target=$2
    local description=$3
    
    # Remove target if it already exists
    if [ -e "$target" ] || [ -L "$target" ]; then
        rm -rf "$target"
    fi
    
    if ln -s "$source" "$target" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description"
    else
        echo -e "${RED}✗${NC} $description: symlink creation failed"
        exit 1
    fi
}

# --------------------------------------------------
# Verify we are inside the project root (optional)
# --------------------------------------------------
# When executed via a pipe there is no script file to check, so skip the check.
if [[ -n "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    if [ ! -f "$PROJECT_ROOT/scripts/$(basename "${BASH_SOURCE[0]}")" ]; then
        echo -e "${RED}Error: Please run this script from the project root directory${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Starting AI-DLC Workflows setup...${NC}\n"

# ===============================================
# Step 1: Initialize Git submodule
# ===============================================
echo -e "${YELLOW}[1/7] Initializing Git submodule${NC}"

if [ ! -d "$PROJECT_ROOT/.vendor/aidlc-workflows" ]; then
    git submodule add https://github.com/awslabs/aidlc-workflows.git "$PROJECT_ROOT/.vendor/aidlc-workflows"
else
    echo "  ($PROJECT_ROOT/.vendor/aidlc-workflows already exists)"
fi

if git -C "$PROJECT_ROOT" submodule update --init --recursive; then
    :  # success
fi
echo -e "${GREEN}✓${NC} Git submodule initialized\n"

# ===============================================
# Step 2: Setup for Kiro
# ===============================================
echo -e "${YELLOW}[2/7] Setting up for Kiro${NC}"

mkdir -p "$PROJECT_ROOT/.kiro/steering"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" "$PROJECT_ROOT/.kiro/steering/aws-aidlc-rules" \
    "Kiro steering rules"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" "$PROJECT_ROOT/.kiro/aws-aidlc-rule-details" \
    "Kiro rule details"
echo ""

# ===============================================
# Step 3: Setup for Amazon Q
# ===============================================
echo -e "${YELLOW}[3/7] Setting up for Amazon Q${NC}"

mkdir -p "$PROJECT_ROOT/.amazonq/rules"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" "$PROJECT_ROOT/.amazonq/rules/aws-aidlc-rules" \
    "Amazon Q rules"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" "$PROJECT_ROOT/.amazonq/aws-aidlc-rule-details" \
    "Amazon Q rule details"
echo ""

# ===============================================
# Step 4: Setup for Cursor (with special handling)
# ===============================================
echo -e "${YELLOW}[4/7] Setting up for Cursor${NC}"

mkdir -p "$PROJECT_ROOT/.cursor/rules"

# Generate Cursor rule file with FRONTMATTER + core-workflow.md merged
cat > "$PROJECT_ROOT/.cursor/rules/ai-dlc-workflow.mdc" << 'EOF'
---
description: "AI-DLC (AI-Driven Development Life Cycle) adaptive workflow for software development"
alwaysApply: true
---
EOF

cat "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" >> "$PROJECT_ROOT/.cursor/rules/ai-dlc-workflow.mdc"
echo -e "${GREEN}✓${NC} Cursor rule file generated"

# Create symlink for rule details
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" "$PROJECT_ROOT/.aidlc-rule-details" \
    "Cursor rule details"
echo ""

# ===============================================
# Step 5: Setup for Cline
# ===============================================
echo -e "${YELLOW}[5/7] Setting up for Cline${NC}"

mkdir -p "$PROJECT_ROOT/.clinerules"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" "$PROJECT_ROOT/.clinerules/core-workflow.md" \
    "Cline core workflow"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" "$PROJECT_ROOT/.clinerules/.aidlc-rule-details" \
    "Cline rule details"
echo ""

# ===============================================
# Step 6: Setup for Claude Code
# ===============================================
echo -e "${YELLOW}[6/7] Setting up for Claude Code${NC}"

mkdir -p "$PROJECT_ROOT/.claude"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" "$PROJECT_ROOT/.claude/CLAUDE.md" \
    "Claude Code instructions"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" "$PROJECT_ROOT/.claude/.aidlc-rule-details" \
    "Claude Code rule details"

# Create root CLAUDE.md symlink (optional entry point)
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" "$PROJECT_ROOT/CLAUDE.md" \
    "Root CLAUDE.md symlink"
echo ""

# ===============================================
# Step 7: Setup for GitHub Copilot
# ===============================================
echo -e "${YELLOW}[7/7] Setting up for GitHub Copilot${NC}"

mkdir -p "$PROJECT_ROOT/.github"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" "$PROJECT_ROOT/.github/copilot-instructions.md" \
    "GitHub Copilot instructions"
create_symlink "$PROJECT_ROOT/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" "$PROJECT_ROOT/.github/.aidlc-rule-details" \
    "GitHub Copilot rule details"
echo ""

# ===============================================
# Completion message
# ===============================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AI-DLC Workflows setup completed!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo "Configured platforms:"
echo "  ✓ Kiro (.kiro/)"
echo "  ✓ Amazon Q (.amazonq/)"
echo "  ✓ Cursor (.cursor/)"
echo "  ✓ Cline (.clinerules/)"
echo "  ✓ Claude Code (.claude/ + CLAUDE.md)"
echo "  ✓ GitHub Copilot (.github/)\n"

echo "Next steps:"
echo "  1. Commit changes: git add -A && git commit -m 'setup: AI-DLC Workflows integration'"
echo "  2. Open the project in your IDE"
echo "  3. Verify that rules are properly loaded in each platform\n"

echo "Verification commands:"
echo "  Kiro CLI:         kiro-cli -> /context show"
echo "  Amazon Q:         Check Rules button in chat"
echo "  Cursor:           Settings -> Rules -> Project Rules"
echo "  Cline:            Check Rules popover under chat input"
echo "  Claude Code:      /config command"
echo "  GitHub Copilot:   /instructions command"
