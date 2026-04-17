# 平台无关的 nix.optimise 包装: 周期性硬链接去重 /nix/store
#
# 设计:
# - Darwin: launchd 定时器, 每周日凌晨 3 点跑
# - NixOS:  systemd timer, 每天凌晨 3 点跑 (NixOS 上 dates 字符串更灵活)
# - 不启用 nix.settings.auto-optimise-store (daemon 级 in-line 硬链接):
#   macOS APFS 上有已知卡顿 (NixOS/nix#6033), 周期任务更稳
#
# 与 Determinate 共存:
# - nix.optimise 依赖 nix.enable = true; Determinate 设 nix.enable = false 时自动跳过
# - 过渡期 (upstream Nix) 或 Android (未启 Determinate) 才生效
# - 在 Determinate 下存量去重由 `nix-store --optimise` 手动触发或等后续集成
#
# 使用:
#   imports = [ ../../pkgs/nix-store/optimise.nix ];
{ config, pkgs, lib, ... }:
{
  nix.optimise = lib.mkIf config.nix.enable (
    if pkgs.stdenv.isDarwin then {
      automatic = true;
      interval = { Weekday = 0; Hour = 3; Minute = 0; };
    } else {
      automatic = true;
      dates = [ "03:00" ];
    }
  );
}
