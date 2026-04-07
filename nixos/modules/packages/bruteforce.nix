{ pkgs
, ...
}:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ffuf
    feroxbuster
    gobuster
    kerbrute
    hashcat
    john
    jwtcrack
    thc-hydra
    ncrack
    python313Packages.dirsearch
    # python313Packages.patator # is marked as broken
    fcrackzip
    medusa
  ];
}
