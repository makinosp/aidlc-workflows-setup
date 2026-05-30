#!/bin/bash

set -e  # Exit immediately on error

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

# Verify we're in the project root
if [ ! -f "scripts/aidlc-workflows-setup.sh" ]; then
    echo -e "${RED}Error: Please run this script from the project root directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting AI-DLC Workflows setup...${NC}\n"

# ===============================================
# Step 1: Initialize Git submodule
# ===============================================
echo -e "${YELLOW}[1/7] Initializing Git submodule${NC}"

if [ ! -d ".vendor/aidlc-workflows" ]; then
    git submodule add https://github.com/awslabs/aidlc-workflows.git .vendor/aidlc-workflows
else
    echo "  (.vendor/aidlc-workflows already exists)"
fi

git submodule update --init --recursive
echo -e "${GREEN}✓${NC} Git submodule initialized\n"

# ===============================================
# Step 2: Setup for Kiro
# ===============================================
echo -e "${YELLOW}[2/7] Setting up for Kiro${NC}"

mkdir -p .kiro/steering
create_symlink "../../.vendor/aidlc-workflows/aws-aidlc-rules" ".kiro/steering/aws-aidlc-rules" \
    "Kiro steering rules"
create_symlink "../../.vendor/aidlc-workflows/aws-aidlc-rule-details" ".kiro/aws-aidlc-rule-details" \
    "Kiro rule details"
echo ""

# ===============================================
# Step 3: Setup for Amazon Q
# ===============================================
echo -e "${YELLOW}[3/7] Setting up for Amazon Q${NC}"

mkdir -p .amazonq/rules
create_symlink "../../.vendor/aidlc-workflows/aws-aidlc-rules" ".amazonq/rules/aws-aidlc-rules" \
    "Amazon Q rules"
create_symlink "../../.vendor/aidlc-workflows/aws-aidlc-rule-details" ".amazonq/aws-aidlc-rule-details" \
    "Amazon Q rule details"
echo ""

# ===============================================
# Step 4: Setup for Cursor (with special handling)
# ===============================================
echo -e "${YELLOW}[4/7] Setting up for Cursor${NC}"

mkdir -p .cursor/rules

# Generate Cursor rule file with FRONTMATTER + core-workflow.md merged
cat > .cursor/rules/ai-dlc-workflow.mdc << 'EOF'
---
description: "AI-DLC (AI-Driven Development Life Cycle) adaptive workflow for software development"
alwaysApply: true
---
EOF

cat .vendor/aidlc-workflows/aws-aidlc-rules/core-workflow.md >> .cursor/rules/ai-dlc-workflow.mdc
echo -e "${GREEN}✓${NC} Cursor rule file generated"

# Create symlink for rule details
create_symlink "../../.vendor/aidlc-workflows/aws-aidlc-rule-details" ".aidlc-rule-details" \
    "Cursor rule details"
echo ""

# ===============================================
# Step 5: Setup for Cline
# ===============================================
echo -e "${YELLOW}[5/7] Setting up for Cline${NC}"

mkdir -p .clinerules
create_symlink "../.vendor/aidlc-workflows/aws-aidlc-rules/core-workflow.md" ".clinerules/core-workflow.md" \
    "Cline core workflow"
create_symlink "../.vendor/aidlc-workflows/aws-aidlc-rule-details" ".clinerules/.aidlc-rule-details" \
    "Cline rule details"
echo ""

# ===============================================
# Step 6: Setup for Claude Code
# ===============================================
echo -e "${YELLOW}[6/7] Setting up for Claude Code${NC}"

mkdir -p .claude
create_symlink "../.vendor/aidlc-workflows/aws-aidlc-rules/core-workflow.md" ".claude/CLAUDE.md" \
    "Claude Code instructions"
create_symlink "../.vendor/aidlc-workflows/aws-aidlc-rule-details" ".claude/.aidlc-rule-details" \
    "Claude Code rule details"

# Create root CLAUDE.md symlink (optional entry point)
create_symlink ".vendor/aidlc-workflows/aws-aidlc-rules/core-workflow.md" "CLAUDE.md" \
    "Root CLAUDE.md symlink"
echo ""

# ===============================================
# Step 7: Setup for GitHub Copilot
# ===============================================
echo -e "${YELLOW}[7/7] Setting up for GitHub Copilot${NC}"

mkdir -p .github
create_symlink "../.vendor/aidlc-workflows/aws-aidlc-rules/core-workflow.md" ".github/copilot-instructions.md" \
    "GitHub Copilot instructions"
create_symlink "../.vendor/aidlc-workflows/aws-aidlc-rule-details" ".github/.aidlc-rule-details" \
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
