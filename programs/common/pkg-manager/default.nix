{ pkgs, useIndex, ... }: {
  imports = [
    ./home-manager
  ];

  home.packages = with pkgs; builtins.filter (el: el != "") [
    # package manager
    (if useIndex then comma else "")          # run software without installing it (need nix-index)
                                                # Github: https://github.com/nix-community/comma
  ];
}
