{ pi, system, ... }: {
  config.home.packages = [
    pi.packages.${system}.coding-agent
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
}
