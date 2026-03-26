{ claude-code, system, ... }: {
  config.home.packages = [
    claude-code.packages.${system}.default
  ];
}
