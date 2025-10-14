# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains Nix flake templates for bootstrapping new projects. Users can initialize projects using `nix flake init --template github:softinio/templates#<template-name>`.

## Architecture

### Template Registry Structure

The root `flake.nix` serves as the template registry. Each template is registered in the `templates` attribute set with:
- `path`: Directory containing the template
- `description`: One-line description shown in `nix flake show`

### Template Requirements

Each template directory must contain:
1. `flake.nix` - Defines the Nix development environment for projects created from this template
2. `README.md` - Comprehensive user-facing documentation with quick start, usage, and customization instructions
3. Sample code and configuration files appropriate for the template's purpose

### Current Templates

**python-ai-starter**: Python 3.13 template with uv package manager, pre-configured AI SDKs (Anthropic, OpenAI, Hugging Face, MCP), and development tools (ruff, pyright, pytest). Uses pydantic-settings for configuration management and structlog for logging.

## Adding New Templates

When creating a new template:

1. Create directory: `mkdir <template-name>`
2. Create template's `flake.nix`:
   - Use `nixpkgs` and `flake-utils` inputs
   - Define `devShells.default` with necessary tools
   - Add helpful shellHook messages
3. Create comprehensive `README.md`:
   - Include quick start with `nix flake init` command
   - Document all common commands
   - Explain project structure and customization
4. Add sample code and configuration files
5. Register in root `flake.nix`:
   ```nix
   templates = {
     template-name = {
       path = ./template-name;
       description = "One-line description";
     };
   };
   ```

## Testing Templates

Test templates locally before committing:

```bash
# Test template initialization
cd /tmp
nix flake init --template /Users/salar/templates#<template-name>

# Verify the development environment works
nix develop

# Test any template-specific commands
```

## Template Design Principles

- **Minimal but complete**: Include only what's necessary, but ensure projects can start immediately
- **Modern tooling**: Use current best practices and latest stable versions
- **Clear documentation**: README should enable users to be productive without external docs
- **Customization-friendly**: Use placeholder names like `myproject` that are easy to find and replace
- **Environment agnostic**: Templates should work via Nix flakes without assuming system packages

## Common Commands

```bash
# List all available templates
nix flake show

# Test a template locally
nix flake init --template .#<template-name>

# Validate flake syntax
nix flake check
```

## File Naming Conventions

- Template directories: lowercase with hyphens (e.g., `python-ai-starter`)
- Template `flake.nix`: Must be in template root directory
- Template `README.md`: Must be in template root directory
- Sample code: Follow language conventions (e.g., Python uses `src/myproject/`)
