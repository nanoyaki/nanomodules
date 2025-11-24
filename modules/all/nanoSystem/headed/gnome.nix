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
  options.nanoSystem.desktop.gnome.enable = mkEnableOption "gnome";

  config = mkIf config.nanoSystem.desktop.gnome.enable {
    services.desktopManager.gnome = {
      enable = true;
      extraGSettingsOverrides = ''
        [org.gnome.settings-daemon.plugins.power]
        sleep-inactive-ac-type="nothing"

        [org.gnome.desktop.media-handling]
        automount=false
        automount-open=false
        autorun-never=true
      '';
    };

    services.displayManager.defaultSession = "gnome";
    services.displayManager.gdm.enable = true;

    programs.nautilus-open-any-terminal.enable = true;
    programs.nautilus-open-any-terminal.terminal = "alacritty";

    environment.gnome.excludePackages = with pkgs; [
      papers
      evince
      snapshot
      geary
      totem
      simple-scan
      gnome-maps
      epiphany
      cheese
      yelp
      gnome-disk-utility
      gnome-tour
      gnome-contacts
      gnome-music
      gnome-console
      gnome-weather
      gnome-connections
      gnome-terminal
    ];
  };
}
