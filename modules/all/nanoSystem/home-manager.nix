{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:

let
  inherit (lib)
    mapAttrs
    filterAttrs
    attrNames
    mkAliasOptionModule
    ;
  inherit (inputs) home-manager nanomodules;

  sharedAlias = mkAliasOptionModule [ "hms" ] [ "home-manager" "sharedModules" ];
  mainHomeConfigAlias =
    mkAliasOptionModule
      [ "hm" ]
      [ "home-manager" "users" config.nanoSystem.mainUserName ];
in

{
  imports = [
    home-manager.nixosModules.home-manager
    sharedAlias
    mainHomeConfigAlias
  ];

  assertions = [
    {
      assertion =
        (attrNames (filterAttrs (_: user: user.home.stateVersion == "") config.nanoSystem.users)) == [ ];
      message = ''
        {option}`home-manager.users.<name>.home.stateVersion` must be set for every user.

        You can do this by setting {option}`users.<name>.home.stateVersion` for every user
        in one of the functions `nanolib.lib.systems.{mkDesktop,mkServer,mkPortable}` you used.

        If you don't want home manager for your user, define them the regular way using
        {option}`users.users.<name>` and probably don't use the nanolib functions.
      '';
    }
  ];

  home-manager = {
    backupFileExtension = "home-bac";
    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;

    sharedModules = [
      nanomodules.homeModules.symlinks
      {
        programs.home-manager.enable = true;
        home.shell.enableShellIntegration = true;
        home.preferXdgDirectories = true;
        xdg.enable = true;
      }
    ];

    users = mapAttrs (username: user: {
      home = {
        inherit username;
        inherit (user.home) stateVersion;
      };
    }) config.nanoSystem.users;
  };

  hms = lib.singleton {
    home.activation.deleteHmBackups = config.hm.lib.dag.entryBefore [ "checkLinkTargets" ] ''
      run ${lib.getExe pkgs.findutils} $HOME \
          ! -readable -prune -o \
          -readable -name "*.home-bac" -exec rm -rf {} + || true
    '';
  };
}
