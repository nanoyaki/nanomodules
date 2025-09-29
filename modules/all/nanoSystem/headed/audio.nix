{
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    mapAttrs
    singleton
    ;
  types' = lib.nanolib.types;

  cfg = config.nanoSystem.audio;
in

{
  options.nanoSystem.audio = {
    latency = mkOption {
      type = types'.powerOf2;
      default = 512;
      description = ''
        Specifies the audio quantum which plays a big
        part in audio latency. Lower values might lead
        to crackly audio but lower latencies.
      '';
    };
    samplingRate = mkOption {
      type = types.enum [
        8000
        16000
        22050
        32000
        44100
        48000
        96000
        192000
      ];
      default = 48000;
      example = 96000;
      description = ''
        The audio sampling rate frequently also referred
        to as audio frequency. 
      '';
    };
  };

  config = {
    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      audio.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;

      wireplumber.enable = true;
      wireplumber.extraConfig."90-defaults".monitor.alsa.rules = singleton {
        matches = singleton {
          # wpctl status -> wpctl inspect <id>
          "media.class" = "Audio/Sink";
        };
        actions.update-props = with cfg; {
          audio.rate = samplingRate;
          api.alsa.rate = samplingRate;
          api.alsa.period-size = latency;
        };
      };
    };

    users.users = mapAttrs (_: _: { extraGroups = [ "audio" ]; }) config.nanoSystem.users;
  };
}
