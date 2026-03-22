{ pkgs, lib, ... }:
{
  # Initialize Metasploit database on first activation
  # msfdb manages its own embedded PostgreSQL on port 5433
  # Uses system PostgreSQL from /run/current-system/sw/bin to ensure version consistency
  home.activation.msfdbInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.msf4/db" ]; then
      export PATH="/run/current-system/sw/bin:$PATH"
      run ${pkgs.metasploit}/bin/msfdb init --use-defaults
    fi
  '';

  # Systemd user service to auto-start msfdb
  systemd.user.services.msfdb = {
    Unit = {
      Description = "Metasploit PostgreSQL Database";
      After = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = "PATH=/run/current-system/sw/bin";
      ExecStart = "${pkgs.metasploit}/bin/msfdb start";
      ExecStop = "${pkgs.metasploit}/bin/msfdb stop";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
