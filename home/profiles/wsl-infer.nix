{ lib, system, ... }:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";
in
{
  # 继承 ide.nix 的所有配置
  imports = [
    ./ide.nix
  ] ++ (lib.optionals isLinux [
    ../modules/ai/vllm
    ../modules/ai/sglang
  ]);

  # WSL 推理环境标识
  home.sessionVariables = {
    WSL_INFER_ENV = "true";
  };
}
