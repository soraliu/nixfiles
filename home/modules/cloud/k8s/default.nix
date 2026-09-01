{ pkgs, unstablePkgs, config, ... }: {
  config = {
    home = {
      packages = (with pkgs; [
        awscli2
        redis
        istioctl
        cilium-cli
        k9s
        yq-go
        minio-client
      ]) ++ (with unstablePkgs; [
        prometheus
        fluxcd
        kubectl
        kubectl-explore
        kubectl-node-shell
        kubectl-view-allocations
        kubectl-ktop
        kubernetes-helm
        kubectl-cnpg
        doctl
      ]);

      file.".config/k9s/config.yaml" = {
        source = ./config.yaml;
        force = true;
      };

      sessionVariables.K9S_CONFIG_DIR = "${config.home.homeDirectory}/.config/k9s";
    };
  };
}
