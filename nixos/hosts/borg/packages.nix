{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    obsidian
    google-chrome
    (hashcat.override { rocmSupport = true; })
  ];
}
