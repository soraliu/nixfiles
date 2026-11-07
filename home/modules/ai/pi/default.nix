{ pi, pkgs, system, lib, ... }: {
  # v1.0.1 起改用上游官方 flake(github:earendil-works/pi/stable),
  # 包 output 为 packages.<system>.pi(原 lukasl-dev/pi.nix 打包仓库为 .coding-agent)
  config.home.packages = [
    pi.packages.${system}.pi
  ];

  # 单机使用 dashboard (localhost:8000), mDNS 多机发现无用;
  # 禁掉后 bridge 每次 pi 启动免去 mDNS browse (~110ms),
  # 冷启动场景免去 server spawn 后最多 10s 的 mDNS advertise 等待
  # (直接连配置端口)。多机使用 dashboard 时删除此项即可恢复发现能力。
  config.home.sessionVariables.PI_DASHBOARD_NO_MDNS = "1";

  # pi-background-tasks 扩展（fork: soraliu/pi-background-tasks）的运行时产物根。
  # 默认写到项目目录下的 .pi/tasks|fusion|delegate，弄脏 git 且频繁变化；
  # 设置后统一落到 ~/.pi 下，项目目录不再出现 .pi
  config.home.sessionVariables.PI_BG_RUNTIME_ROOT = "$HOME/.pi";

  # pi 没有独立 vision 角色；默认模型同时处理文字与图片，其他运行时设置保留。
  config.home.activation.mergePiConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    umask 077
    _decl="${pkgs.callPackage ../../../../pkgs/sops/decrypt.nix {
      inherit pkgs;
      files = [{ from = "secrets/.config/ai/pi-config.enc.json"; to = "pi-config.json"; }];
    }}/pi-config.json"
    _t="$HOME/.pi/agent/settings.json"
    mkdir -p "$HOME/.pi/agent"
    [ -f "$_t" ] || printf '{}\n' > "$_t"
    if "${pkgs.jq}/bin/jq" --slurpfile decl "$_decl" '. * $decl[0]' "$_t" > "$_t.nix-merge.tmp"; then
      mv "$_t.nix-merge.tmp" "$_t"
    else
      rm -f "$_t.nix-merge.tmp"
      echo "pi: WARN: $_t 无法解析, 保持原文件不变" >&2
    fi
  '';

  # 用户级插件与 skills 由 ~/Github/agents 的 profiles 声明并经 just init 安装。
}
