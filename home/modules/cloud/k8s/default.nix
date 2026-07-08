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
    };
  };
}
