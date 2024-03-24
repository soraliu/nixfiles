{ pkgs, ... }: {
  imports = [
    ./pm2
  ];

  home.packages = with pkgs; [
    htop-vim                                  # better top
                                                # Github: https://github.com/KoffeinFlummi/htop-vim
  ];
}
