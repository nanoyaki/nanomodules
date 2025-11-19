{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    replaceString
    mkIf
    map
    attrValues
    flatten
    ;

  cfg = config.environment.mutableFiles;
in

{
  options.environment.mutableFiles = {
    enable = mkEnableOption "mutable file management";

    settings = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:

          {
            options = {
              path = mkOption {
                type = types.path;
                default = name;
                description = ''
                  The path of the mutable file outside the nix store
                '';
              };

              content = mkOption {
                type = types.str;
                default = "";
                description = ''
                  The content of the mutable file
                '';
              };

              file = mkOption {
                type = types.package;
                default = pkgs.writeText "${replaceString "/" "-" config.path}.txt" config.content;
                defaultText = ''pkgs.writeText "''${replaceString "/" "-" config.path}.txt" config.environment.mutableFiles.<name>.content'';
                description = ''
                  The file containing the final content to be written to {option}`config.environment.mutableFiles.<name>.path`
                '';
              };

              owner = mkOption {
                type = types.str;
                default = "root";
                description = ''
                  The owner of the file
                '';
              };

              group = mkOption {
                type = types.str;
                default = "wheel";
                description = ''
                  The owner of the file
                '';
              };

              mode = mkOption {
                type = types.strMatching ''[0-9]{3,4}'';
                default = "600";
                description = ''
                  The owner of the file
                '';
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = mkIf (cfg.enable && (cfg.settings != { })) {
    systemd.tmpfiles.rules = flatten (
      map (setting: [
        "C+ ${setting.path} - - - - ${setting.file}"
        "z ${setting.path} ${setting.mode} ${setting.owner} ${setting.group} - -"
      ]) (attrValues cfg.settings)
    );
  };
}
