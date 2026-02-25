{ pkgs
, ...
}:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cutter
    cutterPlugins.jsdec
    cutterPlugins.rz-ghidra
    ghidra-bin
    jadx
    radare2
    avalonia-ilspy
  ];

  programs.binary-ninja = {
    enable = true;
    package = pkgs.binary-ninja-free-wayland;
  };
}
