{
  description = "NAHO's NixOS logo";

  inputs = {
    flakeUtils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    preCommitHooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/pre-commit-hooks.nix";
    };
  };

  outputs = inputs:
    inputs.flakeUtils.lib.eachDefaultSystem (
      system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in {
        checks = {
          default = inputs.self.packages.${system}.default;

          preCommitHooks = inputs.preCommitHooks.lib.${system}.run {
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
          inherit (inputs.self.checks.${system}.preCommitHooks) shellHook;
        };

        packages.default = let
          file = "main.svg";
        in
          pkgs.stdenv.mkDerivation {
            buildPhase = ''svgo --multipass "${file}"'';
            installPhase = ''mkdir --parent "$out"; mv "${file}" "$out"'';
            name = "logo";
            nativeBuildInputs = [pkgs.nodePackages.svgo];
            src = ./src;
          };
      }
    );
}
