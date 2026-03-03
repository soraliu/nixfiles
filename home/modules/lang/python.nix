{ pkgs, ... }: {
  config.home.packages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.pypdf
    python312Packages.pdfplumber
    uv
  ];
}
