{
  description = "My resume env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    mk-script.url = "github:givikuna/nix-mkScript";
  };

  outputs =
    {
      self,
      nixpkgs,
      mk-script,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkScript = mk-script.lib.mkScript pkgs { };

      tex-pkg = pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-small
          latexmk
          preprint
          titlesec
          marvosym
          enumitem
          fancyhdr
          babel-english
          ;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          tex-pkg

          (with pkgs; elvish)

          (mkScript "build-resume" "scripts/build.elv")
        ];
      };
    };
}
