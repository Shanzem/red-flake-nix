{ config
, lib
, pkgs
, ...
}:

{
  # Keep the red-team DB stack running, but reduce its impact on desktop latency
  # by putting it into a low-weight slice + lowering CPU/IO priority.
  systemd.slices.db-background = {
    description = "Background database/services slice (desktop latency first)";
    sliceConfig = {
      CPUWeight = 25;
      IOWeight = 25;
    };
  };

  systemd.services.neo4j = lib.mkIf (config.services.neo4j.enable or false) {
    serviceConfig = {
      Slice = "db-background.slice";
      Nice = 10;
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
    };
  };

  systemd.services.postgresql = lib.mkIf (config.services.postgresql.enable or false) {
    serviceConfig = {
      Slice = "db-background.slice";
      Nice = 5;
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 7;
    };
  };

  systemd.services."bloodhound-ce" = lib.mkIf
    (
      (config.services ? "bloodhound-ce") && (config.services."bloodhound-ce".enable or false)
    )
    {
      serviceConfig = {
        Slice = "db-background.slice";
        Nice = 10;
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 7;
      };
    };

  # Enable ZRAM swap for better responsiveness
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 100; # Use up to 100% of RAM size for ZRAM (compressed)
    priority = 100; # Higher priority than disk swap
  };

  # NOTE: earlyoom is disabled in hardware.nix for this host
  # With 96GB RAM + 96GB ZRAM, 5% threshold is too aggressive

  # TuneD - Tuning Profile Delivery Mechanism for Linux
  # A modern replacement for PPD(power-profiles-daemon)
  services.tuned = {
    enable = true;
    settings = {
      dynamic_tuning = true;
      daemon = true;
      profile_dirs = "/etc/tuned/";
    };
    ppdSupport = true; # translation of power-profiles-daemon API calls to TuneD
    ppdSettings = {
      main.default = lib.mkForce "performance";
      # Map PPD profiles to TuneD profiles
      profiles.performance = "stellaris-performance";
      profiles.balanced = "balanced";
      profiles.power-saver = "powersave";
    };
  };

  # Custom tuned profile: latency-performance WITHOUT CPU frequency management
  # Lets uccd handle CPU scaling while tuned optimizes everything else
  environment.etc."tuned/stellaris-performance/tuned.conf".text = ''
    [main]
    summary=Optimized for Stellaris laptop - CPU freq managed by uccd
    include=latency-performance

    [cpu]
    # Disable CPU frequency management - let uccd handle it
    # Keep performance governor but don't lock min frequency
    governor=performance
    energy_perf_bias=performance
    # Explicitly unset min_perf_pct to let uccd control scaling
    min_perf_pct=
    max_perf_pct=100

    [sysctl]
    # Inherit from latency-performance but ensure good desktop responsiveness
    kernel.sched_min_granularity_ns=1000000
    kernel.sched_wakeup_granularity_ns=1500000
    kernel.sched_migration_cost_ns=500000
  '';

  environment.etc."tuned/active_profile".text = "stellaris-performance";
  systemd.services.tuned-set-profile = {
    description = "Set TuneD profile";
    after = [ "tuned.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.tuned}/bin/tuned-adm profile stellaris-performance";
    };
  };
  # DBus service that provides power management support to applications
  # Required by `tuned-ppd` for handling power supply changes
  services.upower.enable = true;

  # Ananicy-cpp: auto-prioritize processes (games high, background low)
  # Works well alongside scx - ananicy sets nice/ionice, scx handles scheduling
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    settings = {
      apply_nice = true;
    };
  };

  # Host-specific sched_ext configuration for Stellaris (Core Ultra 9 275HX + RTX 5070 Ti)
  services.scx = {
    enable = lib.mkForce true;

    # scx_bpfland: Best for desktop/KDE + occasional gaming
    # - Designed for interactive workloads and desktop responsiveness
    # - Handles hybrid P/E-core CPUs well
    # - More stable than LAVD
    scheduler = "scx_bpfland";

    # Low Latency mode: -m performance -w
    # Lowers latency at cost of throughput, good for desktop/gaming/audio
    extraArgs = [
      "-m"
      "performance"
      "-w" # Wake sync for lower latency
    ];
  };
}
