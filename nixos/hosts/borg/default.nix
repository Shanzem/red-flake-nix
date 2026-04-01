# Borg host-specific configuration
{
  imports = [
    ./hardware.nix
    ./packages.nix
  ];

  # Standard sysctl profile for desktop with core dumps disabled
  custom.sysctl = {
    enable = true;
    profile = "standard";
    ramGB = 8;
    swappiness = 1;
    qdisc = "fq";
    disableCoreDumps = true;
  };
}
