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

    user = mkOption {
      type = types.str;
      default = "copyparty-mount";
      example = "joe";
      description = ''
        The user that has full access to the mount.

        It is not recommended to change this value but
        rather to add your user to the group defined in
        {option}`services.copyparty-mount.group`
      '';
    };

    group = mkOption {
      type = types.str;
      default = "copyparty-mount";
      example = "users";
      description = ''
        The group that has full access to the mount.

        It is not recommended to change this value but
        rather to add your user to this group.
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
    assertions = [
      {
        assertion =
          config.users.users.${cfg.user}.uid != null || config.users.groups.${cfg.group}.gid != null;
        message = "Uid and gid must be set on the user and group";
      }
    ];

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
      owner = cfg.user;
      mode = "400";
    };

    users.users = mkIf (cfg.user == "copyparty-mount") {
      copyparty-mount = {
        isSystemUser = true;
        inherit (cfg) group;
        uid = 2000;
      };
    };

    users.groups = mkIf (cfg.group == "copyparty-mount") {
      copyparty-mount.gid = 2000;
    };

    # setgid
    systemd.tmpfiles.settings."10-copyparty".${cfg.target}.d = {
      inherit (cfg) user group;
      mode = "2770";
    };

    fileSystems.${cfg.target} = {
      device = "copyparty-dav:${cfg.path}";
      fsType = "rclone";
      options = [
        "config=${config.sops.templates."copyparty.conf".path}"
        "vfs-cache-mode=writes"
        "dir-cache-time=5s"
        "uid=${toString config.users.users.${cfg.user}.uid}"
        "gid=${toString config.users.groups.${cfg.group}.gid}"
        "umask=007"
      ]
      ++ cfg.fsExtraOptions;
    };
  };
}
