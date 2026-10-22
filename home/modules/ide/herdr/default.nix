# herdr: the runtime your coding agents live on
# https://github.com/herdrdev/herdr
# 设计与键位映射见 docs/herdr-integration.md
# - 前缀 ctrl+b(herdr 社区默认);zellij/herdr 概念重叠处覆盖动作键对齐 zellij
# - 直达层:zellij `shared` 块的 Alt-* 和弦移植为 herdr 直达绑定(数组同义)
# - herdr 特有功能(workspace/agent/worktree/通知/侧栏...)保留默认,Q6
# - 外观用 herdr 默认,Q5
{ pkgs, unstablePkgs, lib, secretsUser ? "soraliu", ... }: let
  tomlFormat = pkgs.formats.toml { };

  # 仅覆盖「zellij/herdr 概念重叠」的键;未列出的 action 全部沿用 herdr 默认
  # 前缀默认即 ctrl+b,这里显式写明(防止 herdr 未来改动默认)
  herdrConfig = {
    keys = {
      prefix = "ctrl+b";

      # 会话/关闭(zellij d=detach / q=close focus / x=close tab)
      detach      = "prefix+d";
      close_pane  = [ "prefix+q" "alt+q" ];   # zellij q / Alt q (CloseFocus)
      close_tab   = [ "prefix+x" "alt+x" ];   # zellij x / Alt x (CloseTab)

      # 标签(zellij c/x/,/[/]/1-9 + Alt t/x/[ /])
      new_tab       = [ "prefix+c" "alt+t" ];
      previous_tab = [ "prefix+[" "alt+[" ];   # 上一个 tab(by order;herdr 0.7.5 无「上次活跃 tab」动作)
      next_tab      = [ "prefix+]" "alt+]" ];
      rename_tab    = "prefix+comma";
      # switch_tab 默认 "prefix+1..9";Alt+1..9 经下面 [keys.indexed] tabs = "alt" 叠加

      # 焦点移动(zellij h/j/k/l + Alt h/j/k/l)
      focus_pane_left  = [ "prefix+h" "alt+h" ];
      focus_pane_down  = [ "prefix+j" "alt+j" ];
      focus_pane_up    = [ "prefix+k" "alt+k" ];
      focus_pane_right = [ "prefix+l" "alt+l" ];

      # 分屏(zellij L=right/J=down 即 shift+l/j;herdr split_vertical=并排 / split_horizontal=堆叠)
      split_vertical   = [ "prefix+shift+l" "alt+right" ];
      split_horizontal = [ "prefix+shift+j" "alt+down" ];   # alt+n 让给 new_worktree(下)

      # 全屏(zellij z + Alt m)
      zoom = [ "prefix+z" "alt+m" ];

      # 复制/搜索(zellij "/" 进 search;herdr 进 copy mode 再 "/" 搜)
      # copy_mode 默认是 prefix+[,但 [ 已让给 previous_tab,故 copy mode 移到 zellij 的 "/"避冲突
      copy_mode = "prefix+/";

      # workspace 导航:Alt+g 直接打开可搜索的 session/goto 导航(搜 workspace/tab;等同 prefix+g)
      goto = [ "prefix+g" "alt+g" ];

      # workspace 切换(herdr 特有):Alt+- 上一个 / Alt+= 下一个 / Alt+w 新建 / Alt+d 关闭(直达,无需前缀)
      # previous_workspace / next_workspace 默认未绑;new_workspace 默认 prefix+shift+n、close_workspace 默认 prefix+shift+d,下均补 alt 直达
      # (对齐 new_tab/goto 的「prefix + alt 直达」模式;alt+w / alt+d 不与既有绑定冲突)
      previous_workspace = "alt+-";
      next_workspace    = "alt+=";
      new_workspace     = [ "prefix+shift+n" "alt+w" ];
      close_workspace  = [ "prefix+shift+d" "alt+d" ];   # 关闭/删除当前 workspace(默认带确认提示)

      # 新 worktree(herdr 特有:git worktree 绑新 workspace):Alt+n 直达,保留默认 prefix+shift+g
      # (alt+n 原属 split_horizontal,現调拨给更常用的「开新 worktree」)
      new_worktree     = [ "prefix+shift+g" "alt+n" ];

      # agent 焦点(侧栏 agent 面板):Alt+, 上一个 / Alt+. 下一个
      previous_agent = "alt+,";
      next_agent    = "alt+.";


      # 以下保留 herdr 默认(不覆盖):
      #   resize_mode  = "prefix+r"        # 进去持久调整(对齐 zellij r)
      #   edit_scrollback = "prefix+e"     # 对齐 zellij e
      #   rename_pane  = "prefix+shift+p"  # zellij `;` 风险,保留默认
      #   workspace_picker / swap_pane_* / switch_tab 等见 herdr 文档默认(goto 已加 alt+g)

      # 索引跳转:Alt+1..9 切标签(对齐 zellij Alt 1-9 → GoToTab)
      indexed = { tabs = "alt"; };

      # Herdr Palette 插件(Raycast 风 fuzzy 命令/goto 面板):Alt+p 直达打开。
      # 需先一次性安装:herdr plugin install ramarivera/herdr-palette(cargo 编译;ide profile 已带 Rust)
      command = [
        {
          key = "alt+p";
          type = "plugin_action";
          command = "ramarivera.palette.open";
          description = "Open Herdr Palette";
        }
      ];
    };

    # 分屏 pane 边框显示检测到的 agent 标签(无手动 pane 名时);默认 false —— 置 [ui]
    ui.show_agent_labels_on_pane_borders = true;
    ui.status_indicators = "symbols";

    # 通知:in-app toast 显示在 herdr 内部，后台 workspace 的 agent 完成/需输入时
    # 在 herdr 界面浮动提示(默认 top-left)，不弹 macOS 系统横幅，不依赖 terminal-notifier。
    # 备选:<"system"> 经 terminal-notifier 弹系统横幅,<"terminal"> 让外层终端弹通知,<"off"> 关闭。
    ui.toast.delivery = "herdr";
  };
  # herdr-web-ui (devswha/herdr-web-ui) 的明文 env 模板;HERDR_WEB_TOKEN 属个人 secret,
  # 由 sops 解密后在 activation 中拼接(见下),不再出现在 nix store —— 模板本身无敏感信息。
  # HOST=0.0.0.0: 在 token 已设的前提下同时暴露 LAN+tailnet,公网侧由 vpn_primary 上的
  # Caddy(herdr.soraliu.dev 反代 + header_up -Tailscale-User-Login)收口。
  herdrWebUiEnvContent = pkgs.writeText "herdr-web-ui-env" ''
    HOST=0.0.0.0
    PORT=7317
    HERDR_WEB_APP_NAME=lan-m3
    HERDR_WEB_TELEMETRY=0
  '';

