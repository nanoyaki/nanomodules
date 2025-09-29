{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types literalExpression;

  cfg = config.nanoSystem.ssh;
in

{
  options.nanoSystem.ssh.defaultId = mkOption {
    type = types.path;
    default = "${config.hm.home.homeDirectory}/.ssh/id_${config.nanoSystem.mainUserName}_${config.networking.hostName}";
    defaultText = literalExpression ''''${config.hm.home.homeDirectory}/.ssh/id_''${config.nanoSystem.mainUserName}_''${config.networking.hostName}'';
    example = literalExpression ''/etc/ssh/id_${config.networking.hostName}'';
    description = ''
      The default ssh id file for the main user
      for git repositories
    '';
  };

  config = {
    programs.ssh.knownHosts."git.theless.one".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPkogFEPPOMfkRsBgyuHDQeWQMetWCZbkTpnfajTbu7t";

    systemd.services.ensure-id-file = {
      description = "Ensure main user SSH id";
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.openssh ];

      script = ''
        ssh-keygen \
          -t ed25519 \
          -N "" \
          -C "" \
          -f ${cfg.defaultId}

        chown ${config.nanoSystem.mainUserName}:wheel ${cfg.defaultId}
      '';

      unitConfig.ConditionPathExists = "!${cfg.defaultId}";
      serviceConfig = {
        Type = "oneshot";
        Restart = "no";
      };
    };

    programs.ssh.extraConfig = ''
      Host git.theless.one
        User git
        IdentityFile ${cfg.defaultId}
    '';

    hm.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        git = {
          user = "git";
          host = "github.com codeberg.org gitlab.com git.theless.one";
          identityFile = cfg.defaultId;
        };
        "*".identityFile = cfg.defaultId;
      };
    };
  };
}
