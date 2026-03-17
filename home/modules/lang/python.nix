{ pkgs, unstablePkgs, ... }: {
  config.home.packages = (with pkgs; [
    python312
    python312Packages.pip
    python312Packages.pypdf
    python312Packages.pdfplumber
    uv
    ffmpeg
    openai-whisper
  ]) ++ (with unstablePkgs; [
    # Use unstable version of huggingface-cli (latest version)
    python312Packages.huggingface-hub
  ]);
}
