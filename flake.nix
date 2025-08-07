{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pdftc = pkgs.callPackage ./default.nix { };
        in
        {
          packages.default = pdftc;
          checks.default = pdftc;
        }) //
    {
      overlays.default = final: prev: {
        pdftc = final.callPackage ./default.nix { };
      };
    }
  ;
}
