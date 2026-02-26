{ config
, lib
, pkgs
, ...
}:

{
  # NetworkManager
  networking.networkmanager = {
    enable = true;

    wifi = {
      backend = "iwd";
      powersave = false;
    };

    # Dynamically set NTP servers received via DHCP (systemd-timesyncd).
    # Debug: `sudo journalctl -u NetworkManager-dispatcher -e`
    dispatcherScripts = [
      {
        source = pkgs.writeText "10-update-timesyncd" ''
          [ -z "$CONNECTION_UUID" ] && exit 0
          INTERFACE="$1"
          ACTION="$2"

          case "$ACTION" in
            up|dhcp4-change|dhcp6-change)
              systemctl restart systemd-timesyncd.service
              if [ -n "$DHCP4_NTP_SERVERS" ]; then
                echo "Will add the ntp server $DHCP4_NTP_SERVERS"
              else
                echo "No DHCP4 NTP available."
                exit 0
              fi

              mkdir -p /etc/systemd/timesyncd.conf.d
              echo "[Time]" > "/etc/systemd/timesyncd.conf.d/''${CONNECTION_UUID}.conf"
              echo "NTP=$DHCP4_NTP_SERVERS" >> "/etc/systemd/timesyncd.conf.d/''${CONNECTION_UUID}.conf"
              systemctl restart systemd-timesyncd.service
              ;;

            down)
              rm -f "/etc/systemd/timesyncd.conf.d/''${CONNECTION_UUID}.conf"
              systemctl restart systemd-timesyncd.service
              ;;
          esac

          echo "Done!"
        '';
      }
    ];
  };

  # Let NetworkManager manage DHCP; avoid enabling dhcpcd (it can end up on the boot critical path).
  networking.useDHCP = lib.mkForce false;
  networking.dhcpcd.enable = lib.mkForce false;

  # Wi-Fi via iwd (used by NetworkManager when `networkmanager.wifi.backend = "iwd"`).
  networking.wireless.iwd = {
    enable = true;
    settings = {
      Network.EnableIPv6 = true;
      Settings.AutoConnect = true;
      DriverQuirks.PowerSaveDisable = "*";
    };
  };

  # Expose ports to the network (useful for smbserver/responder/http.server, etc.).
  networking.firewall.enable = false;
  networking.nftables.enable = false;

  # If dhcpcd is enabled elsewhere, avoid a full 1m30 shutdown delay if it hangs while stopping.
  systemd.services = lib.mkIf config.networking.dhcpcd.enable {
    dhcpcd.serviceConfig.TimeoutStopSec = "5s";
  };
}
