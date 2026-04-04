# Shared package sets for home-manager configurations
{ pkgs, pkgsUnstable, ... }:
{
  # Base packages that all users need
  base = with pkgs; [
    oh-my-zsh
    zsh-autosuggestions
    zsh-completions
    nix-zsh-completions
    zsh-syntax-highlighting
    zsh-powerlevel10k
    meslo-lgs-nf
    flatpak
    devenv
  ];

  # Desktop/GUI packages for workstation users
  desktop = with pkgs; [
    papirus-icon-theme
    bibata-cursors
    sweet-nova
    kdePackages.kpackage
  ];

  # Gaming-related packages
  gaming = with pkgs; [
    mangohud
    steam-run
    steamtinkerlaunch
    steam-rom-manager
    umu-launcher
    protonup-qt
    protonup-ng
    heroic
    # itch  # itch fails to build...
    ludusavi
    # Wine
    winetricks
    wineWow64Packages.waylandFull
    bottles
  ];

  # AI/Development tools
  # NOTE: claude-code temporarily commented out - removed from nixpkgs due to leak
  # https://github.com/NixOS/nixpkgs/pull/505911
  # Re-enable once 2.1.90+ lands in nixos-unstable
  development = with pkgsUnstable; [
    # claude-code
    opencode
    codex
    gemini-cli-bin
  ];

  # VPN and networking tools
  networking = with pkgs; [
    eduvpn-client
  ];
}
