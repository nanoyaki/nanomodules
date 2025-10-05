{
  lib,
  pkgs,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    mkEnableOption
    literalExpression
    mkIf
    ;

  cfg = config.services.copyparty-mount;
in

{
  options.services.copyparty-mount = {
    enable = mkEnableOption "copyparty mount";

    server = mkOption {
      type = types.str;
      default = "http://127.0.0.1:3923";
      example = "https://files.example.com";
      description = ''
        The server to connect to *without* a trailing slash.
      '';
    };

    path = mkOption {
      type = types.path;
      default = "/";
      example = "/my-private-directory/my-subdirectory";
      description = ''
        The path of the directory within copyparty to mount to
        the local path {option}`services.copyparty-mount.target`
      '';
    };

    target = mkOption {
      type = types.path;
      default = "/mnt/copyparty";
      example = "/home/joe/copyparty";
      description = ''
        The target path where the remote copyparty directory
        defined in {option}`services.copyparty-mount.path`
        gets mounted
      '';
    };

    copyparty.user = mkOption {
      type = types.str;
      default = "k";
      example = "joe";
      description = ''
        The user used for authenticating with copyparty.

        This is not required and can be any value
        unless `--usernames` is enabled
      '';
    };

    copyparty.sopsPasswordPlaceholder = mkOption {
      type = types.str;
      default = "copyparty-mount";
      example = "joe";
      description = ''
        The sops secrets file containing the *rclone
        obfuscated password* used for authenticating
        with copyparty.

        Generate the obfuscated password using
        {command}`rclone obscure <password>`.
      '';
    };

    fsExtraOptions = mkOption {
      type = types.listOf types.str;
      default = [
        "x-systemd.automount"
        "noauto"
      ];
      example = literalExpression ''
        [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=600"
        ]
      '';
      description = ''
        Options to use in {option}`fileSystems.<name>.options`.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rclone ];

    sops.templates."copyparty.conf" = {
      file = (pkgs.formats.ini { }).generate "copyparty.conf.template" {
        copyparty-dav = {
          type = "webdav";
          url = cfg.server;
          vendor = "owncloud";
          pacer_min_sleep = "0.01ms";
          user = cfg.copyparty.user;
          pass = cfg.copyparty.sopsPasswordPlaceholder;
        };
      };
      mode = "400";
    };

    fileSystems.${cfg.target} = {
      device = "copyparty-dav:${cfg.path}";
      fsType = "rclone";
      options = [
        "config=${config.sops.templates."copyparty.conf".path}"
        "vfs-cache-mode=writes"
        "dir-cache-time=5s"
      ]
      ++ cfg.fsExtraOptions;
    };
  };
}
