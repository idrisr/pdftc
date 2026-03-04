{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem
      [ "x86_64-linux" "aarch64-darwin" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pdftc = pkgs.callPackage ./default.nix { };
        in
        {
          packages = {
            default = pdftc;
            pdftc = pdftc;
          };
          checks.default = pdftc;
          apps = rec {
            default = pdftc;
            pdftc = flake-utils.lib.mkApp {
              drv = pdftc;
            };
          };
        }) //
    {
      overlays.default = final: prev: {
        pdftc = final.callPackage ./default.nix { };
      };
    }
  ;
}
