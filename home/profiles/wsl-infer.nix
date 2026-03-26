{ lib, system, ... }:
let
  isLinux = system == "x86_64-linux" || system == "aarch64-linux";
in
{
  # Inherit all configurations from ide.nix
  imports = [
    ./ide.nix
  ] ++ (lib.optionals isLinux [
    ../modules/ai/vllm
  ]);
}
