{ pi, system, ... }: {
  config.home.packages = [
    pi.packages.${system}.coding-agent
  ];
}
