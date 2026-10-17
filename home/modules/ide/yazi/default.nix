{
  config,
  pkgs,
  lib,
  unstablePkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in {
  # yazi: Rust 终端文件管理器, 本体/插件全部取 nixpkgs-unstable —— 与 yaziPlugins
  # 集合 pin 在同一个 nixpkgs commit 里, `just update-unstable-pkg` 时同步前进,
  # 不存在 `ya pkg` 装到 ~/.config 的版本漂移问题。用法详见同目录 README.md。
  #
  # - wrapper 自带预览工具链: jq/poppler/7zz/ffmpeg/fd/ripgrep/fzf/zoxide/
  #   imagemagick/chafa/resvg, 装完即可预览视频/PDF/图片/压缩包
  # - shell 集成: HM 在 zsh 注入 `yy` 函数, 退出时 cd 到最后浏览目录
  programs.yazi = {
    enable = true;
    package = unstablePkgs.yazi;
    # ouch.yazi 插件的运行时依赖(压缩/预览), 进 wrapper PATH
    extraPackages = [unstablePkgs.ouch];

    # ---- 插件集: nixpkgs yaziPlugins, 与 yazi 本体同一 unstable pin ----
    plugins =
      {
        # [交互] l 一键: 目录进入/文件打开
        smart-enter = unstablePkgs.yaziPlugins.smart-enter;
        # [交互] p 智能粘贴: 粘到 hover 目录而非仅限 cwd
        smart-paste = unstablePkgs.yaziPlugins.smart-paste;
        # [交互] 过滤持续累积, 唯一匹配回车直接进/打开
        smart-filter = unstablePkgs.yaziPlugins.smart-filter;
        # [UI] 三栏(parent/current/preview)显示切换与最大化
        toggle-pane = unstablePkgs.yaziPlugins.toggle-pane;
        # [UI] 全边框(圆角)
        full-border = unstablePkgs.yaziPlugins.full-border;
        # [UI] header/status 双行自定义
        yatline = unstablePkgs.yaziPlugins.yatline;
        # [git] 文件列表 linemode 显示 git 变更状态
        git = unstablePkgs.yaziPlugins.git;
        # [git] g i 打开 lazygit(本体由 ide/git 模块提供)
        lazygit = unstablePkgs.yaziPlugins.lazygit;
        # [性能] 扩展名数据库取代 file(1) 子进程, mime 探测提速
        mime-ext = unstablePkgs.yaziPlugins.mime-ext;
        # [预览] 压缩包预览/打包, zip/7z/rar/xz/zstd 全谱
        ouch = unstablePkgs.yaziPlugins.ouch;
        # [导航] 持久化书签 + fzf 跳转
        yamb = unstablePkgs.yaziPlugins.yamb;
        # [预览] +/- 缩放预览图
        zoom = unstablePkgs.yaziPlugins.zoom;
      }
      // lib.optionalAttrs isDarwin {
        # [macOS] Finder 标签互通, 仅 darwin(WSL 的 ide profile 跳过)
        mactag = unstablePkgs.yaziPlugins.mactag;
      };

    initLua = ''
      require("mime-ext"):setup()
      require("git"):setup()
      require("full-border"):setup { type = ui.Border.ROUNDED }
      require("yatline"):setup()
      require("yamb"):setup {}
    '';

    settings = {
      # yazi.toml
      plugin = {
        prepend_fetchers = [
          {url = "*"; run = "git"; group = "git";}
          {url = "*/"; run = "git"; group = "git";}
        ];
        prepend_previewers = [
          {mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}"; run = "ouch";}
        ];
      };
    };

    keymap = {
      # keymap.toml
      mgr.prepend_keymap =
        [
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "进入目录或打开文件";
          }
          {
            on = "p";
            run = "plugin smart-paste";
            desc = "粘贴到 hover 目录或当前目录";
          }
          {
            on = "F";
            run = "plugin smart-filter";
            desc = "连续过滤";
          }
          {
            on = "T";
            run = "plugin toggle-pane max-preview";
            desc = "预览面板最大化/还原";
          }
          {
            on = "C";
            run = "plugin ouch";
            desc = "压缩选中文件";
          }
          {
            on = ["g" "i"];
            run = "plugin lazygit";
            desc = "打开 lazygit";
          }
          {
            on = ["u" "a"];
            run = "plugin yamb -- save";
            desc = "添加书签";
          }
          {
            on = ["u" "g"];
            run = "plugin yamb -- jump_by_key";
            desc = "按键跳转书签";
          }
          {
            on = ["u" "G"];
            run = "plugin yamb -- jump_by_fzf";
            desc = "fzf 跳转书签";
          }
          {
            on = ["u" "d"];
            run = "plugin yamb -- delete_by_key";
            desc = "按键删除书签";
          }
          {
            on = ["u" "r"];
            run = "plugin yamb -- rename_by_key";
            desc = "按键重命名书签";
          }
          {
            on = ["u" "A"];
            run = "plugin yamb -- delete_all";
            desc = "清空书签";
          }
          {
            on = "+";
            run = "plugin zoom 1";
            desc = "预览图放大";
          }
          {
            on = "-";
            run = "plugin zoom -1";
            desc = "预览图缩小";
          }
        ]
        ++ lib.optionals isDarwin [
          {
            on = ["b" "a"];
            run = "plugin mactag add";
            desc = "macOS 标记选中文件";
          }
          {
            on = ["b" "r"];
            run = "plugin mactag remove";
            desc = "macOS 取消标记";
          }
        ];
    };
  };
}
