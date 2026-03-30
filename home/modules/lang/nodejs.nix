{ unstablePkgs, config, lib, secretsUser, ... }: {
  config.home.packages = with unstablePkgs; [
    volta # node version & binaries manager
    bun
  ];
  config.home.sessionVariables = {
    VOLTA_HOME = "${config.home.homeDirectory}/.volta";
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
  };
  config.programs.sops.decryptFiles = [{
    from = "secrets/users/${secretsUser}/.npmrc.enc";
    to = ".npmrc";
  }];

  config.home.activation.initVoltaCompletion = lib.mkIf config.programs.zsh.enable (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p ${config.programs.zsh.completionsDir}
    ${unstablePkgs.volta}/bin/volta completions zsh > ${config.programs.zsh.completionsDir}/_volta
  '');

  config.home.activation.initVolta = lib.hm.dag.entryAfter [ "initVoltaCompletion" ] ''
    export PATH="${config.home.homeDirectory}/.volta/bin:$PATH"
    ${unstablePkgs.volta}/bin/volta install node
    ${unstablePkgs.volta}/bin/volta install pnpm
  '';

  # pnpm 全局目录初始化，确保 pnpm global bin 可用
  config.home.activation.initPnpm = lib.hm.dag.entryAfter [ "initVolta" "linkGeneration" ] ''
    mkdir -p ${config.home.homeDirectory}/.local/share/pnpm
  '';
}

