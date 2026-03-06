{ lib, pkgs, unstablePkgs, system, ... }:
{
  # 继承 ide.nix 的所有配置
  imports = [
    ./ide.nix
    ./modules/ai/vllm
  ];

  # WSL 推理环境标识
  home.sessionVariables = {
    WSL_INFER_ENV = "true";
  };
}
