#!/usr/bin/env bash
set -euo pipefail

SMARTCASH_VERSION="3.0.0"
RELEASE_BASE_URL="https://github.com/SmartCashCMTY/Node-Client-Wallet/releases/download/v3.0.0"
ARCHIVE_NAME="smartcash3-3.0.0-x86_64-linux-gnu.tar.gz"
ARCHIVE_SHA256="d53c8195768490808c88d178cfb387102b8e69ab452e4c7baddf9af5c44993eb"
SMARTCASH_USER="smartcash"
DATADIR="/var/lib/smartcash3"
CONFDIR="/etc/smartcash3"
SERVICE_FILE="/etc/systemd/system/smardnode.service"
MINER_SERVICE="/etc/systemd/system/smardnode-miner.service"
MINER_TIMER="/etc/systemd/system/smardnode-miner.timer"
MINE_ONCE="/usr/local/sbin/smardnode-mine-once"
MINER_ENV="$CONFDIR/miner.env"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run as root: sudo bash smardnode-install.sh" >&2
  exit 1
fi

if [[ "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage:
  sudo SMARTNODE_PRIVKEY="YOUR_SMARTNODE_PRIVKEY" \
       SMARTNODE_WALLET_ADDRESS="YOUR_WALLET_ADDRESS" \
       bash smardnode-install.sh

Required environment variables:
  SMARTNODE_PRIVKEY="YOUR_SMARTNODE_PRIVKEY"
  SMARTNODE_WALLET_ADDRESS="YOUR_WALLET_ADDRESS"

Optional environment variables:
  EXTERNAL_IP="YOUR_PUBLIC_IPV4"
  MINING_CPU_QUOTA="10%"        (default: 10%)
  GENERATE_BLOCKS="1"           (default: 1)
  MAX_TRIES="100000000"         (default: 100000000)
  MIN_BLOCK_HEIGHT="4269520"    (default: 4269520)
  MIN_CONNECTIONS="1"           (default: 1)

This script installs SmardNode 3.0.0 on Ubuntu Server 24.04 LTS.
EOF
  exit 0
fi

if [[ -z "${SMARTNODE_PRIVKEY:-}" ]]; then
  echo "ERROR: SMARTNODE_PRIVKEY is required." >&2
  echo "Generate it on the controller wallet with: smartcash-cli smartnode genkey" >&2
  echo "Then run: sudo SMARTNODE_PRIVKEY='YOUR_KEY' SMARTNODE_WALLET_ADDRESS='S...' bash smardnode-install.sh" >&2
  exit 1
fi

if [[ -z "${SMARTNODE_WALLET_ADDRESS:-}" ]]; then
  echo "ERROR: SMARTNODE_WALLET_ADDRESS is required." >&2
  echo "Run: sudo SMARTNODE_PRIVKEY='YOUR_KEY' SMARTNODE_WALLET_ADDRESS='S...' bash smardnode-install.sh" >&2
  exit 1
fi

if [[ -z "${EXTERNAL_IP:-}" ]]; then
  EXTERNAL_IP="$(curl -fsS4 https://ifconfig.me || true)"
fi

if [[ -z "$EXTERNAL_IP" ]]; then
  echo "ERROR: Could not auto-detect public IPv4. Re-run with EXTERNAL_IP='YOUR_PUBLIC_IPV4'." >&2
  exit 1
fi

echo "================================================"
echo " SmardNode 3.0.0 Installation"
echo "================================================"
echo " Public IP:         ${EXTERNAL_IP}"
echo " Wallet Address:    ${SMARTNODE_WALLET_ADDRESS}"
echo ""

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y curl ca-certificates tar unzip openssl ufw fail2ban htop jq chrony unattended-upgrades apt-listchanges

timedatectl set-timezone UTC
systemctl enable --now chrony

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'UEOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
UEOF

cat >/etc/apt/apt.conf.d/20auto-upgrades <<'APTEOF'
APT::Periodic::Update-Package-Lists "14";
APT::Periodic::Download-Upgradeable-Packages "14";
APT::Periodic::AutocleanInterval "14";
APT::Periodic::Unattended-Upgrade "14";
APTEOF

systemctl enable apt-daily-upgrade.timer 2>/dev/null || true
systemctl restart apt-daily-upgrade.timer 2>/dev/null || true

if ! swapon --show | grep -q '^'; then
  swapoff /swapfile 2>/dev/null || true
  rm -f /swapfile
  dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
  chmod 600 /swapfile
  mkswap /swapfile > /dev/null
  if swapon /swapfile 2>/dev/null; then
    echo "Swap enabled via /swapfile"
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
  elif modprobe loop 2>/dev/null && LOOPDEV=$(losetup -f 2>/dev/null) && [ -n "$LOOPDEV" ]; then
    losetup "$LOOPDEV" /swapfile
    swapon "$LOOPDEV"
    echo "Swap enabled via loop device $LOOPDEV"
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >>/etc/fstab
  else
    rm -f /swapfile
    echo "WARNING: Could not enable swap (ZFS/LXC limitation). Continuing without swap."
  fi
fi

id "$SMARTCASH_USER" >/dev/null 2>&1 || useradd --system --home "$DATADIR" --shell /usr/sbin/nologin "$SMARTCASH_USER"
install -d -m 0750 -o "$SMARTCASH_USER" -g "$SMARTCASH_USER" "$DATADIR"
install -d -m 0755 "$CONFDIR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"
curl -fL -o "$ARCHIVE_NAME" "$RELEASE_BASE_URL/$ARCHIVE_NAME"
printf '%s  %s\n' "$ARCHIVE_SHA256" "$ARCHIVE_NAME" | sha256sum -c -
tar -xzf "$ARCHIVE_NAME"
install -m 0755 linux-x86_64/smartcashd /usr/local/bin/smartcashd
install -m 0755 linux-x86_64/smartcash-cli /usr/local/bin/smartcash-cli
install -m 0755 linux-x86_64/smartcash-tx /usr/local/bin/smartcash-tx

RPCUSER="smartcashrpc"
RPCPASSWORD="$(openssl rand -hex 32)"

cat >"$CONFDIR/smartcash.conf" <<EOF
daemon=1
server=1
listen=1
txindex=1
maxconnections=128
port=29678
rpcport=29679
rpcbind=127.0.0.1
rpcallowip=127.0.0.1
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
externalip=${EXTERNAL_IP}:29678
addnode=151.252.59.32:29678
addnode=151.252.59.33:29678
sapi=1
sapiport=28080
smartnode=1
smartnodeprivkey=${SMARTNODE_PRIVKEY}
smartnodewallet=${SMARTNODE_WALLET_ADDRESS}
EOF
chown root:"$SMARTCASH_USER" "$CONFDIR/smartcash.conf"
chmod 0640 "$CONFDIR/smartcash.conf"

cat >"$MINER_ENV" <<EOF
PAYOUT_ADDRESS=${SMARTNODE_WALLET_ADDRESS}
GENERATE_BLOCKS=${GENERATE_BLOCKS:-1}
MAX_TRIES=${MAX_TRIES:-100000000}
MIN_BLOCK_HEIGHT=${MIN_BLOCK_HEIGHT:-4269520}
MIN_CONNECTIONS=${MIN_CONNECTIONS:-1}
MINING_CPU_QUOTA=${MINING_CPU_QUOTA:-10%}
EOF
chown root:"$SMARTCASH_USER" "$MINER_ENV"
chmod 0640 "$MINER_ENV"

cat >"$SERVICE_FILE" <<'SERVICEEOF'
[Unit]
Description=SmartCash 3.0.0 SmardNode daemon
After=network-online.target
Wants=network-online.target

[Service]
User=smartcash
Group=smartcash
Type=forking
PIDFile=/run/smartcash3/smartcashd.pid
ExecStart=/usr/local/bin/smartcashd -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 -pid=/run/smartcash3/smartcashd.pid
ExecStop=/usr/local/bin/smartcash-cli -conf=/etc/smartcash3/smartcash.conf -datadir=/var/lib/smartcash3 stop
RuntimeDirectory=smartcash3
RuntimeDirectoryMode=0755
Restart=always
RestartSec=15
TimeoutStartSec=600
TimeoutStopSec=120
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=full
ReadWritePaths=/var/lib/smartcash3 /run
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SERVICEEOF

cat >"$MINER_SERVICE" <<'MINERSVC'
[Unit]
Description=SmartCash 3.0.0 SmardNode block producer
After=smardnode.service
Requires=smardnode.service

[Service]
Type=oneshot
User=root
EnvironmentFile=-/etc/smartcash3/miner.env
RuntimeDirectory=smartcash3
RuntimeDirectoryMode=0755
ExecStart=/usr/local/sbin/smardnode-mine-once
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
TimeoutStartSec=10min

[Install]
WantedBy=multi-user.target
MINERSVC

cat >"$MINER_TIMER" <<'TIMEREOF'
[Unit]
Description=SmardNode block producer timer

[Timer]
OnBootSec=2min
OnUnitActiveSec=55s
AccuracySec=1s
Unit=smardnode-miner.service

[Install]
WantedBy=timers.target
TIMEREOF

cat >"$MINE_ONCE" <<'MINEONCE'
#!/usr/bin/env bash
set -euo pipefail

CONF=/etc/smartcash3/smartcash.conf
DATADIR=/var/lib/smartcash3
CLI=/usr/local/bin/smartcash-cli
LOCK=/run/smartcash3/miner.lock
ENVFILE=/etc/smartcash3/miner.env
NODE_SERVICE=smardnode.service

install -d -m 0755 /run/smartcash3

if [[ -f "$ENVFILE" ]]; then
  source "$ENVFILE"
fi

PAYOUT_ADDRESS="${PAYOUT_ADDRESS:-}"
GENERATE_BLOCKS="${GENERATE_BLOCKS:-1}"
MAX_TRIES="${MAX_TRIES:-100000000}"
MIN_BLOCK_HEIGHT="${MIN_BLOCK_HEIGHT:-4269520}"
MIN_CONNECTIONS="${MIN_CONNECTIONS:-1}"
MINING_CPU_QUOTA="${MINING_CPU_QUOTA:-10%}"
cpu_quota_applied=0

if [[ -z "$PAYOUT_ADDRESS" ]]; then
  echo "PAYOUT_ADDRESS is required. Set it in $ENVFILE." >&2
  exit 1
fi

exec 9>"$LOCK"
flock -n 9 || exit 0

reset_cpu_quota() {
  if (( cpu_quota_applied )); then
    systemctl set-property --runtime "$NODE_SERVICE" CPUQuota=infinity >/dev/null 2>&1 || true
  fi
}

trap reset_cpu_quota EXIT

for _ in $(seq 1 60); do
  if "$CLI" -conf="$CONF" -datadir="$DATADIR" getblockcount >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

height="$("$CLI" -conf="$CONF" -datadir="$DATADIR" getblockcount)"
if (( height < MIN_BLOCK_HEIGHT )); then
  echo "not mining: block height $height is below MIN_BLOCK_HEIGHT=$MIN_BLOCK_HEIGHT"
  exit 0
fi

connections="$("$CLI" -conf="$CONF" -datadir="$DATADIR" getconnectioncount)"
if (( connections < MIN_CONNECTIONS )); then
  echo "not mining: connection count $connections is below MIN_CONNECTIONS=$MIN_CONNECTIONS"
  exit 0
fi

systemctl set-property --runtime "$NODE_SERVICE" "CPUQuota=$MINING_CPU_QUOTA" >/dev/null
cpu_quota_applied=1
"$CLI" -conf="$CONF" -datadir="$DATADIR" generatetoaddress "$GENERATE_BLOCKS" "\"$PAYOUT_ADDRESS\"" "$MAX_TRIES"
MINEONCE

chmod 0755 "$MINE_ONCE"

sed -i 's/^IPV6=yes/IPV6=no/' /etc/default/ufw
ufw allow OpenSSH
ufw allow 29678/tcp
ufw allow 28080/tcp
ufw --force enable
systemctl enable --now fail2ban
systemctl daemon-reload
systemctl enable smardnode
systemctl restart smardnode
systemctl enable smardnode-miner.timer
systemctl start smardnode-miner.timer

echo ""
echo "================================================"
echo " SmardNode 3.0.0 installed successfully!"
echo "================================================"
echo ""
echo " Wallet Address:"
echo "   ${SMARTNODE_WALLET_ADDRESS}"
echo ""
echo " Configuration:"
echo "   Daemon:     $CONFDIR/smartcash.conf"
echo "   Miner:      $MINER_ENV"
echo "   Data:       $DATADIR"
echo ""
echo " Services:"
echo "   systemctl status smardnode --no-pager"
echo "   systemctl status smardnode-miner.timer --no-pager"
echo ""
echo " Useful commands:"
echo "   smartcash-cli -conf=$CONFDIR/smartcash.conf -datadir=$DATADIR getinfo"
echo "   smartcash-cli -conf=$CONFDIR/smartcash.conf -datadir=$DATADIR getconnectioncount"
echo "   smartcash-cli -conf=$CONFDIR/smartcash.conf -datadir=$DATADIR getblockcount"
echo "   smartcash-cli -conf=$CONFDIR/smartcash.conf -datadir=$DATADIR smartnode status"
echo ""
echo " Miner logs:  journalctl -u smardnode-miner -f"
echo ""
echo " Auto-updates: Enabled (every 14 days, auto-reboot at 03:00 if needed)"
echo ""
echo " NOTE: Configure smartnode.conf on your controller wallet"
echo " and run smartnode start-alias."
echo "================================================"
