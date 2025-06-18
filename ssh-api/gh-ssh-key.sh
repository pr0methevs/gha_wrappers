#!/bin/bash
set -e
# Generate SSH Key and Deploy to Github

# Access token must have admin:public_key for DELETE
source ../.env # Provided ACCESS_TOKEN

KEY_NAME="$1:-default-ed25519"
KEY_PATH="$HOME/.ssh/${KEY_NAME}"

echo "KEY PATH is $KEY_PATH"

# -q : quiet mode
# -t : key type
# -N : no passphrase
# -f : filename
ssh-keygen -q -t ed25519 -N "" -f "${KEY_PATH}"

echo "Generated new SSH key at $KEY_PATH"

PUBKEY=$(cat "${HOME}/.ssh/${KEY_NAME}.pub")
TITLE="${USER}@${HOSTNAME}"

RESPONSE=$(curl -s -X POST \
  -H "Authorization: token ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"${TITLE}\",\"key\":\"${PUBKEY//\"/\\\"}\"}" \
  https://api.github.com/user/keys)

KEYID=$(echo "$RESPONSE" | jq -r '.id')

if echo "$RESPONSE" | grep -q '"id":'; then
  echo "Public key deployed successfully."
else
  echo "Failed to deploy key to GitHub:"
  echo "$RESPONSE"
  echo "Verify the Access Token has admin:public_key permission."
  exit 1
fi

echo "Starting ssh-agent"
eval "$(ssh-agent -s)"

echo "Adding generated SSH key to ssh-agent"
ssh-add "${KEY_PATH}"

echo "Added SSH key to the ssh-agent"

# Test the SSH connection

echo "Testing SSH connection to Github"
ssh -T git@github.com