# Nix 磁盘卫生模块: nh (Yet another Nix CLI helper) + 周期 GC
#
# 为什么:
# - nh clean 比 nix-collect-garbage 更完整 (同时清理 gcroot + profile generations)
# - nh.flake 作为 NH_FLAKE 环境变量注入, 免去每次 --flake 参数
# - 按 14 天 + keep 5 策略自动清理, /nix/store 稳态占用 ≤ 8 GB (目标值)
#
# 路径策略:
# - 使用 "path:${config.home.homeDirectory}/.nixfiles" 字符串 (非 Nix path 类型!)
#   → 避免 flake 源树被复制到 /nix/store (与 Determinate Nix lazy-trees 一致)
#   → 代码里无用户名硬编码, HM eval 时按 profile 展开
#   → Darwin 得 /Users/soraliu/.nixfiles; NixOS 得 /home/.../.nixfiles; root 得 /root/.nixfiles
#
# 冲突规避:
# - 与 nix.gc.automatic (NixOS/Darwin 层) 互斥: HM 已在 nh 模块里 warn, 本仓库未启用前者
# - 与 Determinate Nixd 自带 GC 互斥: Phase 4 在 determinate 模块里关掉 (garbageCollector.strategy = "disabled")
#
# 前提: 仓库克隆到 ~/.nixfiles (本仓库约定, wrap 目录只是 symlink 宿主)
{ config, ... }:
{
  programs.nh = {
    enable = true;
    flake = "path:${config.home.homeDirectory}/.nixfiles";
    clean = {
      enable = true;
      # weekly 在 Linux (systemd.time) / Darwin (launchd) 两侧都兼容
      dates = "weekly";
      # --keep 5:        至少保留最近 5 个 generation, 防止长时间不 switch 时被清光
      # --keep-since 14d: 超过 14 天的 generation 方可被清
      extraArgs = "--keep 5 --keep-since 14d";
    };
  };
}
