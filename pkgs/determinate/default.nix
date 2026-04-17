# Determinate Nix 3.x 集成模块 (nix-darwin & NixOS 通用)
#
# 作用:
# - 启用 Determinate Nix runtime (lazy-trees + parallel-eval 默认 on)
# - 把仓库原有 nix.settings.* 迁入 /etc/nix/nix.custom.conf (Determinate 不读 nix.conf 旧路径)
# - 关掉 Determinate Nixd 自带 GC, 避免与 nh clean 的 14d/keep5 语义冲突
#
# 配置分层 (方案 A, 参考 bin/common/pre-init-nix.sh 顶部):
# - 本文件 → /etc/nix/nix.custom.conf: cross-host 不变量 (trusted-users, lazy-trees, sandbox, pubkey)
# - pre-init-nix.sh → user-level nix.conf + VPS 场景 /etc/nix/nix.custom.conf:
#   per-host region (extra-substituters) + VPS fallback (sandbox + pubkey)
# - 本模块只被 Darwin / NixOS 的 systems/*.nix import; pure Ubuntu VPS (home-manager only)
#   场景下由 pre-init-nix.sh 在 Linux 无 /etc/nixos 时写 /etc/nix/nix.custom.conf 兜底
#
# 前提: Nix runtime 必须先升级到 Determinate 3.x, 使用 bin/common/pre-init-nix.sh
#
# 使用: 在 systems/darwin.nix / systems/nixos-wsl.nix 的 modules 里插入:
#   inputs.determinate.darwinModules.default   (Darwin)
#   inputs.determinate.nixosModules.default    (NixOS)
#   再 import 本文件

{ pkgs, homeUser, ... }: {
  determinateNix = {
    enable = true;

    # 写入 /etc/nix/nix.custom.conf
    # 保留仓库原有的 trusted users / sandbox paths / community cache 配置
    customSettings = {
      # @staff 仅 Darwin 有; Linux 用 @wheel
      trusted-users =
        [ homeUser "root" "@wheel" ]
        ++ (if pkgs.stdenv.isDarwin then [ "@staff" ] else [ ]);

      # lazy-trees 在 3.5.2+ 已默认 true, 显式写避免未来漂移
      lazy-trees = true;

      # sops 解密需要 /tmp/.age 可访问 (与 nixConfig.extra-sandbox-paths 等价)
      extra-sandbox-paths = [ "/tmp/.age" ];

      # download-buffer-size: Determinate 3.17 默认 1 MB 过小, 大 nar 下载时 pipeline stall.
      # 对齐 upstream Nix default (64 MB) 让 socket buffer 足以吸收 burst.
      download-buffer-size = 67108864;

      # extra-substituters 不在此声明 (per-host 选择):
      # - Determinate 默认已启 FlakeHub cache + cache.nixos.org
      # - 区域镜像 (清华/交大/USTC) 由 ~/.config/nix/nix.conf 承担 (bin/common/pre-init-nix.sh -r cn 写入)
      # - 原因: 避免在 Nix code 中硬编码区域, 防止 US VPS 误用 CN 镜像变慢
      # - 清华/交大/USTC 镜像签名 = cache.nixos.org-1 pubkey (read-only mirror 同源签名), 不需额外 key
      #
      # extra-trusted-public-keys: region-agnostic (签名与地域无关), 所有机器共用
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # Determinate Nixd 的 JSON 配置 (/etc/determinate/config.json)
  # - garbageCollector.strategy = "disabled": 交给 nh clean 管, 避免双重 GC
  environment.etc."determinate/config.json".text = builtins.toJSON {
    garbageCollector.strategy = "disabled";
  };
}
