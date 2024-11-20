{ pkgs, ... }: {
  imports = [
    ./apps
  ];

  home.packages = with pkgs; [
  ];

  home.sessionVariables = { };

  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
}
