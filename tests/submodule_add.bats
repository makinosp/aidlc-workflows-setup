# ==============================================================================
# Tests for git submodule add (Step 1 of the setup script)
#
# These tests verify that `git submodule add` works correctly when
# .vendor/aidlc-workflows does NOT already exist. They use a local dummy
# repository injected via the AIDLC_WORKFLOWS_REPO_URL environment variable
# to avoid network dependencies.
# ==============================================================================

setup() {
    TEST_TEMP="$(mktemp -d)"

    # Create a minimal git repository (the target project)
    cd "$TEST_TEMP"
    git init -b main
    git config user.email "test@test.com"
    git config user.name "Test"
    git config --global protocol.file.allow always
    git commit --allow-empty -m "initial commit"

    # Create a local dummy submodule source (simulating awslabs/aidlc-workflows)
    mkdir -p "$TEST_TEMP/../fake-upstream"
    cd "$TEST_TEMP/../fake-upstream"
    if [ ! -d ".git" ]; then
        git init -b main
        git config user.email "test@test.com"
        git config user.name "Test"
        mkdir -p aidlc-rules/aws-aidlc-rules
        mkdir -p aidlc-rules/aws-aidlc-rule-details
        cat > aidlc-rules/aws-aidlc-rules/core-workflow.md <<-EOF
# Core Workflow
This is the AI-DLC core workflow.
EOF
        touch aidlc-rules/aws-aidlc-rule-details/.gitkeep
        git add -A
        git commit -m "initial"
    fi

    # Copy the actual scripts directory from the project
    cp -a "${BATS_TEST_DIRNAME}/../scripts" "$TEST_TEMP/"
    chmod +x "$TEST_TEMP/scripts/aidlc-workflows-setup.sh"

    cd "$TEST_TEMP"
}

teardown() {
    cd /
    rm -rf "$TEST_TEMP"
    rm -rf "$TEST_TEMP/../fake-upstream"
}

# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------

assert_symlink() {
    local target=$1
    local expected_source=$2
    local description=$3

    if [ ! -L "$target" ]; then
        echo "FAIL: $description - '$target' is not a symlink" >&2
        return 1
    fi

    local actual_source
    actual_source="$(readlink "$target")"
    if [[ "$actual_source" != "$expected_source" ]]; then
        echo "FAIL: $description - expected '$expected_source', got '$actual_source'" >&2
        return 1
    fi
}

assert_dir() {
    local path=$1
    local description=$2

    if [ ! -d "$path" ]; then
        echo "FAIL: $description - directory '$path' does not exist" >&2
        return 1
    fi
}

# ----------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------

@test "adds git submodule when vendor dir does not exist" {
    cd "$TEST_TEMP"

    run env AIDLC_WORKFLOWS_REPO_URL="$TEST_TEMP/../fake-upstream" bash scripts/aidlc-workflows-setup.sh
    echo "$output"
    [ "$status" -eq 0 ]

    # Verify the submodule was added
    [ -f ".gitmodules" ]
    [[ "$(cat .gitmodules)" == *"fake-upstream"* ]]
    assert_dir ".vendor/aidlc-workflows" "Submodule directory"
    assert_dir ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" "Rules inside submodule"
}

@test "creates all symlinks when submodule is freshly added" {
    cd "$TEST_TEMP"

    run env AIDLC_WORKFLOWS_REPO_URL="$TEST_TEMP/../fake-upstream" bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".kiro/steering/aws-aidlc-rules" \
        "../../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Kiro steering rules"
    assert_symlink ".amazonq/rules/aws-aidlc-rules" \
        "../../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Amazon Q rules"
    assert_symlink "AGENTS.md" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "AGENTS.md (universal)"
    assert_symlink ".aidlc-rule-details" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Shared rule details"
    assert_symlink ".claude/CLAUDE.md" \
        "../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Claude Code instructions"
    assert_symlink "CLAUDE.md" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Root CLAUDE.md"
}

@test "completion message lists all configured platforms after fresh add" {
    cd "$TEST_TEMP"

    run env AIDLC_WORKFLOWS_REPO_URL="$TEST_TEMP/../fake-upstream" bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    [[ "$output" == *"AI-DLC Workflows setup completed"* ]]
    [[ "$output" == *"Kiro (.kiro/)"* ]]
    [[ "$output" == *"Amazon Q (.amazonq/)"* ]]
    [[ "$output" == *"AGENTS.md (universal: Cursor, Cline, Codex, Copilot, etc.)"* ]]
    [[ "$output" == *"Shared .aidlc-rule-details (used by all platforms)"* ]]
    [[ "$output" == *"Claude Code (.claude/ + CLAUDE.md)"* ]]
}
