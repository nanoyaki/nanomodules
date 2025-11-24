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
  options.nanoSystem.desktop.cosmic.enable = (mkEnableOption "cosmic") // {
    default = true;
  };

  config = mkIf config.nanoSystem.desktop.cosmic.enable {
    services.desktopManager.cosmic = {
      enable = true;
      xwayland.enable = true;
    };

    environment.cosmic.excludePackages = with pkgs; [
      cosmic-term
      cosmic-edit
      cosmic-store
      cosmic-player
    ];

    services.displayManager.cosmic-greeter.enable = true;
    services.displayManager.defaultSession = "cosmic";
  };
}
