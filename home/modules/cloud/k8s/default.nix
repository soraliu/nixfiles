{ pkgs, unstablePkgs, config, ... }: {
  config = {
    home = {
      packages = (with pkgs; [
        kubectl
        kubectl-explore
        kubectl-node-shell
        kubectl-ktop
        kubernetes-helm
        istioctl
        k9s
        yq-go
      ]) ++ (with unstablePkgs; [
        fluxcd
      ]);
    };
  };
}
