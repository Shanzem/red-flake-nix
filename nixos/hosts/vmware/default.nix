# VMware host-specific configuration
{
  imports = [
    ./hardware.nix
  ];

  # Standard sysctl profile for VMs
  custom.sysctl = {
    enable = true;
    profile = "standard";
    ramGB = 8;
    swappiness = 1;
    qdisc = "fq";
  };
}
