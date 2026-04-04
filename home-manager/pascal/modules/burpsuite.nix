{ pkgs
, inputs
, ...
}: {
  programs.burp = {
    enable = true;
    proEdition = true;
    package = inputs.burpsuitepro.packages.${pkgs.stdenv.hostPlatform.system}.default;

    wordlists = {
      seclists = "${pkgs.seclists}/share/wordlists/seclists";
    };

    cliArgs = [
      "--suppress-jre-check"
      "--i-accept-the-license-agreement"
      "--disable-auto-update"
      "--disable-check-for-updates-dialog"
      "--temporary-project"
      "--unpause-spider-and-scanner"
    ];

    extensions = [
      # Loaded by default
      "403-bypasser"
      "json-web-tokens"
      "js-miner"
      "param-miner"
      "wsdler"

      # Installed but not loaded
      {
        package = "http-request-smuggler";
        loaded = false;
      }
    ];

    # Settings that are deep-merged into the default config
    settings = {
      display.user_interface = {
        # Enable Darkmode
        look_and_feel = "Dark";

        # Set UI font size to 16
        font_size = "16";
      };
      http_message_display = {
        # Set HTTP message display font to Monospace for better readability
        font_name = "Monospace";

        # Set HTTP message display font size to 20 for better readability
        font_size = "20";

        # Enable font smoothing
        font_smoothing = true;

        # Enable syntax highlighting for HTTP requests and responses
        highlight_requests = true;
        highlight_responses = true;

        # Pretty-print JSON and XML by default in the HTTP message viewer
        pretty_print_by_default = true;
      };
    };
  };
}
