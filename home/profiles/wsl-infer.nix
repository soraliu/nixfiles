{ lib, system, ... }:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";
in
{
  # Inherit all configurations from ide.nix
  imports = [
    ./ide.nix
  ] ++ (lib.optionals isLinux [
    ../modules/lang/gcc.nix
    ../modules/ai/vllm
    ../modules/ai/ov
    ../modules/network/ssh
  ]);
}
