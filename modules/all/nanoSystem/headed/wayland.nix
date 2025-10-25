{
  lib,
  inputs,
  ...
}:

{
  nix.settings.trusted-substituters = [ "https://nixpkgs-wayland.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
  ];

  nixpkgs.overlays = lib.optional (inputs ? nixpkgs-wayland) inputs.nixpkgs-wayland.overlay;
}
