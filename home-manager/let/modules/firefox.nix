# Let's firefox configuration
{ ... }:
{
  imports = [ ../../shared/firefox-base.nix ];

  custom.firefox = {
    enable = true;
    profile = "streaming";
    dnsProvider = "mullvad";
    processCount = 8;
    aggressiveAcceleration = true;
    enableScrollTuning = true;
    enableAIBlocking = false;
    bookmarks = import ./firefox-bookmarks.nix;
  };
}
