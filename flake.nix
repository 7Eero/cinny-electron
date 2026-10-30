{
  description = "Cinny Desktop (Electron Version)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      packages = forAllSystems (system: {
        default = self.packages.${system}.cinny-electron;
        cinny-electron = (pkgsFor system).callPackage ./package.nix { };
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.cinny-electron}/bin/cinny-electron";
          meta.description = "Cinny Desktop (Electron Version)";
        };
      });

      devShells = forAllSystems (system: {
        default = (pkgsFor system).mkShell {
          packages = with (pkgsFor system); [
            nodejs
            pnpm_10
            electron
          ];
        };
      });

      overlays.default = final: prev: {
        cinny-electron = final.callPackage ./package.nix { };
      };
    };
}
