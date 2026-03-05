{ pkgs, config, ... }: {
  config = {
    home.packages = with pkgs; [
      # vLLM 通过 uv 安装，这里添加系统依赖
      gcc-unwrapped.lib
      stdenv.cc.cc.lib
    ];

    programs.pm2.services = [{
      name = "vllm-glm4-flash";
      script = "${config.home.homeDirectory}/.local/share/uv/vllm-env/bin/python";
      args = "-m vllm.entrypoints.openai.api_server --model cyankiwi/GLM-4.7-Flash-AWQ-4bit --quantization compressed-tensors --dtype auto --max-model-len 32768 --gpu-memory-utilization 0.90 --port 8000 --host 127.0.0.1";
      cwd = config.home.homeDirectory;
      env = {
        CUDA_VISIBLE_DEVICES = "0";
        HF_HOME = "${config.home.homeDirectory}/.cache/huggingface";
        LD_LIBRARY_PATH = "/usr/lib/wsl/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.gcc-unwrapped.lib}/lib";
        CC = "${pkgs.gcc}/bin/gcc";
        CXX = "${pkgs.gcc}/bin/g++";
      };
      exp_backoff_restart_delay = 5000;
      max_restarts = 3;
      min_uptime = 10000;
    }];

    # 初始化脚本
    home.activation.initVllm = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      VLLM_ENV="${config.home.homeDirectory}/.local/share/uv/vllm-env"

      if [ ! -d "$VLLM_ENV" ]; then
        echo "Creating vLLM environment..."
        ${pkgs.uv}/bin/uv venv "$VLLM_ENV"
        echo "Installing vLLM..."
        cd "$VLLM_ENV" && ${pkgs.uv}/bin/uv pip install vllm
      fi
    '';
  };
}
