# plannotator: 本地浏览器端 plan/文档/diff 审阅层 (backnotprop/plannotator)
#
# 仅管理 CLI: GitHub Releases 裸二进制 (Bun standalone ~150MB, dontUnpack/dontStrip)。
# 插件与官方 core skills 由 ~/Github/agents 的 profiles 声明并经 just init 安装;
# 升级 CLI 时需核对该仓库中 skills 与插件的版本兼容性。
#
# 版本升级 = 改 version + 4 平台 hash (release 资产 .sha256 hex → nix hash convert
# --to sri)
{
  system,
  pkgs,
  ...
}:
let
  version = "0.28.23";

  # release 资产命名与 sha256 (SRI); hash 取自官方 .sha256 资产, 数学换算非独立校验
  assets = {
    x86_64-linux = {
      asset = "plannotator-linux-x64";
      hash = "sha256-1A3BY96ED0GxVCYRfuSD3G0tv949BYEpZCpvRg1zgw8=";
    };
    aarch64-linux = {
      asset = "plannotator-linux-arm64";
      hash = "sha256-Am5sDssOsXbjLvlnAx75v2MPYob9k0diRCn0fUSHHV8=";
    };
    x86_64-darwin = {
      asset = "plannotator-darwin-x64";
      hash = "sha256-aqovw1tD8TKmXZayOv6chcF+6IVeUGHCDq/0zRCJdjY=";
    };
    aarch64-darwin = {
      asset = "plannotator-darwin-arm64";
      hash = "sha256-6CNMUBBecKK5lCyqKNINlU7sOGUkQ4a3Of7ZQPfeQdM=";
    };
  };
  asset = assets.${system};

  plannotator-cli = pkgs.stdenv.mkDerivation {
    pname = "plannotator";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/${asset.asset}";
      hash = asset.hash;
    };
    # Bun standalone 裸二进制: 不解包不 strip (strip 会破坏内嵌 JS payload)
    dontUnpack = true;
    dontStrip = true;
    installPhase = ''
      install -Dm755 $src $out/bin/plannotator
    '';
  };
in
{
  config.home.packages = [ plannotator-cli ];
}
