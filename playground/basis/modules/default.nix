let
  add1 = import ./add.nix 1;
in {
  val = add1 2;
}
