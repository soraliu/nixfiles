{ pi, system, lib, config, ... }:

let
  isDarwin = system == "x86_64-darwin" || system == "aarch64-darwin";
in
{
  config.home.packages = [
    pi.packages.${system}.coding-agent
  ];

  # ---- pi-dashboard server 常驻优化 (仅 darwin, launchd) ----
  #
  # 问题: @blackbelt-technology/pi-agent-dashboard 的 bridge 扩展在 server
  # 冷启动时 (重启电脑后第一个 pi session) 会:
  #   1. 阻塞数秒 (node 冷启动 + jiti 编译 + 扫描 session 目录, 实测 4-8s)
  #   2. 在输入框上方挂自旋 Loader widget ("starting dashboard server … Ns",
  #      bridge.ts 的 pi-dashboard-launch widget, placement: aboveEditor),
  #      server ready 前一直占位, 影响输入框显示
  #
  # 方案: 登录时由 LaunchAgent 提前拉起 server daemon (与 bridge auto-start
  # 相同的 start 入口, 幂等: 已在运行时 health check 秒过).
  # 此后所有 pi 启动一律走热路径 (mDNS/health check 实测 ~110ms),
  # 启动 widget 永不出现, 冷启动等待归零.
  #
  # KeepAlive 保持 false (默认): launchd 不自动重启, 原因:
  #   - server 意外退出 → 下次任意 pi 启动时 bridge autoStart 兜底拉起
  #   - 手动 pi-dashboard stop 不会被 launchd 立即拉回, 尊重手动控制
  #
  # node 路径说明: 通过 zsh -lc 登录 shell 解析 (volta 管理的 node,
  # PATH 来自 zprofile), 与终端内运行 pi 时的 node 环境一致;
  # launchd 原生环境 PATH 极小, 直接指定 node 会找不到二进制.
  config.launchd.agents.pi-dashboard-server = lib.mkIf isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/zsh"
        "-lc"
        "exec node ${config.home.homeDirectory}/.pi/agent/npm/node_modules/@blackbelt-technology/pi-agent-dashboard/packages/server/bin/pi-dashboard.mjs start"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/pi-dashboard-server.out.log";
      StandardErrorPath = "/tmp/pi-dashboard-server.err.log";
    };
  };

  # 单机使用 dashboard (localhost:8000), mDNS 多机发现无用;
  # 禁掉后 bridge 每次 pi 启动免去 mDNS browse (~110ms),
  # 冷启动场景免去 server spawn 后最多 10s 的 mDNS advertise 等待
  # (直接连配置端口)。多机使用 dashboard 时删除此项即可恢复发现能力。
  config.home.sessionVariables.PI_DASHBOARD_NO_MDNS = "1";
}
