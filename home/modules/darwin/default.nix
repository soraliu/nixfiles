{ pkgs, unstablePkgs, ... }: {
  imports = [
    ./apps
  ];

  home.packages = (with pkgs; [
    tesseract
  ]) ++ (with unstablePkgs; [
  ]);

  home.sessionVariables = { };

  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
}
