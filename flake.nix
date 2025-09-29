# SPDX-FileCopyrightText: 2025 Hana Kretzer <hanakretzer@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later
{
  description = "An extension for nixpkgs with nightly package updates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nanolib = {
      url = "git+https://git.theless.one/nanoyaki/nanolib.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{ flake-parts, systems, ... }:

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./modules
      ];

      perSystem =
        { pkgs, ... }:

        {
          formatter = pkgs.nixfmt-tree;
        };

      systems = import systems;
    };
}
