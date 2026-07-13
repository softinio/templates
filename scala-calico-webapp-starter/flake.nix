{
  description = "MyWebApp — Typelevel + Calico full-stack web application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, devshell, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ devshell.overlays.default ];
          };
        in
        {
          # commands and most packages live in devshell.toml; JAVA_HOME
          # needs a nix store path so it is set here
          devShells.default = pkgs.devshell.mkShell {
            imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
            packages = [ pkgs.jdk21 ];
            env = [
              {
                name = "JAVA_HOME";
                value = "${pkgs.jdk21}";
              }
            ];
          };

          packages.default =
            let
              millDeps = pkgs.fetchMillDeps {
                name = "mywebapp-mill-deps";
                src = ./.;
                # Update after dependency changes:
                #   nix build 2>&1 | grep 'got:' (paste the new hash here)
                millDepsHash = pkgs.lib.fakeSha256;
              };
            in
            pkgs.stdenv.mkDerivation {
              pname = "mywebapp";
              version = "0.1.0";
              src = ./.;

              nativeBuildInputs = with pkgs; [
                mill
                millDeps.setupHook
                jdk21
                tailwindcss_4
                makeWrapper
              ];

              TAILWINDCSS = "${pkgs.tailwindcss_4}/bin/tailwindcss";

              buildPhase = ''
                runHook preBuild
                mill -i --no-server backend.assembly
                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall
                mkdir -p $out/share/java $out/bin
                cp out/backend/assembly.dest/out.jar \
                  $out/share/java/mywebapp.jar
                makeWrapper ${pkgs.jdk21}/bin/java $out/bin/mywebapp \
                  --add-flags "-jar $out/share/java/mywebapp.jar"
                runHook postInstall
              '';
            };
        }
      ) // {
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.mywebapp;
        in
        {
          options.services.mywebapp = {
            enable = lib.mkEnableOption "MyWebApp website";

            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.default;
              description = "mywebapp package to run.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 8080;
              description = "Local port the server listens on.";
            };

            baseUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://example.com";
              description = "Canonical base URL used in links and metadata.";
            };

            environmentFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "EnvironmentFile with secrets.";
            };

            nginx = {
              enable = lib.mkEnableOption "nginx vhost with ACME";
              domain = lib.mkOption {
                type = lib.types.str;
                default = "example.com";
                description = "Domain for the nginx virtual host.";
              };
            };
          };

          config = lib.mkIf cfg.enable {
            services.postgresql = {
              enable = true;
              ensureDatabases = [ "mywebapp" ];
              ensureUsers = [
                {
                  name = "mywebapp";
                  ensureDBOwnership = true;
                }
              ];
            };

            systemd.services.mywebapp = {
              description = "MyWebApp website";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" "postgresql.service" ];
              requires = [ "postgresql.service" ];

              environment = {
                MYWEBAPP_HTTP_HOST = "127.0.0.1";
                MYWEBAPP_HTTP_PORT = toString cfg.port;
                MYWEBAPP_BASE_URL = cfg.baseUrl;
                MYWEBAPP_DB_USER = "mywebapp";
                MYWEBAPP_DB_NAME = "mywebapp";
                MYWEBAPP_DB_SOCKET_DIR = "/run/postgresql";
              };

              serviceConfig = {
                ExecStart = "${cfg.package}/bin/mywebapp";
                DynamicUser = true;
                User = "mywebapp";
                Restart = "on-failure";
                RestartSec = 5;
                EnvironmentFile =
                  lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;

                # hardening
                NoNewPrivileges = true;
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                CapabilityBoundingSet = "";
              };
            };

            services.nginx = lib.mkIf cfg.nginx.enable {
              enable = true;
              recommendedProxySettings = true;
              recommendedTlsSettings = true;
              virtualHosts.${cfg.nginx.domain} = {
                enableACME = true;
                forceSSL = true;
                locations."/" = {
                  proxyPass = "http://127.0.0.1:${toString cfg.port}";
                };
              };
            };
          };
        };
    };
}
