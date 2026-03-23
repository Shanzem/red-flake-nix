_:
{
  services = {
    kdeconnect.enable = true; # enable KDE Connect
    ssh-agent.enable = true; # enable SSH Agent
    udiskie.enable = true; # Automount - make sure your user is in the disk group
  };

  # Fix KDE Connect "Failed to send mDNS query" errors at startup
  # KDE Connect starts before network is fully configured; delay its start
  systemd.user.services.kdeconnect = {
    Unit = {
      After = [ "graphical-session.target" "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      # Add a small delay to ensure network interfaces have IP addresses assigned
      ExecStartPre = "/run/current-system/sw/bin/sleep 5";
    };
  };

  # Fix drkonqi-coredump-pickup.service timeout
  # This KDE crash handler service times out if there are no coredumps to process
  # Increase the timeout to prevent the "Failed with result 'timeout'" error
  systemd.user.services.drkonqi-coredump-pickup = {
    Service = {
      TimeoutStartSec = "5min";
    };
  };
}
