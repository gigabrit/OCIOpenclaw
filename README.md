# OCI OpenClaw + Ollama Bootstrap

Cloud-init script to automate Ollama and OpenClaw installation on Oracle Cloud Infrastructure (OCI) instances running Oracle Linux 9.

## What It Does

- Installs Node.js 22 (LTS)
- Installs Ollama (AI model runner)
- Installs OpenClaw (AI agent gateway)
- Pre-downloads `llama3:latest` model
- Installs optional messaging provider plugins (Feishu, Slack, WhatsApp, Nostr)
- Creates systemd services for auto-start
- Generates API key for OpenClaw authentication

## Requirements

- OCI Instance with Oracle Linux 9
- CPU-only or GPU instance (script works with both)
- Root access during initialization

## Usage

### OCI Console Method

1. Create a new compute instance
2. In the **Advanced** section, expand **Management**
3. Paste the contents of `oci-openclaw-init.sh` into the **Initialization script** text area
4. Launch the instance

### Manual Method

```bash
# SSH into your instance
ssh opc@<instance-ip>

# Run as root
sudo curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/REPO/main/oci-openclaw-init.sh | bash
```

## Post-Install

### Check Installation

```bash
# View the connection details and API key
cat ~/openclaw-connection-info.txt

# Check service status
sudo systemctl status ollama
sudo systemctl status openclaw

# View logs
sudo cat /var/log/openclaw-init.log
sudo journalctl -u openclaw -f
```

### Access via SSH Tunnel

```bash
ssh -L 18789:localhost:18789 -L 11434:localhost:11434 opc@<instance-ip>
```

Then open:
- **OpenClaw Control UI**: http://localhost:18789
- **Ollama API**: http://localhost:11434

### Pair Your Device

After accessing the Control UI, complete the onboarding process to pair your device.

## Configuration

### Environment Variables

The script sets these in the systemd service:

| Variable | Description |
|----------|-------------|
| `OPENCLAW_API_KEY` | Auto-generated API key for authentication |
| `OLLAMA_HOST` | Points to local Ollama instance |

### Ports

| Service | Port | Description |
|---------|------|-------------|
| OpenClaw | 18789 | Web UI and API |
| Ollama | 11434 | Model serving API |

## Troubleshooting

### Ollama Install Fails

If you see an error about `zstd`, the script will handle it automatically. If running manually:

```bash
sudo dnf install -y zstd
curl -fsSL https://ollama.com/install.sh | sh
```

### Services Won't Start

Check logs:
```bash
sudo journalctl -u ollama -n 50
sudo journalctl -u openclaw -n 50
```

### Firewall Issues

The script attempts to open ports via `firewalld`. If using custom security groups, ensure ports 18789 and 11434 are open in your OCI security rules.

## Security Notes

- OpenClaw is configured with a randomly generated API key
- Default setup listens on localhost only (safe with SSH tunnel)
- Connection info file is chmod 600 (readable only by opc user)
- No remote pairing is configured by default (manual pairing required)

## License

MIT - See LICENSE file for details.

## Contributing

Issues and PRs welcome. Tested on:
- Oracle Linux 9 (x86_64)
- OCI VM.Standard.E4.Flex shape

## Related

- [Ollama](https://ollama.com)
- [OpenClaw](https://github.com/openclaw/openclaw)
