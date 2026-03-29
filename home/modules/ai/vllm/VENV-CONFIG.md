# vLLM 动态版本配置

## 功能

支持为每个模型指定独立的 vLLM/torch/transformers 版本，自动创建隔离的 venv。

## 配置方式

在模型的 `config.nix` 中添加 `pythonDeps` 字段：

```nix
{
  name = "vllm-model-name";
  model = "model/path";

  # 可选：指定 Python 依赖版本
  pythonDeps = {
    vllm = "0.18.0";           # 必选（或 "latest"）
    torch = "2.10.0";          # 可选，通过 override 强制版本
    transformers = "5.4.0";    # 可选，通过 override 强制版本
  };

  # ... 其他配置
}
```

## 版本处理逻辑

- **vllm**: 指定版本或使用 "latest"
- **torch/transformers**:
  - 指定时：生成 override 文件强制使用该版本
  - 不指定时：使用 vllm 声明的依赖版本

## venv 命名

根据版本组合生成唯一路径：`~/.cache/vllm-venv-{hash}`

示例：
- `{ vllm = "0.18.0"; transformers = "5.4.0"; }` → `vllm-venv-abc12345`
- `{ vllm = "0.18.0"; }` → `vllm-venv-def67890`
- `{}` (默认) → `vllm-venv-xyz98765`

## 使用步骤

1. 修改模型配置添加 `pythonDeps`
2. 运行 `home-manager switch`
3. 检查 venv：`ls -la ~/.cache/vllm-venv-*`
4. 验证版本：`~/.cache/vllm-venv-*/bin/python -c "import vllm; print(vllm.__version__)"`
5. 启动模型：`nix run ~/.cache/vllm-flake#vllm-model-name`

## 示例配置

### 默认版本（无配置）
```nix
{ name = "vllm-model"; model = "path"; }
```
使用最新版本 vllm 及其依赖。

### 指定 vllm 版本
```nix
{
  name = "vllm-model";
  pythonDeps = { vllm = "0.18.0"; };
}
```
使用 vllm 0.18.0 及其声明的依赖。

### 指定 vllm + override transformers
```nix
{
  name = "vllm-model";
  pythonDeps = {
    vllm = "0.18.0";
    transformers = "5.4.0";
  };
}
```
使用 vllm 0.18.0，强制 transformers 5.4.0。
