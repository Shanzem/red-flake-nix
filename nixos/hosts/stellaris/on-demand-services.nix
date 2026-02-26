{ config, lib, ... }:
{
  # Keep these services installed/configured, but don't start them automatically.
  # Start them when needed via `sudo systemctl start <name>`.
  systemd.services = {
    #bloodhound-ce.wantedBy = lib.mkForce [ ];
    #neo4j.wantedBy = lib.mkForce [ ];
    #postgresql.wantedBy = lib.mkForce [ ];

    docker = lib.mkIf config.virtualisation.docker.enable {
      wantedBy = lib.mkForce [ ];
    };

    ollama.wantedBy = lib.mkForce [ ];
  };

  # Docker is socket-activated by default on NixOS. If you want it truly "manual",
  # disable the socket too, otherwise any access to /run/docker.sock will start it.
  systemd.sockets.docker = lib.mkIf config.virtualisation.docker.enable {
    wantedBy = lib.mkForce [ ];
  };
}
