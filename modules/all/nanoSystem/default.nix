{
  hostname,
  users,
  platform,
  type,
}:

# This module makes a few assumptions based on
# my own personal usage. For example, the assumption
# that there's a "main user".

{
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    literalExpression
    mkIf
    filterAttrs
    length
    mapAttrs
    optionalAttrs
    singleton
    ;
  inherit (builtins) elemAt attrNames;
  inherit (lib.nanolib.global) toUppercase;
  types' = lib.nanolib.types;

  cfg = config.nanoSystem;
in

{
  imports = [
    ./home-manager.nix
    ./locale.nix
    ./sops.nix
    ./nix.nix
    ./ssh.nix
    ./git.nix
    ./input.nix
    ./boot.nix
    ./comfort.nix
    ./deployment.nix
  ]
  ++ singleton (./. + config.nanoSystem.systemType);

  options.nanoSystem = {
    users = mkOption {
      types = types.attrsOf (
        types.submodule (
          { config, name, ... }:

          {
            options = {
              isMainUser = mkOption {
                type = types.bool;
                default = false;
                example = literalExpression ''true'';
                description = ''
                  Whether the user is the main user on the system.
                '';
              };

              isSuperuser = mkOption {
                type = types.bool;
                default = config.isMainUser || name == "root";
                defaultText = literalExpression ''config.isMainUser || name == "root"'';
                example = literalExpression ''true'';
                description = ''
                  Whether the user should be granted root privileges.
                '';
              };

              hashedPasswordSopsKey = mkOption {
                type = with types; nullOr str;
                default = null;
                example = "users/<name>";
                description = ''
                  The sops key in the default sops file where the hashed
                  password for the user is defined. When `null` an initial
                  default password `default` will be used.

                  To generate a password for a user, use
                  {command}`mkpasswd -m bcrypt`.
                '';
              };

              home.stateVersion = mkOption {
                type = types.strMatching ''\d{2}\.\d{2}'';
                default = "";
                example = "25.11";
                description = ''
                  The state version to pass to home manager. See
                  {option}`home-manager.users.<name>.home.stateVersion`
                  for more context.
                '';
              };
            };
          }
        )
      );
      default = users;
      description = ''
        The users of the system and to configure home manager for.
      '';
      example = literalExpression ''
        {
          joe = {
            isMainUser = true;
            isSuperuser = true;
            hashedPasswordSopsKey = "users/joe";
            home.stateVersion = "25.11";
          };
        }
      '';
      readOnly = true;
    };

    mainUserName = mkOption {
      type = types.str;
      default = elemAt (attrNames (filterAttrs (_: user: user.isMainUser) cfg.users)) 0;
      defaultText = literalExpression ''builtins.elemAt (builtins.attrNames (lib.filterAttrs (_: user: user.mainUser) config.nanoSystem.users)) 0'';
      description = ''
        The main user of the system.
      '';
      readOnly = true;
    };

    systemType = mkOption {
      type = types'.system;
      default = type;
      description = ''
        The type of device this system should get optimized for.
        Servers don't come with a desktop environment and portables
        are optimized for power efficiency.
      '';
      readOnly = true;
    };
  };

  config = {
    assertions = [
      {
        assertion = (length (attrNames (filterAttrs (_: user: user.isMainUser) cfg.users))) == 1;
        message = "Only one user can be the main user and at least one user has to be the main user";
      }
      {
        assertion = cfg.users.${cfg.mainUserName}.isSuperuser;
        message = "The main user is required to be a superuser";
      }
      {
        assertion = (!(cfg.users ? root)) || cfg.users.root.isSuperuser;
        message = "The root user is required to be a superuser";
      }
    ];

    users.mutableUsers = false;
    users.users = mapAttrs (
      username: user:
      {
        isNormalUser = true;
        description = toUppercase username;
        extraGroups = mkIf user.isSuperuser [ "wheel" ];
      }
      // optionalAttrs (user.hashedPasswordSopsKey == null) {
        initialPassword = builtins.warn ''
          Initial password `default` has been set. Please make sure
          to unset {option}`users.users.${username}.initialPassword`
          once you've set your own.
        '' (lib.mkDefault "default");
      }
    ) (filterAttrs (username: _: username != "root") cfg.users);

    networking.hostName = hostname;
    nixpkgs.hostPlatform.system = platform;

    networking.useDHCP = lib.mkDefault true;

    utilities.comfort.enable = lib.mkDefault true;
  };
}
