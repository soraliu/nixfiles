{ pkgs, unstablePkgs, ... }: {
  config.home.packages = (with pkgs; [
    python312
    python312Packages.pip
    python312Packages.pypdf
    python312Packages.pdfplumber
    uv
  ]) ++ (with unstablePkgs; [
    # 使用 unstable 版本的 huggingface-cli（最新版本）
    python312Packages.huggingface-hub
  ]);
}
