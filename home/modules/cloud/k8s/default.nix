{ pkgs, unstablePkgs, config, ... }: {
  config = {
    home = {
      packages = (with pkgs; [
        kubectl
        kubectl-explore
        kubectl-node-shell
        kubectl-ktop
        kubectl-cnpg
        kubernetes-helm
        redis
        istioctl
        cilium-cli
        k9s
        yq-go
      ]) ++ (with unstablePkgs; [
        fluxcd
      ]);
    };
  };
}
