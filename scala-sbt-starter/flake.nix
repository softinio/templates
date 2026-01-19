{
  description = "Scala project with sbt, scala-cli, and scalafmt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      devshell,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };

        # Common packages for all Scala versions
        commonPackages = with pkgs; [
          coursier
          git
          jdk21
          metals
          sbt
          scala-cli
          scalafmt
        ];

        # Scala 3 devshell (default)
        scala3Shell = pkgs.devshell.mkShell {
          name = "scala3-dev";
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
          packages = commonPackages ++ [ pkgs.scala_3 ];
          env = [
            {
              name = "SCALA_VERSION";
              value = "3";
            }
            {
              name = "JAVA_HOME";
              value = "${pkgs.jdk21}";
            }
            {
              name = "TOOLCHAINS";
              value = "swift";
            }
          ];
          devshell.startup.welcome.text = ''
            echo "Scala 3 Development Environment"
            echo "Scala: $(scala -version 2>&1 | head -1)"
            echo ""
            echo "Using Scala 3. For Scala 2.13, use: nix develop .#scala2"
          '';
        };

        # Scala 2.13 devshell
        scala2Shell = pkgs.devshell.mkShell {
          name = "scala2-dev";
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
          packages = commonPackages ++ [ pkgs.scala_2_13 ];
          env = [
            {
              name = "SCALA_VERSION";
              value = "2.13";
            }
            {
              name = "JAVA_HOME";
              value = "${pkgs.jdk21}";
            }
            {
              name = "TOOLCHAINS";
              value = "swift";
            }
          ];
          devshell.startup.welcome.text = ''
            echo "Scala 2.13 Development Environment"
            echo "Scala: $(scala -version 2>&1 | head -1)"
            echo ""
            echo "Using Scala 2.13. For Scala 3, use: nix develop .#scala3"
          '';
        };

      in
      {
        devShells = {
          default = scala3Shell;
          scala3 = scala3Shell;
          scala2 = scala2Shell;
        };
      }
    );
}
