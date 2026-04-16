{ codex-cli, system, ... }: {
  config.home.packages = [
    codex-cli.packages.${system}.default
  ];
}
