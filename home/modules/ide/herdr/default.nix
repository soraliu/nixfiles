# herdr: the runtime your coding agents live on
# https://github.com/herdrdev/herdr
# 设计与键位映射见 docs/herdr-integration.md
# - 前缀 ctrl+b(herdr 社区默认);zellij/herdr 概念重叠处覆盖动作键对齐 zellij
# - 直达层:zellij `shared` 块的 Alt-* 和弦移植为 herdr 直达绑定(数组同义)
# - herdr 特有功能(workspace/agent/worktree/通知/侧栏...)保留默认,Q6
# - 外观用 herdr 默认,Q5
{ pkgs, unstablePkgs, lib, ... }: let
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
      split_horizontal = [ "prefix+shift+j" "alt+down" "alt+n" ];

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

    # 通知:herdr 默认 ui.toast.delivery=off → pi/agent 完成不提示。开 in-app toast,
    # 在「后台 workspace 的 agent 完成/需输入」时弹;想收到 herdr 之外的系统横幅改 "system"
    # (macOS 上 system 优先 terminal-notifier,可后续在 home.packages 加 pkgs.terminal-notifier)
    ui.toast.delivery = "herdr";
  };
in {
  home.packages = [ unstablePkgs.herdr ];

  home.file.".config/herdr/config.toml".source =
    tomlFormat.generate "config.toml" herdrConfig;

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
      "$_herdr" plugin install ramarivera/herdr-palette --yes </dev/null >/dev/null 2>&1 || true
    fi
    # 2) 链接 cargo 子 manifest(裸命令)覆盖根 manifest(相对路径),并软链二进制到 ~/.local/bin
    _bin="$(ls "$HOME"/.config/herdr/plugins/github/ramarivera.palette-*/target/release/herdr-palette 2>/dev/null | head -1)"
    if [ -n "$_bin" ] && [ -x "$_bin" ]; then
      _root="$(dirname "$(dirname "$(dirname "$_bin")")")"
      "$_herdr" plugin link "$_root/cargo" >/dev/null 2>&1 || true
      mkdir -p "$HOME/.local/bin" 2>/dev/null || true
      ln -sfn "$_bin" "$HOME/.local/bin/herdr-palette" 2>/dev/null || true
    fi
  '';
}
