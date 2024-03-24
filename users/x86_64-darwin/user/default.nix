{ pkgs, ... }: {
  home.username = "user";
  home.homeDirectory = "/Users/user";

  home.packages = with pkgs; [];

  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
}
