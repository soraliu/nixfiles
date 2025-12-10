{ pkgs, unstablePkgs, ... }: {
  imports = [
    ./apps
  ];

  home.packages = (with pkgs; [
    tesseract
  ]) ++ (with unstablePkgs; [
  ]);

  home.sessionVariables = { };

  # 禁用 home-manager 自动安装应用，避免 App Management 权限问题
  targets.darwin.copyApps.enable = false;

  targets.darwin.currentHostDefaults."com.apple.controlcenter".BatteryShowPercentage = true;
}
