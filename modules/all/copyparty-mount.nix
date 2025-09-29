{
  lib,
  config,
  ...
}:

let
  inherit (lib) mkOption types mkEnableOption literalExpression mkIf;

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

    fsExtraOptions = mkOption {
      type = types.listOf types.str;
      default = [ "x-systemd.automount" "noauto" ];
      example = literalExpression ''
        [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=600"
        ]
      '';
      description = ''
        Options to use in {option}`fileSystems.<name>.options`.
      ''
    };
  };

  config = mkIf cfg.enable {
    services.davfs2.enable = true;

    users.users = mkIf (cfg.user == "copyparty-mount") {
      copyparty-mount.isSystemUser = true;
    };

    users.groups = mkIf (cfg.group == "copyparty-mount") {
      copyparty-mount = { };
    };

    fileSystems.${cfg.target} = {
      device = "${cfg.server}${cfg.path}";
      fsType = "davfs";
      options = [ "uid=${config.users.groups.copyparty-mount.uid}" "gid=${config.users.groups.copyparty-mount.gid}" "umask=007" ] ++ cfg.fsExtraOptions;
    };
  };
}