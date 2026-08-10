# SmardNodeInstall 3.0.0

SmartCash 3.0.0 SmardNode installer for Ubuntu Server 24.04 LTS.

## What It Does

SmardNodeInstall is the interactive installer for SmardNode 3.0.
It downloads and runs the official SmardNode installer with the values you provide.

## Quick Start

```bash
wget https://raw.githubusercontent.com/SmartCashCMTY/SmardNodeInstall3.0/v3.0.0/SmardNodeInstall.sh
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
- 4 GB RAM (recommended: 8 GB RAM)
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
wget https://raw.githubusercontent.com/SmartCashCMTY/SmardNodeInstall3.0/v3.0.0/SmardNodeInstall.sh
sudo bash ./SmardNodeInstall.sh
```

## Backup

- `/etc/smartcash3/smartcash.conf`
- `/etc/smartcash3/miner.env`

## Security

### Installer Integrity

The installer verifies the SHA256 checksum of the downloaded `smardnode-install.sh`
before execution to protect against supply-chain attacks and unauthorized modifications.
If the hash does not match, installation is aborted.

The expected hash is hardcoded in `SmardNodeInstall.sh` and must be updated whenever
the upstream `smardnode-install.sh` changes in the
[SmardNode3.0](https://github.com/SmartCashCMTY/SmardNode3.0) repository.

### Private Key Handling

- `SmardNodeInstall.sh` prompts interactively for the private key and wallet
  address. These values are never passed via environment variables to avoid
  exposure through `/proc/<pid>/environ`.
- Secrets are written to a temporary file with restrictive permissions
  (`chmod 600`), sourced by the child installer, and securely deleted on exit
  via a trap handler.
- **Important:** The private key you type at the prompt may persist in your bash
  history. Consider running `history -c` or `history -d` after installation to
  remove it.

### System Updates

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

SmartCashCMTY installer code is released under the MIT License.
See [LICENSE](LICENSE) for details.

The SmartCash Core binaries installed by this script are separate software
components distributed under the MIT License. See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)
for a complete overview of all installed components and their licenses.

SmartCash Core source: https://github.com/SmartCashCMTY/Core-Source-Repo

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied.
Use at your own risk.

## Cryptocurrency Risks

Cryptocurrencies involve substantial risk of loss. You are solely responsible for
securing your wallets and private keys, and for compliance with local laws and tax obligations.
