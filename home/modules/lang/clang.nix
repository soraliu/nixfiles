{ pkgs, ... }: {
  config.home.packages = with pkgs; builtins.filter (el: el != "") [
    (if !pkgs.stdenv.isDarwin then
      clang_16      # better than gcc13, provide c++ compiler
    else "")
    (if !pkgs.stdenv.isDarwin then
      clang-tools  # better than gcc13, provide c++ tools (use latest version)
    else "")
  ];
}
