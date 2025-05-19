#!/bin/bash


HASHICORP_URL=<>
VOTE_ACCOUNT=<>
# Load the Vault token from /home/sol/.env.prod
if [[ -f "/home/sol/.env.prod" ]]; then
    VAULT_TOKEN=$(grep -E '^VAULT_TOKEN=' /home/sol/.env.prod | cut -d '=' -f2-)
    if [[ -z "$VAULT_TOKEN" ]]; then
        echo "Error: VAULT_TOKEN is not set in /home/sol/.env.prod." >&2
        exit 1
    fi
else
    echo "Error: /home/sol/.env.prod file not found." >&2
    exit 1
fi

# Create a temporary JSON file in memory
TMP_IDENTITY_FILE=$(mktemp /dev/shm/id.json.XXXXXX)

# Fetch the secret using curl and store it in the temporary file
curl -s --header "X-Vault-Token: $VAULT_TOKEN" \
  "$HASHICORP_URL"\
    | jq -r '.data.data.PRIVATE_KEY | @json' > "$TMP_IDENTITY_FILE"

# Verify if the temporary file is not empty
if [[ ! -s "$TMP_IDENTITY_FILE" ]]; then
    echo "Error: Failed to fetch or write the identity file." >&2
    rm -f "$TMP_IDENTITY_FILE"
    exit 1
fi

# Run the validator using the temporary file

exec /home/sol/.local/share/solana/install/active_release/bin/agave-validator \
    --identity "$TMP_IDENTITY_FILE" \
    --vote-account "$VOTE_ACCOUNT" \
    --only-known-rpc \
    --log "/home/sol/logs/solana-validator.log" \
    --ledger "/mnt/ledger" \
    --accounts "/mnt/accounts" \
    --snapshots "/mnt/snapshots" \
    --rpc-port 8899 \
    --limit-ledger-size \
    --private-rpc \
    --known-validator 7XSY3MrYnK8vq693Rju17bbPkCN3Z7KvvfvJx4kdrsSY \
    --known-validator Ft5fbkqNa76vnsjYNwjDZUXoTWpP7VYm3mtsaQckQADN \
    --known-validator 9QxCLckBiJc783jnMvXZubK4wH86Eqqvashtrwvcsgkv \
    --known-validator eoKpUABi59aT4rR9HGS3LcMecfut9x7zJyodWWP43YQ \
    --known-validator dDzy5SR3AXdYWVqbDEkVFdvSPCtS9ihF5kJkHCtXoFs  \
    --no-snapshot-fetch \
    --entrypoint entrypoint.testnet.solana.com:8001 \
    --entrypoint entrypoint2.testnet.solana.com:8001 \
    --entrypoint entrypoint3.testnet.solana.com:8001 \
    --use-snapshot-archives-at-startup when-newest \
    --minimal-snapshot-download-speed 10485760 \
    --block-production-method central-scheduler-greedy

# Clean up the temporary identity file after the process ends
EXIT_CODE=$?
rm -f "$TMP_IDENTITY_FILE"
exit $EXIT_CODE
