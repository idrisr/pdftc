{ writeShellApplication, python3 }:
let
  python = python3.withPackages (ps: [ ps.pikepdf ]);
in
writeShellApplication {
  runtimeInputs = [ python ];
  name = "pdftc";

  text = ''
    exec ${python}/bin/python ${./pdftc.py} "$@"
  '';
}
