#!/bin/bash
set -euo pipefail

RUNNER_DIR="runner"

mkdir -p "$RUNNER_DIR"

cd "$RUNNER_DIR"

# Get the latest runner version
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

# Download the runner
echo "Downloading ${LATEST_VERSION}"

# TODO: Handle both x64 and ARM
curl -o actions-runner-linux-x64.tar.gz -L "https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64-${LATEST_VERSION}.tar.gz"

# Extract
echo "Extracting ..."
tar xzf ./actions-runner-linux-x64.tar.gz

echo "Done ! Downloaded and extracted the latest Runner version : ${LATEST_VERSION} to ./${RUNNER_DIR}"