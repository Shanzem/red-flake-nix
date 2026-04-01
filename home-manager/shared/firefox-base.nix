# Parameterized firefox base module
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.custom.firefox;

  # DNS provider URIs
  dnsProviderUri = {
    cloudflare = "https://mozilla.cloudflare-dns.com/dns-query";
    mullvad = "https://doh.mullvad.net/dns-query";
    none = "";
  };

  # Base settings shared across all profiles
  baseSettings = {
    # Disable remote prefs
    "remote.prefs.recommended" = false;

    # Performance settings
    "browser.preferences.defaultPerformanceSettings.enabled" = false;
    "gfx.use_text_smoothing_setting" = true;

    # Wayland / fractional scaling
    "widget.wayland.fractional-scale.enabled" = true;

    # Process count
    "dom.ipc.processCount" = cfg.processCount;

    # About config
    "browser.aboutConfig.showWarning" = false;

    # Telemetry
    "toolkit.telemetry.enabled" = false;

    # Session restore
    "browser.startup.page" = 3;
    "browser.sessionstore.resume_from_crash" = true;
    "browser.sessionstore.max_resumed_crashes" = 2;
    "browser.sessionstore.restore_on_demand" = true;
    "browser.sessionstore.restore_pinned_tabs_on_demand" = true;

    # New tab page
    "browser.newtabpage.enabled" = true;
    "browser.newtabpage.activity-stream.topSitesRows" = 2;
    "browser.newtabpage.storageVersion" = 1;
    "browser.newtab.preload" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.system.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.feeds.sections" = false;
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.feeds.snippets" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
    "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
    "browser.newtabpage.activity-stream.default.sites" = "";

    # Tab manager
    "browser.tabs.tabmanager.enabled" = false;

    # Dark mode
    "browser.in-content.dark-mode" = true;
    "ui.systemUsesDarkTheme" = 1;
    "ui.key.menuAccessKeyFocuses" = false;
    "browser.theme.toolbar-theme" = 0;
    "browser.theme.content-theme" = 0;

    # DRM/Media
    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.visible" = true;
    "media.gmp-widevinecdm.enabled" = true;

    # Extensions
    "browser.discovery.enabled" = false;
    "extensions.getAddons.showPane" = false;
    "extensions.getAddons.cache.enabled" = false;
    "extensions.htmlaboutaddons.recommendations.enabled" = false;
    "extensions.pocket.enabled" = false;
    "extensions.screenshots.disabled" = true;
    "extensions.blocklist.enabled" = false;
    "identity.fxaccounts.enabled" = false;

    # Crash reporting
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "toolkit.coverage.endpoint.base" = "";
    "toolkit.coverage.opt-out" = true;
    "toolkit.telemetry.coverage.opt-out" = true;
    "browser.region.update.enabled" = false;
    "browser.region.network.url" = "";
    "browser.aboutHomeSnippets.updateUrl" = "";
    "browser.selfsupport" = false;

    # Safe browsing (disabled for pentesting)
    "browser.safebrowsing.phishing.enabled" = false;
    "browser.safebrowsing.malware.enabled" = false;
    "browser.safebrowsing.blockedURIs.enabled" = false;
    "browser.safebrowsing.downloads.enabled" = false;
    "browser.safebrowsing.downloads.remote.enabled" = false;
    "browser.safebrowsing.downloads.remote.block_dangerous" = false;
    "browser.safebrowsing.downloads.remote.block_dangerous_host" = false;
    "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
    "browser.safebrowsing.downloads.remote.block_uncommon" = false;
    "browser.safebrowsing.downloads.remote.url" = "";
    "browser.safebrowsing.provider.*.gethashURL" = "";
    "browser.safebrowsing.provider.*.updateURL" = "";
    "browser.pagethumbnails.capturing_disabled" = true;
    "browser.startup.homepage_override.mstone" = "ignore";
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
    "extensions.ui.lastCategory" = "about:addons";
    "browser.vpn_promo.enabled" = false;
    "app.normandy.enabled" = false;
    "extensions.webextensions.restrictedDomains" = "";
    "network.connectivity-service.enabled" = false;
    "browser.search.geoip.url" = "";

    # Cookie banners
    "cookiebanners.service.mode" = 2;
    "cookiebanners.service.mode.privateBrowsing" = 2;

    # Media autoplay
    "media.autoplay.default" = 5;
    "layout.css.prefers-color-scheme.content-override" = 0;
    "dom.security.https_only_mode" = false;
    "dom.serviceWorkers.enabled" = false;

    # DNS over HTTPS
    "network.trr.mode" = if cfg.dnsProvider == "none" then 0 else 1;
    "network.trr.uri" = dnsProviderUri.${cfg.dnsProvider};
    "network.dns.echconfig.enabled" = true;
    "network.dns.http3_echconfig.enabled" = true;

    # Prefetch
    "network.prefetch-next" = false;
    "network.dns.disablePrefetch" = false;

    # WebRTC
    "media.peerconnection.ice.default_address_only" = true;

    # Geolocation
    "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";

    # Forms
    "signon.rememberSignons" = false;
    "signon.autofillForms" = false;
    "browser.formfill.enable" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.heuristics.enabled" = false;
    "signon.formlessCapture.enabled" = false;
    "network.auth.subresource-http-auth-allow" = 1;

    # Hardware acceleration
    "media.hardware-video-decoding.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.rdd-vpx.enabled" = true;
    "webgl.enable-debug-renderer-info" = false;
    "network.http.speculative-parallel-limit" = 0;

    # XDG portal
    "widget.use-xdg-desktop-portal.file-picker" = 1;

    # Network performance
    "network.http.pipelining" = true;
    "network.http.proxy.pipelining" = true;
    "network.http.pipelining.maxrequests" = 32;
    "network.http.max-connections" = 900;
    "network.http.max-persistent-connections-per-server" = 10;
    "network.http.max-persistent-connections-per-proxy" = 10;

    # Rendering
    "content.notify.interval" = 50;
    "content.notify.ontimer" = true;
    "content.interrupt.parsing" = true;
    "content.max.tokenizing.time" = 3000;
    "content.switch.threshold" = 250000;
    "nglayout.initialpaint.delay" = 0;
  };

  # Scroll tuning settings (touchpad/APZ)
  scrollTuningSettings = lib.optionalAttrs cfg.enableScrollTuning {
    "apz.gtk.kinetic_scroll.enabled" = true;
    "apz.gtk.kinetic_scroll.delta_mode" = 2;
    "apz.gtk.pangesture.delta_mode" = 2;
    "apz.gtk.kinetic_scroll.pixel_delta_mode_multiplier" = 20;
    "apz.gtk.pangesture.pixel_delta_mode_multiplier" = 20;
    "apz.gtk.touchpad_hold.enabled" = false;
    "general.smoothScroll" = true;
    "general.smoothScroll.msdPhysics.enabled" = true;
    "apz.fling_friction" = 0.012;
    "apz.fling_min_velocity_threshold" = 4.0;
    "apz.overscroll.enabled" = true;
    "layout.frame_rate.precise" = true;
  };

  # AI blocking settings
  aiBlockingSettings = lib.optionalAttrs cfg.enableAIBlocking {
    "browser.ai.control.default" = "blocked";
    "browser.ai.control.linkPreviewKeyPoints" = "blocked";
    "browser.ai.control.pdfjsAltText" = "blocked";
    "browser.ai.control.sidebarChatbot" = "blocked";
    "browser.ai.control.smartTabGroups" = "blocked";
    "browser.ai.control.translations" = "blocked";
    "browser.aiwindow.enabled" = false;
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.page" = false;
    "browser.ml.linkPreview.enabled" = false;
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.userEnabled" = false;
    "browser.translations.enable" = false;
    "extensions.ml.enabled" = false;
    "pdfjs.enableAltText" = false;
  };

  # Aggressive acceleration settings
  aggressiveAccelerationSettings = lib.optionalAttrs cfg.aggressiveAcceleration {
    "gfx.webrender.all" = true;
    "gfx.webgpu.ignore-blocklist" = true;
    "dom.webgpu.enabled" = true;
    "gfx.webrender.compositor" = true;
    "gfx.webrender.compositor.force-enabled" = true;
    "gfx.webrender.layer-compositor" = true;
    "gfx.webrender.precache-shaders" = true;
    "layers.force-active" = true;
    "layers.acceleration.disabled" = false;
    "layers.acceleration.force-enabled" = true;
    "gfx.canvas.accelerated" = true;
    "gfx.canvas.accelerated.aa-stroke.enabled" = true;
    "gfx.canvas.accelerated.async-present" = true;
    "gfx.canvas.accelerated.force-enabled" = true;
    "widget.wayland.opaque-region.enabled" = false;
    "widget.dmabuf.force-enabled" = true;
    "webgl.force-enabled" = true;
    "layers.offmainthreadcomposition.enabled" = true;
    "layers.offmainthreadcomposition.async-animations" = true;
    "layers.async-video.enabled" = true;
    "html5.offmainthread" = true;
  };

  # Base extensions shared by all users
  baseExtensions = {
    "addon@darkreader.org" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "uBlock0@raymondhill.net" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "wappalyzer@crunchlabz.com" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "{f6ca2dfb-43a6-4334-9fad-8d5a71a1fe67}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/simple-modify-header/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "simple-translate@sienori" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/simple-translate/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "{c3c10168-4186-445c-9c5b-63f12b8e2c87}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-editor/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "{f1423c11-a4e2-4709-a0f8-6d6a68c83d08}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/hacktools/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "default-compact-dark-theme@glitchii.github.io" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/default-compact-dark-theme/latest.xpi";
      installation_mode = "force_installed";
    };
    "plasma-browser-integration@kde.org" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/plasma-integration/latest.xpi";
      installation_mode = "force_installed";
    };
    "{ce25b613-ecd1-47e0-9492-c0260efb633c}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/google-sign-in-popup-blocker/latest.xpi";
      installation_mode = "force_installed";
    };
    "PwnFoxy@la1n23.lol" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/pwnfox/latest.xpi";
      installation_mode = "force_installed";
      default_area = "navbar";
    };
    "magnolia_limited_permissions@12.34" = {
      install_url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-4.2.3.0-custom.xpi";
      installation_mode = "force_installed";
    };
  };

  # Extra config for user.js
  baseExtraConfig = ''
    user_pref("remote.prefs.recommended", false);
    user_pref("browser.preferences.defaultPerformanceSettings.enabled", false);
    user_pref("gfx.use_text_smoothing_setting", true);
    user_pref("dom.ipc.processCount", ${toString cfg.processCount});
    user_pref("widget.wayland.fractional-scale.enabled", true);
    user_pref("browser.theme.content-theme", 0);
    user_pref("browser.theme.toolbar-theme", 0);
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    user_pref("full-screen-api.warning.timeout", 0);
    user_pref("apz.overscroll.enabled", true);
    user_pref("browser.shell.checkDefaultBrowser", false);
    user_pref("privacy.resistFingerprinting", false);
    user_pref("ui.systemUsesDarkTheme", 1);
    user_pref("browser.translations.automaticallyPopup", false);
    user_pref("browser.bookmarks.defaultLocation", "toolbar");
    user_pref("browser.toolbars.bookmarks.visibility", "always");
    user_pref("browser.tabs.loadBookmarksInTabs", true);
  '';

  scrollTuningExtraConfig = lib.optionalString cfg.enableScrollTuning ''
    user_pref("apz.gtk.kinetic_scroll.enabled", true);
    user_pref("apz.gtk.kinetic_scroll.delta_mode", 2);
    user_pref("apz.gtk.pangesture.delta_mode", 2);
    user_pref("apz.gtk.kinetic_scroll.pixel_delta_mode_multiplier", 20);
    user_pref("apz.gtk.pangesture.pixel_delta_mode_multiplier", 20);
    user_pref("apz.gtk.touchpad_hold.enabled", false);
    user_pref("general.smoothScroll", true);
  '';

  aggressiveExtraConfig = lib.optionalString cfg.aggressiveAcceleration ''
    user_pref("layers.acceleration.disabled", false);
    user_pref("layers.acceleration.force-enabled", true);
    user_pref("layers.force-active", true);
    user_pref("gfx.webrender.all", true);
    user_pref("gfx.webgpu.ignore-blocklist", true);
    user_pref("gfx.webrender.precache-shaders", true);
    user_pref("dom.webgpu.enabled", true);
    user_pref("gfx.webrender.compositor", true);
    user_pref("gfx.webrender.compositor.force-enabled", true);
    user_pref("gfx.webrender.layer-compositor", true);
    user_pref("widget.wayland.opaque-region.enabled", false);
    user_pref("media.hardware-video-decoding.enabled", true);
    user_pref("media.hardware-video-decoding.force-enabled", true);
    user_pref("media.ffmpeg.vaapi.enabled", true);
    user_pref("media.rdd-vpx.enabled", true);
  '';
