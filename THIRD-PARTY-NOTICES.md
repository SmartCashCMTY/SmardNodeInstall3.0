# Third-Party Notices

This repository provides an interactive installer for SmardNode 3.0.
The installer scripts are MIT-licensed by SmartCashCMTY. The software
installed by these scripts retains its own licensing.

## SmartCashCMTY Installer Code (MIT Licensed)

The following files are original work by SmartCashCMTY:
- SmardNodeInstall.sh (interactive entry-point wrapper)
- smardnode-install.sh (core installer - downloads and configures SmartCash Core)
- auto-updates-setup.sh (Ubuntu unattended-upgrades configuration)
- LICENSE
- README.md

Copyright (c) 2025 SmartCash Community - MIT License

## SmartCash Core Binaries (Downloaded at Install Time)

| Component | Version | Source |
|-----------|---------|--------|
| smartcashd | 3.0.0 | SmartCashCMTY/Node-Client-Wallet releases v3.0.0 |
| smartcash-cli | 3.0.0 | SmartCashCMTY/Node-Client-Wallet releases v3.0.0 |
| smartcash-tx | 3.0.0 | SmartCashCMTY/Node-Client-Wallet releases v3.0.0 |

- **Download URL:** https://github.com/SmartCashCMTY/Node-Client-Wallet/releases/download/v3.0.0/smartcash3-3.0.0-x86_64-linux-gnu.tar.gz
- **SHA256:** d53c8195768490808c88d178cfb387102b8e69ab452e4c7baddf9af5c44993eb
- **License:** MIT
- **Copyright:** Copyright (c) 2009-2017 The Bitcoin Core developers; Copyright (c) 2017-2020 The SmartCash developers
- **Integrity:** SHA256 checksum verified at install time

## System Packages (Ubuntu 24.04 APT Repositories)

The installer installs the following packages from Ubuntu APT repositories:
- curl, ca-certificates, tar, unzip, openssl, ufw, fail2ban, htop, jq, chrony
- unattended-upgrades, apt-listchanges

Each package is distributed under its respective open-source license.

## Installer Chain

The SmardNodeInstall.sh wrapper downloads and executes smardnode-install.sh
from the sibling repository:
https://github.com/SmartCashCMTY/SmardNode3.0

This installer from the sibling repo performs the actual SmartCash Core
download, configuration, and systemd service setup.

## Trademarks

"SmartCash", "Bitcoin", and other names and logos are trademarks of their
respective owners.
