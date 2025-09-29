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
    ;

  cfg = config.nanoSystem.deployment;
in

{
  # host = { ... };
  options.nanoSystem.deployment = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
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
                <targetUser>@${name}
              '';
            };
          };
        }
      )
    );
  };
  #    mkAttrsOf (mkSubmoduleOption {
  #   # username; usually root
  #   targetUser = mkStrOption;
  #   # key or key contents
  #   publicKey = mkEither mkPathOption mkStrOption;
  # });

  config = {
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
    ) cfg;
  };
}
