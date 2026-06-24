# ==============================================================================
# Integration tests for full execution of aidlc-workflows-setup.sh
# ==============================================================================
#
# These tests run the script as a black box (no source-loading) in a temporary
# git repository, and verify that all platform directories, symlinks, and
# generated files are created correctly.
# ==============================================================================

setup() {
    TEST_TEMP="$(mktemp -d)"

    # Create a minimal git repository
    cd "$TEST_TEMP"
    git init -b main
    git config user.email "test@test.com"
    git config user.name "Test"
    git commit --allow-empty -m "initial commit"

    # Create the vendor directory structure (simulating an already-checked-out
    # submodule so the script skips `git submodule add` during tests)
    mkdir -p ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules"
    mkdir -p ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details"

    # Create a fake core-workflow.md so Cursor merge can be verified
    cat > ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" <<-EOF
# Core Workflow
This is the AI-DLC core workflow.
EOF

    # Placeholder so rule-details dir is not empty
    touch ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details/.gitkeep"

    # Copy the actual scripts directory from the project (pre-existing structure)
    cp -a "${BATS_TEST_DIRNAME}/../scripts" .
    chmod +x "scripts/aidlc-workflows-setup.sh"

    git add -A
    git commit -m "add vendor mock and setup script"
}

teardown() {
    cd /
    rm -rf "$TEST_TEMP"
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

@test "script exits 0 when run from the project root" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]
}

@test "creates all platform directories" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_dir ".kiro/steering" "Kiro steering dir"
    assert_dir ".amazonq/rules" "Amazon Q rules dir"
    assert_dir ".claude" "Claude dir"
    assert_dir ".aidlc-rule-details" "Shared rule details dir"
}

@test "creates symlinks for Kiro" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".kiro/steering/aws-aidlc-rules" \
        "../../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Kiro steering rules"
    assert_symlink ".kiro/aws-aidlc-rule-details" \
        "../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Kiro rule details"
}

@test "creates symlinks for Amazon Q" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".amazonq/rules/aws-aidlc-rules" \
        "../../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Amazon Q rules"
    assert_symlink ".amazonq/aws-aidlc-rule-details" \
        "../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Amazon Q rule details"
}

@test "creates AGENTS.md symlink" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink "AGENTS.md" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "AGENTS.md (universal)"
}

@test "creates shared .aidlc-rule-details symlink" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".aidlc-rule-details" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Shared rule details"
}

@test "creates symlinks for Claude Code" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".claude/CLAUDE.md" \
        "../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Claude Code instructions"
    assert_symlink "CLAUDE.md" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Root CLAUDE.md"
}

@test "completion message lists all configured platforms" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    [[ "$output" == *"AI-DLC Workflows setup completed"* ]]
    [[ "$output" == *"Kiro (.kiro/)"* ]]
    [[ "$output" == *"Amazon Q (.amazonq/)"* ]]
    [[ "$output" == *"AGENTS.md (universal: Cursor, Cline, Codex, Copilot, etc.)"* ]]
    [[ "$output" == *"Shared .aidlc-rule-details (used by all platforms)"* ]]
    [[ "$output" == *"Claude Code (.claude/ + CLAUDE.md)"* ]]
}

@test "skips git submodule add when vendor already exists" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    [[ "$output" != *"git submodule add"* ]]
}

@test "can run the script twice without errors (idempotent)" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    # All symlinks should still be valid after second run
    assert_symlink "AGENTS.md" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Idempotent: AGENTS.md symlink"
    assert_symlink ".aidlc-rule-details" \
        ".vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Idempotent: Shared rule details"
    assert_symlink ".kiro/steering/aws-aidlc-rules" \
        "../../.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Idempotent: Kiro steering rules"
}
