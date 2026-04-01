# TUXEDO Stellaris host-specific configuration
{
  imports = [
    ./hardware.nix
    ./performance.nix
    ./avatar.nix
    ./gaming.nix
    ./nvidia.nix
    ./ollama.nix
    ./on-demand-services.nix
    ./packages.nix
  ];

  # Workstation sysctl profile with all optimizations enabled
  custom.sysctl = {
    enable = true;
    profile = "workstation";
    ramGB = 96;
    swappiness = 100; # High swappiness for ZRAM
    qdisc = "cake";
    enableZRAMOptimizations = true;
    enableGamingTweaks = true;
    enableTransparentHugepages = true;
    enableAdvancedNetworking = true;
    enableSecurityHardening = true;
  };
}
