# Scala SBT Starter Template

A Scala project template with sbt, scala-cli, and scalafmt pre-configured in a Nix development environment.

## Features

- **Scala 3** (default) or **Scala 2.13** - Switch between versions easily
- **Build Tools**:
  - `sbt` - Standard Scala build tool
  - `scala-cli` - Fast scripting and prototyping
  - `coursier` - Dependency resolution
- **Code Quality**:
  - `scalafmt` - Code formatting
- **IDE Support**:
  - Metals LSP via sbt's built-in BSP server
- **Nix Flakes** - Reproducible development environment

## Quick Start

### Using Nix Flakes

```bash
# Create a new project from this template
nix flake init --template github:softinio/templates#scala-sbt-starter

# Or create in a new directory
nix flake new --template github:softinio/templates#scala-sbt-starter ./my-scala-project
```

### Setup

1. Enter the development environment:
   ```bash
   nix develop
   ```

2. Create a new sbt project:
   ```bash
   # For Scala 3
   newScala3

   # For Typelevel stack (Cats, Cats Effect, etc.)
   newTypelevel

   # For Scala 2.13
   newScala2
   ```

3. Start sbt before opening your editor (enables BSP for Metals):
   ```bash
   sbt
   ```
   Then open your editor. When Metals prompts for a build server, select **sbt**.

## Development

### Switching Scala Versions

```bash
# Use Scala 3 (default)
nix develop
# or explicitly
nix develop .#scala3

# Use Scala 2.13
nix develop .#scala2
```

### Common Commands

```bash
# Compile the project
sbt compile

# Run tests
sbt test

# Run the application
sbt run

# Start Scala REPL with project classes
sbt console

# Format code
scalafmt

# Check formatting without changes
scalafmt --check

# Format only changed files
scalafmt --mode diff
```

### Using scala-cli

For quick scripts and prototyping:

```bash
# Run a Scala file directly
scala-cli run MyScript.scala

# Start a REPL
scala-cli repl

# Package as a standalone JAR
scala-cli package MyApp.scala -o myapp
```

## Customization

1. **Rename the project**: Update `name` in your `build.sbt`
2. **Add dependencies**: Edit `build.sbt` with your library dependencies
3. **Configure scalafmt**: Create `.scalafmt.conf` in your project root

### Example .scalafmt.conf

```hocon
version = 3.8.3
runner.dialect = scala3
maxColumn = 100
```

## Project Structure

After running one of the `new*` commands, your project will look like:

```
.
├── build.sbt               # Build configuration
├── project/
│   └── build.properties    # sbt version
├── src/
│   ├── main/scala/         # Source code
│   └── test/scala/         # Tests
├── devshell.toml           # Devshell commands
├── flake.nix               # Nix flake configuration
└── README.md
```

## License

MIT License - See LICENSE file for details
