# plannotator: 本地浏览器端 plan/文档/diff 审阅层 (backnotprop/plannotator)
#
# 集成方式 = CLI (进 PATH) + 官方 core Agent Skills (~/.agents/skills 共享目录):
#   - CLI: GitHub Releases 裸二进制 (Bun standalone ~150MB, dontUnpack/dontStrip)
#   - skills: repo apps/skills/core 下 4 个, 与 CLI 锚定同一 release tag, 版本一处改
#   - omp 的 agents provider 默认发现 ~/.agents/skills (lark-* 同款);
#     本机 ~/.omp/agent/skills 是 just init 自建 skill 管线的根, 不碰
# 不装宿主插件 (pi-extension)/hooks: plan 退出自动审阅等宿主行为见 PLAN-plannotator.md
#
# 版本升级 = 改 version + 4 平台 hash (release 资产 .sha256 hex → nix hash convert
# --to sri) + skills tarball prefetch (nix-prefetch-url --unpack <tar.gz>)
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

  # skills 与 CLI 同 tag, 版本一致性锚定
  skills-src = pkgs.fetchFromGitHub {
    owner = "backnotprop";
    repo = "plannotator";
    rev = "v${version}";
    hash = "sha256-QxyDUNlf7gvuyb22iNwdzt4vYafF9kDzTu1oj2bMfnU=";
  };
in
{
  config.home.packages = [ plannotator-cli ];

  # ~/.agents/skills: Agent Skills 共享目录, 目录自身由其他流程管理 (npx skills 等),
  # home.file 只声明这 4 个条目; nix store symlink 对 omp/pi 的 SKILL.md 读取透明
  config.home.file = {
    ".agents/skills/plannotator".source = "${skills-src}/apps/skills/core/plannotator";
    ".agents/skills/plannotator-review".source = "${skills-src}/apps/skills/core/plannotator-review";
    ".agents/skills/plannotator-annotate".source = "${skills-src}/apps/skills/core/plannotator-annotate";
    ".agents/skills/plannotator-last".source = "${skills-src}/apps/skills/core/plannotator-last";
  };
}
