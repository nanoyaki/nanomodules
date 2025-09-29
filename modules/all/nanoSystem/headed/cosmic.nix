{
  pkgs,
  ...
}:

{
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

  services.displayManager = {
    cosmic-greeter.enable = true;
    defaultSession = "cosmic";
  };
}
