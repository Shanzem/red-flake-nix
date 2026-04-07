# Parameterized vscode base module
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.custom.vscode;

  # Base extensions shared across all profiles
  baseExtensions = with pkgs.vscode-extensions; [
    # --- Nix / Environment ---
    mkhl.direnv # integrates direnv with VSCode
    bbenoist.nix # basic Nix language support
    jnoortheen.nix-ide # advanced Nix IDE features (linting, completion)

    # --- Code editing / navigation ---
    christian-kohler.path-intellisense # auto-complete file paths
    formulahendry.auto-rename-tag # auto-rename paired HTML/XML tags
    vscode-icons-team.vscode-icons # nice file icons
    mechatroner.rainbow-csv # colorize CSV columns
    catppuccin.catppuccin-vsc # Catppuccin theme
    catppuccin.catppuccin-vsc-icons # Catppuccin file icons
    esbenp.prettier-vscode # Prettier code formatter
    ms-vscode.hexeditor # Hex editor for binary files

    # --- Markdown / Docs ---
    yzhang.markdown-all-in-one # Markdown shortcuts, TOC, auto formatting
    davidanson.vscode-markdownlint # Linting for Markdown

    # --- Git / GitHub ---
    eamodio.gitlens # Git blame/history/insights
    github.vscode-pull-request-github # PR & issue integration with GitHub

    # --- Programming languages ---
    ms-vscode.cpptools # C/C++ IntelliSense & debugging
    ms-python.python # Python language support
    ms-python.vscode-pylance # Python analysis engine (fast autocomplete)
    tamasfe.even-better-toml # TOML syntax highlighting (Rust, configs)
    redhat.vscode-yaml # YAML validation & schema support
    ms-vscode.powershell # PowerShell language support

    # --- AI ---
    github.copilot # GitHub Copilot AI pair programmer
  ];

  # Base user settings shared across all profiles
  baseSettings = {
    "[nix]"."editor.tabSize" = 2;
    "nix.formatterPath" = "treefmt"; # set nix formatter to treefmt to match GitHub CI
    "editor.formatOnSave" = true;
    "workbench.colorTheme" = "Catppuccin Mocha";

    # disable telemetry
    "telemetry.telemetryLevel" = "off";
    "telemetry.feedback.enabled" = false;
    "gitlens.telemetry.enabled" = false;
    "redhat.telemetry.enabled" = false;
    "workbench.enableExperiments" = false;
  };

  # Build the package with optional overrides
  basePackage =
    if cfg.commandLineArgs != "" then
      pkgs.vscode.override { inherit (cfg) commandLineArgs; }
    else
      pkgs.vscode;

  finalPackage =
    if cfg.fixDuplicateIcon then
      basePackage.overrideAttrs
        (_finalAttrs: prevAttrs: {
          desktopItems = lib.map
            (item:
              if item.meta.name == "code-url-handler.desktop" then
                item.overrideAttrs
                  (_final: prev: {
                    text = lib.replaceStrings [ "StartupWMClass=Code\n" ] [ "" ] prev.text;
                  })
              else
                item
            )
            prevAttrs.desktopItems;
        })
    else
      basePackage;
in
{
  options.custom.vscode = {
    enable = lib.mkEnableOption "custom vscode configuration";

    commandLineArgs = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Extra command line arguments for VSCode.";
    };

    fixDuplicateIcon = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Fix duplicate VSCode icon in taskbar caused by code-url-handler.";
    };

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional VSCode extensions to install.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional user settings merged into the base settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = finalPackage;

      # disable mutable extensions
      mutableExtensionsDir = false;

      # set profiles
      profiles = {
        default = {
          # disable update check
          enableUpdateCheck = false;

          # disable extension update check
          enableExtensionUpdateCheck = false;

          # set extensions
          extensions = baseExtensions ++ cfg.extraExtensions;

          # set user settings
          userSettings = baseSettings // cfg.extraSettings;
        };
      };
    };
  };
}
