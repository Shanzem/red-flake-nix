# Common plasma-manager configuration
# Imports the shared base with default settings
{ ... }:
{
  imports = [ ../../shared/plasma-manager-base.nix ];

  custom.plasma = {
    enable = true;
    terminal = "ghostty";
    wallpaperResolution = "auto";
    keyboardLayout = "de";
    enablePowerdevilService = true;
    strictMode = true;
    autoLock = true;
    displayTimeouts = { turnOff = 900; dim = 600; };
    disableBlur = true;
    enableTripleBuffering = true;
    hideBrowserIntegrationReminder = true;
  };
}
