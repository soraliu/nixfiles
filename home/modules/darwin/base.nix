{ pkgs, unstablePkgs, ... }: {
  home.packages = (with pkgs; [
    tesseract
  ]) ++ (with unstablePkgs; [
  ]);

  home.sessionVariables = { };

  # Disable home-manager auto app installation to avoid App Management permission issues
  targets.darwin.copyApps.enable = false;

  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
}
