{ config
, lib
, pkgs
, inputs
, ...
}:
{
  # Override linux-firmware globally so enableAllFirmware uses our patched version
  # Also override tuxedo-drivers to fix compatibility with Linux 6.19+
  nixpkgs.overlays = [
    # Overlay 1: Update tuxedo-drivers to 4.21.2 for Linux 6.19 compatibility
    (final: prev: {
      linuxKernel = prev.linuxKernel // {
        packagesFor = kernel:
          (prev.linuxKernel.packagesFor kernel).extend (_: lpPrev: {
            tuxedo-drivers = lpPrev.tuxedo-drivers.overrideAttrs (_: {
              version = "4.21.2";
              src = final.fetchFromGitLab {
                group = "tuxedocomputers";
                owner = "development/packages";
                repo = "tuxedo-drivers";
                rev = "v4.21.2";
                hash = "sha256-KMn3O3Rq8LaZAgr6R7zNeBn637zZDFD2E2X+a3zKN3s=";
              };
              # v4.21.2 moved udev rules to files/usr/lib/udev/rules.d/
              postInstall = ''
                substituteInPlace files/usr/lib/udev/rules.d/* \
                  --replace-quiet "/bin/bash" "${final.lib.getExe final.bash}" \
                  --replace-quiet "/bin/sh" "${final.lib.getExe final.bash}"
                install -Dm 0644 -t $out/etc/udev/rules.d files/usr/lib/udev/rules.d/*
              '';
            });
          });
      };
    })
    # Overlay 2: Patch linux-firmware with correct GuC/HuC versions
    (final: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final.zstd ];
        postInstall = (oldAttrs.postInstall or "") + ''
          # Arrow Lake-HX Xe2: Override GuC firmware with specific version
          # The default linux-firmware may have a version that causes TLB invalidation timeouts.
          # This replaces the firmware BEFORE compression happens.
          #
          # Check DRM coredump for firmware version mismatches:
          #   sudo cat /sys/class/drm/card0/device/devcoredump/data | strings

          # GuC firmware for Meteor Lake / Arrow Lake Xe
          rm -f $out/lib/firmware/i915/mtl_guc_70.bin $out/lib/firmware/i915/mtl_guc_70.bin.zst 2>/dev/null || true
          cp ${final.fetchurl {
            url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/i915/mtl_guc_70.bin";
            sha256 = "sha256-d5Twtqvl/NnG9HA12v4hmfMKbn0jC9WlP7+ABaYOWRE="; # nix-prefetch-url "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/i915/mtl_guc_70.bin" | xargs nix hash to-sri --type sha256
          }} $out/lib/firmware/i915/mtl_guc_70.bin

          # HuC firmware for GT1 media (Firefox VAAPI)
          rm -f $out/lib/firmware/i915/mtl_huc_gsc.bin $out/lib/firmware/i915/mtl_huc_gsc.bin.zst 2>/dev/null || true
          cp ${final.fetchurl {
            url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/i915/mtl_huc_gsc.bin";
            sha256 = "sha256-PqI/OelGEi0URlZdGgfAhmvz48iBm0MTSSU3HYd8pM0="; # nix-prefetch-url "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/i915/mtl_huc_gsc.bin" | xargs nix hash to-sri --type sha256
          }} $out/lib/firmware/i915/mtl_huc_gsc.bin
        '';
      });
    })
  ];

  custom = {
    # set Kernel options
    kernel = {
      flavor = "cachyos";
      cachyos.variant = "latest";
      cachyos.target = "x86_64-v3";
    };

    # enable ZFS encryption
    zfs.encryption = true;

    # disable Intel OpenCL legacy runtime
    IntelComputeRuntimeLegacy.enable = false;

    # set display resolution to 1600p
    display.resolution = "1600p";

    # set bootloader resolution to 1080p or 1440p (Dark Matter GRUB Theme only supports these two resolutions)
    bootloader.resolution = "1440p";
  };

  nix.settings = {
    # Increase the number of parallel build jobs for Nix to 24
    max-jobs = lib.mkForce 24;

    # Enable system features for better performance based on the CPU features
    system-features = [
      "nixos-test"
      "benchmark"
      "kvm"
      "big-parallel"
      "gccarch-arrowlake"
      "gccarch-x86-64-v3"
    ];
  };

  boot = {
    initrd.availableKernelModules = [
      "zfs"
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
      "ahci"
    ];
    initrd.kernelModules = [
      "mei" # Make sure MEI is up before xe tries to talk to GSC
      "mei_me"
      "mei_gsc_proxy"
      "xe"
    ];
    blacklistedKernelModules = [
      "nouveau"
      "nvidiafb"
      "rivafb"
      #"i915" # don't blacklist i915. i915.force_probe=!7d67 already prevents i915 from binding to the iGPU
      "spd5118" # blacklist to avoid these issues: [  146.522972] spd5118 14-0050: Failed to write b = 0: -6    [  146.522974] spd5118 14-0050: PM: dpm_run_callback(): spd5118_resume [spd5118] returns -6     [  146.522978] spd5118 14-0050: PM: failed to resume async: error -6
    ];
    kernelModules = [
      "kvm-intel"
      "msr" # /dev/cpu/CPUNUM/msr provides an interface to read and write the model-specific registers (MSRs) of an x86 CPU
      "tuxedo_keyboard"
      "tuxedo_io"
      "efi_pstore" # EFI-based pstore backend for crash logs (uses UEFI variables)
      "ramoops" # RAM-based oops/panic logger (fallback)
      "netconsole" # Network console for remote kernel log capture
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      tuxedo-drivers # TUXEDO-specific drivers
      r8125 # Realtek 2.5GbE Ethernet driver
    ];

    # TUXEDO-specific: kernel parameters
    kernelParams = [
      # ACPI / keyboard
      "acpi_enforce_resources=lax" # Allow legacy driver access to ACPI resources; fixes non-compliant SW_LID implementations on some laptops

      # Modern standby / suspend
      "mem_sleep_default=s2idle" # Use s2idle (a.k.a. S0ix / modern standby) instead of deep (S3); Core Ultra CPUs don’t support S3
      # See: https://www.tuxedocomputers.com/en/Power-management-with-suspend-for-current-hardware.tuxedo

      # Intel Xe / i915 binding for Meteor Lake / Arrow Lake
      "i915.force_probe=!7d67" # Prevent old i915 driver from binding this GPU
      "xe.force_probe=7d67" # Force the new xe driver to bind the Meteor Lake device (PCI ID 7d67)

      # Intel i915: Disable Display Power Savings
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_dc=0"

      # Intel Xe: Quiet the FBC/PSR noise / flicker; Disable xe DC states
      "xe.enable_fbc=0"
      "xe.enable_psr=0"
      "xe.enable_dc=0"
      #"xe.enable_sagv=0" # Disable SAGV (System Agent voltage/frequency scaling) for stability

      # Intel Xe (i915): Load GuC + HuC
      # Force Xe driver to load GuC + HuC (bitmask: 1=GuC submission, 2=HuC → 3=both)
      #"xe.guc_load=3"
      "i915.enable_guc=3" # Same bitmask (GuC+HuC)

      # Intel Xe: Quiet GuC firmware logs
      #"xe.guc_log_level=0"

      # Intel Xe: Disable verbose HW state warnings (hides non-fatal TLB WARN_ON)
      #"xe.verbose_state_checks=0"

      # Intel Xe: Keep the driver default wedged policy (avoids kernel taint from wedged_mode=0)

      # Quiet Intel Xe DRM debug kernel log spam (TLB/PHY refclk issues...)
      #"drm.debug=0x0"

      # Workarounds for Intel `xe` TLB invalidation fence timeouts / PHY refclk hiccups.
      # DMC wakelock: prevent Display Microcontroller power state races that cause TLB timeouts
      "xe.enable_dmc_wl=1"
      # Disable SAGV (System Agent voltage/frequency scaling) for stability.
      "xe.enable_sagv=0"
      # Enable DMC flip queue for better atomic commit coordination (may reduce "Device or resource busy" errors)
      "xe.enable_flipq=1"
      # Disable Panel Replay / PSR2 selective fetch. Some panels/firmware combos misbehave here.
      "xe.enable_panel_replay=0"
      "xe.enable_psr2_sel_fetch=0"
      "xe.psr_safest_params=1"
      # Let the driver manage display power wells automatically.
      # Previously had xe.disable_power_well=0 to keep them on, but this can cause
      # PHY refclk state inconsistencies during suspend/resume.

      # === GPU DEBUG OPTIONS ===
      # DRM debug logging (bitmask: 0x1=core, 0x2=driver, 0x4=kms, 0x10=atomic, 0x100=lease, 0x200=vbl)
      # 0x0 = disabled (default), 0x6 = DRIVER + KMS for debugging
      "drm.debug=0x0"

      # Intel Xe GuC firmware debug logging (0=off, 1-4=increasing verbosity)
      "xe.guc_log_level=0"

      # Kernel log buffer (2MB is enough for reduced logging)
      "log_buf_len=2M"

      # Intel Hybrid perf
      "intel_pstate=passive" # Let userspace (TUXEDO Control Center / TLP) manage P-states for Intel hybrid CPUs

      # Select full kernel preemption via PREEMPT_DYNAMIC: lets higher‑prio tasks preempt most kernel code -> lower latency/better interactivity, small throughput/overhead cost.
      "preempt=full"

      # Prefer THP madvise for desktop/gaming workloads.
      "transparent_hugepage=madvise"

      # Disable split lock detection - some games/apps trigger split locks causing micro-stutter
      "split_lock_detect=off"

      # Let the kernel select the default CPUIdle governor (typically `menu` on tickless systems).
      #"cpuidle.governor=teo"

      # PCIe ASPM: prioritize latency over power saving.
      # Monitor S0ix (s2idle) suspend power draw/residency; disabling ASPM can increase sleep drain on some laptops.
      "pcie_aspm.policy=performance"

      # NVMe: Force PS0-only (disable APST sleep states) for zero-latency IO
      # Eliminates 10-100ms runtime stalls from NVMe power wakeup → fixes IO PSI spikes & desktop "stickiness"
      # Power cost: ~0.5-1W idle
      # Does not affect suspend/lid-close (S0ix/S3 uses separate shutdown sequence)
      "nvme_core.default_ps_max_latency_us=0"

      # Boot / quiet
      "quiet"
      "splash"

      # Watchdog: enabled for detecting hard lockups (Intel iTCO watchdog)
      # NMI watchdog fires on hard CPU lockups; iTCO_wdt handles system-wide hangs
      # Watchdog timeout is configured via systemd-watchdog (default 10s)

      # Security mitigations off for performance (use only on trusted single-user systems)
      "mitigations=off"

      # AHCI: skip staggered spin-up for faster boot
      "libahci.ignore_sss=1"

      # Enable SysRq key for debugging/recovery
      "sysrq_always_enabled=1"

      # Disable audit subsystem
      "audit=0"

      # Classic network interface naming (eth0, wlan0)
      "net.ifnames=0"
      "biosdevname=0"

      # Timer/clock optimizations
      "tsc=reliable"
      "clocksource=tsc"

      # Workqueue: disable power-efficient mode for lower latency
      "workqueue.power_efficient=0"

      # RCU: expedited grace periods for faster synchronization
      "rcupdate.rcu_expedited=1"
    ];

    # --- extra kernel module options (goes into /etc/modprobe.d/nixos.conf) ---#
    # Keep this minimal: ONLY 'options' lines and no stray prose (avoid multi-line comment blocks that might confuse parsing).
    extraModprobeConfig = ''
      # Make sure MEI is up before xe tries to talk to GSC
      softdep xe pre: mei_gsc_proxy mei_me mei

      # NOTE: xe does not support i915-style guc_load/enable_guc toggles.
      # Keeping driver defaults; see `modinfo -p xe` for available parameters.

      # Virtualization
      options kvm_intel nested=1

      # Wi-Fi / power
      options iwlmvm power_scheme=1
      options iwlwifi power_save=0 uapsd_disable=1

      # Ramoops: RAM-based crash logger (fallback if EFI pstore unavailable)
      # Increased buffer sizes for verbose debug logging (8MB total)
      options ramoops mem_size=8388608 console_size=4194304 pmsg_size=1048576 ftrace_size=1048576

      # Netconsole: Send kernel logs over network for real-time capture
      # Configure at runtime with: modprobe netconsole netconsole=@/wlan0,6666@<RECEIVER_IP>/
      # Or use the systemd service below for dynamic configuration

      # TUXEDO keyboard module: set these as module options (NOT kernel cmdline)
      options tuxedo_keyboard kbd_backlight_mode=0

      # ZFS ARC tuning for 96GB RAM
      # Cap ARC at 16GB to leave ~80GB for apps/games (default would use ~48GB)
      options zfs zfs_arc_max=17179869184
    '';
  };

  # Pstore/ramoops: Capture kernel crash logs across reboots
  # Logs are stored in /sys/fs/pstore/ after a crash
  fileSystems."/sys/fs/pstore" = {
    device = "pstore";
    fsType = "pstore";
    options = [ "defaults" ];
  };

  # Systemd service to archive pstore crash logs on boot
  systemd.services.pstore-archive = {
    description = "Archive pstore crash logs";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "pstore-archive" ''
        PSTORE_DIR="/sys/fs/pstore"
        ARCHIVE_DIR="/var/log/pstore"

        # Create archive directory if it doesn't exist
        mkdir -p "$ARCHIVE_DIR"

        # Check if there are any files to archive
        if [ -n "$(ls -A $PSTORE_DIR 2>/dev/null)" ]; then
          TIMESTAMP=$(date +%Y%m%d-%H%M%S)
          CRASH_DIR="$ARCHIVE_DIR/$TIMESTAMP"
          mkdir -p "$CRASH_DIR"

          # Copy all pstore files to archive
          cp -a "$PSTORE_DIR"/* "$CRASH_DIR"/ 2>/dev/null || true

          # Clear pstore after archiving
          for f in "$PSTORE_DIR"/*; do
            [ -e "$f" ] && rm -f "$f" 2>/dev/null || true
          done

          echo "Archived pstore crash logs to $CRASH_DIR"
        fi
      '';
    };
  };

  # Netconsole: Real-time kernel log streaming over network
  # Usage: On receiver machine, run: nc -u -l -p 6666
  # Then on this machine: sudo systemctl start netconsole@<RECEIVER_IP>
  # Example: sudo systemctl start netconsole@192.168.1.100
  systemd.services."netconsole@" = {
    description = "Netconsole kernel log streaming to %i";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "netconsole-start" ''
        TARGET_IP="$1"
        # Find default interface and local IP
        IFACE=$(${pkgs.iproute2}/bin/ip route get "$TARGET_IP" | ${pkgs.gawk}/bin/awk '/dev/ {print $5; exit}')
        LOCAL_IP=$(${pkgs.iproute2}/bin/ip route get "$TARGET_IP" | ${pkgs.gawk}/bin/awk '/src/ {print $7; exit}')
        # Get target MAC (send a ping first to populate ARP cache)
        ${pkgs.iputils}/bin/ping -c1 -W1 "$TARGET_IP" >/dev/null 2>&1 || true
        TARGET_MAC=$(${pkgs.iproute2}/bin/ip neigh show "$TARGET_IP" | ${pkgs.gawk}/bin/awk '{print $5; exit}')
        [ -z "$TARGET_MAC" ] && TARGET_MAC="ff:ff:ff:ff:ff:ff"

        # Configure netconsole dynamically via configfs
        NETCON_DIR="/sys/kernel/config/netconsole/target1"
        mkdir -p "$NETCON_DIR"
        echo "$IFACE" > "$NETCON_DIR/dev_name"
        echo "$LOCAL_IP" > "$NETCON_DIR/local_ip"
        echo 6665 > "$NETCON_DIR/local_port"
        echo "$TARGET_IP" > "$NETCON_DIR/remote_ip"
        echo 6666 > "$NETCON_DIR/remote_port"
        echo "$TARGET_MAC" > "$NETCON_DIR/remote_mac"
        echo 1 > "$NETCON_DIR/enabled"
        echo "Netconsole streaming to $TARGET_IP:6666 via $IFACE ($LOCAL_IP)"
      '' + " %i";
      ExecStop = pkgs.writeShellScript "netconsole-stop" ''
        NETCON_DIR="/sys/kernel/config/netconsole/target1"
        [ -d "$NETCON_DIR" ] && {
          echo 0 > "$NETCON_DIR/enabled" 2>/dev/null || true
          rmdir "$NETCON_DIR" 2>/dev/null || true
        }
      '';
    };
  };

  # Mount configfs for dynamic netconsole configuration
  fileSystems."/sys/kernel/config" = {
    device = "configfs";
    fsType = "configfs";
    options = [ "defaults" ];
  };

  hardware = {
    # enable firmware with a license allowing redistribution
    enableRedistributableFirmware = lib.mkForce true;

    # enable all firmware regardless of license
    enableAllFirmware = lib.mkForce true;

    # Firmware is overridden via nixpkgs.overlays at the top of this file
    # This ensures enableAllFirmware uses our patched linux-firmware with correct GuC version

    # enable CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkForce true;

    # Enable general graphics acceleration (required for hybrid setups)
    graphics = {
      enable = true;
      enable32Bit = true; # For Steam and other 32-bit apps
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vpl-gpu-rt # For Intel QSV (Quick Sync Video)
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
      ];
    };

    # Enable Bluetooth
    bluetooth.enable = true;

    # TUXEDO-specific: drivers, Keyboard lighting and fan control (from nixpkgs)
    tuxedo-drivers.enable = true;
    tuxedo-rs = {
      # Important: disable tuxedo-rs and tailor-gui to avoid conflict with tuxedo-drivers and tuxedo-control-center
      enable = lib.mkForce false;
      tailor-gui.enable = lib.mkForce false; # GUI for TUXEDO Control Center equivalent
    };
    tuxedo-control-center = {
      enable = false; # Disable original TUXEDO Control Center via tuxedo-nixos
      package = inputs.tuxedo-nixos.packages.x86_64-linux.default;
    };
  };

  # Intel Xe suspend preparation: ensure DRM operations complete before suspend
  # This prevents KWin from getting stuck in drm_open during the freeze phase
  # when the Xe driver has pending PHY/refclk operations
  systemd.services.xe-suspend-prep = {
    description = "Prepare Intel Xe GPU for suspend";
    before = [ "systemd-suspend.service" "systemd-hibernate.service" ];
    wantedBy = [ "suspend.target" "hibernate.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "xe-suspend-prep" ''
        # Sync filesystem to ensure no pending IO
        sync
        # Brief delay to let Xe driver complete any pending PHY/display operations
        # This helps avoid the "PHY A failed to request refclk" race during suspend
        sleep 1
      '';
    };
  };

  # SDDM startup: wait for DRM GPU drivers to fully initialize
  # This works around the race condition where SDDM starts before xe driver is ready
  # See: https://github.com/sddm/sddm/issues/1917
  systemd.services.display-manager = {
    after = [ "systemd-udev-settle.service" ];
    wants = [ "systemd-udev-settle.service" ];
  };

  # Use Wayland SDDM with kwin_wayland compositor
  # X11 mode has NixOS module bugs (empty CompositorCommand causes sddm-helper-start-wayland crash)
  # Force Intel GPU for the greeter to avoid NVIDIA issues
  services.displayManager.sddm.wayland.enable = lib.mkForce true;

  # SDDM X11 mode requires xserver to be enabled
  # Use Intel iGPU only for X11 - NVIDIA nouveau is blacklisted so modesetting fails on dGPU
  services.xserver.enable = true;
  services.xserver.deviceSection = ''
    BusID "PCI:0:2:0"
  '';

  # Prevent X from auto-adding the NVIDIA GPU as a secondary screen
  # Without this, modesetting auto-probes nvidia-drm and fails because glamor
  # tries to use Mesa's nouveau driver which doesn't work with nvidia kernel module
  services.xserver.serverFlagsSection = ''
    Option "AutoAddGPU" "false"
  '';

  # Systemd hardware watchdog: automatically reboot on hard lockups
  # Intel iTCO watchdog will reset the system if systemd fails to ping it
  systemd.settings.Manager = {
    # Hardware watchdog timeout (seconds) - system reboots if no ping within this time
    RuntimeWatchdogSec = "30";
    # Reboot watchdog - ensure clean reboot completes within this time
    RebootWatchdogSec = "10min";
    # Shutdown watchdog - ensure clean shutdown completes within this time
    ShutdownWatchdogSec = "10min";
  };

  # Enable Uniwill Control Center
  # https://github.com/nanomatters/ucc
  services.uccd = {
    enable = true;
  };

  # Fix TCC service missing commands
  #systemd.services.tccd = {
  # Add missing utilities to PATH for TCC to work properly
  #  path = with pkgs; [
  #    toybox # provides 'users', 'cat', etc.
  #    util-linux # provides additional system utilities
  #    procps # provides process utilities
  #  ];
  #};

  # Fix tccd-sleep.service: upstream has broken ExecStart/ExecStop with quoted commands
  #systemd.services.tccd-sleep = {
  #  serviceConfig = {
  #    ExecStart = lib.mkForce "${pkgs.systemd}/bin/systemctl stop tccd";
  #    ExecStop = lib.mkForce "${pkgs.systemd}/bin/systemctl start tccd";
  #  };
  #};

  services.xserver = {
    # For Wayland (KDE), prevent kwin_wayland from using NVIDIA by default.
    # This forces it to use Intel instead, which is more stable and power-efficient
    displayManager.sessionCommands = ''
      export LIBVA_DRIVER_NAME=iHD
      export VDPAU_DRIVER=va_gl
      export MESA_LOADER_DRIVER_OVERRIDE=iris
      export __GLX_VENDOR_LIBRARY_NAME=mesa
      export ANV_ENABLE_PIPELINE_CACHE=1
      export NIXOS_OZONE_WL=1

      # Don't set PRIME/NVIDIA variables globally - let apps default to Intel
      # Steam and other apps can override these as needed
    '';

    # Enable Intel & NVIDIA driver in XServer
    videoDrivers = [
      "modesetting"
      "nvidia"
    ];

    # Set DPI to 147
    dpi = 147; # Stellaris 16 2560x1600 ~188PPI logical 147 @150%
  };

  services.thermald.enable = lib.mkForce false; # Thermal management

  services.auto-cpufreq.enable = lib.mkForce false; # Disable if using TLP / TCCD / UCCD

  # Make sure nothing else fights TLP
  # default is `on` on Gnome / KDE, and prevents using tlp:
  # https://discourse.nixos.org/t/cant-enable-tlp-when-upgrading-to-21-05/13435
  services.power-profiles-daemon.enable = lib.mkForce false;

  powerManagement = {
    enable = lib.mkForce true;
    powertop.enable = lib.mkForce false;
  };

  # On hybrid CPUs (P/E-cores), irqbalance can be a win or a loss depending on workload/power goals.
  # Keep it off by default for laptop power behavior, but make it easy to A/B test via a specialisation.
  services.irqbalance.enable = lib.mkDefault false;

  # Disable earlyoom on this machine. earlyoom kills at 5% RAM/ZRAM—too aggressive for 96GB + zram100%.
  services.earlyoom = {
    enable = lib.mkForce false;
  };

  # Enable the usbmuxd ("USB multiplexing daemon") service. This daemon is in charge of multiplexing connections over USB to an iOS device.
  services.usbmuxd.enable = true;

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Force intel-media-driver; Quick Sync decode/encode
    VDPAU_DRIVER = "va_gl"; # Forces Intel via VAAPI; VDPAU → VAAPI fallback
    MESA_LOADER_DRIVER_OVERRIDE = "iris"; # Xe OpenGL/Vulkan (not anv; iris=Gen12+)
    __GLX_VENDOR_LIBRARY_NAME = "mesa"; # Mesa GLX (avoid Nouveau/NVIDIA proprietary)
    ANV_ENABLE_PIPELINE_CACHE = "1"; # Enable Vulkan pipeline caching; Vulkan cache speedup
    NIXOS_OZONE_WL = "1"; # Hint Electron/Chromium apps to use Wayland natively
    # mesa_glthread = "true"; # Disabled: causes KWin CPU spikes with Intel Xe driver
    # Don't set PRIME/NVIDIA variables globally - let apps default to Intel
    # Steam and other apps can override these as needed

    # KWin Wayland fixes for Intel Xe (Arrow Lake)
    # https://bugs.kde.org/show_bug.cgi?id=513296
    # Increase safety margin to give Xe driver more time for atomic commits (default 1000µs)
    # Higher value = more latency but fewer "Device or resource busy" errors
    #KWIN_DRM_OVERRIDE_SAFETY_MARGIN = "3000";
    # Silence "atomic commit failed: Device or resource busy" warnings from kwin_drm
    # These are non-fatal retries that spam the journal; the actual commits succeed on retry
    QT_LOGGING_RULES = "kwin_drm.warning=false";
    #KWIN_DRM_NO_AMS = "1"; # Disable Atomic Mode Setting entirely; DISABLED: causes slow kwin rendering
    # Force software cursor to avoid hardware cursor plane atomic commits
    #KWIN_FORCE_SW_CURSOR = "1";
    # NOTE: KWIN_DRM_DEVICES is ':'-separated; don't use /dev/dri/by-path/* (they contain ':' in the PCI address).
    # Intel iGPU (0000:00:02.0) first, NVIDIA dGPU (0000:02:00.0) second.
    KWIN_DRM_DEVICES = "/dev/dri/card-intel:/dev/dri/card-nvidia";
  };

  # HiDPI fixes => https://github.com/NixOS/nixos-hardware/blob/3f7d0bca003eac1a1a7f4659bbab9c8f8c2a0958/common/hidpi.nix
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
  console.earlySetup = lib.mkDefault true;

  # Host-specific udev rules for NVMe optimization
  services.udev.extraRules = lib.mkAfter ''
    # Disable Thunderbolt wakeup to prevent spurious S0ix wakes (GPE46)
    # TB4 USB Controller and NHI
    ACTION=="add|change", SUBSYSTEM=="pci", KERNEL=="0000:00:0d.0", ATTR{power/wakeup}="disabled"
    ACTION=="add|change", SUBSYSTEM=="pci", KERNEL=="0000:00:0d.2", ATTR{power/wakeup}="disabled"
    # TB4 PCIe Root Ports
    ACTION=="add|change", SUBSYSTEM=="pci", KERNEL=="0000:00:07.0", ATTR{power/wakeup}="disabled"
    ACTION=="add|change", SUBSYSTEM=="pci", KERNEL=="0000:00:07.1", ATTR{power/wakeup}="disabled"

    # Stable DRM symlinks for KWin/SDDM Wayland (avoid ':' in names; KWIN_DRM_DEVICES uses ':' as a separator)
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/card-intel"
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:02:00.0", SYMLINK+="dri/card-nvidia"

    # All NVMe SSDs: Kyber + low-latency for smooth UI/gaming (9100 Pro optimized)
    ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme*n*", ENV{DEVTYPE}=="disk", \
      ATTR{queue/scheduler}="kyber", \
      ATTR{queue/nr_requests}="32", \
      ATTR{queue/rq_affinity}="2", \
      ATTR{queue/iosched/read_lat_nsec}="2000000", \
      ATTR{queue/iosched/write_lat_nsec}="10000000", \
      ATTR{queue/read_ahead_kb}="128"

    # ZFS partitions on NVMe: Re-apply parent settings (handles pool changes)
    ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="nvme*n*p*", ENV{ID_FS_TYPE}=="zfs_member", \
      ATTR{../queue/scheduler}="kyber", \
      ATTR{../queue/nr_requests}="32", \
      ATTR{../queue/rq_affinity}="2", \
      ATTR{../queue/iosched/read_lat_nsec}="2000000", \
      ATTR{../queue/iosched/write_lat_nsec}="10000000", \
      ATTR{../queue/read_ahead_kb}="128"

    # Samsung NVMe: Extra iomem relaxation (Gen5 perf boost)
    ACTION=="add|change", SUBSYSTEM=="nvme", ATTR{vendor}=="0x144d", ATTR{model}=="Samsung SSD 9100 PRO*", \
      ATTR{device/iomem_policy}="relaxed"
  '';
}
