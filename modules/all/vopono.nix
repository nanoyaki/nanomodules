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
    mkPackageOption
    mkIf
    ;
  inherit (lib.lists) unique flatten;
  inherit (lib.attrsets) attrValues mapAttrs;
  inherit (lib.strings) concatMapStrings;

  cfg = config.services.vopono;
in

{
  options.services.vopono = {
    enable = mkEnableOption "vopono, for a network namespace for VPNs";

    package = mkPackageOption pkgs "vopono" { };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/vopono";
      example = "/home/vopono";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/wireguard.conf";
      description = ''
        The path to a Wireguard or OpenVPN configuration file.
      '';
    };

    protocol = mkOption {
      type = types.enum [
        "Wireguard"
        "OpenVPN"
      ];
      default = "Wireguard";
      example = "OpenVPN";
      description = ''
        The VPN protocol to use.
      '';
    };

    interface = mkOption {
      type = types.str;
      default = "";
      example = "eth0";
    };

    namespace = mkOption {
      type = types.str;
      default = "vopono0";
      example = "vp0";
      description = ''
        The namespace for the vopono network.
      '';
    };

    systemd.services = mkOption {
      type = with types; attrsOf (either port (listOf port));
      default = { };
      example = lib.literalExpression "{ deluge = 8112; }";
      description = ''
        Map of systemd services to ports to forward from network namespace to the host
        If you don't need to forward any use an empty list.
      '';
    };

    allowedTCPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      example = lib.literalExpression "[ 80 ]";
      description = ''
        TCP ports to forward to vopono's network namespace.
      '';
    };

    allowedUDPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      example = lib.literalExpression "[ 80 ]";
      description = ''
        UDP ports to forward to vopono's network namespace.
      '';
    };

    allowHostAccess = mkEnableOption "host access";

    host = mkOption {
      type = types.str;
      default = "10.200.1.1";
      readOnly = true;
      description = ''
        The host's IP address.
      '';
    };

    voponoHost = mkOption {
      type = types.str;
      default = "10.200.1.2";
      readOnly = true;
      description = ''
        The vopono network namespace's host IP address.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.vopono = {
      isSystemUser = true;
      group = "vopono";
      home = cfg.dataDir;
    };

    users.groups.vopono = { };

    systemd.tmpfiles.settings."10-vopono-config"."${cfg.dataDir}/.config/vopono".d = {
      user = "vopono";
      group = "vopono";
      mode = "770";
    };

    networking.firewall.interfaces."${cfg.namespace}_d" = {
      inherit (cfg)
        allowedTCPPorts
        allowedUDPPorts
        ;
    };

    systemd.services = {
      vopono-daemon = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        path =
          with pkgs;
          [
            wireguard-tools
            iproute2
            procps
            openvpn
          ]
          ++ lib.optional config.networking.nftables.enable nftables
          ++ lib.optional (!config.networking.nftables.enable) iptables;

        environment.RUST_LOG = "info";

        serviceConfig = {
          User = "root";
          Group = "root";
          Type = "simple";
          Restart = "on-failure";
          RestartSec = "5s";
          ExecStart = "${lib.getExe cfg.package} daemon";
        };
      };

      vopono = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "vopono-daemon.service" ];
        after = [ "vopono-daemon.service" ];

        unitConfig.ConditionPathExists = "${cfg.dataDir}/.config/vopono";

        script = ''
          ${lib.getExe cfg.package} exec \
            ${lib.optionalString (cfg.interface != "") "-i ${cfg.interface}"} \
            -u vopono \
            --keep-alive \
            ${
              concatMapStrings (port: "-f ${toString port} ") (unique (flatten (attrValues cfg.systemd.services)))
            } \
            ${
              concatMapStrings (port: "-o ${toString port} ") (
                unique (cfg.allowedTCPPorts ++ cfg.allowedUDPPorts)
              )
            } \
            --allow-host-access \
            --custom ${cfg.configFile} \
            --protocol ${cfg.protocol} \
            --custom-netns-name ${cfg.namespace} \
            "${pkgs.writeShellScript "keep-alive" ''
              while true; do sleep 3600; done
            ''}"
        '';

        serviceConfig = {
          Type = "simple";
          Restart = "no";
          User = "vopono";
          Group = "vopono";
        };
      };
    }
    // mapAttrs (_: _: {
      after = [ "vopono-daemon.service" ];
      bindsTo = [ "vopono-daemon.service" ];
      partOf = [ "vopono-daemon.service" ];

      serviceConfig = {
        BindPaths = [ "/etc/netns/${cfg.namespace}/resolv.conf:/etc/resolv.conf" ];
        NetworkNamespacePath = "/var/run/netns/${cfg.namespace}";
      };
    }) cfg.systemd.services;
  };
}
