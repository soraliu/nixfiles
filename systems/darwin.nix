{ unstablePkgs, homeUser, ... }: {
  imports = [
    ./darwin-activation.nix
    ../pkgs/nix-store/optimise.nix
    # Determinate Nix 3.x: lazy-trees + parallel-eval + customSettings
    # trusted-users / extra-sandbox-paths / community cache 等已迁入此模块
    ../pkgs/determinate
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  # 注: trusted-users / experimental-features 已迁到 pkgs/determinate 的 customSettings
  # determinateNix.enable = true 会自动设置 nix.enable = false, nix.settings.* 不再起作用
  nixpkgs.config.allowUnfree = true;

  # system.primaryUser for activation scripts that need user context
  system.primaryUser = homeUser;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "right";
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  system.defaults.NSGlobalDomain.InitialKeyRepeat = 12;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;

  # 「自动切换到文稿的输入法」的底层键：每个输入上下文记忆各自输入源，
  # 否则浏览器等无文本聚焦场景会把全局输入源带成 ABC
  system.defaults.CustomUserPreferences."com.apple.HIToolbox" = {
    AppleGlobalTextInputProperties.TextInputGlobalPropertyPerContextInput = true;
  };

  fonts.packages = with unstablePkgs; [
    nerd-fonts.sauce-code-pro
  ];
}
