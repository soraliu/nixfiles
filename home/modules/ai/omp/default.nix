{ omp, system, ... }: {
  # oh-my-pi (omp): pi-mono 的姊妹发行版,双栈并存试用(plans/omp-switch.md)
  # 包 output 为 packages.<system>.omp(上游 flake 同时提供 homeManagerModules,
  # 但试用期 settings 留在 ~/.omp 平文件管理,不声明式化)
  config.home.packages = [
    omp.packages.${system}.omp
  ];
}
