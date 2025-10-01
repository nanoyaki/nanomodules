{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf singleton;
in

{
  options.nanoSystem.comfort-utilities.enable =
    (mkEnableOption ''what nano deems as "comfort utilities"'')
    // {
      description = ''
        This enables utilities that I use on a regular
        basis and are by no means required. Feel free
        to just keep these disabled as these are very
        opinionated.
      '';
    };

  config = mkIf config.nanoSystem.comfort-utilities.enable {
    users.defaultUserShell = pkgs.zsh;
    programs.zsh = {
      enable = true;

      enableCompletion = true;
      enableBashCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestions.enable = true;

      interactiveShellInit = ''
        bindkey "^[[H"    beginning-of-line
        bindkey "^[[F"    end-of-line
        bindkey "^[[3~"   delete-char
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word
        bindkey "^[[3;5~" kill-word
        bindkey "^H"      backward-kill-word
        WORDCHARS='*?_[]~=&;!#$%^(){}<>'
      '';

      histSize = 10000;
    };

    environment = {
      shellAliases.copy = "rsync -a --info=progress2 --info=name0";
      systemPackages = with pkgs; [
        prefetch
        unrar
        unzip
        p7zip
        ncdu
        jq
      ];
      sessionVariables = {
        MANPAGER = "sh -c 'col -bx | ${lib.getExe pkgs.bat} -l man -p'";
        MANROFFOPT = "-c";
      };
    };

    hms = singleton {
      programs = {
        zsh.enable = true;
        zellij = {
          enable = true;
          settings.pane_frames = false;
        };
        starship = {
          enable = true;
          enableZshIntegration = true;
        };
        lsd.enable = true;
        btop.enable = true;
        bat.enable = true;
        fastfetch.enable = true;
        ripgrep.enable = true;
      };
    };
  };
}
