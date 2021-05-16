{ sources ? import ./nix/sources.nix
}:

let
  pkgs = import sources.nixpkgs {};
  niv = (import sources.niv {}).niv;

  opam2nix = import (builtins.fetchTarball "https://github.com/timbertson/opam2nix/archive/version-1.2.0.tar.gz") {};
  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_08;

  soupaultSrc = sources.soupault;

  soupaultSrcResolved = pkgs.runCommand "soupault-src-resolved" {GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";} ''
    echo "resolving soupault dependencies..."
    ${pkgs.rsync}/bin/rsync -r ${soupaultSrc}/ .
    echo '###'
    pwd
    ls -al .
    echo '###'
    export HOME=$(pwd)/.home
    ${opam2nix}/bin/opam2nix resolve --ocaml-version 4.08.1 soupault.opam
    mkdir $out
    cp -R . $out
  '';

  soupault = let
    opamSubset = opam2nix.build {
      ocaml = ocamlPackages.ocaml;
      selection = "${soupaultSrcResolved}/opam-selection.nix";
      src = soupaultSrcResolved;
    };
  in 
    opamSubset.soupault;

  # soupault = pkgs.ocamlPackages.buildDune2Package {
  #   pname = "soupault";
  #   version = soupaultSrc.rev;
  #   buildInputs = [
  #     pkgs.coreutils
  #   ] ++ (with pkgs.ocamlPackages; [
  #     ocaml
  #     dune
  #     lambdasoup
  #   ]);
  # };

in
  pkgs.stdenv.mkDerivation {
    name = "ryanartecona.github.io";

    buildInputs = [
      niv
      # soupault
    ];

    passthru = {
      inherit
        opam2nix
        soupaultSrc
        soupault;
    };
  }
