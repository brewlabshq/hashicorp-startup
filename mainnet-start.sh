#!/bin/bash

HASHICORP_URL=< Add url here >
VOTE_ACCOUNT=<VOTE ACCOUNT>
jito_block_engine_url="https://amsterdam.mainnet.block-engine.jito.wtf"
jito_relayer_url="http://amsterdam.mainnet.relayer.jito.wtf:8100"
jito_shred_receiver_address="74.118.140.240:1002"
ntp="ntp.amsterdam.jito.wtf"
tip_payment_pubkey="T1pyyaTNZsKv2WcRAB8oVnk93mLJw2XzjtVYqCsaHqt"
tip_distribution_pubkey="4R3gSG8BpU4t19KYj8CfnbtRpnT8gtk4dvTHxVRwc2r7"
merkle_root_authority="GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib"
genesis_hash="5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d"
commission_bps=1000

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
  "$HASHICORP_URL" \
    | jq -r '.data.data.PRIVATE_KEY | @json' > "$TMP_IDENTITY_FILE"

# Verify if the temporary file is not empty
if [[ ! -s "$TMP_IDENTITY_FILE" ]]; then
    echo "Error: Failed to fetch or write the identity file." >&2
    rm -f "$TMP_IDENTITY_FILE"
    exit 1
fi

# Create a symbolic link for the identity file
LINKED_IDENTITY_FILE="/home/sol/id.json"
ln -sf "$TMP_IDENTITY_FILE" "$LINKED_IDENTITY_FILE"

# Run the validator using the symbolic link
exec agave-validator \
    --identity "$LINKED_IDENTITY_FILE" \
    --vote-account "$VOTE_ACCOUNT" \
    --authorized-voter "$LINKED_IDENTITY_FILE" \
    --only-known-rpc \
    --log "/home/sol/logs/solana-validator.log" \
    --ledger "/mnt/ledger" \
    --accounts "/mnt/accounts" \
    --snapshots "/mnt/snapshot" \
    --rpc-port 8899 \
    --limit-ledger-size \
    --private-rpc \
    --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
    --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
    --tip-payment-program-pubkey "$tip_payment_pubkey" \
    --tip-distribution-program-pubkey "$tip_distribution_pubkey" \
    --merkle-root-upload-authority "$merkle_root_authority" \
    --commission-bps $commission_bps \
    --shred-receiver-address "$jito_shred_receiver_address" \
    --block-engine-url "$jito_block_engine_url" \
    --block-production-method central-scheduler-greedy \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --minimal-snapshot-download-speed 10485760 \
    --incremental-snapshot-interval-slots 0 # remove this if you need snapshot

# Clean up the temporary identity file after the process ends
EXIT_CODE=$?
rm -f "$TMP_IDENTITY_FILE"
exit $EXIT_CODE
