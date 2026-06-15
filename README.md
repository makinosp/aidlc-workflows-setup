# AI-DLC Workflows Setup

[![License](https://img.shields.io/github/license/makinosp/aidlc-workflows-setup)](https://opensource.org/licenses/BSD-3-Clause)

This repository provides an automated setup script to integrate [AI-DLC (AI-Driven Development Life Cycle) Workflows](https://github.com/awslabs/aidlc-workflows) into your project using Git submodules and symbolic links.

The script is designed to **work from any directory** — it automatically detects the project root via Git or script location.

## Why use this script?

This script streamlines the integration of AI-DLC workflows by automating the following:

- **Submodule Management**: Automatically adds `awslabs/aidlc-workflows` as a Git submodule.
- **Complex Configuration**: Creates all necessary platform-specific directories (e.g., `.kiro`, `.amazonq`, `.cursor`, etc.).
- **Symlink Orchestration**: Sets up all symbolic links to ensure a single source of truth while maintaining platform compatibility.
- **Cursor Optimization**: Automatically generates the specialized `.mdc` file required for Cursor's advanced rule support.
- **Zero-Config Execution**: Works from any directory without needing to navigate to the project root first.
- **Seamless Updates**: Makes upgrading AI-DLC rules effortless via Git submodules and symbolic links, ensuring all platform-specific configurations stay in sync.

## What is AI-DLC?

AI-DLC is an intelligent software development workflow that:

- Adapts to your project's complexity and needs
- Maintains quality standards throughout development
- Keeps you in control of the AI-assisted development process
- Works with multiple coding agents and IDEs

Learn more: [AI-DLC GitHub Repository](https://github.com/awslabs/aidlc-workflows)

## Supported Platforms

This setup script configures AI-DLC for all major AI coding agents:

| Platform | Configuration | Verification |
|----------|---|---|
| **Kiro** | `.kiro/steering/` | `kiro-cli` → `/context show` |
| **Amazon Q** | `.amazonq/rules/` | Chat Rules button |
| **Cursor** | `.cursor/rules/` | Settings → Rules → Project Rules |
| **Cline** | `.clinerules/` | Rules popover in chat |
| **Claude Code** | `.claude/` + `CLAUDE.md` | `/config` command |
| **GitHub Copilot** | `.github/copilot-instructions.md` | `/instructions` command |

## Quick Start

### Prerequisites

- Git with submodule support
- Bash shell (Linux/macOS/WSL2)
- One or more of the supported platforms installed

> [!NOTE]
> **Windows users**: This script requires a Unix-like environment. Use WSL2 (Windows Subsystem for Linux), Git Bash, or Cygwin to run the script. Native Windows PowerShell or Command Prompt are not supported due to bash-specific syntax and symbolic link requirements.

### Setup

Run the setup script directly from GitHub using curl:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/makinosp/aidlc-workflows-setup/refs/heads/main/scripts/aidlc-workflows-setup.sh)"
```

> This downloads and executes the script in a single command. The script auto-detects the project root using Git (`git rev-parse --show-toplevel`), falling back to the parent of the script's directory. It works correctly **no matter which directory you run it from**.

The script will:

- Add `awslabs/aidlc-workflows` as a Git submodule in `.vendor/`
- Create platform-specific configuration directories
- Set up symbolic links to the core rules and rule details
- Generate Cursor's combined rule file (FRONTMATTER + core workflow)

### Commit the changes

After the script completes successfully:

```bash
git add -A
git commit -m "setup: AI-DLC Workflows integration"
```

### Verify setup

See verification commands in the [Verification](#verification) section below.

## Architecture

### Directory Structure

After running the setup script, your project will have:

```
your-project/
├── .vendor/
│   └── aidlc-workflows/               # Git submodule (source of truth)
│       └── aidlc-rules/
│           ├── aws-aidlc-rules/
│           │   └── core-workflow.md
│           └── aws-aidlc-rule-details/
│
├── .kiro/
│   ├── steering/
│   │   └── aws-aidlc-rules → …/aidlc-rules/aws-aidlc-rules
│   └── aws-aidlc-rule-details → …/aidlc-rules/aws-aidlc-rule-details
│
├── .amazonq/
│   ├── rules/
│   │   └── aws-aidlc-rules → …/aidlc-rules/aws-aidlc-rules
│   └── aws-aidlc-rule-details → …/aidlc-rules/aws-aidlc-rule-details
│
├── .cursor/
│   └── rules/
│       └── ai-dlc-workflow.mdc        # Generated: FRONTMATTER + core-workflow.md
│
├── .clinerules/
│   ├── core-workflow.md → …/aidlc-rules/aws-aidlc-rules/core-workflow.md
│   └── .aidlc-rule-details → …/aidlc-rules/aws-aidlc-rule-details
│
├── .claude/
│   ├── CLAUDE.md → …/aidlc-rules/aws-aidlc-rules/core-workflow.md
│   └── .aidlc-rule-details → …/aidlc-rules/aws-aidlc-rule-details
│
├── .github/
│   ├── copilot-instructions.md → …/aidlc-rules/aws-aidlc-rules/core-workflow.md
│   └── .aidlc-rule-details → …/aidlc-rules/aws-aidlc-rule-details
│
├── .aidlc-rule-details → .vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rule-details
│
└── CLAUDE.md → .vendor/aidlc-workflows/aidlc-rules/aws-aidlc-rules/core-workflow.md
```

### Key Design Decisions

1. **Single Source of Truth**: All rules are maintained in `.vendor/aidlc-workflows/` (Git submodule)
2. **Symbolic Links**: Platform-specific configurations use symlinks to avoid duplication
3. **Cursor Special Handling**: Cursor receives a merged file (FRONTMATTER + core workflow) for proper metadata support
4. **Git Submodule**: Allows easy updates and reproducibility across team members

## Verification

After setup, verify that rules are properly loaded in each platform:

### Kiro

```bash
kiro-cli
/context show
```

Look for entries under `.kiro/steering/aws-aidlc-rules`.

### Amazon Q Developer

In the IDE chat window, click the **Rules** button in the lower right corner and verify `aws-aidlc-rules` is listed.

### Cursor IDE

1. Open **Settings** → **Rules** → **Commands**
2. Under **Project Rules**, confirm you see `ai-dlc-workflow` listed
3. Verify it's enabled (toggle switch)

### Cline

In the chat interface, look for the **Rules** popover under the chat input field. Verify `core-workflow.md` is listed and active.

### Claude Code

Use the `/config` command to view current configuration and confirm `CLAUDE.md` is active.

### GitHub Copilot

1. Open Copilot Chat panel (Cmd/Ctrl+Shift+I)
2. Select **Configure Chat** (gear icon) → **Chat Instructions**
3. Verify `copilot-instructions.md` is listed
4. Alternatively, type `/instructions` in chat to view active instructions

## Using AI-DLC

Once setup and verified:

1. **Start with "Using AI-DLC..."**: Begin any request with "Using AI-DLC, ..." in your AI agent's chat
2. **Follow the workflow**: The AI-DLC adaptive workflow activates automatically
3. **Review and approve**: Carefully review each proposed phase and approve before proceeding
4. **Monitor artifacts**: All generated artifacts are placed in the `aidlc-docs/` directory

> [!IMPORTANT]
> Always review and approve each phase of the AI-DLC workflow before proceeding to ensure quality and maintain control over the development process.

Learn more: [Working with AI-DLC](https://github.com/awslabs/aidlc-workflows/blob/main/docs/WORKING-WITH-AIDLC.md)

## Updating AI-DLC Rules

To update the AI-DLC rules to the latest version:

```bash
git submodule update --remote --merge
git add .vendor/aidlc-workflows
git commit -m "chore: update AI-DLC Workflows to latest version"
```

> [!NOTE]
> All symlinks will automatically point to the updated rules after the submodule update.

## Troubleshooting

## Troubleshooting

### Rules not loading in platform

- Verify symlinks are correct: `ls -la .kiro/steering/`
- Restart the IDE/agent after setup
- Check file encodings are UTF-8

### Symlink creation failed

- Ensure you have write permissions in the project directory
- Check disk space availability

### Cursor rule file too large

If `.cursor/rules/ai-dlc-workflow.mdc` exceeds size limits:

- Keep only necessary sections
- Or use Option 2 from [Cursor setup guide](https://github.com/awslabs/aidlc-workflows#cursor-ide)

### Git submodule issues

Reinitialize submodules:

```bash
git submodule update --init --recursive
```

## License

This setup script is provided under the BSD-3 License.

## References

- [AI-DLC GitHub Repository](https://github.com/awslabs/aidlc-workflows)
- [AI-DLC Methodology Blog](https://aws.amazon.com/blogs/devops/ai-driven-development-life-cycle/)
- [AI-DLC Method Definition Paper](https://prod.d13rzhkk8cj2z0.amplifyapp.com/)
