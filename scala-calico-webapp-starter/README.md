# scala-calico-webapp-starter

A Nix flake template for full-stack Scala 3 web applications on the
[Typelevel](https://typelevel.org) stack, modeled on
[bayareatechtalks](https://github.com/softinio/bayareatechtalks). Includes:

- **Hybrid rendering**: [http4s](https://http4s.org) (ember) server-renders
  every page with scalatags (SEO-friendly), while
  [Calico](https://www.armanbilge.com/calico/) (Scala.js) *islands* add
  interactivity — the server emits `<div data-island="...">` placeholders
  and the frontend mounts components into them
- **Shared code**: a cross-compiled `shared` module (one source tree for
  JVM and JS) holding DTOs, circe codecs, and form validation used by both
  the browser and the server
- **PostgreSQL** via [skunk](https://typelevel.org/skunk/) with
  [dumbo](https://github.com/rolang/dumbo) (Flyway-style) migrations that
  run at startup
- **Tailwind CSS v4** compiled into the server's resources by the build
- **[Mill](https://mill-build.org) 1.1.7** build with scalafmt, scalafix,
  and a self-contained assembly jar (JS bundle, CSS, fonts, migrations all
  inside)
- **Nix devshell** ([numtide devshell](https://github.com/numtide/devshell))
  with a command menu including PostgreSQL lifecycle helpers and a one-shot
  `runDev`
- **NixOS module** for production deployment (hardened systemd service,
  PostgreSQL over unix sockets, optional nginx + ACME)
- GitHub Actions CI (compile, format check, scalafix check, tests, assembly)

The starter app is a tiny "notes" page demonstrating the full loop:
server-rendered list + a Calico island form that validates client-side with
the shared rules, POSTs JSON, and stores rows via skunk.

## Quick Start

```bash
mkdir mywebapp && cd mywebapp
nix flake init --template github:softinio/templates#scala-calico-webapp-starter
./setup.sh    # interactive rename of all placeholders
nix develop
runDev        # starts PostgreSQL, creates the db, boots the server
```

Then open <http://localhost:8080>.

## Devshell commands

Type `menu` inside `nix develop`:

| Command | What it does |
| --- | --- |
| `runDev` | Start PostgreSQL (in `/tmp`), provision the database, run the server |
| `runTests` | All tests, JVM + JS |
| `runLint` | scalafmt + scalafix rewrites |
| `checkCI` | Exactly what CI runs (fatal warnings on) |
| `buildJar` | Self-contained fat jar |
| `watchFrontend` | Relink the Scala.js bundle on change (pair with `MYWEBAPP_DEV_ASSETS=out/frontend/fastLinkJS.dest`) |
| `startPostgres` / `stopPostgres` / `postgresStatus` / `resetDB` | Database lifecycle |

Without Nix: install a JDK (21+), PostgreSQL, and Node, run `npm install`
(provides the Tailwind CLI), and use `./mill` directly — the committed
launcher downloads Mill itself.

## Configuration

All runtime configuration is environment variables prefixed `MYWEBAPP_`
(renamed by `setup.sh`): `_HTTP_HOST`, `_HTTP_PORT`, `_BASE_URL`,
`_DB_HOST`, `_DB_PORT`, `_DB_USER`, `_DB_PASSWORD`, `_DB_NAME`,
`_DB_SOCKET_DIR` (unix socket, used by the NixOS module), `_DEV_ASSETS`.
See `backend/src/.../Config.scala`.

## Adding to the app

- **New page**: add a method to `html/Pages.scala` and a route in
  `routes/Routes.scala`.
- **New island**: add a component in `frontend/src/.../ui/`, a case in the
  `Main.mount` match, and emit `data-island` / `data-props` from a page.
  Props round-trip through a shared circe codec.
- **New migration**: add `backend/resources/db/migration/V2__*.sql` AND
  register the path in `db/Database.scala`.
- **Fatal warnings** are CI-only; reproduce locally with `CI=true ./mill ...`.

## Production (NixOS)

The flake exposes `packages.default` (assembly jar wrapped as a binary;
fill in `millDepsHash` on first `nix build`) and `nixosModules.default`:

```nix
{
  imports = [ mywebapp.nixosModules.default ];
  services.mywebapp = {
    enable = true;
    nginx.enable = true;
    environmentFile = "/run/secrets/mywebapp";
  };
}
```
