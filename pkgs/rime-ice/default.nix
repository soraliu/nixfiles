# 雾凇拼音（rime-ice）上游方案包
# 从 GitHub 获取 rime-ice 的 schema、dict、lua、opencc 等文件
# 用于 home/modules/darwin/apps/rime 模块部署到 ~/Library/Rime/
{ pkgs, lib, ... }:
let
  cfg = {
    version = "2026.03.16";
    rev = "18cb213d9f9da76ac58dae67fc428220889e370e";
    sha256 = "0g3ak7x725y418hsc5lyi1jm068sb2qnng2nwsimqlklfm90hnvc";
  };
in
{
  options.programs.rimeIce = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = lib.mdDoc "Whether to enable rime-ice schema deployment.";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = cfg.version;
      description = lib.mdDoc "Version of rime-ice to use.";
    };
    src = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fetchFromGitHub {
        owner = "iDvel";
        repo = "rime-ice";
        rev = cfg.rev;
        sha256 = cfg.sha256;
      };
      description = lib.mdDoc "rime-ice source package.";
    };
  };
}
