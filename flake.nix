{
  description = "Terraform Infrastructure development environment";
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
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.tenv
            pkgs.pre-commit
            pkgs.terraform-docs
            pkgs.trivy
            pkgs.gitleaks
            pkgs.hugo
          ];

          # Define the versions we want to use
          shellHook = ''
            TERRAFORM_VERSION="1.11.4"

            echo "Checking for required tool versions..."

            # Check if Terraform is installed at the correct version
            if ! tenv tf list | grep -q "$TERRAFORM_VERSION"; then
              echo "OpenTofu $TERRAFORM_VERSION is not installed."
              echo "Run: tenv tf install $TERRAFORM_VERSION"
              INSTALL_NEEDED=1
            fi

            # If installations are needed, exit with instructions
            if [ -n "$INSTALL_NEEDED" ]; then
              echo ""
              echo "After installing the required versions, activate them with:"
              echo "tenv tf use $TERRAFORM_VERSION"
              echo ""
              echo "Or run this shell again to verify."
            else
              # Set the versions to use
              tenv tf use $TERRAFORM_VERSION
              echo "Environment ready with Terraform $TERRAFORM_VERSION"
            fi
          '';
        };
      }
    );
}
