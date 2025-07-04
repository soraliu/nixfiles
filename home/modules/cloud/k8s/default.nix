{ pkgs, config, ... }: {
  config = {
    home = {
      packages = with pkgs; [
        kubectl
        kubernetes-helm
        istioctl
      ];
    };
  };
}