in lib.mkMerge [
  {
  # herdr 主体(通知已在上方改为 herdr 内部 toast,不再需要 terminal-notifier)
  home.packages = [ unstablePkgs.herdr ];

  # config.toml 必须是「真实可写文件」: herdr 运行期会写它(TUI 上报权限错误), 而
  # home.file 产物是 symlink → /nix/store 只读。HM 25.11 的 home.file 没有 copy 模式
  # (linkGeneration 固定 ln -Tsf), 改为 activation 里复制一份普通文件。
  # 覆盖前若目标已是普通文件且内容与 nix 声明不同 → 先备份到固定名 .backup(保留
  # 最近一次被覆盖内容, 不堆积); 插件注册在 plugins.json/plugins/, 不受影响。
  # 幂等: rm -f 不 follow symlink, 只删链接/文件本身。
  # activation 运行于 set -eu -o pipefail, 严禁用 [ -L ... ] && rm 的短路写法
  # (条件为假时返回非零会杀死整个 activation, 参见上方 installHerdrPalettePlugin
  # 的 lan-m4 教训注释)。home.file 条目移除后残留旧 symlink 由 HM cleanOldGen
  # 自动 cleanup; 此处 rm -f 兜底, 与 DAG 相对顺序无关。
  home.activation.copyHerdrConfigToml = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _dst="$HOME/.config/herdr/config.toml"
    _src="${tomlFormat.generate "config.toml" herdrConfig}"
    mkdir -p "$(dirname "$_dst")"
    # 目标已存在、是普通文件、内容与 nix 声明不同 → 先备份再覆盖
    if [ -e "$_dst" ] && [ ! -L "$_dst" ] && ! cmp -s "$_src" "$_dst"; then
      cp -f "$_dst" "$_dst.backup"
    fi
    rm -f "$_dst"
    cp "$_src" "$_dst"
    chmod 644 "$_dst"
  '';

  # zsh 补全:nixpkgs herdr 包自带 _herdr;此处复制到 zinit 的补全目录,
  # 方便 zinit 的 fpath + compinit 加载(若已自带则保持覆盖均为无害覆盖)。
  home.activation.genHerdrZshCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${unstablePkgs.herdr}/share/zsh/site-functions/_herdr"
    if [ -f "$src" ]; then
      mkdir -p "$HOME/.local/share/zinit/completions" 2>/dev/null || true
      cp -f "$src" "$HOME/.local/share/zinit/completions/_herdr" 2>/dev/null || true
    fi
  '';

  # 安装并暴露 Herdr Palette 插件二进制。
  # herdr 0.7.5 的 GitHub 流程 `plugin install` 会注册「根 manifest」,其 pane 命令是相对路径
  # `target/release/herdr-palette`;而 pane 由 herdr 服务器用「服务器进程自己的 PATH」解析 spawn ——
  # 相对路径文件名含 `/`,PATH 搜索永远找不到,`alt+p` 报 "No viable candidates found in PATH"。
  # 改用仓库自带的「cargo 子 manifest」(<plugin_root>/cargo/herdr-plugin.toml,pane 命令为「裸
  # `herdr-palette``),用 `plugin link` 覆盖根 manifest;再把构建好的二进制软链到 ~/.local/bin
  # (交互/服务器 PATH) → 服务器 spawn 能找到 `herdr-palette`。
  # 幂等:缺二进制 → 重装(重克隆+重建)自愈;已构建 → 跳过重建,并刷新 link + 软链。
  # `</dev/null` 强制非交互 stdin → `--yes` 生效,不弹 "Install this plugin?"。
  # 需 cargo(ide profile 的 rust 模块已带)+ 联网;失败不阻断 switch;排查可手动:
  #   herdr plugin install ramarivera/herdr-palette --yes  # 看 cargo 输出
  #   herdr plugin link ~/.config/herdr/plugins/github/ramarivera.palette-*/cargo
  #   ln -sfn .../target/release/herdr-palette ~/.local/bin/herdr-palette
  home.activation.installHerdrPalettePlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _herdr="${unstablePkgs.herdr}/bin/herdr"
    export PATH="''${HOME_PROFILE_DIRECTORY:-$HOME/.nix-profile}/bin:$PATH"
    # 1) 确保二进制已构建(缺则重装)
    if ! ls "$HOME"/.config/herdr/plugins/github/ramarivera.palette-*/target/release/herdr-palette >/dev/null 2>&1; then
      if ! "$_herdr" plugin install ramarivera/herdr-palette --yes </dev/null >/dev/null 2>&1; then
        echo "Warning: herdr plugin install ramarivera/herdr-palette failed; palette will not be linked" >&2
      fi
    fi
    # 2) 链接 cargo 子 manifest(裸命令)覆盖根 manifest(相对路径),并软链二进制到 ~/.local/bin
    # NOTE: 赋值必须带 `|| true` —— activation 运行于 `set -eu -o pipefail`,
    # palette 未装成时 bash 把不匹配的 glob 字面量传给 ls,ls 退出码 2 会
    # 经由命令替换赋值直接杀死整个 activation
    # (lan-m4 clawbot 报 "Exited(2)" 的根因)
    _bin="$(ls "$HOME"/.config/herdr/plugins/github/ramarivera.palette-*/target/release/herdr-palette 2>/dev/null | head -1)" || true
    if [ -n "$_bin" ] && [ -x "$_bin" ]; then
      _root="$(dirname "$(dirname "$(dirname "$_bin")")")"
      "$_herdr" plugin link "$_root/cargo" >/dev/null 2>&1 || true
      mkdir -p "$HOME/.local/bin" 2>/dev/null || true
      ln -sfn "$_bin" "$HOME/.local/bin/herdr-palette" 2>/dev/null || true
    fi
  '';

  # 安装自建 herdr-agent-notifier 插件(soraliu/herdr-agent-notifier,GitHub 托管):
  # agent done/blocked 时写入常驻 strip pane(替代 5s 即逝的内置 toast),Enter 跳转。
  # GitHub-managed 安装:herdr 克隆到 ~/.config/herdr/plugins/github/<id>-<hash>/,
  # 其他机器 switch 即得,不依赖本地 ~/Github 检出。幂等判据「github:soraliu/... 源已注册」;
  # 升级插件:重跑 herdr plugin install soraliu/herdr-agent-notifier(替换 managed checkout)。
  # 本地开发路径:unlink 后 herdr plugin link ~/Github/herdr-agent-notifier。
  # node 由 volta/ide 提供;失败不阻断 switch。
  home.activation.installHerdrAgentNotifierPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _herdr="${unstablePkgs.herdr}/bin/herdr"
    if ! "$_herdr" plugin list </dev/null 2>/dev/null | grep -q "github:soraliu/herdr-agent-notifier"; then
      "$_herdr" plugin unlink soraliu.agent-notifier >/dev/null 2>&1 || true
      if ! "$_herdr" plugin install soraliu/herdr-agent-notifier --yes </dev/null >/dev/null 2>&1; then
        echo "Warning: herdr plugin install soraliu/herdr-agent-notifier failed; agent-notifier not installed" >&2
      fi
    fi
  '';
  } # end main set

  (lib.mkIf (secretsUser == "soraliu") {
  # ======================================================================
  # herdr-web-ui (手机/浏览器客户端): 仅 soraliu 环境安装。
  # token 用属主 age key 加密(secrets/users/soraliu/herdr/web-ui-token.enc),
  # 其余 env 行由 nix 明文管理 —— clawbot 等独立 secretsUser 的环境不解密不安装。
  # 注意: 必须用 lib.mkMerge + lib.mkIf 做条件整合,而非在 module return set 上
  # `// lib.optionalAttrs` 硬合并 —— 后者是 plain attrset last-win 合并,会把主段
  # (含 home.packages 等全部定义)丢给 module system 之外的旧求值结果。
  # ======================================================================

  # 1) 构建期解密 token 到 ~/.config/herdr-web-ui/token (0600)
  programs.sops.decryptFiles = [{
    from = "secrets/users/soraliu/herdr/web-ui-token.enc";
    to = ".config/herdr-web-ui/token";
    mode = "0600";
  }];

  # 2) 幂等安装插件(已装则跳过);失败不阻断 switch。
  # 手动恢复:`herdr plugin install devswha/herdr-web-ui --yes`(需 GitHub 可达,必要时挂代理)。
  home.activation.installHerdrWebUiPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _herdr="${unstablePkgs.herdr}/bin/herdr"
    export PATH="''${HOME_PROFILE_DIRECTORY:-$HOME/.nix-profile}/bin:$PATH"
    if ! "$_herdr" plugin list </dev/null 2>/dev/null | grep -q "devswha.herdr-web-ui"; then
      "$_herdr" plugin install devswha/herdr-web-ui --yes </dev/null >/dev/null 2>&1 || true
    fi
  '';

  # 3) 组装 env: 明文模板 + 解密后的 token → 插件配置目录的 .env (幂等重写)。
  # herdr-web-ui 0.3.25+ 优先读 .env(旧版读 env);插件卸载重装不影响(herdr plugin config-dir 持久)。
  home.activation.genHerdrWebUiEnv =
    lib.hm.dag.entryAfter [ "writeBoundary" "installHerdrWebUiPlugin" ] ''
      umask 077
      _env_dir="$HOME/.config/herdr/plugins/config/devswha.herdr-web-ui"
      mkdir -p "$_env_dir"
      _token="$(cat "$HOME/.config/herdr-web-ui/token" 2>/dev/null || true)"
      if [ -z "$_token" ]; then
        echo "herdr-web-ui: token missing (sops decrypt failed? see ~/.config/herdr-web-ui/token), .env not rewritten" >&2
      else
        cat "${herdrWebUiEnvContent}" > "$_env_dir/.env"
        echo "HERDR_WEB_TOKEN=$_token" >> "$_env_dir/.env"
        unset _token
      fi
    '';
  }) # end lib.mkIf (secretsUser == "soraliu") — herdr-web-ui
]
