{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pdftc = pkgs.callPackage ./default.nix { };
          benchApp = pkgs.writeShellApplication {
            name = "pdftc-bench";
            runtimeInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.hyperfine
              pdftc
            ];
            text = ''
              if [ ! -f "$PWD/bench/bench.sh" ]; then
                echo "bench/bench.sh not found; run from repo root" >&2
                exit 1
              fi

              export PDFTC_ROOT="$PWD"
              exec "$PWD/bench/bench.sh"
            '';
          };
        in
        {
          packages = {
            default = pdftc;
            pdftc = pdftc;
          };
          checks.default = pdftc;
          apps = {
            default = flake-utils.lib.mkApp { drv = pdftc; };
            pdftc = flake-utils.lib.mkApp { drv = pdftc; };
            bench = flake-utils.lib.mkApp { drv = benchApp; };
          };
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.coreutils
              pkgs.gnused
              pkgs.hyperfine
              pkgs.pdftk
              (pkgs.python3.withPackages (ps: [ ps.reportlab ]))
              pkgs.ripgrep
            ];
          };
        }) //
    {
      overlays.default = final: prev: {
        pdftc = final.callPackage ./default.nix { };
      };
    }
  ;
}
