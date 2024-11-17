{ useCommon, ... }: {
  imports = [
    # required
    ./pkg-manager
  ] ++ [
    ./fs
    ./ide
    ./ai
    ./lang
    ./network
    ./process
    ./tools
  ];
}
