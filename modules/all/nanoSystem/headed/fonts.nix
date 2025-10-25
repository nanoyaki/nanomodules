{
  lib,
  pkgs,
  ...
}:

{
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      noto-fonts-cjk-sans
      nerd-fonts.fira-code
      nerd-fonts.caskaydia-cove
      twemoji-color-font
    ];

    fontconfig = {
      antialias = true;
      defaultFonts = {
        serif = [ "Noto Sans CJK JP" ];
        sansSerif = [ "Noto Sans CJK JP" ];
        monospace = [
          "FiraCode Nerd Font"
          "CaskaydiaCove Nerd Font Mono"
        ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };

  hms = lib.singleton {
    gtk.font = {
      package = pkgs.noto-fonts-cjk-sans;
      name = "Noto Sans CJK JP";
    };
  };
}
