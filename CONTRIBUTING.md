# Contributing to OCI OpenClaw Bootstrap

Thanks for your interest in contributing!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development

### Testing the Script

Test on a fresh OCI instance:

```bash
# Create a new Oracle Linux 9 instance
# Paste script into Initialization script field
# Verify installation completes successfully
```

### Code Style

- Use `set -e` for error handling
- Log all actions with timestamps
- Comment complex sections
- Keep the script idempotent where possible

### Reporting Issues

When reporting issues, please include:

- OCI instance shape (e.g., VM.Standard.E4.Flex)
- Oracle Linux version
- Relevant log output from `/var/log/openclaw-init.log`
- Output of `sudo systemctl status ollama openclaw`

## Questions?

Open an issue or reach out in the discussions.
