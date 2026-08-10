#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# SECURITY NOTICE
# ==============================================================================
# This script downloads and executes the SmardNode installer from the official
# SmartCashCMTY GitHub repository. The following security measures are in place:
#
#   1. SHA256 hash verification of the downloaded installer script to prevent
#      supply-chain attacks and ensure integrity.
#   2. The private key (SMARTNODE_PRIVKEY) is passed via environment variable,
#      which may be visible in /proc/<pid>/environ on the local system. After
#      installation completes, all sensitive environment variables are explicitly
#      unset to limit exposure.
#   3. Temporary files are cleaned up on exit via a trap handler.
#
#   WARNING: The private key entered at the prompt will be stored in your bash
#   history unless you clear it. After installation, consider running:
#       history -d $(history 1 | awk '{print $1}')
#   or clearing history with: history -c
# ==============================================================================

SMARDNODE_INSTALL_URL="https://raw.githubusercontent.com/SmartCashCMTY/SmardNode3.0/main/smardnode-install.sh"

# Expected SHA256 hash of the downloaded installer script.
# IMPORTANT: This hash must be updated whenever smardnode-install.sh changes in
# the upstream repository. To generate the correct hash, download the script and
# run: sha256sum smardnode-install.sh
SMARDNODE_INSTALL_SHA256="REPLACE_WITH_EXPECTED_SHA256_HASH"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo bash ./SmardNodeInstall.sh" >&2
  exit 1
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_curl_if_missing() {
  if command_exists curl; then
    return
  fi
  apt-get update
  apt-get install -y curl ca-certificates
}

read_required_value() {
  local var_name="$1"
  local prompt="$2"
  local value="${!var_name:-}"

  if [[ -z "$value" ]]; then
    read -r -p "$prompt" value
  fi

  if [[ -z "$value" ]]; then
    echo "ERROR: Missing required value: $var_name" >&2
    exit 1
  fi

  printf -v "$var_name" '%s' "$value"
}

echo "================================================"
echo " SmardNodeInstall 3.0.0"
echo "================================================"
echo ""
echo "This installer downloads the official SmardNode installer from:"
echo "$SMARDNODE_INSTALL_URL"
echo ""
echo "You will be prompted for:"
echo "  1. SMARTNODE_PRIVKEY (from controller wallet)"
echo "  2. SMARTNODE_WALLET_ADDRESS (your SmardNode wallet address)"
echo ""

read_required_value SMARTNODE_PRIVKEY "Enter SMARTNODE_PRIVKEY from controller wallet: "

echo ""
read_required_value SMARTNODE_WALLET_ADDRESS "Enter SMARTNODE_WALLET_ADDRESS: "

if [[ -z "${EXTERNAL_IP:-}" ]]; then
  read -r -p "Enter public server IPv4 or leave empty for auto-detect: " EXTERNAL_IP || true
fi

echo ""
echo "================================================"
echo " Starting installation..."
echo "================================================"
echo ""

install_curl_if_missing

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"; unset SMARTNODE_PRIVKEY SMARTNODE_WALLET_ADDRESS EXTERNAL_IP' EXIT

curl -fsSL -o "$tmpdir/smardnode-install.sh" "$SMARDNODE_INSTALL_URL"

echo ""
echo "Verifying SHA256 checksum of smardnode-install.sh..."
computed_hash="$(sha256sum "$tmpdir/smardnode-install.sh" | awk '{print $1}')"
if [[ "$computed_hash" != "$SMARDNODE_INSTALL_SHA256" ]]; then
  echo "ERROR: SHA256 checksum mismatch!" >&2
  echo "  Expected: $SMARDNODE_INSTALL_SHA256" >&2
  echo "  Got:      $computed_hash" >&2
  echo "The downloaded script may have been tampered with or modified upstream." >&2
  echo "Installation aborted for security." >&2
  exit 1
fi
echo "Checksum verified OK."

chmod +x "$tmpdir/smardnode-install.sh"

if [[ -n "${EXTERNAL_IP:-}" ]]; then
  EXTERNAL_IP="$EXTERNAL_IP" \
  SMARTNODE_PRIVKEY="$SMARTNODE_PRIVKEY" \
  SMARTNODE_WALLET_ADDRESS="$SMARTNODE_WALLET_ADDRESS" \
  bash "$tmpdir/smardnode-install.sh"
else
  SMARTNODE_PRIVKEY="$SMARTNODE_PRIVKEY" \
  SMARTNODE_WALLET_ADDRESS="$SMARTNODE_WALLET_ADDRESS" \
  bash "$tmpdir/smardnode-install.sh"
fi

unset SMARTNODE_PRIVKEY SMARTNODE_WALLET_ADDRESS EXTERNAL_IP

echo ""
echo "================================================"
echo " SmardNodeInstall completed."
echo "================================================"
echo " Check SmartNode status:"
echo "   systemctl status smardnode --no-pager"
echo " Check block producer:"
echo "   systemctl status smardnode-miner.timer --no-pager"
echo "   journalctl -u smardnode-miner -f"
echo ""
echo "SECURITY REMINDER: The private key may still be in your bash history."
echo "  To remove the last command from history: history -d \$(history 1 | awk '{print \$1}')"
echo "  To clear all history: history -c"
