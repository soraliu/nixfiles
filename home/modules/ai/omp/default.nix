{
  unstablePkgs,
  pkgs,
  lib,
  ...
}:
let
  # pi-session-prs fork(marcoskichel 上游, omp-compat 分支): PR 行经 setWidget(belowEditor)
  # 渲染在 editor 带下方一行, 按 state 分组(●/✔/✕); 终端支持时 PR 编号为 OSC 8 可点击链接(herdr 内
  # Ctrl+点击), 否则降级纯文本; /prs 选开浏览器; /prs list 在 transcript 输出 markdown 链接列表。
  # fork 另含 omp 兼容: agent_end 事件名 + 本地 OSC8 实现。
  # 93df0fd: herdr 会话(HERDR_ENV/HERDR_*_ID)显式视为可点击 —— 安装的插件从自己的 node_modules 解析
  # 上游 pi-tui, 其静态探测看不见 herdr(隐藏外层终端)误报 false; herdr 实际自渲染 OSC 8 并 Ctrl+点击打开。
  # 868241a: aboveEditor→belowEditor —— omp 给 aboveEditor widget 硬编码前置 Spacer(1), PR 行上方多一个
  # 空行; belowEditor 容器无 spacer, PR 行紧贴 editor 带。
  pi-session-prs = unstablePkgs.fetchFromGitHub {
    owner = "soraliu";
    repo = "pi-session-prs";
    rev = "868241a72f31eaf04b0636b8592e1873d614ebca";
    hash = "sha256-IG7moxUS1EG4PjnQAnC3ky8ZIniNmiY/1mE0FVe/MTw=";
  };

  # omp config.yml 声明母本(sops 密文, 可含私密字段), 构建期解密到 /nix/store, switch 时 merge 进本机文件。
  # ide 系与 clawbot 共用同一把 age 密钥(pre-init-age 从 WebDAV 恢复到 /tmp/.age/keys.txt), 故共用同一密文;
  # agent-models 按 user 分家是因为它管的是 apiKey 目录, omp config 无 per-user 数据。将来要分家再挪
  # secrets/users/<user>/ 另建密文。前提: 构建机须先跑过 pre-init-age, 否则本 derivation 求值即失败。
  _ompConfigDec = pkgs.callPackage ../../../../pkgs/sops/decrypt.nix {
    inherit pkgs;
    files = [
      {
        from = "secrets/.config/ai/omp-config.enc.json";
        to = "omp-config.json";
      }
    ];
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

  # ~/.omp/agent/config.yml: omp 主配置(omp 运行时会回写, 如主题/UI 偏好), 不再静态全量覆写;
  # 声明母本 = secrets/.config/ai/omp-config.enc.json, switch 时 merge 进本机已有配置,
  # 逻辑与 agent-models 同款(其只管 models.yml, 本文件由本模块负责):
  #   - 声明(密文)字段覆盖同名本机字段(改密文即生效);
  #   - 本机独有字段(运行时状态/手改)永久保留, 不被 switch 清掉;
  #   - 从密文删除的字段不清理本机残留(声明式只做增量收敛); 数组无 id 概念, 整体被密文侧替换。
  config.home.activation.mergeOmpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    umask 077
    _jq="${pkgs.jq}/bin/jq"
    _yq="${pkgs.yq-go}/bin/yq"
    _dec="${_ompConfigDec}"

    # YAML → JSON → jq '*' deep-merge(嵌套对象递归, 密文侧优先) → YAML;
    # 首次 switch 会重排 store 链接时代的手写排版, 之后字节级幂等。
    _t="$HOME/.omp/agent/config.yml"
    mkdir -p "$HOME/.omp/agent"
    [ -f "$_t" ] || printf '{}\n' > "$_t"
    if "$_yq" -o=json -I=0 '.' "$_t" > "$_t.nix-merge.tmp" && \
       "$_jq" --slurpfile decl "$_dec/omp-config.json" '. * $decl[0]' "$_t.nix-merge.tmp" > "$_t.nix-merge2.tmp" && \
       "$_yq" -o=yaml -P '.' "$_t.nix-merge2.tmp" > "$_t.nix-yml.tmp"; then
      mv "$_t.nix-yml.tmp" "$_t"
      rm -f "$_t.nix-merge.tmp" "$_t.nix-merge2.tmp"
    else
      rm -f "$_t.nix-merge.tmp" "$_t.nix-merge2.tmp" "$_t.nix-yml.tmp"
      echo "omp: WARN: $_t 无法解析, 保持原文件不变" >&2
    fi
  '';
}
