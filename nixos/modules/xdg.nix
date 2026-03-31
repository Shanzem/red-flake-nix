{ pkgs
, ...
}:

{
  # enable dconf
  # Fix GTK themes not applied in Wayland
  programs.dconf.enable = true;

  # enable XDG Desktop Menu specification
  xdg.menus.enable = true;

  # enable XDG autostart
  xdg.autostart.enable = true;

  # enable XDG icons
  xdg.icons.enable = true;

  # enable XDG sounds
  xdg.sounds.enable = true;

  # enable XDG terminal exec
  xdg.terminal-exec.enable = true;

  # XDG portal settings
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      # GTK portal needed for Settings interface (DPI, fonts) used by some GTK apps
      xdg-desktop-portal-gtk
    ];
    configPackages = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config = {
      # Portal config for KDE Plasma sessions
      # See: https://wiki.archlinux.org/title/XDG_Desktop_Portal
      common = {
        # Use KDE portal by default, fall back to GTK for interfaces KDE doesn't implement
        default = [ "kde" "gtk" ];
      };
    };
  };

  # Stub .desktop files for KDE services that don't ship them
  # Fixes "Failed to register with host portal: App info not found" errors
  # See: https://discuss.kde.org/t/failed-to-register-with-host-portal-qdbuserror-org-freedesktop-portal-error-failed/43117
  environment.systemPackages = [
    (pkgs.writeTextDir "share/applications/org.kde.ActivityManager.desktop" ''
      [Desktop Entry]
      Name=KDE Activity Manager
      Type=Application
      Exec=${pkgs.kdePackages.kactivitymanagerd}/libexec/kactivitymanagerd
      NoDisplay=true
    '')
    (pkgs.writeTextDir "share/applications/org.kde.ksmserver.desktop" ''
      [Desktop Entry]
      Name=KDE Session Manager
      Type=Application
      Exec=${pkgs.kdePackages.plasma-workspace}/bin/ksmserver
      NoDisplay=true
    '')
    (pkgs.writeTextDir "share/applications/org.kde.kded6.desktop" ''
      [Desktop Entry]
      Name=KDE Daemon
      Type=Application
      Exec=${pkgs.kdePackages.kded}/bin/kded6
      NoDisplay=true
    '')
    (pkgs.writeTextDir "share/applications/org.kde.gmenudbusmenuproxy.desktop" ''
      [Desktop Entry]
      Name=GMenu DBus Menu Proxy
      Type=Application
      Exec=${pkgs.kdePackages.plasma-workspace}/bin/gmenudbusmenuproxy
      NoDisplay=true
    '')
    (pkgs.writeTextDir "share/applications/org.kde.xembedsniproxy.desktop" ''
      [Desktop Entry]
      Name=XEmbed SNI Proxy
      Type=Application
      Exec=${pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy
      NoDisplay=true
    '')
    (pkgs.writeTextDir "share/applications/org.kde.org_kde_powerdevil.desktop" ''
      [Desktop Entry]
      Name=KDE Power Management
      Type=Application
      Exec=${pkgs.kdePackages.powerdevil}/libexec/org_kde_powerdevil
      NoDisplay=true
    '')
  ];

  # Ensure portal and application directories are linked
  environment.pathsToLink = [
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];
}
