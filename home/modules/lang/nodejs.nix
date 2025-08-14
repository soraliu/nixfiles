{ unstablePkgs, config, lib, ... }: {
  config.home.packages = with unstablePkgs; [
    volta # node version & binaries manager
  ];
  config.home.sessionVariables = {
    VOLTA_HOME = "$HOME/.volta";
  };
  config.programs.sops.decryptFiles = [{
    from = "secrets/.npmrc.enc";
    to = ".npmrc";
  }];

  config.home.activation.initVolta = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    echo "Enable Volta completion: ${config.programs.zsh.enable}"
    if "${config.programs.zsh.enable}" != "false"; then
      mkdir -p ${config.programs.zsh.completionsDir}
      ${unstablePkgs.volta}/bin/volta completions zsh > ${config.programs.zsh.completionsDir}/_volta
    fi

    export PATH="$HOME/.volta/bin:$PATH"
    ${unstablePkgs.volta}/bin/volta install node
    ${unstablePkgs.volta}/bin/volta install pnpm
  '';
}
