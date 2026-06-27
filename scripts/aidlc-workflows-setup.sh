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

# Helper function: calculate relative path from target dir to source (pure Bash, no realpath dependency)
calculate_relative_path() {
    local source="$1"
    local target_dir="$2"

    # Normalize: ensure both are absolute
    local abs_source
    if [[ "$source" == /* ]]; then
        abs_source="$source"
    else
        abs_source="$PROJECT_ROOT/$source"
    fi

    local abs_target_dir
    if [[ "$target_dir" == /* ]]; then
        abs_target_dir="$target_dir"
    else
        abs_target_dir="$PROJECT_ROOT/$target_dir"
    fi

    # Remove trailing slashes
    abs_source="${abs_source%/}"
    abs_target_dir="${abs_target_dir%/}"

    # Split into components
    IFS='/' read -ra source_parts <<< "$abs_source"
    IFS='/' read -ra target_parts <<< "$abs_target_dir"

    # Find common prefix length
    local common=0
    local min_len=$(( ${#source_parts[@]} < ${#target_parts[@]} ? ${#source_parts[@]} : ${#target_parts[@]} ))
    for (( i=0; i<min_len; i++ )); do
        if [[ "${source_parts[$i]}" == "${target_parts[$i]}" ]]; then
            (( common++ ))
        else
            break
        fi
    done

    # Build relative path
    local result=""
    # Add ../ for remaining target parts after common prefix
    for (( i=common; i<${#target_parts[@]}; i++ )); do
        if [[ -n "$result" ]]; then
            result="$result/.."
        else
            result=".."
        fi
    done
    # Add remaining source parts after common prefix
    for (( i=common; i<${#source_parts[@]}; i++ )); do
        if [[ -n "$result" ]]; then
            result="$result/${source_parts[$i]}"
        else
            result="${source_parts[$i]}"
        fi
    done

    echo "$result"
}

# Helper function to create symlinks with error handling
create_symlink() {
    local source=$1
    local target=$2
    local description=$3

    # Back up existing regular files (not symlinks) before overwriting
    if [ -f "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.bak.$(date +%s)"
        mv "$target" "$backup"
        echo -e "${YELLOW}⚠${NC} Backed up existing ${description} to $backup"
    elif [ -e "$target" ] || [ -L "$target" ]; then
        rm -rf "$target"
    fi

    # Calculate relative path from target directory to source
    local target_dir
    target_dir=$(dirname "$target")
    local relative_source
    if command -v realpath &> /dev/null; then
        # Use realpath for accuracy when available
        local absolute_source
        if [[ "$source" == /* ]]; then
            absolute_source="$source"
        else
            absolute_source="$PROJECT_ROOT/$source"
        fi
        relative_source=$(realpath --relative-to="$target_dir" "$absolute_source")
    else
        # Fallback: pure Bash relative path calculation
        relative_source=$(calculate_relative_path "$source" "$target_dir")
    fi

    if ln -s "$relative_source" "$target"; then
        echo -e "${GREEN}✓${NC} $description"
    else
        echo -e "${RED}✗${NC} $description: symlink creation failed for '$source' -> '$target'"
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
echo -e "${YELLOW}[1/6] Initializing Git submodule${NC}"

if [ ! -d "$PROJECT_ROOT/.vendor/aidlc-workflows" ]; then
    if ! git submodule add https://github.com/awslabs/aidlc-workflows.git "$PROJECT_ROOT/.vendor/aidlc-workflows"; then
        echo -e "${RED}✗ Failed to add git submodule${NC}"
        echo "  Possible causes: network error, invalid URL, or path already in .gitmodules"
        echo "  Try: git submodule update --init --recursive"
        exit 1
    fi
else
    echo "  ($PROJECT_ROOT/.vendor/aidlc-workflows already exists)"
fi

if ! git -C "$PROJECT_ROOT" submodule update --init --recursive; then
    echo -e "${RED}✗ Failed to update git submodule${NC}"
    echo "  Try: git submodule update --init --recursive"
    exit 1
fi
echo -e "${GREEN}✓${NC} Git submodule initialized\n"

# ===============================================
# Step 2: Setup for Kiro
# ===============================================
echo -e "${YELLOW}[2/6] Setting up for Kiro${NC}"

mkdir -p "$PROJECT_ROOT/.kiro/steering"
create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" ".kiro/steering/aws-aidlc-rules" \
    "Kiro steering rules"
create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" ".kiro/aws-aidlc-rule-details" \
    "Kiro rule details"
echo ""

# ===============================================
# Step 3: Setup for Amazon Q
# ===============================================
echo -e "${YELLOW}[3/6] Setting up for Amazon Q${NC}"

mkdir -p "$PROJECT_ROOT/.amazonq/rules"
create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" ".amazonq/rules/aws-aidlc-rules" \
    "Amazon Q rules"
create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" ".amazonq/aws-aidlc-rule-details" \
    "Amazon Q rule details"
echo ""

# ===============================================
# Step 4: Setup for AGENTS.md (multi-agent universal entry point)
# ===============================================
echo -e "${YELLOW}[4/6] Setting up for AGENTS.md${NC}"

create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" "AGENTS.md" \
    "AGENTS.md (universal: Cursor, Cline, Codex, Copilot, etc.)"
echo ""

# ===============================================
# Step 5: Setup for shared .aidlc-rule-details
# ===============================================
echo -e "${YELLOW}[5/6] Setting up for shared .aidlc-rule-details${NC}"

create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" ".aidlc-rule-details" \
    "Shared rule details (used by all platforms)"
echo ""

# ===============================================
# Step 6: Setup for Claude Code (CLAUDE.md only)
# ===============================================
echo -e "${YELLOW}[6/6] Setting up for Claude Code${NC}"

mkdir -p "$PROJECT_ROOT/.claude"
create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" ".claude/CLAUDE.md" \
    "Claude Code instructions"

# Create root CLAUDE.md symlink (optional entry point)
create_symlink ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" "CLAUDE.md" \
    "Root CLAUDE.md symlink"
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
echo "  ✓ AGENTS.md (universal: Cursor, Cline, Codex, Copilot, etc.)"
echo "  ✓ Shared .aidlc-rule-details (used by all platforms)"
echo "  ✓ Claude Code (.claude/ + CLAUDE.md)\n"

echo "Next steps:"
echo "  1. Commit changes: git add -A && git commit -m 'setup: AI-DLC Workflows integration'"
echo "  2. Open the project in your IDE"
echo "  3. Verify that rules are properly loaded in each platform\n"

echo "Verification commands:"
echo "  Kiro CLI:         kiro-cli -> /context show"
echo "  Amazon Q:         Check Rules button in chat"
echo "  Cursor/Cline/Codex: Check AGENTS.md in project root"
echo "  Claude Code:      /config command"
echo "  GitHub Copilot:   /instructions command"
