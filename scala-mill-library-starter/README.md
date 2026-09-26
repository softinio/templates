# scala-mill-library-starter

A Nix flake template for bootstrapping Scala library projects using the [Mill](https://mill-build.org) build tool. Includes:

- Cross-Scala 3 build (3.3.8 LTS + 3.9.0 latest)
- Dual-module structure: core library (cats) + cats-effect/FS2 integration
- Git-tag-based automatic versioning via [mill-git](https://github.com/jodersky/mill-git)
- Maven Central publishing via Sonatype
- Laika documentation site (Helium theme) with build/preview commands,
  published to GitHub Pages from each release tag, optionally on a custom domain
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
- JDK 21 (provided by the devshell); published artifacts target Java 21 bytecode,
  which is the highest `-release` either Scala 3 compiler accepts. The nixpkgs
  `mill` wrapper pins JAVA_HOME to its own JDK 21 regardless of what the devshell
  lists, so 21 is what the build actually runs on. CI additionally runs the test
  suites on Java 25 via the `MYLIBRARY_JVM` environment variable, since
  `--release 21` guarantees the API surface exists but not that the code behaves
  the same on a later JVM

## Development

Enter the Nix devshell:

```bash
nix develop
```

### Commit `flake.lock`

The first `nix develop` writes a `flake.lock` pinning nixpkgs. **Commit it.**
This template deliberately ships without one so that new projects start on a
current nixpkgs, but until the lock is committed `flake.nix` only tracks
`nixos-unstable` by ref, so CI resolves it afresh on every run. The JDK, Mill,
Node and scala-cli versions can then shift between two runs of identical code,
turning a green build red with no commit in between.

```bash
git add flake.lock && git commit -m "Pin nixpkgs"
```

Update deliberately later with `nix flake update`, which moves the whole
toolchain at once.

### Common Commands

| Command | Description |
|---|---|
| `mill __.compile` | Compile all modules |
| `mill __.test` | Run all tests |
| `mill "__[3.9.0].test"` | Test every module with Scala 3.9.0 |
| `mill "mylibrary[3.3.8].test"` | Test one module with one Scala version |
| `mill "mylibrary-cats-effect[3.3.8].test"` | Test cats-effect module with Scala 3.3.8 |
| `fmt` | Format all sources with Scalafmt |
| `fmtCheck` | Check formatting without modifying |
| `mill "__[3.9.0].docJar"` | Generate Scaladoc for every module |
| `mill docs.build` (or `buildDocs`) | Build the Laika documentation site |
| `mill docs.preview` (or `previewDocs`) | Serve the docs at http://localhost:4242 |
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
├── docs/                             # Laika documentation sources (Markdown)
│   └── index.md
├── scripts/                          # scala-cli scripts running Laika
│   ├── LaikaBuild.scala
│   └── LaikaPreview.scala
└── .github/workflows/
    ├── ci.yml                        # CI: test + format check + docs site build
    ├── release.yml                   # Release: publish to Maven Central
    └── docs.yml                      # Docs: publish the site after each release
```

The template uses two Mill cross modules:

- **`mylibrary`** — core library (depends on cats-core), cross-built for Scala 3.3.8 and 3.9.0
- **`mylibrary-cats-effect`** — cats-effect + FS2 integration, depends on the core module

Both modules extend `GitVersionedPublishModule`, so the version is automatically derived from git tags (e.g. tagging `v0.1.0` publishes version `0.1.0`).

### Why releases publish from the LTS only

All Scala 3.x releases are binary compatible, so `artifactScalaVersion` collapses
them to a single `_3` coordinate. That means publishing every cross-version races
them to the same address, and which one lands varies between releases. TASTy is
only backward compatible on top of that: artifacts built by 3.9.0 cannot be read
by a 3.3 compiler, while 3.3.8-built ones are readable by both. So the release
workflow pins publishing to `__[3.3.8]`, and the newer cross-version in CI serves
as compile verification rather than a publish target. This matches what cats, fs2,
http4s and circe all do.

## Documentation Site

The `docs/` directory holds the Markdown sources for a documentation site
rendered by [Laika](https://typelevel.org/Laika/) with the Helium theme.

| Command | Description |
|---|---|
| `mill docs.build` | Build the site into `site/target/docs/site` |
| `mill docs.preview` | Build and serve the site at http://localhost:4242 |

Inside the devshell the `buildDocs` and `previewDocs` aliases wrap these
commands. Both shell out to `scala-cli` (provided by the devshell) to run the
scripts in `scripts/`; customize the Helium theme (title, nav links, footer)
there. The preview serves what `docs.build` produced rather than rendering its
own copy, so what you preview is what gets published.

Write versions in the Markdown as `@VERSION@`. The build replaces it with the
version being documented -- the release tag when publishing, the git-derived
version locally. (Laika's own `${...}` variables do not work for this: inside a
fenced Scala block the syntax highlighter treats them as string interpolation,
and they render verbatim.)

### Publishing the site

CI builds the site on every push, to prove it still renders, but does not
publish it. `docs.yml` publishes it to the `gh-pages` branch after each
successful release, built from the release tag, so the live docs never
describe unreleased changes. It can also be run by hand from the Actions tab
for a given tag.

After the first release has created `gh-pages`, turn on Pages once:
**Settings → Pages → Deploy from a branch → `gh-pages` / `(root)`**. Or:

```bash
gh api -X POST repos/myorg/mylibrary/pages -f 'source[branch]=gh-pages' -f 'source[path]=/'
```

The site is then served at `https://myorg.github.io/mylibrary/`.

**Custom domain.** Set a `DOCS_DOMAIN` repository variable (**Settings → Secrets
and variables → Actions → Variables**) to e.g. `docs.example.dev`, and add a DNS
`CNAME` record pointing it at `myorg.github.io`. Every deploy then writes the
`CNAME` file; without that, each push would delete the file and GitHub would
drop the domain. Then:

- If the domain is on Cloudflare, set the record to **DNS only** (grey cloud).
  Behind the proxy GitHub cannot issue its certificate, and `.dev` and other
  HSTS-preloaded domains will not load at all without one.
- Verify the domain under your account's Pages settings, so nobody else can
  claim the subdomain.
- Once GitHub has issued the certificate, tick **Enforce HTTPS**.

## Publishing to Maven Central

Publishing uses [Sonatype Central](https://central.sonatype.com). You need a Sonatype account and a GPG key.

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `MILL_PGP_PASSPHRASE` | GPG key passphrase |
| `MILL_PGP_SECRET_BASE64` | Base64-encoded, ASCII-armored GPG private key |
| `MILL_SONATYPE_USERNAME` | Sonatype Central **user token** username |
| `MILL_SONATYPE_PASSWORD` | Sonatype Central **user token** password |

The Sonatype values are a generated user token (**central.sonatype.com → View
Account → Generate User Token**), not your login. The token username is a random
string, and the username and password must come from the same token. Anything
else fails at upload with `401 {"error":{"message":"Invalid token"}}`. A 401
publishes nothing, so re-running the same tag after fixing the secrets is safe.
Generating a new token revokes the previous one, so update every repo that
publishes with it.

A tell in the release log: GitHub masks secret values, so if your group id
prints as `com.***`, the username secret is literally your login name.

To set the key secret without the key touching the screen:

```bash
export GPG_TTY=$(tty)
key=$(gpg --pinentry-mode loopback --export-secret-keys --armor <KEY_ID> | base64)
[ -n "$key" ] && printf '%s' "$key" | gh secret set MILL_PGP_SECRET_BASE64 -R myorg/mylibrary \
  || echo "export failed, secret NOT set"
unset key
```

The guard matters: if gpg cannot prompt for the passphrase (no `pinentry`
installed, or `GPG_TTY` unset), it exports nothing, and an unguarded pipe
stores an empty secret while `gh` reports success. `--pinentry-mode loopback`
makes gpg prompt in the terminal itself.

### Publishing a Release

Push a git tag prefixed with `v`:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow will publish to Maven Central and create a GitHub release with auto-generated notes. When it succeeds, `docs.yml` publishes the documentation site for that tag.

## Customization

After setup, customize `build.mill` to:

- Add your library's actual dependencies in `mvnDeps`
- Remove the cats-effect module if you don't need it
- Add or remove Scala versions in `scalaVersions`
- Update `pomSettings` with your project details
