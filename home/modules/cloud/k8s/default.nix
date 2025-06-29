{ pkgs, config, ... }: {
  config = {
    home = {
      packages = with pkgs; [
        kubectl
      ];
    };
  };
}
