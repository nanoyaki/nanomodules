{
  lib,
  config,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.nanoSystem.localization;

  characterSet = lib.strings.concatStrings (
    lib.lists.drop 1 (lib.strings.splitString "." cfg.locale)
  );
  posixLocalePredicate = lang: (builtins.match "^[a-z]{2}_[A-Z]{2}$" lang) != null;

  languageType = types.strMatching ''^([a-z]{2}|[a-z]{2}_[A-Z]{2})'';
in

{
  options.nanoSystem.localization = {
    timezone = mkOption {
      type = types.str;
      default = "";
      example = "Europe/Berlin";
      description = ''
        The IANA timezone to use for the system.
      '';
    };

    language = mkOption {
      type = with types; either languageType (listOf languageType);
      default = "en_GB";
      example = "de_DE";
      description = ''
        Sets the LANGUAGE environment variable and glibc locale,
        as well as the default language for terminal messages
        and the LC_MESSAGES environment variable.

        When evaluated it uses the first POSIX locale as the
        LC_MESSAGES and glibc locale.
      '';
    };

    locale = mkOption {
      # The regex for the character set is quite silly
      # but covers every character set i can think of
      type = types.strMatching ''^[a-z]{2}_[A-Z]{2}\.[A-Z0-9\-\.\:\/\(\)]*'';
      default = "en_GB.UTF-8";
      example = "de_DE.UTF-8";
      description = ''
        The locale used for anything else but messages. This
        must be a POSIX locale with the character set separated
        using the first `.` character.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion =
          (builtins.isString cfg.language && posixLocalePredicate cfg.language)
          || lib.lists.any posixLocalePredicate cfg.language;
        message = ''
          The {option}`nanoSystem.localization.language` option must contain 
          at least one POSIX locale.
        '';
      }
    ];

    time.timeZone = cfg.timezone;

    i18n = {
      defaultLocale = cfg.locale;

      extraLocaleSettings = rec {
        LANGUAGE =
          if builtins.isString cfg.language then
            "${cfg.language}.${characterSet}"
          else
            "${lib.lists.findFirst posixLocalePredicate "en_US" cfg.language}.${characterSet}";
        LC_MESSAGES = LANGUAGE;
      }
      // lib.genAttrs [
        "LC_ADDRESS"
        "LC_IDENTIFICATION"
        "LC_MEASUREMENT"
        "LC_MONETARY"
        "LC_NAME"
        "LC_NUMERIC"
        "LC_PAPER"
        "LC_TELEPHONE"
        "LC_TIME"
        "LC_COLLATE"
        "LC_CTYPE"
      ] (_: cfg.locale);
    };

    environment.sessionVariables = config.i18n.extraLocaleSettings // {
      LC_ALL = "";
      LANGUAGE = lib.mkForce (
        if builtins.isString cfg.language then
          cfg.language
        else
          lib.strings.concatStrings (lib.strings.intersperse ":" cfg.language)
      );
    };
  };
}
