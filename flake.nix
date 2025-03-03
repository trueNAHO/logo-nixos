{
  description = "NAHO's NixOS logo";

  inputs = {
    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };

    git-hooks = {
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "nixpkgs";
      };

      url = "github:cachix/git-hooks.nix";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in {
        checks = {
          default = inputs.self.packages.${system}.default;

          git-hooks = inputs.git-hooks.lib.${system}.run {
            hooks = {
              alejandra = {
                enable = true;
                settings.verbosity = "quiet";
              };

              typos.enable = true;
              yamllint.enable = true;
            };

            src = ./.;
          };
        };

        devShells.default = pkgs.mkShell {
          inherit (inputs.self.checks.${system}.git-hooks) shellHook;
        };

        packages.default = let
          file = "main.svg";
        in
          pkgs.stdenv.mkDerivation {
            buildPhase = ''svgo --multipass "${file}"'';
            installPhase = ''mkdir --parents "$out"; mv "${file}" "$out"'';
            name = "logo";
            nativeBuildInputs = [pkgs.nodePackages.svgo];
            src = ./src;
          };
      }
    );
}
