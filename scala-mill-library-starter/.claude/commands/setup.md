# Setup: Customize This Library Template

This command helps you rename the placeholder names in this template to match your actual library.

## Instructions for Claude

Ask the user for the following values one by one (or all at once if they prefer):

1. **Library name** — the artifact name and directory name (e.g. `cool-lib`, `mylib`). This replaces `mylibrary`.
2. **Maven organization** — the Maven group ID (e.g. `com.softinio`). This replaces `com.example`.
3. **GitHub org/user** — GitHub handle or org name (e.g. `softinio`). This replaces `myorg`.
4. **Developer name** — full name for POM metadata (e.g. `Jane Doe`). This replaces `My Name`.
5. **Developer URL** — personal or org website (e.g. `https://softinio.com`). This replaces `https://example.com`.
6. **Library description** — one-line description for POM metadata. This replaces `A Scala 3 library`.

## Replacements to Make

After collecting the values, make the following substitutions across **all** files in this project:

| Placeholder | Replace with |
|---|---|
| `mylibrary-cats-effect` | `<library-name>-cats-effect` |
| `mylibrary` | `<library-name>` |
| `MyLibrary` | `<LibraryName>` (title-cased) |
| `com.example` | `<organization>` |
| `myorg` | `<github-org>` |
| `My Name` | `<developer-name>` |
| `https://example.com` | `<developer-url>` |
| `A Scala 3 library` | `<description>` |
| `MYLIBRARY_DOC_VERSION` | `<LIBRARY_NAME_UPPER>_DOC_VERSION` |

## Files to Update

- `build.mill`
- `README.md`
- `flake.nix`
- `devshell.toml`
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
- `mylibrary/src/MyLibrary.scala`
- `mylibrary/test/src/MyLibraryTest.scala`
- `mylibrary-cats-effect/src/MyLibraryIO.scala`
- `mylibrary-cats-effect/test/src/MyLibraryIOTest.scala`

## Directory Renames

After updating file contents, rename:
- `mylibrary/` → `<library-name>/`
- `mylibrary-cats-effect/` → `<library-name>-cats-effect/`

## Cleanup

After all replacements are done:
- Delete `setup.sh`
- Delete `.claude/commands/setup.md` (this file)

Then inform the user of what was changed and remind them to:
1. Add their library's actual `mvnDeps` in `build.mill`
2. Set up GitHub secrets for Maven Central publishing
