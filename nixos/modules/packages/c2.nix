{ pkgs, pkgsUnstable, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    sliver
    pkgsUnstable.penelope
  ];
}
