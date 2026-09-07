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
      previous_tab  = [ "prefix+[" "alt+[" ];
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

      # 以下保留 herdr 默认(不覆盖):
      #   resize_mode  = "prefix+r"        # 进去持久调整(对齐 zellij r)
      #   edit_scrollback = "prefix+e"     # 对齐 zellij e
      #   rename_pane  = "prefix+shift+p"  # zellij `;` 风险,保留默认
      #   goto / workspace_picker / swap_pane_* / switch_tab 等见 herdr 文档默认

      # 索引跳转:Alt+1..9 切标签(对齐 zellij Alt 1-9 → GoToTab)
      indexed = { tabs = "alt"; };
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
}
