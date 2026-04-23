# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-23

### Added
- Initial release
- Automated installation of Ollama and OpenClaw on Oracle Linux 9
- Pre-downloads llama3:latest model
- Installs optional messaging provider plugins (Feishu, Slack, WhatsApp, Nostr)
- Includes zstd dependency fix for Ollama installation
- Systemd service configuration for both Ollama and OpenClaw
- Automatic API key generation
- SSH tunnel documentation
- Comprehensive logging to /var/log/openclaw-init.log

### Fixed
- Added `zstd` package to dependencies (required by Ollama install script)
- Corrected OpenClaw default port from 3000 to 18789
