{ useCommon, ... }: {
  imports = [
    # required
    ./pkg-manager
  ] ++ (if useCommon then [
    ./fs
    ./ide
    ./ai
    ./lang
    ./network
    ./process
    ./tools
  ] else []);
}
