#!/bin/bash

set -e

# Directory where the runner will be set up; downloaded using the setup.sh script
RUNNERS_DIR="runner"

OWNER_REPO="${1}"
# Replace with your actual owner/repo
# OWNER_REPO=""  
# RUNNER_NAME="$2"
RUNNER_NAME="${2:-auto-runner}"


if [[ -z ${OWNER_REPO} ]]; then
	echo "Usage: $0 owner/repo optional:[runner-name]"
	exit 1
fi

# Exit if .env doesn't exist
[ ! -f .env ] && { echo ".env not found"; exit 1; }

set -a  # Automatically export all variables
source .env
set +a  # Disable auto-export

if [[ -z "${ACCESS_TOKEN}" ]]; then
  echo "ACCESS_TOKEN is not set in .env"
  exit 1
fi

unset REGISTRATION_TOKEN

# Github API Alternative if GH CLI is available
# TOKEN=$(gh api --method POST /repos/$OWNER_REPO/actions/registration-token --jq .token)

# if command -v jq &>/dev/null; then
if [ -x "$(command -v jq)" ]; then

  echo "Using jq to parse for registration token"

  REGISTRATION_TOKEN=$(curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${OWNER_REPO}/actions/runners/registration-token" \
    | jq -r '.token')

else 

  echo "Using grep to parse for registration token"

  REGISTRATION_TOKEN=$(curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${OWNER_REPO}/actions/runners/registration-token" \
    | grep -oP '"token": "\K[^"]+' )

fi

# echo "REGISTRATION_TOKEN = ${REGISTRATION_TOKEN}"

export REGISTRATION_TOKEN

if [[ -z "${REGISTRATION_TOKEN}" ]]; then
  echo "Registration Token is not set. Please check your ACCESS_TOKEN permissions."
  exit 1
fi

cd "${RUNNERS_DIR}"

if [ -f ".runner" ]; then
  echo "Existing runner detected. Removing previous registration..."
  REMOVE_TOKEN=$(curl -s -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/${OWNER_REPO}/actions/runners/remove-token | jq -r '.token')
  ./config.sh remove --token "${REMOVE_TOKEN}"
fi


./config.sh --url "https://github.com/${OWNER_REPO}" \
	--token "${REGISTRATION_TOKEN}" \
	--name "${RUNNER_NAME}" \
	--labels "linux" \
	--work "_work" \
	--unattended \
	--replace

  echo "Runner configured successfully."


read -p "Do you want to install the runner as a service? (y/n): " INSTALL_SERVICE
if [[ "$INSTALL_SERVICE" == "y" || "$INSTALL_SERVICE" == "Y" ]]; then
  sudo ./svc.sh install
  sudo ./svc.sh start
  echo "Runner installed and started as a service!"
else
  read -p "Do you want to start the runner now (not as a service)? (y/n): " START
  if [[ "$START" == "y" || "$START" == "Y" ]]; then
    ./run.sh
  else
    echo "Runner is configured but not started."
    echo "Execute './run.sh' to start the runner manually."
  fi
fi
echo -e "\nRunner is ready! 👍\n"
exit 0 
