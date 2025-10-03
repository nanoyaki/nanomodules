{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.nanoSystem;
in

{
  options.nanoSystem.fcitx5.enable = mkEnableOption "opinionated fcitx5";

  config = mkIf cfg.fcitx5.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        addons = with pkgs; [
          fcitx5-mozc
          fcitx5-gtk
        ];
        waylandFrontend =
          config.services.displayManager.gdm.wayland
          || config.services.desktopManager.plasma6.enable
          || config.services.desktopManager.cosmic.enable;
        settings.inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = cfg.keyboard.layout;
            DefaultIM = "keyboard-${cfg.keyboard.layout}";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-${cfg.keyboard.layout}";
            Layout = cfg.keyboard.layout;
          };
        };
      };
    };
  };
}
