# SmardNodeInstall 3.0.0

SmartCash 3.0.0 SmardNode installer for Ubuntu Server 24.04 LTS.

## What It Does

SmardNodeInstall is the interactive installer for SmardNode 3.0.
It downloads and runs the official SmardNode installer with the values you provide.

## Quick Start

```bash
wget https://raw.githubusercontent.com/SmartCashCMTY/SmardNodeInstall3.0/main/SmardNodeInstall.sh
sudo bash ./SmardNodeInstall.sh
```

## Process

1. **SMARTNODE_PRIVKEY** - generated on your controller wallet with `smartcash-cli smartnode genkey`
2. **SMARTNODE_WALLET_ADDRESS** - your SmardNode wallet address
3. Optional **EXTERNAL_IP** - leave empty for auto-detection
4. The official SmardNode installer is downloaded and executed

```
┌─────────────────────────────────────────────────────────┐
│               SmardNodeInstall.sh                        │
│                                                         │
│  1. Prompt: SMARTNODE_PRIVKEY                           │
│  2. Prompt: SMARTNODE_WALLET_ADDRESS                    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │            smardnode-install.sh                  │    │
│  │                                                  │    │
│  │  smartcash.conf:                                 │    │
│  │    smartnode=1                                   │    │
│  │    smartnodeprivkey=...                          │    │
│  │    smartnodewallet=S...                          │    │
│  │    sapi=1                                        │    │
│  │                                                  │    │
│  │  miner.env:                                      │    │
│  │    PAYOUT_ADDRESS=S...                           │    │
│  │                                                  │    │
│  │  Services:                                       │    │
│  │    smardnode.service                             │    │
│  │    smardnode-miner.timer                         │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## System Requirements

- Ubuntu Server 24.04 LTS
- Public IPv4 address
- 2 vCPU (recommended: 4 vCPU)
- 2 GB RAM (recommended: 8 GB RAM)
- 30 GB SSD (recommended: 120 GB NVMe)

## Configuration After Installation

| File | Purpose |
|------|---------|
| `/etc/smartcash3/smartcash.conf` | Daemon configuration |
| `/etc/smartcash3/miner.env` | Block producer configuration |

## Services

```bash
systemctl status smardnode --no-pager
systemctl status smardnode-miner.timer --no-pager
```

## Update

```bash
wget https://raw.githubusercontent.com/SmartCashCMTY/SmardNodeInstall3.0/main/SmardNodeInstall.sh
sudo bash ./SmardNodeInstall.sh
```

## Backup

- `/etc/smartcash3/smartcash.conf`
- `/etc/smartcash3/miner.env`

## Security

Automatic security updates can be enabled with:

```bash
sudo bash auto-updates-setup.sh
```

## Credits

Original SmartCash Project: https://github.com/smartcash
This repository is an update 3.0.0 based on the open-source work of the SmartCash project.
All rights to original components, trademarks, logos, source code, and documentation remain
with their respective owners.

## License

SmartCash Core is released under the MIT License.
See https://github.com/SmartCashCMTY/Core-Source-Repo for the full license text.

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied.
Use at your own risk.

## Cryptocurrency Risks

Cryptocurrencies involve substantial risk of loss. You are solely responsible for
securing your wallets and private keys, and for compliance with local laws and tax obligations.
