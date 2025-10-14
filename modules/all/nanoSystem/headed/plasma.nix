{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.nanoSystem.desktop.plasma;
in

{
  options.nanoSystem.desktop.plasma = {
    enable = mkEnableOption "plasma";

    isDefault = mkEnableOption "plasma as the default session";
  };

  config = mkIf cfg.enable {
    services.desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = false;
    };

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      konsole
      kate
      ktexteditor
      baloo-widgets
      okular
      elisa
      khelpcenter
      discover
    ];

    services.displayManager.defaultSession = mkIf cfg.isDefault "plasma";
  };
}
