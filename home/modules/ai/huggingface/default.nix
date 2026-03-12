{ config, lib, ... }: {
  config = {
    # HuggingFace mirror configuration
    home.sessionVariables = {
      # Use hf-mirror.com as HuggingFace mirror
      HF_ENDPOINT = "https://hf-mirror.com";

      # HuggingFace cache directory
      HF_HOME = "${config.home.homeDirectory}/.cache/huggingface";

      # Transformers cache directory (compatible with old versions)
      TRANSFORMERS_CACHE = "${config.home.homeDirectory}/.cache/huggingface/transformers";

      # HuggingFace Hub cache directory
      HF_HUB_CACHE = "${config.home.homeDirectory}/.cache/huggingface/hub";
    };
  };
}
