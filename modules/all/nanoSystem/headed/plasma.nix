{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
in

{
  options.nanoSystem.desktop.plasma.enable = mkEnableOption "plasma";

  config = mkIf config.nanoSystem.desktop.plasma.enable {
    services.desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = false;
    };

    services.displayManager.defaultSession = "plasma";
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositor = "kwin";
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
  };
}
