{
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    mapAttrs'
    nameValuePair
    literalExpression
    mkIf
    mkEnableOption
    ;

  cfg = config.nanoSystem.deployment;
in

{
  options.nanoSystem.deployment = {
    enable = mkEnableOption "deployment keys";

    addresses = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            targetUser = mkOption {
              type = types.str;
              default = "";
              example = "root";
              description = ''
                The user to log into over ssh. It's recommended
                to use the root user or a user that has trusted
                access to the nix store.
              '';
            };

            publicKey = mkOption {
              type = with types; either pathInStore str;
              default = "";
              example = literalExpression ''./id_ed25519.pub'';
              description = ''
                The public key that is allowed to deploy to
                <targetUser>@<host>
              '';
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.nanoSystem.systemType == "server" -> cfg.addresses != { };
        message = "Servers are required to have at least one deployment address specified.";
      }
    ];

    users.users = mapAttrs' (
      host: deployment:
      nameValuePair deployment.targetUser {
        openssh.authorizedKeys.keys = [
          (
            if (builtins.typeOf deployment.publicKey) == "path" then
              builtins.readFile deployment.publicKey
            else
              deployment.publicKey
          )
        ];
      }
    ) cfg.addresses;
  };
}
