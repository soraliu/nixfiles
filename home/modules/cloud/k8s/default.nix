{ pkgs, unstablePkgs, config, ... }: {
  config = {
    home = {
      packages = (with pkgs; [
        kubectl
        kubectl-explore
        kubectl-node-shell
        kubectl-ktop
        kubernetes-helm
        awscli2
        redis
        istioctl
        cilium-cli
        k9s
        yq-go
        minio-client
        doctl
      ]) ++ (with unstablePkgs; [
        fluxcd
        kubectl-cnpg
      ]);
    };
  };
}
