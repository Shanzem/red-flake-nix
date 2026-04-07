# Letgamer's vscode configuration
# Imports the shared base with development/server-focused settings
{ pkgs
, ...
}:
{
  imports = [ ../../shared/vscode-base.nix ];

  custom.vscode = {
    enable = true;

    extraExtensions = with pkgs.vscode-extensions; [
      oops418.nix-env-picker # select nix-env / nix-shell for projects
      oderwat.indent-rainbow # colorful indentation
      adpyke.codesnap # code screenshotter
      ibm.output-colorizer # log and output colorizer
      rust-lang.rust-analyzer # Rust support
      myriad-dreamin.tinymist # Typst Integration
      ms-azuretools.vscode-docker # Docker Extension
      ms-vscode-remote.remote-ssh # Remote SSH to my Server
    ];

    extraSettings = {
      "update.channel" = "none";
      "security.workspace.trust.enabled" = false;
      "remote.SSH.defaultExtensions" = [
        "ms-azuretools.vscode-docker"
        "oderwat.indent-rainbow"
      ];
    };
  };
}
