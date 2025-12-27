# GHA CLI Wrapper

The following sections provides a "Getting Up to Speed" overview, designed to be completed in approximately 15 minutes. 

> [!INFO] RTM - Read The Manual
> For comprehensive and detailed documentation, please consult the project wiki.

### 📋 0. Overview

**Purpose:** An interactive terminal-based wrapper for the GitHub CLI (`gh`) that streamlines triggering GitHub Actions workflows.

**What it does:** This tool provides a fuzzy-finder (fzf) powered interface for selecting repositories, branches, and workflows from your GitHub organization. It intelligently parses workflow YAML files to detect `workflow_dispatch` inputs—including booleans, strings, and choice types—and presents them in an interactive menu for configuration before execution.

**Problem Solved:** Manually triggering `workflow_dispatch` workflows via the GitHub UI or raw CLI commands is tedious and error-prone, especially when dealing with multiple repositories, branches, and complex input parameters. This tool eliminates the friction of remembering repository names, workflow file names, and input parameters.

**Key Benefits:**
- **Interactive Selection:** Fuzzy-finder powered menus for repos, branches, and workflows
- **Input Type Awareness:** Automatically detects and presents appropriate input controls (booleans, choices, strings)
- **Zero Configuration Recall:** No need to remember workflow names, input parameters, or exact syntax

**Functions:**

- **Repository Selection:** Select from a curated list of repositories defined in `repos.txt`
- **Branch Selection:** Choose target branches from `branches.txt` for workflow execution
- **Workflow Discovery:** Automatically fetches and displays all available workflows for the selected repository
- **Input Configuration:** Parses workflow YAML to detect inputs, types, and options for interactive configuration
- **Workflow Execution:** Executes the configured workflow via `gh workflow run`

#### Table of Contents

- [0. Overview](#-0-overview)
- [1. Architecture & Business Context](#️-1-architecture--business-context)
- [2. Getting Started (15-Minute Path)](#-2-getting-started-15-minute-path)
- [3. Testing](#-3-testing)
- [4. CI/CD & Deployment](#-4-cicd--deployment)
- [Contributing](#-contributing)

---

### 🏗️ 1. Architecture & Business Context

#### Business Context

This tool is part of the GitHub Actions wrapper toolkit ecosystem, designed to improve developer experience when working with GitHub Actions. It sits alongside the `dynamic_runner_registrator` tool, together forming a comprehensive toolkit for GitHub Actions management.

#### Architectural Context

```
┌─────────────────────────────────────────────────────────┐
│                    gha.sh (Entry Point)                 │
├─────────────────────────────────────────────────────────┤
│  repos.txt ──► Repo Selection (fzf)                     │
│  branches.txt ──► Branch Selection (fzf)                │
│                     │                                   │
│                     ▼                                   │
│         gh workflow list ──► Workflow Selection (fzf)   │
│                     │                                   │
│                     ▼                                   │
│         gh workflow view --yaml ──► yq Parse Inputs     │
│                     │                                   │
│                     ▼                                   │
│         Interactive Input Configuration (fzf)           │
│                     │                                   │
│                     ▼                                   │
│         gh workflow run ──► Execute Workflow            │
└─────────────────────────────────────────────────────────┘
```

##### Technology Stack

**Languages:**
- Bash 3.2+ (macOS/Linux compatible)

**Frameworks & Libraries:**
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder for interactive selection
- [yq](https://github.com/mikefarah/yq) - YAML parsing for workflow input detection
- [gh](https://github.com/cli/cli) - GitHub CLI for API interactions

**Infrastructure:**
- Runtime environment: Bash shell (macOS/Linux)
- Deployment platform: Local workstation / developer machine
- External Dependencies: GitHub API (authenticated via `gh auth`)

---

### 🚀 2. Getting Started (15-Minute Path)

#### Prerequisites

**Required Access:**
- GitHub account with access to target repositories
- Authenticated `gh` CLI session (`gh auth login`)

**Required Software:**
- `gh` (GitHub CLI) version 2.0.0 or higher
- `fzf` (Fuzzy Finder) version 0.24.0 or higher
- `yq` (YAML Processor) version 4.0.0 or higher
- Bash 3.2 or higher (default on macOS)

**Installation (macOS):**
```bash
brew install gh fzf yq
```

**Installation (Linux - Fedora/RHEL):**
```bash
dnf install gh-cli yq
# fzf installation via package manager or git clone
```

#### Project Structure

```
gha-cli-wrapper/
├── gha.sh           # Main executable script
├── repos.txt        # Repository list configuration
├── branches.txt     # Branch list configuration
└── README.md        # This documentation
```

**Key Directories:**
- `gha.sh`: Main entry point and all business logic
- `repos.txt`: User-configurable list of repositories (one per line, without owner prefix)
- `branches.txt`: User-configurable list of target branches (one per line)

#### Installation Steps

```bash
# Step 1: Clone the repository
git clone https://github.com/pr0methevs/gha_wrappers.git

# Step 2: Navigate to project directory
cd gha_wrappers/gha-cli-wrapper

# Step 3: Ensure dependencies are installed
brew install gh fzf yq   # macOS
# OR
dnf install gh-cli yq    # Linux (Fedora/RHEL)

# Step 4: Authenticate with GitHub
gh auth login

# Step 5: Configure repositories
# Edit repos.txt with your repository names (one per line, without owner)
echo "my-repo-name" >> repos.txt

# Step 6: Configure branches
# Edit branches.txt with branches you use (one per line)
echo "main" >> branches.txt
echo "develop" >> branches.txt
```

#### Running Locally

```bash
# Make executable (if needed)
chmod +x gha.sh

# Run the wrapper
./gha.sh

# Alternative: Add to PATH for global access
export PATH="$PATH:$(pwd)"
gha.sh
```

---

### 🧪 3. Testing

#### Local Testing

**Validation Steps:**

1. **Verify dependencies are installed:**
```bash
command -v gh && command -v fzf && command -v yq && echo "All dependencies installed"
```

2. **Verify GitHub authentication:**
```bash
gh auth status
```

3. **Test repository access:**
```bash
gh repo view owner/repo-name
```

4. **Dry run workflow list:**
```bash
gh workflow list -R owner/repo-name --all
```

**Manual Testing:**
- Run `./gha.sh` and step through each selection menu
- Verify workflow inputs are correctly detected and displayed
- Confirm workflow execution command is correctly formatted

---

### 🔄 4. CI/CD & Deployment

#### Pipelines

This is a local developer tool and does not have automated CI/CD pipelines.

#### Deployment Locations

**Availability:** Developer workstation only (not deployed to servers)

**Distribution:**
- Clone directly from GitHub repository
- No package manager distribution currently

#### Usage Tips

| Use Case | Steps | Notes |
|----------|-------|-------|
| Trigger a workflow | Run `./gha.sh`, select repo/branch/workflow, configure inputs | Interactive fzf menus guide the process |
| Add a new repo | Add repo name to `repos.txt` | One repo per line, no owner prefix needed |
| Add a new branch | Add branch name to `branches.txt` | One branch per line |

---

### 🤝 Contributing

#### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make changes and test locally
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/)
5. Open a Pull Request

#### Code Style Guidelines

- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Maintain Bash 3.2 compatibility (for macOS)
- Use `shellcheck` for static analysis
