{ pkgs, config, ... }: {
  config = {
    home.packages = with pkgs; [
      # vLLM 通过 uv 安装，这里只添加系统依赖
    ];

    programs.pm2.services = [{
      name = "vllm-glm4-flash";
      script = "${config.home.homeDirectory}/.local/share/uv/vllm-env/bin/python";
      args = "-m vllm.entrypoints.openai.api_server --model zai-org/GLM-4.7-Flash --dtype bfloat16 --max-model-len 96000 --gpu-memory-utilization 0.9 --port 8000 --host 127.0.0.1";
      cwd = config.home.homeDirectory;
      env = {
        CUDA_VISIBLE_DEVICES = "0";
        HF_HOME = "${config.home.homeDirectory}/.cache/huggingface";
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
        "$VLLM_ENV/bin/pip" install vllm
      elif [ ! -f "$VLLM_ENV/bin/vllm" ]; then
        echo "vLLM not found in venv, installing..."
        "$VLLM_ENV/bin/pip" install vllm
      fi
    '';
  };
}
