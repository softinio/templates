{
  description = "Python AI/ML project with uv and development tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        python = pkgs.python313;

        # Development shell packages
        devPackages = with pkgs; [
          python
          uv
          ruff
          pyright

          # Additional useful tools
          git
          pre-commit
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = devPackages;

          shellHook = ''
            echo "Python AI/ML Development Environment"
            echo "Python: $(python --version)"
            echo "uv: $(uv --version)"
            echo ""
            echo "Quick start:"
            echo "  uv sync              # Install dependencies"
            echo "  uv run pytest        # Run tests"
            echo "  uv run ruff check    # Lint code"
            echo "  pre-commit install   # Set up git hooks"

            # Set up Python environment
            export PYTHONPATH="$PWD/src:$PYTHONPATH"
          '';
        };
      }
    );
}
