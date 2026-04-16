{ pkgs, ... }:

{
  home.packages = with pkgs; [
    iperf3
    dog # modern DNS client, replaces dogdns, Github: https://github.com/ogham/dog
    bandwhich # show network usage by process, need be executed by `sudo bandwhich`, Github: https://github.com/imsnif/bandwhich
    htop-vim # better top, Github: https://github.com/KoffeinFlummi/htop-vim
  ];
}
