{ pkgs, lib, ... }:

let
  podmanBin = "${pkgs.podman}/bin/podman";
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
  programs.zsh.initContent = lib.mkAfter ''
    _podman_sock=$(${podmanBin} machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
    if [ -n "$_podman_sock" ] && [ -S "$_podman_sock" ]; then
      export DOCKER_HOST="unix://$_podman_sock"
    fi
    unset _podman_sock
  '';

  # 首次激活时自动初始化 podman machine
  # podman machine init 依赖 ssh-keygen，需显式补充 PATH
  home.activation.initPodman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${lib.makeBinPath (with pkgs; [ openssh podman ])}:$PATH"
    if ${podmanBin} machine list --format '{{.Name}}' 2>/dev/null | grep -q 'podman-machine-default'; then
      $DRY_RUN_CMD echo "podman machine already exists, skipping init"
    else
      $DRY_RUN_CMD ${podmanBin} machine init || true
    fi
  '';

  # 登录时自动启动 podman machine
  launchd.agents.podman-machine-start = {
    enable = true;
    config = {
      ProgramArguments = [ podmanBin "machine" "start" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/podman-machine-start.out.log";
      StandardErrorPath = "/tmp/podman-machine-start.err.log";
    };
  };
}
