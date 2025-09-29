{ self, lib, ... }:

{
  flake.nixosModules = {
    copyparty-mount = import ./all/copypary-mount.nix;
    all =
      { ... }:

      {
        imports = builtins.map (module: self.nixosModules.${module}) (
          lib.remove "all" (builtins.attrNames self.nixosModules)
        );
      };
  };
}
