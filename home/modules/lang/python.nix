{ pkgs, unstablePkgs, lib, ... }: let
  # bump nixpkgs-unstable (2026-10-14) 后, huggingface-hub 工具链的一批深层 python
  # 依赖拿不到 Hydra darwin 缓存、只能本地构建, 而其 pytest 在 macOS 上存在环境性
  # 失败 (anyio: test_tls_connectable server_hostname / BlockingPortal unraisable;
  #  aiohttp: test_tcp_connector_socket_factory unraisable)。运行时不受影响。
  # 修复方式: 集合级 overrideScope 让 huggingface-hub 的依赖解析指向跳过检查的
  # 版本; 后续 bump 再遇到同类 darwin 测试失败, 在下方列表追加包名即可。
  darwinSkipCheck = [
    "anyio"
    "aiohttp"
  ];
  python312Unstable = unstablePkgs.python312Packages.overrideScope (self: super:
    lib.genAttrs darwinSkipCheck (name:
      super.${name}.overridePythonAttrs (_: { doCheck = false; })
    )
  );
in {
  config.home.packages = (with pkgs; [
    python312
    python312Packages.pip
    python312Packages.pypdf
    python312Packages.pdfplumber
    uv
    ffmpeg
    openai-whisper
  ]) ++ [
    # Use unstable version of huggingface-cli (latest version)
    python312Unstable.huggingface-hub
  ];
}
