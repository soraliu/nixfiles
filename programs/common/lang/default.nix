{ pkgs, ... }: {
  home.packages = with pkgs; builtins.filter (el: el != "") [
    (if !pkgs.stdenv.isDarwin then
      clang_16                                # better than gcc13, provide c++ compiler
    else "")
    clang-tools_16                            # better than gcc13, provide c++ tools

    nodejs_20                                 # nodejs, npm

    python3                                   # python3
    python311Packages.pip                     # pip3

    rustc                                     # rust
    cargo                                     # rust package maanger

    stylua                                    # lua

    go                                        # go

    sqlite                                    # db
  ];

  home.sessionVariables = {
    GOPATH = "$HOME/go";
    PATH = "${pkgs.nodejs_20}/bin:$GOPATH/bin:$PATH";
  };
}
