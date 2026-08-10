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
#   2. The private key and wallet address are written to a temporary file with
#      restricted permissions (chmod 600), sourced by the child installer, and
#      deleted on exit. Sensitive values are never passed via environment
#      variables, preventing exposure through /proc/<pid>/environ.
#   3. Temporary files are cleaned up on exit via a trap handler.
#
#   WARNING: The private key entered at the prompt will be stored in your bash
#   history unless you clear it. After installation, consider running:
#       history -d $(history 1 | awk '{print $1}')
#   or clearing history with: history -c
# ==============================================================================

SMARDNODE_INSTALL_COMMIT="0b0a6630cde285a9e583159be2a43e33840a0e28"
SMARDNODE_INSTALL_URL="https://raw.githubusercontent.com/SmartCashCMTY/SmardNode3.0/${SMARDNODE_INSTALL_COMMIT}/smardnode-install.sh"

# Expected SHA256 hash of the downloaded installer script.
# This hash corresponds to commit 0b0a6630. If the commit changes, update both
# SMARDNODE_INSTALL_COMMIT and this hash. To generate the hash:
#   curl -fL -o smardnode-install.sh "${SMARDNODE_INSTALL_URL}"
#   sha256sum smardnode-install.sh
SMARDNODE_INSTALL_SHA256="2dedd664585dcad3dff86e1f78ad99a50801342083a831bd5f3ebe65f25c108a"

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
secretfile="$(mktemp)"
chmod 600 "$secretfile"
trap 'rm -rf "$tmpdir" "$secretfile"; unset SMARTNODE_PRIVKEY SMARTNODE_WALLET_ADDRESS EXTERNAL_IP' EXIT

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

{
  echo "SMARTNODE_PRIVKEY=\"$SMARTNODE_PRIVKEY\""
  echo "SMARTNODE_WALLET_ADDRESS=\"$SMARTNODE_WALLET_ADDRESS\""
  if [[ -n "${EXTERNAL_IP:-}" ]]; then
    echo "EXTERNAL_IP=\"$EXTERNAL_IP\""
  fi
} > "$secretfile"

bash "$tmpdir/smardnode-install.sh" "$secretfile"

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
