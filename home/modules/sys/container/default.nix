{ pkgs, lib, ... }:

let
  podmanBin = "${pkgs.podman}/bin/podman";

  # init + start 合并到 launchd agent 里执行, 不放在 home.activation:
  # 1) launchd agent 以目标用户身份运行, 环境干净, 不会阻塞 switch 关键路径.
  # 2) activation 里跑 podman machine 会把 switch 耦合到 VM 启动成败 (downloads 500MB, VM boot 风险).
  #
  # 状态机三路径 (通过 machine list --format '{{.Running}}' 判断):
  #   不存在    → init + start
  #   存在+停止 → start
  #   存在+运行 → 什么都不做 (关键! 避免第二次 start 扰动已运行的 VM,
  #               之前的 "switch 后 VM 损坏" 事故就是因为重复触发 start 中断了 ignition first-boot)
  #
  # timeout 15 防止 machine list 因残留 socket/lock 卡死时传导到 launchd.
  podmanMachineUp = pkgs.writeShellScript "podman-machine-up" ''
    set -u
    export PATH="${lib.makeBinPath (with pkgs; [ openssh podman coreutils ])}:$PATH"

    # 用 Name|Running 格式一次性拿到存在性+运行状态
    state=$(timeout 15 ${podmanBin} machine list --format '{{.Name}}|{{.Running}}' 2>/dev/null \
              | grep '^podman-machine-default|' || true)

    if [ -z "$state" ]; then
      echo "[podman-machine-up] machine 不存在, init + start" >&2
      ${podmanBin} machine init || {
        echo "[podman-machine-up] machine init 失败" >&2
        exit 1
      }
      exec ${podmanBin} machine start
    fi

    if echo "$state" | grep -q '|true$'; then
      echo "[podman-machine-up] machine 已在运行, skip (避免扰动)" >&2
      exit 0
    fi

    echo "[podman-machine-up] machine 存在但已停止, 执行 start" >&2
    exec ${podmanBin} machine start
  '';
in
{
  home.packages = with pkgs; [
    docker-client # docker cli
    podman
    podman-tui
  ];

  # 动态设置 DOCKER_HOST 指向 podman API socket
  # https://podman-desktop.io/docs/migrating-from-docker/using-the-docker_host-environment-variable
  # macOS 推荐通过 podman machine inspect 获取 socket 路径
  #
  # 两层防御, 避免 zsh 启动被 podman state lock 卡死:
  # 1) 目录不存在 (machine 从未初始化) → 直接 skip, 不 fork 子进程, 零开销
  # 2) timeout 2s → 就算 podman machine init 正在后台跑 (持锁几分钟), inspect 会被超时中断,
  #                 zsh 最多多 2 秒启动, 不会无限卡住
  # 超时发生时降级为不设 DOCKER_HOST, 用户可稍后 `exec zsh` 重新拉取.
  programs.zsh.initContent = lib.mkAfter ''
    if [ -d "$HOME/.local/share/containers/podman/machine" ]; then
      _podman_sock=$(${pkgs.coreutils}/bin/timeout 2 ${podmanBin} machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
      if [ -n "$_podman_sock" ] && [ -S "$_podman_sock" ]; then
        export DOCKER_HOST="unix://$_podman_sock"
      fi
      unset _podman_sock
    fi
  '';

  # 登录时确保 podman machine 已初始化并启动
  # KeepAlive = false: `machine start` 成功后会正常退出, 若 KeepAlive=true 会被 launchd 紧循环重启.
  launchd.agents.podman-machine-start = {
    enable = true;
    config = {
      ProgramArguments = [ "${podmanMachineUp}" ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/podman-machine-start.out.log";
      StandardErrorPath = "/tmp/podman-machine-start.err.log";
    };
  };
}
