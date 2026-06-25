#!/usr/bin/env bash
set -euo pipefail

SMARDNODE_INSTALL_URL="https://raw.githubusercontent.com/SmartCashCMTY/SmardNode3.0/main/smardnode-install.sh"

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
trap 'rm -rf "$tmpdir"' EXIT

curl -fsSL -o "$tmpdir/smardnode-install.sh" "$SMARDNODE_INSTALL_URL"
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

echo ""
echo "================================================"
echo " SmardNodeInstall completed."
echo "================================================"
echo " Check SmartNode status:"
echo "   systemctl status smardnode --no-pager"
echo " Check block producer:"
echo "   systemctl status smardnode-miner.timer --no-pager"
echo "   journalctl -u smardnode-miner -f"
