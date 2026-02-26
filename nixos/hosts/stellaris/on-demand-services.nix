{ config, lib, ... }:
{
  # Keep these services installed/configured, but don't start them automatically.
  # Start them when needed via `sudo systemctl start <name>`.
  systemd.services = {
    #bloodhound-ce.wantedBy = lib.mkForce [ ];
    #neo4j.wantedBy = lib.mkForce [ ];
    #postgresql.wantedBy = lib.mkForce [ ];

    # do not start docker on bootup
    docker = lib.mkIf config.virtualisation.docker.enable {
      wantedBy = lib.mkForce [ ];
    };

    # do not start podman on bootup
    podman = lib.mkIf config.virtualisation.podman.enable {
      wantedBy = lib.mkForce [ ];
    };

    # do not start ollama on bootup
    ollama.wantedBy = lib.mkForce [ ];

    # do not start usbmuxd on bootup
    usbmuxd.wantedBy = lib.mkForce [ ];
  };

  # Docker is socket-activated by default on NixOS. If you want it truly "manual",
  # disable the socket too, otherwise any access to /run/docker.sock will start it.
  systemd.sockets.docker = lib.mkIf config.virtualisation.docker.enable {
    wantedBy = lib.mkForce [ ];
  };

  # Podman is socket-activated by default on NixOS. If you want it truly "manual",
  # disable the socket too, otherwise any access to /run/podman/podman.sock will start it.
  systemd.sockets.podman = lib.mkIf config.virtualisation.podman.enable {
    wantedBy = lib.mkForce [ ];
  };

  # Disable default fwupd-refresh.timer. We do this manually
  systemd.timers.fwupd-refresh.wantedBy = lib.mkForce [ ];

  # Disable default nh-clean.timer. We do this manually
  systemd.timers.nh-clean.wantedBy = lib.mkForce [ ];

  # Disable default podman-prune.timer. We do this manually
  systemd.timers.podman-prune.wantedBy = lib.mkForce [ ];
}
