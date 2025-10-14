# Python AI/ML Starter Template

A modern Python project template for AI and machine learning development with pre-configured tools and AI SDK integrations.

## Features

- **Python 3.13+** - Latest Python version
- **Package Management** - `uv` for fast, reliable dependency management
- **Development Tools**:
  - `ruff` - Fast linting and formatting
  - `pyright` - Static type checking
  - `pytest` - Testing framework
  - `pre-commit` - Git hooks for code quality
- **AI/ML SDKs** - Pre-configured for:
  - Anthropic (Claude)
  - OpenAI
  - Hugging Face
  - Model Context Protocol (MCP)
- **Nix Flakes** - Reproducible development environment

## Quick Start

### Using Nix Flakes

```bash
# Create a new project from this template
nix flake init --template github:softinio/templates#python-ai-starter

# Or create in a new directory
nix flake new --template github:softinio/templates#python-ai-starter ./my-ai-project
```

### Setup

1. Enter the development environment:
   ```bash
   nix develop
   ```

2. Install dependencies:
   ```bash
   uv sync
   ```

3. Set up pre-commit hooks:
   ```bash
   pre-commit install
   ```

4. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

## Development

### Project Structure

```
.
├── src/myproject/        # Source code
│   ├── __init__.py
│   └── main.py
├── tests/myproject/      # Tests
│   ├── __init__.py
│   └── test_main.py
├── .env.example          # Environment variable template
├── .gitignore
├── .pre-commit-config.yaml
├── .python-version
├── devshell.toml
├── flake.nix
├── pyproject.toml
└── README.md
```

### Common Commands

```bash
# Run tests
uv run pytest

# Lint code
uv run ruff check src

# Format code
uv run ruff format src

# Type check
uv run pyright

# Run your application
uv run python src/myproject/main.py
```

### Environment Variables

Create a `.env` file with your configuration:

```bash
# API Keys
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
HUGGINGFACE_TOKEN=your_token_here

# Application Settings
LOG_LEVEL=INFO
```

## Customization

1. **Rename the project**: Replace `myproject` throughout the codebase with your project name
2. **Add dependencies**: Edit `pyproject.toml` and run `uv sync`
3. **Configure tools**: Adjust settings in `pyproject.toml` for ruff, pytest, etc.

## Dependencies

Core dependencies included:
- `anthropic` - Anthropic API client
- `openai` - OpenAI API client
- `huggingface-hub` - Hugging Face Hub client
- `mcp[cli]` - Model Context Protocol
- `httpx` - HTTP client
- `pydantic` - Data validation
- `pydantic-settings` - Settings management
- `structlog` - Structured logging
- `tenacity` - Retry logic

Development dependencies:
- `pytest` - Testing
- `ruff` - Linting and formatting
- `pyright` - Type checking
- `pre-commit` - Git hooks

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please ensure:
- Tests pass: `uv run pytest`
- Code is formatted: `uv run ruff format src`
- Linting passes: `uv run ruff check src`
- Type checking passes: `uv run pyright`
