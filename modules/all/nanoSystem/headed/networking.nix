{ lib, config, ... }:

let
  inherit (lib) filterAttrs mapAttrs;
  superusers = filterAttrs (_: user: user.isSuperuser) config.nanoSystem.users;
in

{
  users.users = mapAttrs (_: _: { extraGroups = [ "networkmanager" ]; }) superusers;

  networking.networkmanager.enable = lib.mkDefault true;
}
