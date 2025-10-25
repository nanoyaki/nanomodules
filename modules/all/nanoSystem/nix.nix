{
  self,
  lib,
  inputs,
  pkgs,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    literalExpression
    filter
    map
    optional
    ;

  cfg = config.nanoSystem.nix;
in

{
  options.nanoSystem.nix.flake = mkOption {
    type = types.str;
    default = "${config.users.users.${config.nanoSystem.mainUserName}.home}/flake";
    defaultText = literalExpression ''''${config.users.users.''${config.nanoSystem.mainUserName}.home}/flake'';
    example = "/etc/nixos";
    description = ''
      The location that contains the system's flake.
    '';
  };

  config = {
    nixpkgs.overlays =
      map
        (
          input:
          if inputs.${input}.overlays ? ${input} then
            inputs.${input}.overlays.${input}
          else
            inputs.${input}.overlays.default
        )
        (
          filter (input: inputs ? ${input}) [
            "nanopkgs"
            "lazy-apps"
            "nur"
          ]
        )
      ++ optional (inputs ? nixpkgs-stable) (
        final: _: {
          stable = import inputs.nixpkgs-stable {
            inherit (final.stdenv.hostPlatform) system;
            inherit (config.nixpkgs) config;
          };
        }
      );
    nixpkgs.config.allowUnfree = lib.mkDefault true;

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = [
          "root"
          "@wheel"
        ];
        trusted-substituters = [
          "https://cache.nixos.org/"
          "https://hydra.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        auto-optimise-store = true;
      };

      optimise = {
        automatic = true;
        dates = "daily";
        randomizedDelaySec = "15min";
        persistent = true;
      };

      registry = {
        self.flake = self;
      }
      // lib.mapAttrs (_: value: { flake = value; }) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    };

    environment.sessionVariables.FLAKE = cfg.flake;
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--keep 10 --keep-since 7d";
      };
      inherit (cfg) flake;
    };

    programs.direnv.enable = true;
  };
}
