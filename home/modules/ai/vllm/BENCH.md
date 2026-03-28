# benchmark

```bash
wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json

nix develop ~/.cache/vllm-flake#default

# text
vllm bench serve \
  --backend vllm \
  --model GadflyII/GLM-4.7-Flash-NVFP4 \
  --dataset-name sharegpt \
  --dataset-path ./ShareGPT_V3_unfiltered_cleaned_split.json \
  --num-prompts 1000 \
  --request-rate 20

# embedding
vllm bench serve \
  --backend openai-embeddings \
  --model Qwen/Qwen3-VL-Embedding-8B \
  --base-url http://localhost:8013 \
  --endpoint /v1/embeddings \
  --dataset-name random \
  --random-input-len 512 \
  --random-output-len 1 \
  --num-prompts 1000 \
  --request-rate 20
```
