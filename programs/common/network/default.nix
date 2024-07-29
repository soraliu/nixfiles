{ pkgs, ... }: {
  imports = [
    ./clash-meta
  ];

  home.packages = with pkgs; [
    # # network
    inetutils                                 # provide: `telnet`, `ftp`, `hostname`, `ifconfig`, `traceroute`, `ping`, etc
    wget                                      # wget
    curl                                      # curl
    wrk                                       # API pressure test tool
    dogdns                                    # dig alternative
    bandwhich                                 # show network usage by process, need be executed by `sudo bandwhich`
                                                # Github: https://github.com/imsnif/bandwhich
  ];
}
