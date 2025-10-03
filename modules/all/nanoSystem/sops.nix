{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mapAttrs
    mapAttrs'
    nameValuePair
    literalExpression
    filterAttrs
    optional
    ;

  cfg = config.nanoSystem.sops;

  sopsPasswordUsers = filterAttrs (
    _: user: user.hashedPasswordSopsKey != null
  ) config.nanoSystem.users;
in

{
  imports = optional (inputs ? sops-nix) inputs.sops-nix.nixosModules.sops;

  options.nanoSystem.sops = {
    enable = mkEnableOption "sops-nix as the secrets manager" // {
      default = true;
    };
    defaultSopsFile = mkOption {
      type = types.nullOr types.pathInStore;
      default = null;
      example = literalExpression ''./secrets/host.yaml'';
      description = ''
        The path to the default sops file that contains
        the users' passwords.
      '';
    };
  };

  config = mkIf (cfg.enable && (inputs ? sops-nix)) {
    assertions = [
      {
        assertion = cfg.defaultSopsFile != null;
        message = "A store path to the default sops file in {option}`nanoSystem.sops.defaultSopsFile` is required";
      }
    ];

    environment.systemPackages = [ pkgs.sops ];

    sops = {
      inherit (cfg) defaultSopsFile;
      defaultSopsFormat = "yaml";

      age.keyFile = "${
        config.users.users.${config.nanoSystem.mainUserName}.home
      }/.config/sops/age/keys.txt";
      secrets = mapAttrs' (
        _: user: nameValuePair user.hashedPasswordSopsKey { neededForUsers = true; }
      ) sopsPasswordUsers;
    };

    users.users = mapAttrs (_: user: {
      hashedPasswordFile = config.sops.secrets.${user.hashedPasswordSopsKey}.path;
    }) sopsPasswordUsers;
  };
}
