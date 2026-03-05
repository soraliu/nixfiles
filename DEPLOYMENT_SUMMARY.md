# OpenClaw + vLLM + GLM-4.7-Flash 部署总结

## 部署日期
2026-03-05 至 2026-03-06

## 部署状态
🟡 **部分完成** - vLLM 模型正在加载中，OpenClaw 需要修复依赖

## 已完成的工作

### 1. Nix 模块创建 ✅

#### vLLM 模块
- **文件**: `home/modules/ai/vllm/default.nix`
- **功能**:
  - Python 虚拟环境管理 (`~/.local/share/uv/vllm-env`)
  - PM2 服务配置
  - 环境变量配置 (CUDA, LD_LIBRARY_PATH, CC, CXX)
  - 自动初始化脚本

#### OpenClaw 模块
- **文件**: `home/modules/ai/openclaw/default.nix`
- **功能**:
  - Node.js 22 和 pnpm 依赖
  - PM2 服务配置
  - 自动克隆 clawfiles 仓库

#### Python 模块更新
- **文件**: `home/modules/lang/python.nix`
- **更新**: 添加 huggingface-hub (unstable 版本)

### 2. clawfiles 仓库初始化 ✅

- **仓库**: https://github.com/soraliu/clawfiles
- **位置**: `~/.openclaw`
- **内容**:
  - `openclaw.json` - 主配置文件 (包含 Telegram bot token)
  - `package.json` - Node.js 依赖
  - `pnpm-lock.yaml` - 锁定文件
  - `skills/`, `hooks/`, `workflows/`, `scripts/` - 目录结构
  - OpenClaw 2026.3.2 已安装为本地依赖

### 3. 模型下载 ✅

- **模型**: cyankiwi/GLM-4.7-Flash-AWQ-4bit
- **位置**: `~/.cache/huggingface/hub/models--cyankiwi--GLM-4.7-Flash-AWQ-4bit/`
- **大小**: 约 18.9GB (4 个 safetensors 文件)
- **量化**: compressed-tensors (WNA16, 4-bit)

### 4. 环境配置 ✅

#### vLLM 环境
- Python 虚拟环境: `~/.local/share/uv/vllm-env`
- vLLM 版本: 0.16.0
- PyTorch 版本: 2.9.1+cu128
- Transformers 版本: 5.3.0

#### 环境变量
```bash
CUDA_VISIBLE_DEVICES=0
HF_HOME=~/.cache/huggingface
LD_LIBRARY_PATH=/usr/lib/wsl/lib:${gcc-lib}/lib
CC=${gcc}/bin/gcc
CXX=${gcc}/bin/g++
```

### 5. PM2 服务配置 ✅

#### vLLM 服务
```javascript
{
  name: "vllm-glm4-flash",
  script: "~/.local/share/uv/vllm-env/bin/python",
  args: "-m vllm.entrypoints.openai.api_server --model cyankiwi/GLM-4.7-Flash-AWQ-4bit --quantization compressed-tensors --dtype auto --max-model-len 32768 --gpu-memory-utilization 0.90 --port 8000 --host 127.0.0.1",
  env: { /* 见上方环境变量 */ }
}
```

#### OpenClaw 服务
```javascript
{
  name: "openclaw",
  script: "~/.openclaw/node_modules/.bin/openclaw",
  args: "gateway",
  cwd: "~/.openclaw"
}
```

### 6. Git 提交记录 ✅

#### nixfiles 仓库
```
a2ef000 fix(ai): add CC and CXX environment variables for Triton compilation
783e5f5 fix(ai): add LD_LIBRARY_PATH for vLLM and improve activation script
790b1e3 fix(ai): add git and npm to PATH in OpenClaw activation script
b40fe2a fix(ai): remove global OpenClaw installation, use npx instead
b7ed1dc fix(nodejs): make Volta initialization more robust with error handling
2da168b fix(ai): add WSL2 CUDA library path to LD_LIBRARY_PATH
6e50a15 fix(ai): add --device cuda flag and DEBUG logging for vLLM
b94dd27 fix(ai): remove unsupported --device flag and DEBUG logging from vLLM
85ce679 fix(ai): reduce max-model-len to 32768 and gpu-memory-utilization to 0.85
cf89203 fix(ai): further reduce max-model-len to 16384 and gpu-memory-utilization to 0.80
c4ee7ad feat(ai): switch to AWQ 4-bit quantized model to reduce VRAM usage
11594e1 fix(ai): use locally installed OpenClaw instead of npx
f2fed7c fix(ai): use compressed-tensors quantization instead of awq
```

#### clawfiles 仓库
```
ceae66c feat: initialize OpenClaw configuration
f0ec70e feat: switch to AWQ 4-bit quantized model
8875eb8 feat: add OpenClaw as local dependency
```

## 当前状态

### vLLM 服务 🟡
- **状态**: 运行中 (online)
- **运行时间**: 10+ 分钟
- **GPU 显存**: 19GB / 32GB
- **进程**: PID 436438 (python3.12)
- **问题**: 模型加载时间过长，日志停在 "Starting to load model" 之后
- **可能原因**:
  - 模型文件较大 (18.9GB)
  - Marlin 内核编译需要时间
  - WSL2 I/O 性能限制

