{ unstablePkgs, lib, ... }: {
  # oh-my-pi (omp): pi-mono 的姊妹发行版, 双栈并存试用(plans/omp-switch.md)
  # 改用 nixpkgs-unstable 的 pkgs.omp (#47 原先的 flake input 方案每次更新都要
  # 本地源码重编 bun/rust 全链; nixpkgs 官方包走 cache.nixos.org 二进制缓存, 零编译。
  # 版本随 nixpkgs-unstable pin 滚动, 滞后上游 tag 约数周, 试用期可接受)
  config.home.packages = [
    unstablePkgs.omp
  ];

  # omp 用户级扩展经 omp plugin install 初始化(幂等:缺才装;失败仅告警不阻断 switch)。
  # 手动恢复: omp plugin install npm:@plannotator/pi-extension
  config.home.activation.installOmpPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _omp="${unstablePkgs.omp}/bin/omp"
    export PATH="''${HOME_PROFILE_DIRECTORY:-$HOME/.nix-profile}/bin:$PATH"
    if ! "$_omp" plugin list --json </dev/null 2>/dev/null | grep -q "plannotator"; then
      "$_omp" plugin install npm:@plannotator/pi-extension </dev/null >/dev/null 2>&1 \
        || echo "Warning: omp plugin install npm:@plannotator/pi-extension failed; install manually after switch" >&2
    fi
  '';
}
