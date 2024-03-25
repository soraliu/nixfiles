{ pkgs, ... }: {
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";


  home.packages = with pkgs; [];

  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
}
