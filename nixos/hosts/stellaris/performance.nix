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

  # Enable earlyoom as a safety net to kill processes before the system hangs
  services.earlyoom = {
    enable = true;
    enableNotifications = true; # Notify the user when a process is killed
    freeMemThreshold = 5; # Kill processes if free memory drops below 5%
    freeSwapThreshold = 5; # Kill processes if free swap (ZRAM) drops below 5%
  };

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

  # Host-specific sched_ext configuration for Stellaris (Core Ultra 9 275HX + RTX 5070 Ti)
  services.scx = {
    enable = false; # Disabled for now due to issues with 100% CPU load on the LAVD scheduler

    # Workaround for https://github.com/NixOS/nixpkgs/issues/441768
    package = pkgs.scx.full.overrideAttrs (old: {
      postPatch = ''
        rm meson-scripts/fetch_bpftool meson-scripts/fetch_libbpf
        patchShebangs ./meson-scripts
        cp ${old.fetchBpftool} meson-scripts/fetch_bpftool
        cp ${old.fetchLibbpf} meson-scripts/fetch_libbpf
        substituteInPlace ./meson-scripts/build_bpftool \
          --replace-fail '/bin/bash' '${lib.getExe pkgs.bash}'
      '';
    });

    # Why choose LAVD on 275HX (P/E hybrid)?
    # - Prioritizes latency and frame-time stability for desktop + gaming (virtual-deadline, futex boost).
    # - Hybrid-aware with core compaction + energy model to prefer P-cores under interactive/mixed load.
    # - Good responsiveness under stress; we let TCC manage frequency to avoid policy conflicts.
    scheduler = "scx_lavd";

    # Let TCC/tccd own CPU frequency; LAVD handles scheduling and P-core preference
    extraArgs = [
      "--performance" # Keeps compaction; enables EM-based CPU preference (P-cores first)
      "--no-freq-scaling" # Avoid conflicts with TCC controlling governors/EPP
      "--slice-min-us"
      "250"
      "--slice-max-us"
      "3000"
      "--preempt-shift"
      "5"
    ];
  };
}
