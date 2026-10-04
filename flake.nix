{
  description = "Nixp - Alternative Nix typed frontend";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      for-all-systems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      devShells = for-all-systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # odin
              odin
              ols

              # scripting
              elvish
              nushell

              # build
              just
              just-formatter
              just-lsp
              justbuild
            ];

            shellHook = ''
              echo "hewwo :3"
            '';
          };
        }
      );
    };
}
