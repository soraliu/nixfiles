{ unstablePkgs, lib, ... }:
let
  # pi-session-prs fork(marcoskichel 上游, omp-compat 分支): PR 行经 setWidget(aboveEditor)
  # 渲染在 statusline 上方一行(紧贴 session-title 行), 按 state 分组(●/✔/✕);
  # 终端支持时 PR 编号为 OSC 8 可点击链接(herdr 内 ⌘+点击), 否则降级纯文本; /prs 选开浏览器; /prs list
  # 在 transcript 输出 markdown 链接列表。fork 另含 omp 兼容: agent_end 事件名 + 本地 OSC8 实现。
  # 上游 npm 包未发布 omp 适配, 故 pin 到 fork commit 的 git checkout 本地安装。
  pi-session-prs = unstablePkgs.fetchFromGitHub {
    owner = "soraliu";
    repo = "pi-session-prs";
    rev = "90e9248d2f02340349d907c2e9cbd31a63437df3";
    hash = "sha256-DPEQCnpT1eub16qS3VKON8XX6og3hVmAu3naZTrSTXI=";
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

  # ~/.omp/agent/config.yml: omp 主配置; 全量为静态偏好(无运行时数据),
  # 声明式管理, 每次以 home-manager 版本为准(手改会被 switch 覆盖)。
  # agent-models 模块只合并 models.yml, 不触碰本文件。
  config.home.file.".omp/agent/config.yml".text = ''
    modelRoles:
      default: 1xtoken/glm-5.3
    symbolPreset: unicode
    composer:
      shape: band
    theme:
      dark: titanium
    setupVersion: 2
    task:
      eager: preferred
    terminal:
      showProgress: false
    statusLine:
      preset: full
    dev:
      autoqaConsent: granted
  '';
}
