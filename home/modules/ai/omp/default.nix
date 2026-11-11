{
  unstablePkgs,
  pkgs,
  lib,
  config,
  ...
}:
let
  # omp config.yml 声明母本(sops 密文, 可含私密字段), 构建期解密到 /nix/store, switch 时 merge 进本机文件。
  # ide 系与 clawbot 共用同一把 age 密钥(pre-init-age 从 WebDAV 恢复到 /tmp/.age/keys.txt), 故共用同一密文;
  # agent-models(models.yml + apiKey)与 omp config 同策略: 密文在用户共享的 secrets/.config/ai/, ide 系与
  # clawbot 一体共享。前提: 构建机须先跑过 pre-init-age, 否则本 derivation 求值即失败。
  _ompConfigDec = pkgs.callPackage ../../../../pkgs/sops/decrypt.nix {
    inherit pkgs;
    files = [
      {
        from = "secrets/.config/ai/omp-config.enc.json";
        to = "omp-config.json";
      }
    ];
  };
  ompArgv0 = pkgs.writeShellScriptBin "omp" ''
    # herdr 内禁用 omp 自带通知通道(PI_NOTIFICATIONS, pi 遗产 env):omp 在 herdr 里会
    # spawn `herdr notification show` 发 toast,而 herdr 检测到 omp 进程后又会对同一完成
    # 发原生状态 toast("omp finished", 带跳转 target) —— 修复 argv[0] 检测后两者并存,
    # 每次完成弹两条重复通知。herdr 内以原生 toast 为准(与 pi 行为一致: pi 无此通道);
    # herdr 外 PI_NOTIFICATIONS 不设, 终端 OSC/BEL 通知照常。
    if [ "''${HERDR_ENV:-}" = "1" ]; then
      export PI_NOTIFICATIONS=off
    fi
    exec -a omp "${unstablePkgs.bun}/bin/bun" "${unstablePkgs.omp}/lib/omp/packages/coding-agent/dist/cli.js" "$@"
  '';
in
{
  # oh-my-pi (omp): pi-mono 的姊妹发行版, 双栈并存试用(plans/omp-switch.md)
  # 改用 nixpkgs-unstable 的 pkgs.omp (#47 原先的 flake input 方案每次更新都要
  # 本地源码重编 bun/rust 全链; nixpkgs 官方包走 cache.nixos.org 二进制缓存, 零编译。
  # 版本随 nixpkgs-unstable pin 滚动, 滞后上游 tag 约数周, 试用期可接受)
  #
  # argv[0] wrapper: herdr 的 agent 进程检测读 KERN_PROCARGS2 的 argv[0](macOS 等价
  # /proc/cmdline)。pi 是 Node, 启动时 process.title="pi" 会重写 argv[0]; omp 跑在
  # bun 上, 其 process.title 赋值不写回 kernel procargs —— nixpkgs wrapper exec bun 后
  # 进程名永远是 "bun", herdr 识别不出 Agent::Omp, omp pane 的 herdr-omp-agent-state
  # 扩展上报被 route_full_lifecycle_hook_report 拒收(process_present=false),
  # pane.agent_status_changed 永不触发, agent-notifier 列表对 omp 恒空。
  # 用 exec -a omp 把 argv[0] 固定为 "omp"(实测: 上报被接受, 事件流恢复)。
  # 直接 exec 原包 store 路径里的 bun+cli.js, 保持 wrapper 单层(argv[0] 不再被
  # 嵌套 wrapper 的 exec 抹掉)。
  config.home.packages = [ ompArgv0 ];

  # 用户级插件与 skills 由 ~/Github/agents 的 profiles 声明并经 just init 安装。

  # ~/.omp/agent/config.yml: omp 主配置(omp 运行时会回写, 如主题/UI 偏好), 不再静态全量覆写;
  # 声明母本 = secrets/.config/ai/omp-config.enc.json, switch 时 merge 进本机已有配置,
  # 逻辑与 agent-models 同款(其只管 models.yml, 本文件由本模块负责):
  #   - 声明(密文)字段覆盖同名本机字段(改密文即生效);
  #   - 本机独有字段(运行时状态/手改)永久保留, 不被 switch 清掉;
  #   - 从密文删除的字段不清理本机残留(声明式只做增量收敛); 数组无 id 概念, 整体被密文侧替换。
  #   - mnemopi.dbPath 由模块按 $HOME 注入(跨机安全), 密文不含 dbPath;
  #     merge 语义不变——密文字段覆盖同名本机字段, 本机独有字段保留。
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
       "$_jq" --arg home "$HOME" --slurpfile decl "$_dec/omp-config.json" \
         '. * $decl[0] | .mnemopi.dbPath = ($home + "/.mnemopi/mnemopi.db")' \
         "$_t.nix-merge.tmp" > "$_t.nix-merge2.tmp" && \
       "$_yq" -o=yaml -P '.' "$_t.nix-merge2.tmp" > "$_t.nix-yml.tmp"; then
      mv "$_t.nix-yml.tmp" "$_t"
      rm -f "$_t.nix-merge.tmp" "$_t.nix-merge2.tmp"
    else
      rm -f "$_t.nix-merge.tmp" "$_t.nix-merge2.tmp" "$_t.nix-yml.tmp"
      echo "omp: WARN: $_t 无法解析, 保持原文件不变" >&2
    fi
  '';
}
