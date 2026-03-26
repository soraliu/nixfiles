# 可复用的 openclaw HM 模块：pnpm global install + launchd/systemd 服务
# 配置文件由消费者通过 configPath 指定（如 clawfiles repo 中的 openclaw.json）
{ pkgs, config, lib, ... }:

let
  cfg = config.programs.openclawLocal;
  homeDir = config.home.homeDirectory;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  voltaBin = "${homeDir}/.volta/bin";
  pnpmHome = "${homeDir}/.local/share/pnpm";
  profileDir = config.home.profileDirectory;
  goPath = "${homeDir}/go";
  # PATH 与 home/modules/ide/zsh/init.zsh 保持一致（prepend 语义，优先级从高到低）
  darwinPath = lib.concatStringsSep ":" [
    voltaBin                              # nodejs (volta) — highest priority
    pnpmHome                              # pnpm
    "${homeDir}/.local/bin"               # user local binaries
    "${goPath}/bin"                       # golang
    "${profileDir}/bin"                   # nix home-manager profile
    "/run/current-system/sw/bin"          # nix-darwin system
    "/nix/var/nix/profiles/default/bin"   # nix default profile
    "/opt/homebrew/bin"                   # macOS homebrew
    "${homeDir}/.mint/bin"                # macOS mint
    "/usr/bin"
    "/bin"
  ];
  linuxPath = lib.concatStringsSep ":" [
    voltaBin                              # nodejs (volta) — highest priority
    pnpmHome                              # pnpm
    "${homeDir}/.local/bin"               # user local binaries
    "${goPath}/bin"                       # golang
    "${profileDir}/bin"                   # nix home-manager profile
    "/run/current-system/sw/bin"          # nixos system
    "/nix/var/nix/profiles/default/bin"   # nix default profile
    "/usr/bin"
    "/bin"
  ];
in
{
  options.programs.openclawLocal = {
    enable = lib.mkEnableOption "OpenClaw gateway (pnpm global install)";

    version = lib.mkOption {
      type = lib.types.str;
      default = "2026.3.24";
      description = "固定的 openclaw 版本号，通过 pnpm add -g openclaw@version 安装。";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/.openclaw";
      description = "OpenClaw 状态目录（日志、会话），对应 OPENCLAW_HOME。";
    };

    gatewayPort = lib.mkOption {
      type = lib.types.int;
      default = 18789;
      description = "Gateway 监听端口。";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.stateDir}/openclaw.json";
      description = "openclaw.json 配置文件路径（由外部提供，如 clawfiles repo）。";
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables.OPENCLAW_HOME = homeDir;

    # 通过 volta 管理的 pnpm 安装固定版本
    # 依赖 nodejs.nix 中 volta install pnpm 已完成
    # pnpm 10+ 默认阻止依赖 build scripts（供应链安全），需 approve-builds 批准
    # 否则 sharp 等原生模块不会编译，导致运行时报错
    # 依赖 nodejs.nix 中 initPnpm 已完成 pnpm 目录初始化
    home.activation.installOpenclaw = lib.hm.dag.entryAfter [ "initPnpm" ] ''
      export PATH="${voltaBin}:${pnpmHome}:${lib.getBin pkgs.git}/bin:$PATH"
      export VOLTA_HOME="${homeDir}/.volta"
      export PNPM_HOME="${pnpmHome}"
      run ${voltaBin}/pnpm add -g openclaw@${cfg.version}
      run ${voltaBin}/pnpm approve-builds -g --all
    '';

    # 状态目录
    home.activation.openclawDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p \
        ${cfg.stateDir} \
        ${homeDir}/.openclaw/logs
    '';

    # macOS: launchd agent
    launchd.agents."ai.openclaw.gateway" = lib.mkIf isDarwin {
      enable = true;
      config = {
        Label = "ai.openclaw.gateway";
        ProgramArguments = [
          "${pnpmHome}/openclaw"
          "gateway"
          "--port"
          "${toString cfg.gatewayPort}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 1;
        WorkingDirectory = cfg.stateDir;
        StandardOutPath = "${homeDir}/.openclaw/logs/gateway.log";
        StandardErrorPath = "${homeDir}/.openclaw/logs/gateway.err.log";
        EnvironmentVariables = {
          HOME = homeDir;
          VOLTA_HOME = "${homeDir}/.volta";
          PATH = darwinPath;
          NODE_EXTRA_CA_CERTS = "/etc/ssl/cert.pem";
          NODE_USE_SYSTEM_CA = "1";
          OPENCLAW_CONFIG_PATH = cfg.configPath;
          OPENCLAW_STATE_DIR = cfg.stateDir;
          OPENCLAW_IMAGE_BACKEND = "sips";
          OPENCLAW_GATEWAY_PORT = toString cfg.gatewayPort;
          OPENCLAW_LAUNCHD_LABEL = "ai.openclaw.gateway";
          OPENCLAW_SERVICE_MARKER = "openclaw";
          OPENCLAW_SERVICE_KIND = "gateway";
          OPENCLAW_SERVICE_VERSION = cfg.version;
        };
      };
    };

    # Linux: systemd user service
    systemd.user.services."openclaw-gateway" = lib.mkIf isLinux {
      Unit.Description = "OpenClaw gateway";
      Service = {
        ExecStart = "${pnpmHome}/openclaw gateway --port ${toString cfg.gatewayPort}";
        WorkingDirectory = cfg.stateDir;
        Restart = "always";
        RestartSec = "1s";
        Environment = [
          "HOME=${homeDir}"
          "VOLTA_HOME=${homeDir}/.volta"
          "PATH=${linuxPath}"
          "OPENCLAW_CONFIG_PATH=${cfg.configPath}"
          "OPENCLAW_STATE_DIR=${cfg.stateDir}"
          "OPENCLAW_GATEWAY_PORT=${toString cfg.gatewayPort}"
          "OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
          "OPENCLAW_SERVICE_MARKER=openclaw"
          "OPENCLAW_SERVICE_KIND=gateway"
          "OPENCLAW_SERVICE_VERSION=${cfg.version}"
        ];
        StandardOutput = "append:${homeDir}/.openclaw/logs/gateway.log";
        StandardError = "append:${homeDir}/.openclaw/logs/gateway.err.log";
      };
    };
  };
}
