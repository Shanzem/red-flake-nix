# Pascal's vscode configuration
# Imports the shared base with security-focused settings
{ lib
, pkgs
, ...
}:
{
  imports = [ ../../shared/vscode-base.nix ];

  custom.vscode = {
    enable = true;

    # fix issue with duplicate vscode icon in task bar due to code-url-handler
    # see: https://github.com/NixOS/nixpkgs/issues/391341#issuecomment-3016213912
    fixDuplicateIcon = true;

    extraExtensions = with pkgs.vscode-extensions; [
      arrterian.nix-env-selector # select nix-env / nix-shell for projects
      ms-python.black-formatter # Black formatter for Python
      dbaeumer.vscode-eslint # ESLint integration for JS/TS
      anthropic.claude-code # Claude Code AI integration
    ];

    extraSettings = {
      "update.mode" = "none";
      "update.showReleaseNotes" = false;
      "extensions.autoUpdate" = false;
      "extensions.ignoreRecommendations" = true;
      "nixEnvSelector.useFlakes" = true;
      "editor.smoothScrolling" = true;
      "editor.stablePeek" = true;
      "editor.tabCompletion" = "on";
      "editor.cursorBlinking" = "smooth";
      "editor.cursorSmoothCaretAnimation" = "on";
      "workbench.settings.alwaysShowAdvancedSettings" = true;
      "workbench.startupEditor" = "none";
      "workbench.preferredDarkColorTheme" = "Catppuccin Mocha";
      "workbench.tips.enabled" = false;
      "workbench.externalBrowser" = "firefox";
      "workbench.list.smoothScrolling" = true;
      "workbench.welcomePage.walkthroughs.openOnInstall" = false;
      "workbench.editor.enablePreviewFromCodeNavigation" = true;
      "workbench.editor.enablePreviewFromQuickOpen" = true;
      "window.restoreFullscreen" = true;
      "window.newWindowDimensions" = "maximized";
      "powershell.powerShellAdditionalExePaths"."Downloaded PowerShell" = lib.getExe pkgs.powershell;
      "powershell.powerShellAdditionalExePaths"."Built PowerShell" = lib.getExe pkgs.powershell;
      "powershell.promptToUpdatePowerShell" = false;
      "scm.alwaysShowActions" = true;
      "scm.alwaysShowRepositories" = true;
      "terminal.explorerKind" = "external";
      "terminal.external.linuxExec" = "ghostty +new-window";
      "telemetry.editStats.details.enabled" = false;
      "telemetry.editStats.enabled" = false;
      "telemetry.editStats.showDecorations" = false;
      "telemetry.editStats.showStatusBar" = false;
    };
  };
}
