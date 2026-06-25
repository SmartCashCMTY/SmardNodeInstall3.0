#!/bin/bash
set -e

echo "=== SmardNode Auto-Update Setup ==="

apt-get update -qq
apt-get install -y -qq unattended-upgrades update-notifier-common

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
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
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "14";
APT::Periodic::Download-Upgradeable-Packages "14";
APT::Periodic::AutocleanInterval "14";
APT::Periodic::Unattended-Upgrade "14";
EOF

systemctl enable apt-daily-upgrade.timer 2>/dev/null || true
systemctl restart apt-daily-upgrade.timer 2>/dev/null || true

echo "=== Running unattended-upgrade test ==="
unattended-upgrade --dry-run --debug 2>&1 | tail -5

echo ""
echo "=== Setup Complete ==="
echo "Updates: every 14 days"
echo "Reboot:  automatic at 03:00 if needed"
echo "Logs:    /var/log/unattended-upgrades/"
