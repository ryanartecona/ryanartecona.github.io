{ sources ? import ./nix/sources.nix
}:

let
  pkgs = import sources.nixpkgs {};
  niv = (import sources.niv {}).niv;

  ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_08;

  soupault = pkgs.stdenv.mkDerivation rec {
    name = "soupault";
    version = "2.7.0";
    src = (pkgs.fetchurl {
      url = "https://github.com/dmbaturin/soupault/releases/download/${version}/soupault-${version}-macos-x86_64.tar.gz"; 
      sha256 = "179vhgjgsp8gfn9rxdh28ncvrd2d6l83d4r3p6sj46lkzvm6kair";
    });
    installPhase = ''
      mkdir -p $out/bin
      cp soupault $out/bin/
    '';
  };

in
  pkgs.stdenv.mkDerivation {
    name = "ryanartecona-github-io";

    buildInputs = [
      niv
      soupault
      pkgs.asciidoctor
      pkgs.cmark
      pkgs.entr
      # need pandoc for literate haskell post
      pkgs.pandoc
      # should replace with dart-sass once it's in nixpkgs
      pkgs.sassc
    ];

    passthru = {
      inherit
        ocamlPackages
        soupault;
    };
  }
