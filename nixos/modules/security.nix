_:

{
  # TPM2 Settings
  # Enable TPM2 Module
  security.tpm2.enable = true;

  # sudo settings
  security.sudo = {
    extraConfig = "Defaults lecture=never\nDefaults passwd_timeout=0\nDefaults insults";
  };

  # Polkit rules
  security.polkit.extraConfig = ''
    // Allow wheel users to suspend/hibernate without password
    // Workaround for SDDM Wayland not properly releasing seat on login
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.suspend" ||
           action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
           action.id == "org.freedesktop.login1.hibernate" ||
           action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
           action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });

    // Allow gamemode pkexec helpers (cpugovctl, gpuclockctl, procsysctl) without password
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec") {
        var program = action.lookup("program") || "";
        if (program.indexOf("gamemode") !== -1 &&
            (program.indexOf("cpugovctl") !== -1 ||
             program.indexOf("gpuclockctl") !== -1 ||
             program.indexOf("procsysctl") !== -1)) {
          return polkit.Result.YES;
        }
      }
    });
  '';

}
