# VPS host-specific configuration
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./packages.nix
    ./services.nix
  ];

  # Standard sysctl profile for VPS with core dumps disabled
  custom.sysctl = {
    enable = true;
    profile = "standard";
    ramGB = 8;
    swappiness = 1;
    qdisc = "fq";
    disableCoreDumps = true;
  };
}
