# scala-mill-library-starter

A Nix flake template for bootstrapping Scala library projects using the [Mill](https://mill-build.org) build tool. Includes:

- Cross-Scala 3 build (3.3.6 LTS + 3.8.2 latest)
- Dual-module structure: core library + cats-effect integration
- Git-tag-based automatic versioning via [mill-git](https://github.com/jodersky/mill-git)
- Maven Central publishing via Sonatype
- Scalafmt formatting
- GitHub Actions CI and release workflows
- Nix devshell with all required tools

## Quick Start

```bash
mkdir mylibrary && cd mylibrary
nix flake init --template github:softinio/templates#scala-mill-library-starter
```

## Setup

After initializing the template, customize the placeholder names using one of these methods:

### Option A: Shell script

```bash
bash setup.sh
```

### Option B: Claude Code

Open the project in Claude Code and run:

```
/project:setup
```

Both methods will prompt you for your library name, Maven organization, GitHub handle, developer info, and description, then rename all placeholders accordingly.

## Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
- Java 17 or later (provided by the devshell)

## Development

Enter the Nix devshell:

```bash
nix develop
```

### Common Commands

| Command | Description |
|---|---|
| `mill __.compile` | Compile all modules |
| `mill __.test` | Run all tests |
| `mill "mylibrary[3.8.2].test"` | Test core module with Scala 3.8.2 |
| `mill "mylibrary-cats-effect[3.3.6].test"` | Test cats-effect module with Scala 3.3.6 |
| `fmt` | Format all sources with Scalafmt |
| `fmtCheck` | Check formatting without modifying |
| `mill "mylibrary[3.8.2].docJar"` | Generate Scaladoc |
| `mill __.publishLocal` | Publish to local Ivy repository |

## Project Structure

```
.
├── build.mill                        # Mill build definition
├── devshell.toml                     # Nix devshell configuration
├── flake.nix                         # Nix flake
├── .mill-version                     # Mill version pin
├── .scalafmt.conf                    # Scalafmt configuration
├── mylibrary/                        # Core library module
│   ├── src/
│   │   └── MyLibrary.scala
│   └── test/src/
│       └── MyLibraryTest.scala
├── mylibrary-cats-effect/            # cats-effect integration module
│   ├── src/
│   │   └── MyLibraryIO.scala
│   └── test/src/
│       └── MyLibraryIOTest.scala
└── .github/workflows/
    ├── ci.yml                        # CI: test + format check
    └── release.yml                   # Release: publish to Maven Central
```

The template uses two Mill cross modules:

- **`mylibrary`** — core library, cross-built for Scala 3.3.6 and 3.8.2
- **`mylibrary-cats-effect`** — cats-effect + FS2 integration, depends on the core module

Both modules extend `GitVersionedPublishModule`, so the version is automatically derived from git tags (e.g. tagging `v0.1.0` publishes version `0.1.0`).

## Publishing to Maven Central

Publishing uses [Sonatype Central](https://central.sonatype.com). You need a Sonatype account and a GPG key.

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `MILL_PGP_PASSPHRASE` | GPG key passphrase |
| `MILL_PGP_SECRET_BASE64` | Base64-encoded GPG private key |
| `MILL_SONATYPE_PASSWORD` | Sonatype Central password |
| `MILL_SONATYPE_USERNAME` | Sonatype Central username |

### Publishing a Release

Push a git tag prefixed with `v`:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow will publish to Maven Central and create a GitHub release with auto-generated notes.

## Customization

After setup, customize `build.mill` to:

- Add your library's actual dependencies in `mvnDeps`
- Remove the cats-effect module if you don't need it
- Add or remove Scala versions in `scalaVersions`
- Update `pomSettings` with your project details
