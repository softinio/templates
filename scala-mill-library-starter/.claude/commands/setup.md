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

Apply these **in order** — the earlier, more specific rules must win over the
later, broader ones.

| Placeholder | Replace with |
|---|---|
| `com.example.mylibrary` | `<organization>.<pkg-name>` |
| `com.example` | `<organization>` |
| `mylibrary-cats-effect` | `<library-name>-cats-effect` |
| `object mylibrary ` | `object <module-ident> ` |
| `mylibrary(` | `<module-ident>(` |
| `MYLIBRARY_DOC_VERSION` | `<UPPER_NAME>_DOC_VERSION` |
| `MYLIBRARY_JVM` | `<UPPER_NAME>_JVM` |
| `mylibrary` | `<library-name>` |
| `MyLibrary` | `<PascalName>` |
| `myorg` | `<github-org>` |
| `My Name` | `<developer-name>` |
| `https://example.com` | `<developer-url>` |
| `A Scala 3 library` | `<description>` |

Derive the name variants from the library name, which is lower-case words
separated by `-` (e.g. `cool-lib`):

- `<pkg-name>` — a valid Scala package segment: hyphens **removed** (`coollib`).
  `com.example.cool-lib` would not compile.
- `<PascalName>` — each `-`-separated word capitalized, hyphens removed
  (`CoolLib`). Do **not** just upper-case the first letter — `Cool-lib` is not a
  valid Scala identifier.
- `<UPPER_NAME>` — upper-cased with `-` replaced by `_` (`COOL_LIB`). A `-` is
  not legal in an environment variable name.
- `<module-ident>` — the library name, backtick-quoted if it contains a `-`
  (`` `cool-lib` ``), since Mill object names are Scala identifiers. Used only
  for the `object` definition and the references to that module in
  `build.mill` (`moduleDeps`, `docs.gitVersion`); artifact names, directories
  and docs keep the plain hyphenated form.

## Files to Update

Every text file that still mentions a placeholder. Discover them rather than
working from a fixed list, so nothing is missed as the template evolves:

```bash
grep -rIl -e 'mylibrary' -e 'MyLibrary' -e 'MYLIBRARY' -e 'com\.example' \
  -e 'myorg' -e 'My Name' -e 'example\.com' -e 'A Scala 3 library' . \
  --exclude-dir=.git --exclude-dir=.jj --exclude-dir=out --exclude=setup.sh
```

At the time of writing that covers `build.mill`, `README.md`, `flake.nix`,
`.github/workflows/ci.yml`, `docs/index.md`, `scripts/LaikaBuild.scala`,
`scripts/LaikaPreview.scala`, and the four module sources.

## Directory and File Renames

After updating file contents, rename the directories:
- `mylibrary/` → `<library-name>/`
- `mylibrary-cats-effect/` → `<library-name>-cats-effect/`

and the sources, so the file names match the renamed types:
- `<library-name>/src/MyLibrary.scala` → `<PascalName>.scala`
- `<library-name>/test/src/MyLibraryTest.scala` → `<PascalName>Test.scala`
- `<library-name>-cats-effect/src/MyLibraryIO.scala` → `<PascalName>IO.scala`
- `<library-name>-cats-effect/test/src/MyLibraryIOTest.scala` → `<PascalName>IOTest.scala`

## Cleanup

After all replacements are done:
- Delete `setup.sh`
- Delete `.claude/commands/setup.md` (this file)

Then inform the user of what was changed and remind them to:
1. Add their library's actual `mvnDeps` in `build.mill`
2. Set up GitHub secrets for Maven Central publishing
