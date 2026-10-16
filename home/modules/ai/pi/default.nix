{ pi, system, lib, ... }: {
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

  # pi 用户级扩展经 pi install 初始化(幂等:缺才装;失败仅告警不阻断 switch)。
  # 本机现役 0.27.15 已装则守卫直接跳过,版本维持现状;升级仍走 pi update。
  # 手动恢复: pi install npm:@plannotator/pi-extension
  config.home.activation.installPiPlannotator = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _pi="${pi.packages.${system}.pi}/bin/pi"
    export PATH="''${HOME_PROFILE_DIRECTORY:-$HOME/.nix-profile}/bin:$PATH"
    if ! "$_pi" list </dev/null 2>/dev/null | grep -q "npm:@plannotator/pi-extension"; then
      "$_pi" install npm:@plannotator/pi-extension </dev/null >/dev/null 2>&1 \
        || echo "Warning: pi install npm:@plannotator/pi-extension failed; install manually after switch" >&2
    fi
  '';
}
