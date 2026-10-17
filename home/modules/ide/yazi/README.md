# yazi

终端文件管理器([sxyazi/yazi](https://github.com/sxyazi/yazi), Rust, 异步 I/O)。本模块本体与全部插件均取自项目的 `nixpkgs-unstable`(`unstablePkgs.yazi` + `unstablePkgs.yaziPlugins.*`),两者 pin 在**同一个 nixpkgs commit** 里——`just update-unstable-pkg` 时同步前进,不存在 `ya pkg` 装到 `~/.config/yazi/plugins` 的版本漂移。

升级日常:

```sh
just update-unstable-pkg && just switch-home ide   # darwin: just switch-darwin soraliu
```

## shell 集成

HM 在 zsh 注入 `yy` 函数(cd-on-quit wrapper):`yy` 启动,退出后 shell 自动 cd 到最后浏览的目录。直接敲 `yazi` 则不带这个行为。

## 键位速查(本模块覆盖项)

| 键 | 动作 | 插件 |
|---|---|---|
| `l` | 进入目录 / 打开文件 | smart-enter |
| `p` | 粘贴到 hover 目录或当前目录 | smart-paste |
| `F` | 连续过滤 | smart-filter |
| `T` | 预览面板最大化 / 还原 | toggle-pane |
| `C` | 压缩选中文件 | ouch |
| `g` `i` | 打开 lazygit | lazygit |
| `u` `a` / `u` `g` / `u` `G` | 加书签 / 按键跳转 / fzf 跳转 | yamb |
| `u` `d` / `u` `r` / `u` `A` | 删书签 / 重命名 / 清空 | yamb |
| `+` / `-` | 预览图放大 / 缩小 | zoom |
| `b` `a` / `b` `r` | macOS 标记 / 取消标记(仅 darwin) | mactag |

除上述前缀键外其余均为 yazi 原生默认(`h/j/k/l` 导航、`y` 复制、`x` 剪切、`Space` 选择、`/` 搜索、`z` zoxide 跳转等)。

## 插件用法明细

### smart-enter(交互)

`l` 一键化:hover 目录则 `enter`,hover 文件则 `open`。默认 `open` 只作用于 hover 单文件(与原生 `enter` 行为一致,避免批量误开);想按一次 `l` 打开所有选中文件,在 `initLua` 改 `require("smart-enter"):setup { open_multi = true }`。

### smart-paste(交互)

`p` 时若 hover 的是目录,粘贴进该目录;hover 文件则贴到当前目录。解决原生 `paste` 只贴 cwd、 无法直接"贴进眼前这个文件夹"的问题。

### smart-filter(交互)

`F` 进入过滤:连续输入持续缩小结果(原生 `filter` 输完即止);若过滤后只剩一个目录,回车直接进入;剩一个文件则打开。按 `Esc` 退出过滤模式,期间用 `Tab` 在结果里跳转。

### toggle-pane(布局)

`T` 循环切换预览栏的 显示 ↔ 隐藏 ↔ 最大化。需要宽列表看文件名时 `T` 收起预览,看大图/长文本时 `T` 放满。`plugin toggle-pane min-preview` 是显式两态切换版本(当前用 max-preview);参数可换 `parent` / `current` 作用到其他栏。

### full-border(视觉)

init.lua 里已 `setup { type = ui.Border.ROUNDED }`,三栏 + 预览整体圆角边框。改成 `ui.Border.PLAIN` 得直角风格。

### yatline(状态栏)

默认 header/status 双行信息(mode、目录、文件计数、选中计数等),`require("yatline"):setup()` 零配置可用。深度自定义(分段、图标、配色、主题)见 [yatline wiki](https://github.com/imsi32/yatline.yazi/wiki) 与 [yatline-themes](https://github.com/imsi32/yatline-themes);配套插件 `yaziPlugins.yatline-githead`(行内 git 分支)如需可在本模块追加上游同名包。

### git(git 状态 linemode)

作为 fetcher(`prepend_fetchers`,group=git)后台拉取,文件列表以 linemode 形式显示 `git status`:新文件 `A`、修改 `M`、未跟踪 `?` 等着色字符。样式可经 `theme = { git = { unstaged = { fg = "blue"; }; ... }; }` 调整。

### lazygit(git TUI)

`g i` 检测当前目录属 git 仓库则挂起 yazi 进 lazygit,退出后回到原位。lazygit 本体在 `ide/git` 模块的 home.packages 里(`unstablePkgs.lazygit`),无额外依赖。整仓库操作(stash/rebase/branch)走这里,单文件 git 状态看上面的 git linemode。

### mime-ext(性能)

用内置扩展名数据库替换 `file(1)` 起子进程探测 mime——Yazi 打开/预览/样式渲染的第一步都依赖 mime,这步从"每个文件 fork 进程"变"查表"。无扩展名文件自动回退原生 `file(1)`,行为无损。

### ouch(压缩包)

- **预览**:yazi.toml 里 `prepend_previewers` 接管 zip/7z/rar/xz/zstd/tar 家族的 mime,`J`/`K` 滚动长列表。
- **压缩**:`C` 打包选中文件,默认 zip;输入文件名时带后缀即按后缀定格式(如 `foo.7z`),或改 `plugin ouch 7z` 固定默认格式。
- 解压不需要插件——yazi 原生支持(选中 `x`)。

### yamb(书签)

书签持久化在 `~/.config/yazi/bookmark`(yazi 会话间保留)。`u a` 把当前目录存为书签(分配随机键),`u g` 按键直跳,`u G` 经 fzf 模糊跳(目录多时用这个),`u d` 删,`u r` 重命名,`u A` 清空。想预置固定书签,在 `initLua` 的 `require("yamb"):setup { bookmarks = { { tag = "Downloads"; path = os.getenv("HOME") .. "/Downloads/"; key = "d"; }; }; }` 里加(完整参数见其 [README](https://github.com/h-hg/yamb.yazi))。

### zoom(预览图)

`+`/`-` 逐级缩放当前 hover 的图片预览。视频/PDF 预览是转成图后同样适用。

### mactag(macOS 专属)

`b a` 给选中文件加 macOS 标签(等于 Finder 里右键彩色标签),`b r` 移除——标签与 Finder/Spotlight 双向可见。依赖 macOS 自带的 `tag` 基建,无需额外二进制。非 darwin 平台(WSL 上的 ide profile)本模块直接跳过该插件与键位。

## 终端要求

- **图片预览**:iTerm2/Kitty/WezTerm/Ghostty/Warp 内置协议开箱即用(本机 iTerm2 ✓);不支持图形协议的终端回退 chafa ASCII 预览
- **图标**:需要 Nerd Font(yatline/yamb 的装饰图标依赖);无则显示为方框,功能不受影响

## 版本注意

- yazi 上游自我定位 public beta,插件间只保证「插件 HEAD ↔ yazi HEAD」对齐;本模块全部走 nixpkgs 单一 pin,对齐关系由 nixpkgs 的 yazi 维护者保证(插件包版本号直接带对应 yazi 版本前缀),这是比 `ya pkg` 更稳的通道
- lazygit 插件上游声明基于 yazi stable,当前 unstable pin 的组合(nixpkgs 打包时点)已对齐
