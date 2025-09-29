{ lib, config, ... }:

{
  xdg.portal.xdgOpenUsePortal = true;
  hms = lib.singleton {
    xdg.autostart.enable = true;
    xdg.portal = removeAttrs config.xdg.portal [
      "gtkUsePortal"
      "lxqt"
      "wlr"
    ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = config.nanoSystem.mainUserName;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GDK_BACKEND = "wayland";
  };

  services.libinput.mouse.accelProfile = "flat";
  services.xserver.xkb = config.nanoSystem.keyboard;
}
