{ pkgs, lib, config, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
  venvPython = "${pkgs.python313}/bin/python";
  venvPath = "${config.home.homeDirectory}/.cache/ov-venv";
  configPathRelativeToHome = ".openviking/ov.conf";
  cliConfigPathRelativeToHome = ".openviking/ovcli.conf";
  configPath = "${config.home.homeDirectory}/${configPathRelativeToHome}";
  cliConfigPath = "${config.home.homeDirectory}/${cliConfigPathRelativeToHome}";
in {
  config = lib.mkIf isLinux {
    home.activation.ovSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "初始化 OpenViking 环境..."

      # 创建配置目录
      mkdir -p "${config.home.homeDirectory}/.config/ov"
      mkdir -p "${config.home.homeDirectory}/.openviking"

      # 清理损坏的环境
      if [ -d "${venvPath}" ]; then
        if [ ! -f "${venvPath}/bin/activate" ]; then
          echo "清理损坏的虚拟环境..."
          rm -rf "${venvPath}"
        fi
      fi

      # 创建虚拟环境
      if [ ! -d "${venvPath}" ]; then
        echo "创建 uv 虚拟环境: ${venvPath}"
        ${pkgs.uv}/bin/uv venv --python ${venvPython} "${venvPath}"
      fi

      # 安装 OpenViking 0.2.13
      echo "安装 OpenViking 0.2.13..."
      source "${venvPath}/bin/activate"
      ${pkgs.uv}/bin/uv pip install \
        --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
        openviking==0.2.13
    '';

    # sops 解密配置文件
    programs.sops = {
      decryptFiles = [{
        from = "secrets/.config/ov/ov.conf";
        to = configPathRelativeToHome;
      } {
        from = "secrets/.config/ov/ovcli.conf";
        to = cliConfigPathRelativeToHome;
      }];
    };

    # 启动脚本
    home.packages = [
      (pkgs.writeShellScriptBin "ov" ''
        export OPENVIKING_CONFIG_FILE="${configPath}"
        export OPENVIKING_CLI_CONFIG_FILE="${cliConfigPath}"
        export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
        exec "${venvPath}/bin/ov" "$@"
      '')
      (pkgs.writeShellScriptBin "openviking" ''
        export OPENVIKING_CONFIG_FILE="${configPath}"
        export OPENVIKING_CLI_CONFIG_FILE="${cliConfigPath}"
        export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
        exec "${venvPath}/bin/openviking" "$@"
      '')
      (pkgs.writeShellScriptBin "openviking-server" ''
        export OPENVIKING_CONFIG_FILE="${configPath}"
        export OPENVIKING_CLI_CONFIG_FILE="${cliConfigPath}"
        export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
        exec "${venvPath}/bin/openviking-server" "$@"
      '')
    ];

    home.sessionVariables = {
      OPENVIKING_CONFIG_FILE = configPath;
      OPENVIKING_CLI_CONFIG_FILE=cliConfigPath;
    };

    # pm2 服务配置
    programs.pm2 = {
      enable = true;
      services = [{
        name = "openviking-server";
        script = "${venvPath}/bin/openviking-server";
        args = "--host 0.0.0.0 --port 1933 --with-bot";
        interpreter = "${venvPath}/bin/python";
        env = {
          OPENVIKING_CONFIG_FILE = configPath;
          OPENVIKING_CLI_CONFIG_FILE=cliConfigPath;
          LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH";
        };
        exp_backoff_restart_delay = 100;
      }];
    };
  };
}
