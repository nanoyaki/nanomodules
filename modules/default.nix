{ self, lib, ... }:

let
  inherit (lib) mapAttrs' nameValuePair removeSuffix;

  modules = mapAttrs' (
    module: _: nameValuePair (removeSuffix ".nix" module) (import (./all + "/${module}"))
  ) (builtins.readDir ./all);
in

{
  flake.nixosModules = {
    all =
      { ... }:

      {
        imports = builtins.map (module: self.nixosModules.${module}) (
          builtins.attrNames (removeAttrs modules [ "nanoSystem" ])
        );
      };
  }
  // modules;
}
