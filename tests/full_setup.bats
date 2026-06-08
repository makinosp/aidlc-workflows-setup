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
    assert_dir ".cursor/rules" "Cursor rules dir"
    assert_dir ".clinerules" "Cline rules dir"
    assert_dir ".claude" "Claude dir"
    assert_dir ".github" "GitHub dir"
}

@test "creates symlinks for Kiro" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".kiro/steering/aws-aidlc-rules" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Kiro steering rules"
    assert_symlink ".kiro/aws-aidlc-rule-details" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Kiro rule details"
}

@test "creates symlinks for Amazon Q" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".amazonq/rules/aws-aidlc-rules" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Amazon Q rules"
    assert_symlink ".amazonq/aws-aidlc-rule-details" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Amazon Q rule details"
}

@test "creates Cursor .mdc file with frontmatter and core-workflow content" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    [ -f ".cursor/rules/ai-dlc-workflow.mdc" ]

    local mdc_content
    mdc_content="$(<.cursor/rules/ai-dlc-workflow.mdc)"

    # Frontmatter
    [[ "$mdc_content" == *"description: \"AI-DLC (AI-Driven Development Life Cycle) adaptive workflow for software development\""* ]]
    [[ "$mdc_content" == *"alwaysApply: true"* ]]

    # Core-workflow content appended
    [[ "$mdc_content" == *"# Core Workflow"* ]]
    [[ "$mdc_content" == *"This is the AI-DLC core workflow."* ]]
}

@test "creates symlinks for Cline" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".clinerules/core-workflow.md" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Cline core workflow"
    assert_symlink ".clinerules/.aidlc-rule-details" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Cline rule details"
}

@test "creates symlinks for Claude Code" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".claude/CLAUDE.md" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Claude Code instructions"
    assert_symlink ".claude/.aidlc-rule-details" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "Claude Code rule details"
    assert_symlink "CLAUDE.md" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Root CLAUDE.md"
}

@test "creates symlinks for GitHub Copilot" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    assert_symlink ".github/copilot-instructions.md" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "GitHub Copilot instructions"
    assert_symlink ".github/.aidlc-rule-details" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details" \
        "GitHub Copilot rule details"
}

@test "completion message lists all configured platforms" {
    cd "$TEST_TEMP"
    run bash scripts/aidlc-workflows-setup.sh
    [ "$status" -eq 0 ]

    [[ "$output" == *"AI-DLC Workflows setup completed"* ]]
    [[ "$output" == *"Kiro (.kiro/)"* ]]
    [[ "$output" == *"Amazon Q (.amazonq/)"* ]]
    [[ "$output" == *"Cursor (.cursor/)"* ]]
    [[ "$output" == *"Cline (.clinerules/)"* ]]
    [[ "$output" == *"Claude Code (.claude/ + CLAUDE.md)"* ]]
    [[ "$output" == *"GitHub Copilot (.github/)"* ]]
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
    assert_symlink ".github/copilot-instructions.md" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md" \
        "Idempotent: GitHub Copilot symlink"
    assert_symlink ".kiro/steering/aws-aidlc-rules" \
        "$TEST_TEMP/.vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules" \
        "Idempotent: Kiro steering rules"
}
