{ pkgs, ... }: {
  home.packages = with pkgs; [
    clang_16                                  # better than gcc13, provide c++ compiler
    clang-tools_16                            # better than gcc13, provide c++ tools

    nodejs_20                                 # nodejs, npm

    python3                                   # python3
    python311Packages.pip                     # pip3

    rustc                                     # rust
    cargo                                     # rust package maanger
  ];

  home.sessionVariables = {
    PATH = "${pkgs.nodejs_20}/bin:$PATH";
  };
}
