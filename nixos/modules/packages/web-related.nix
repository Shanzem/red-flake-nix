{ inputs, pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    httrack
    updog
    (burpsuite.override { jdk = javaPackages.compiler.openjdk25; })
    inputs.burpsuitepro.packages.${system}.default
    zap
    xssstrike
    xsser
    xxeinjector
  ];
}