in
{
  options.custom.firefox = {
    enable = lib.mkEnableOption "custom firefox configuration";

    profile = lib.mkOption {
      type = lib.types.enum [ "security" "streaming" ];
      default = "security";
      description = "Firefox profile type (security or streaming).";
    };

    dnsProvider = lib.mkOption {
      type = lib.types.enum [ "cloudflare" "mullvad" "none" ];
      default = "cloudflare";
      description = "DNS over HTTPS provider.";
    };

    processCount = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "DOM IPC process count.";
    };

    aggressiveAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable aggressive GPU acceleration (WebGPU, force-enabled layers, etc).";
    };

    enableScrollTuning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable touchpad/APZ scroll tuning.";
    };

    enableAIBlocking = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable Firefox AI features.";
    };

    extraExtensions = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "Additional extensions to install.";
    };

    bookmarks = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Bookmarks to add to the toolbar.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure profiles.ini is writable
    home.activation.ensureWritableFirefoxProfilesIni = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      set -euo pipefail
      ff_dir="$HOME/.mozilla/firefox"
      profiles_ini="$ff_dir/profiles.ini"

      mkdir -p "$ff_dir"

      if [ -L "$profiles_ini" ]; then
        tmp="$(mktemp)"
        cp -aL "$profiles_ini" "$tmp" || true
        rm -f "$profiles_ini"
        if [ -s "$tmp" ]; then
          cat "$tmp" > "$profiles_ini"
        else
          : > "$profiles_ini"
        fi
        rm -f "$tmp"
      fi

      if [ ! -s "$profiles_ini" ]; then
        cat > "$profiles_ini" <<EOF
      [General]
      Version=2
      StartWithLastProfile=1

      [Profile0]
      Name=${config.programs.firefox.profiles.redflake.name or "Red-Flake"}
      IsRelative=1
      Path=${config.programs.firefox.profiles.redflake.path or "redflake"}
      Default=1
      EOF
      fi

      chmod u+rw "$profiles_ini" || true
    '';

    # Fix profile directory
    home.activation.fixFirefoxProfileDir = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      profile_dir="$HOME/.mozilla/firefox/${config.programs.firefox.profiles.redflake.path or "redflake"}"
      if [ -e "$profile_dir" ] && [ ! -d "$profile_dir" ]; then
        backup="$profile_dir.hm-backup-$(date +%s)"
        echo "Home Manager: '$profile_dir' is not a directory; moving it to '$backup'..."
        mv "$profile_dir" "$backup"
      fi
    '';

    programs.firefox = {
      enable = true;
      languagePacks = [ "en-US" ];
      package = pkgs.firefox-bin;

      profiles.redflake = {
        id = 0;
        name = "Red-Flake";
        isDefault = true;
        path = "redflake";

        search = {
          default = "google";
          privateDefault = "google";
          force = true;
          order = [ "google" ];
          engines = {
            "google" = {
              urls = [{ template = "https://www.google.com/search?q={searchTerms}&hl=en"; }];
              icon = "https://www.google.com/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@go" ];
            };
          };
        };

        settings =
          baseSettings
          // scrollTuningSettings
          // aiBlockingSettings
          // aggressiveAccelerationSettings;

        extraConfig = baseExtraConfig + scrollTuningExtraConfig + aggressiveExtraConfig;

        bookmarks = {
          force = true;
          settings = [
            {
              name = "toolbar";
              toolbar = true;
              inherit (cfg) bookmarks;
            }
          ];
        };
      };

      policies = {
        # Updates & Background Services
        AppAutoUpdate = false;
        BackgroundAppUpdate = false;

        # Telemetry & Data Collection
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;

        # Disable useless features
        DisableMasterPasswordCreation = true;
        DisableProfileImport = true;
        DisableProfileRefresh = true;

        # Disable AI
        GenerativeAI = {
          Enabled = false;
          Chatbot = false;
          LinkPreviews = false;
          TabGroups = false;
          Translations = false;
          Locked = true;
        };

        # Nice to haves
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        HardwareAcceleration = true;
        DisplayMenuBar = "default-off";
        SearchBar = "unified";
        OfferToSaveLogins = false;

        # Certificates
        Certificates = {
          ImportEnterpriseRoots = true;
          Install = [ "/etc/ssl/certs/BurpSuiteCA.der" ];
        };

        # Extensions
        ExtensionSettings =
          baseExtensions
          // cfg.extraExtensions;
      };
    };
  };
}
