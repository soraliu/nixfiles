{ pkgs, lib, config, inputs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;

  vllmLib = import ./lib.nix { inherit pkgs lib config; };

  # 顶层 symlink，用于 nix run 调试入口
  vllmModulePath = "${config.home.homeDirectory}/.cache/vllm-flake";

  # 通用 vllm CLI wrapper（不绑定特定模型，使用 nix 的 python 环境）
  vllmWrapper = pkgs.writeShellScriptBin "vllm" ''
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${vllmLib.libPath}:$LD_LIBRARY_PATH"
    exec ${vllmLib.vllmPython}/bin/python -m vllm.entrypoints.openai.api_server "$@"
  '';

  # 导入所有模型配置
  models = [
    { cfg = import ./models/glm-4.7-flash/config.nix; }
    # { cfg = import ./models/qwen3.5-chat/config.nix; }
    # { cfg = import ./models/qwen3-embedding-4b/config.nix; }
    # 新增模型：在此添加一行
  ];

  aggregated = vllmLib.mkModels models;

in {
  imports = [
    ../../../../pkgs/pm2
  ];

  config = lib.mkIf isLinux {
    # 顶层 symlink，用于 cd ~/.cache/vllm-flake && nix run .#vllm-<name> 调试
    home.file."${vllmModulePath}".source = ./.;

    home.packages = aggregated.packages ++ aggregated.wrappers ++ aggregated.socatScripts ++ [
      vllmWrapper
    ];

    # pm2 服务配置 — 统一由 pm2 管理进程生命周期
    programs.pm2 = {
      enable = true;
      services = aggregated.pm2Services;
    };
  };
}
