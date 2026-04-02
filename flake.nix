{
  description = "garrettleber.com development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.site = pkgs.mkShell {
          packages = [
            pkgs.python312
            pkgs.uv
          ];
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.python312
            pkgs.uv
            pkgs.pre-commit
          ];

          shellHook = ''
            uv sync --project site/ --quiet
            source site/.venv/bin/activate
            echo "Python venv activated (site/.venv)"
          '';
        };
      }
    );
}
