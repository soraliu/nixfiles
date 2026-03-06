{ config, lib, ... }: {
  config = {
    # HuggingFace 镜像配置
    home.sessionVariables = {
      # 使用 hf-mirror.com 作为 HuggingFace 镜像
      HF_ENDPOINT = "https://hf-mirror.com";

      # HuggingFace 缓存目录
      HF_HOME = "${config.home.homeDirectory}/.cache/huggingface";

      # Transformers 缓存目录（兼容旧版本）
      TRANSFORMERS_CACHE = "${config.home.homeDirectory}/.cache/huggingface/transformers";

      # HuggingFace Hub 缓存目录
      HF_HUB_CACHE = "${config.home.homeDirectory}/.cache/huggingface/hub";
    };
  };
}
