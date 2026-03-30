# VPS host-specific services
# Most services are configured in nixos/modules/services.nix
# This file only contains VPS-specific overrides
_:
{
  # VPS typically doesn't need fwupd (no physical firmware to update)
  services.fwupd.enable = false;
}
