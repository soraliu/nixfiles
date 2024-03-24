{ pkgs, ... }: {
  home.packages = with pkgs; [
    # doc
    tldr                                      # community-maintained help pages
                                                # Github: https://github.com/tldr-pages/tldr

    # makefile
    gnumake                                   # provide make

    # # TODO: get familiar with these commands
    # bup                                       # dedup backup tool

    unixtools.whereis                         # whereis

    # string
    sd                                        # sed alternative
    jq                                        # jq format
  ];
}
