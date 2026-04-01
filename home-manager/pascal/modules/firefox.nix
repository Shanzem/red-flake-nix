# Pascal's firefox configuration
{ ... }:
{
  imports = [ ../../shared/firefox-base.nix ];

  custom.firefox = {
    enable = true;
    profile = "security";
    dnsProvider = "cloudflare";
    processCount = 24;
    aggressiveAcceleration = false;
    enableScrollTuning = true;
    enableAIBlocking = true;
    bookmarks = import ./firefox-bookmarks.nix;
    extraExtensions = {
      "firefox@betterttv.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/betterttv/latest.xpi";
        installation_mode = "force_installed";
      };
      "frankerfacez@frankerfacez.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/frankerfacez/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };
}
