{
  lib,
  config,
  ...
}:

let
  inherit (lib) mkOption types mkDefault;
  cfg = config.nanoSystem.keyboard;
in

{
  options.nanoSystem.keyboard = {
    layout = mkOption {
      type = types.str;
      default = "de";
      example = "fr";
      description = ''
        1:1 map of {option}`services.xserver.xkb.layout`
      '';
    };
    variant = mkOption {
      type = types.str;
      default = "";
      description = ''
        1:1 map of {option}`services.xserver.xkb.variant`
      '';
    };
  };

  config.console.keyMap = mkDefault cfg.layout;
}