### OpenClaw 服务 ❌
- **状态**: 重启循环 (waiting restart)
- **问题**: 依赖已安装，但服务启动失败
- **原因**: 需要进一步调试

## 待完成的任务

### 1. 等待 vLLM 模型加载完成 ⏳
- 预计还需 5-10 分钟
- 需要监控日志直到看到 "Uvicorn running" 或 "Application startup complete"

### 2. 测试 vLLM API ⏳
```bash
# 测试模型列表
curl http://127.0.0.1:8000/v1/models

# 测试推理
curl http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cyankiwi/GLM-4.7-Flash-AWQ-4bit",
    "messages": [{"role": "user", "content": "你好"}],
    "max_tokens": 100
  }'
```

### 3. 修复 OpenClaw 服务 ⏳
```bash
# 检查日志
pm2 logs openclaw --err --lines 50

# 可能需要的操作
cd ~/.openclaw
pnpm install  # 重新安装依赖
pm2 restart openclaw
```

### 4. 测试 Telegram Bot ⏳
1. 在 Telegram 中搜索你的 bot
2. 发送 `/start`
3. 发送测试消息: "你好，请介绍一下你自己"
4. 验证 bot 通过本地 GLM-4.7-Flash 回复

### 5. 创建 Skill 文档 ⏳
- 位置: `~/Github/spec-for-agi/skills/nixos-ai-agent-deployment/`
- 内容:
  - `SKILL.md` - 主文档
  - `scripts/verify-deployment.sh` - 验证脚本
  - `references/nix-modules.md` - Nix 模块参考
  - `references/openclaw-config.md` - OpenClaw 配置参考

### 6. 推送所有更改 ⏳
```bash
cd ~/Github/nixfiles && git push
cd ~/Github/spec-for-agi && git add . && git commit -m "feat(skill): add nixos-ai-agent-deployment skill" && git push
```

## 关键技术问题和解决方案

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| PyTorch 检测不到 CUDA | WSL2 CUDA 库路径未包含 | 添加 `/usr/lib/wsl/lib` 到 `LD_LIBRARY_PATH` |
| Triton 编译失败 | 找不到 C 编译器 | 设置 `CC` 和 `CXX` 环境变量 |
| Transformers 不识别模型 | 版本过旧 | 升级到 5.3.0 |
| npm 全局安装失败 | Nix store 只读 | 改用本地安装 (pnpm add) |
| vLLM 参数错误 | `--device` 不被支持 | 移除该参数 |
| 量化方法不匹配 | 模型使用 compressed-tensors | 更新 `--quantization` 参数 |
| GPU 内存不足 | BF16 模型太大 (59GB) | 使用 4-bit 量化模型 (19GB) |
| 模型下载卡住 | huggingface-cli 超时 | 使用 wget 直接下载 |

## 系统架构

```
┌─────────────────┐
│  Telegram Bot   │
└────────┬────────┘
         │
         v
┌─────────────────┐      ┌──────────────┐
│    OpenClaw     │─────>│  vLLM API    │
│   (Node.js)     │      │  (Python)    │
└─────────────────┘      └──────┬───────┘
         │                       │
         v                       v
┌─────────────────┐      ┌──────────────┐
│   clawfiles     │      │ GLM-4.7-Flash│
│  (Git Config)   │      │   (4-bit)    │
└─────────────────┘      └──────────────┘
```

## 性能指标

- **模型大小**: 18.9GB (量化后)
- **GPU 显存占用**: 19GB (加载中)
- **预期显存占用**: 20-22GB (运行时)
- **上下文长度**: 32768 tokens
- **GPU 利用率**: 90%

## 下一步建议

1. **立即**: 等待 vLLM 模型加载完成 (监控 GPU 显存和日志)
2. **然后**: 测试 vLLM API 是否正常工作
3. **接着**: 修复 OpenClaw 服务并测试 Telegram Bot
4. **最后**: 创建 Skill 文档并推送所有更改

## 优化建议

### 短期优化
1. 增加 PM2 日志级别以便调试
2. 添加健康检查脚本
3. 配置自动重启策略

### 长期优化
1. 考虑使用 GGUF 格式模型 (更小的显存占用)
2. 实现模型缓存预热
3. 添加监控和告警
4. 配置负载均衡 (如果需要多实例)

## 参考资料

- [vLLM 文档](https://docs.vllm.ai/)
- [OpenClaw 文档](https://openclaw.ai/)
- [GLM-4 模型卡](https://huggingface.co/THUDM/glm-4-9b-chat)
- [Compressed Tensors 量化](https://github.com/neuralmagic/compressed-tensors)
- [WSL2 CUDA 支持](https://docs.nvidia.com/cuda/wsl-user-guide/)

## 联系信息

- nixfiles: https://github.com/soraliu/nixfiles
- clawfiles: https://github.com/soraliu/clawfiles
- spec-for-agi: https://github.com/soraliu/spec-for-agi

---

**最后更新**: 2026-03-06 01:02 UTC
**部署者**: Claude Code (Opus 4.6)
