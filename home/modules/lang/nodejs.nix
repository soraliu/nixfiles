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

  config.home.activation.initVoltaCompletion = lib.mkIf config.programs.zsh.enable (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p ${config.programs.zsh.completionsDir}
    ${unstablePkgs.volta}/bin/volta completions zsh > ${config.programs.zsh.completionsDir}/_volta
  '');

  config.home.activation.initVolta = lib.hm.dag.entryAfter [ "initVoltaCompletion" ] ''
    export PATH="$HOME/.volta/bin:$PATH"
    ${unstablePkgs.volta}/bin/volta install node || echo "Warning: Failed to install node via Volta"
    ${unstablePkgs.volta}/bin/volta install pnpm || echo "Warning: Failed to install pnpm via Volta"
    ${unstablePkgs.volta}/bin/volta install @anthropic-ai/claude-code@latest || echo "Warning: Failed to install claude-code"
    ${unstablePkgs.volta}/bin/volta install openclaw@latest || echo "Warning: Failed to install openclaw"
  '';
}
