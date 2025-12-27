# GitHub Actions Wrappers

A collection of shell-based tools for streamlining GitHub Actions workflows and runner management.

## 📋 Overview

This monorepo contains developer utilities that wrap the GitHub CLI (`gh`) to simplify common GitHub Actions tasks. These tools are designed for developers who frequently interact with GitHub Actions—whether triggering workflows or managing self-hosted runners.

## 🧰 Projects

| Project | Description | Use Case |
|---------|-------------|----------|
| [**gha-cli-wrapper**](./gha-cli-wrapper/) | Interactive fuzzy-finder interface for triggering `workflow_dispatch` workflows | Quickly trigger workflows with complex inputs across multiple repos |
| [**dynamic_runner_registrator**](./dynamic_runner_registrator/) | Automated self-hosted runner setup and SSH key management | Register/unregister GitHub Actions runners for private repositories |

---

### 🚀 GHA CLI Wrapper

An interactive terminal tool that uses `fzf` to provide a menu-driven interface for triggering GitHub Actions workflows.

**Key Features:**
- Fuzzy-finder selection for repositories, branches, and workflows
- Automatic detection of workflow inputs (boolean, string, choice types)
- Interactive input configuration before execution

**Quick Start:**
```bash
cd gha-cli-wrapper
./gha.sh
```

📖 [Full Documentation →](./gha-cli-wrapper/README.md)

---

### 🤖 Dynamic Runner Registrator

A toolkit for automating the setup and registration of self-hosted GitHub Actions runners, with built-in SSH key management.

**Key Features:**
- Downloads and configures the latest GitHub Actions Runner
- Automates runner registration and removal via the GitHub API
- Generates and uploads SSH keys to GitHub

**Quick Start:**
```bash
cd dynamic_runner_registrator
# Set your access token in .env
./setup.sh        # Download runner
./registration.sh # Register with your repo
```

📖 [Full Documentation →](./dynamic_runner_registrator/README.md)

---

## 🔧 Prerequisites

All tools require the GitHub CLI authenticated:

```bash
# Install GitHub CLI
brew install gh          # macOS
dnf install gh-cli       # Fedora/RHEL

# Authenticate
gh auth login
```

## 📁 Repository Structure

```
gha_wrappers/
├── gha-cli-wrapper/              # Workflow trigger tool
│   ├── gha.sh                    # Main script
│   ├── repos.txt                 # Repository configuration
│   └── branches.txt              # Branch configuration
│
├── dynamic_runner_registrator/   # Runner management toolkit
│   ├── setup.sh                  # Runner download script
│   ├── registration.sh           # Runner registration script
│   ├── env.sh                    # Environment loader
│   └── ssh-api/                  # SSH key management
│       └── gh-ssh-key.sh         # SSH key generator/uploader
│
└── README.md                     # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Submit a Pull Request

---

> **Pro tip:** Both tools are designed to be idempotent and safe. Run them with confidence!
