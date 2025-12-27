## 🚀 Welcome to the GitHub Runner Automation Toolkit!

This repo is your all-in-one Swiss Army knife for setting up custom GitHub Actions runners and managing SSH keys with style. 

> **Why?**  
> This toolkit was written to make it painless to set up and manage self-hosted runners—especially for **private repositories**, where extra steps and secure handling of tokens and SSH keys are required. No more manual runner registration or key wrangling!

Here’s what each script does:


---

### 🌱 `env.sh` & `.env`
*Environment variable magic!*
- `.env` holds your secrets (like your GitHub access token).
- `env.sh` loads them up for your scripts.

---

### 🗄️ `env.bak`
*A backup for your environment variable names, not the secrets-because sharing secrets is not fun, not remembering what they were is even worse*

---

### 🏗️ `setup.sh`
*Downloads and unpacks the latest GitHub Actions Runner for you. No more manual downloads—just run and chill!*

---

### 🤖 `registration.sh`
*Automates runner registration with your repo. It fetches a registration token and configures your runner with a single command. Supports both `jq` and `grep` for parsing—because flexibility is cool.*

#### 🚦 What Does This Script Do?

- **Loads secrets** from `.env` and checks for a valid `ACCESS_TOKEN`.
- **Accepts arguments** for `owner/repo` and an optional runner name (defaults to `auto-runner`).
- **Fetches a registration token** from the GitHub API (using `jq` or `grep` depending on availability on the host).
- **Detects and removes** any previously registered runner before re-registering.
- **Registers the runner** with your repository using `config.sh`.
- **Prompts to install the runner as a system service** (recommended), or to start it interactively.
- **Provides clear user prompts and status messages** throughout.


---

## SSH Key Automation Toolkit 

### 🔑 `ssh-api/gh-ssh-key.sh`
*Generates a shiny new ed25519 SSH key, uploads it to your GitHub account, and adds it to your local ssh-agent. All you need for secure, key-based GitHub access, in one go!*

---


### 🛡️ `.gitignore`
*Keeps your secrets and runner files out of git. Safety first!*

---

## How to Use

1. **Set your access token** in `.env`.
2. **Run `setup.sh`** to grab the latest runner.
3. **Register your runner** with `registration.sh`.
4. **Generate and upload SSH keys** with `ssh-api/gh-ssh-key.sh`.

---

## 🔐 About Access Tokens & Permissions

To use this toolkit, you’ll need a **GitHub Personal Access Token** with the following permissions:

### 🏃 Runner Registration & Removal

- **Scope:** `repo` (for private repositories)  
- **Fine-grained permissions:**  
  - `Actions: Read and Write` (required for registration and removal of runners)

This token is used to:
- **Request a registration token** (to add a runner)
- **Request a removal token** (to remove/unregister a runner)

### 🔑 SSH Key Management

- **Scope:** `admin:public_key`  
  (or, for fine-grained tokens: `Public SSH keys: Read and Write`)

This is required for:
- **Adding SSH keys to your GitHub account via the API**

---

> **Note:**  
> - For **private repositories**, your token must have access to the repo.
> - Never share your access token or commit it to version control.
> - Store your token securely in the `.env` file (which is already gitignored .. you'll need to create it).

---


> **Pro tip:** All scripts are designed to be idempotent and safe. Tweak, run, and automate with confidence!

---

Happy automating! 🚦