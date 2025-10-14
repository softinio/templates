# Project Templates

A collection of Nix flake templates for quickly bootstrapping new projects with best practices and modern tooling.

## Available Templates

### python-ai-starter

Python project template for AI/ML development with pre-configured AI SDKs and modern Python tooling.

**Features:**
- Python 3.13+
- Package management with `uv`
- Pre-configured AI/ML SDKs (Anthropic, OpenAI, Hugging Face, MCP)
- Development tools: ruff, pyright, pytest
- Pre-commit hooks for code quality
- Structured logging and settings management
- Reproducible Nix development environment

**Quick start:**
```bash
nix flake init --template github:softinio/templates#python-ai-starter
```

[See full documentation →](./python-ai-starter/README.md)

## Usage

### Initialize in Current Directory

```bash
nix flake init --template github:softinio/templates#<template-name>
```

### Create New Directory with Template

```bash
nix flake new --template github:softinio/templates#<template-name> ./my-project
```

### List Available Templates

```bash
nix flake show github:softinio/templates
```

## Template Structure

Each template includes:
- `flake.nix` - Nix flake configuration for reproducible development environment
- `README.md` - Comprehensive documentation and usage guide
- Project-specific configuration files
- Sample code and tests to get started quickly

## Contributing

Contributions are welcome! To add a new template:

1. Create a new directory with your template name
2. Add a `flake.nix` with the development environment
3. Add a comprehensive `README.md` with usage instructions
4. Include sample code and configuration files
5. Register the template in the root `flake.nix`

## Requirements

- [Nix](https://nixos.org/download.html) with flakes enabled

To enable flakes, add to your `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

## License

MIT License - See individual template directories for specific licensing information.

## Author

Created and maintained by [Salar Rahmanian](https://github.com/softinio)

## Related Projects

- [python-starter-template](https://github.com/softinio/python-starter-template) - The original Python AI/ML template repository
- [NixOS/templates](https://github.com/NixOS/templates) - Official Nix templates
- [nix-community/templates](https://github.com/nix-community/templates) - Community Nix templates
