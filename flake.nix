{
  description = "My resume env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    mk-script.url = "github:givikuna/nix-mkScript";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      mk-script,
    }:
    let
      each-sys = (with nixpkgs; with lib; genAttrs) (import systems);

      tex-pkg =
        pkgs:
        (with pkgs; with texlive; combine) {
          inherit (with pkgs; texlive)
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

      resumeworks-pkg =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          runtime-path = pkgs.lib.makeBinPath (
            (with pkgs; [
              coreutils
              elvish
            ])
            ++ [ (tex-pkg pkgs) ]
          );
        in
        pkgs.writeShellScriptBin "resumeworks" ''
          export PATH="${runtime-path}:$PATH"
          export RESUMEWORKS_ROOT="${self}"
          exec ${with pkgs; elvish}/bin/elvish ${./scripts/resumeworks.elv} "$@"
        '';
    in
    {
      packages = each-sys (system: {
        default = resumeworks-pkg system;
        resumeworks = resumeworks-pkg system;
      });

      devShells = each-sys (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              (with pkgs; elvish)

              (tex-pkg pkgs)

              (mk-script.lib.mkScript pkgs { } "build-resume" "scripts/build.elv")
              (mk-script.lib.mkScript pkgs { } "deploy-resume" "scripts/deploy.elv")
            ];
          };
        }
      );
    };
}
