{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) mkEnableOption mkDefault;

  cfg = config.nanoSystem.desktop.cosmic.enable;
in

{
  options.nanoSystem.desktop.cosmic.enable = (mkEnableOption "cosmic") // {
    default = true;
  };

  config = {
    services.desktopManager.cosmic = {
      enable = cfg;
      xwayland.enable = true;
    };

    environment.cosmic.excludePackages = with pkgs; [
      cosmic-term
      cosmic-edit
      cosmic-store
      cosmic-player
    ];

    services.displayManager = {
      cosmic-greeter.enable = true;
      defaultSession = mkDefault "cosmic";
    };
  };
}
