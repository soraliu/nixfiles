{ unstablePkgs, lib, ... }:
let
  # pi-session-prs fork(marcoskichel 上游, omp-compat 分支): diff 为 omp 兼容性三处改动 —
  # 1) agent_settled -> agent_end 事件名; 2) hyperlink 改本地 OSC8 实现; 3) 新增 /prs list。
  # 效果: footer 按 state 分组显示本 session 的 PRs, /prs 选开浏览器, /prs list 输出
  # markdown 链接列表(TUI 渲染为可点击 OSC 8 hyperlink, herdr pane 内可直接点击)。
  # 上游 npm 包未发布 omp 适配, 故 pin 到 fork commit 的 git checkout 本地安装。
  pi-session-prs = unstablePkgs.fetchFromGitHub {
    owner = "soraliu";
    repo = "pi-session-prs";
    rev = "c228b62e12911c623f71c133676fb21916a7cb9a";
    hash = "sha256-5SWzUrHFY5OpvW6q+Pvj0fcNT5525eiHQjMzPnz8tYQ=";
  };
in
{
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
    # pi-session-prs 从 nix store 的 fork checkout 本地安装(link 模式), 依赖 gh CLI 在 PATH
    if ! "$_omp" plugin list --json </dev/null 2>/dev/null | grep -q "pi-session-prs"; then
      "$_omp" plugin install ${pi-session-prs} </dev/null >/dev/null 2>&1 \
        || echo "Warning: omp plugin install pi-session-prs failed; install manually after switch" >&2
    fi
  '';
}
