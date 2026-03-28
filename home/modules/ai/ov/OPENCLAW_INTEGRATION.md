# OpenClaw 接入 OpenViking 指南

## 服务端配置

OpenViking 服务端运行在：

- **主机**: wsl-infer 节点 (10.1.1.3)
- **端口**: 1933
- **地址**: `http://10.1.1.3:1933`

服务通过 pm2 管理，自动启动。

## OpenClaw 配置

在 OpenClaw 配置文件 `~/.openclaw/openclaw.json` 中添加：

```json
{
  "context_db": {
    "type": "openviking",
    "url": "http://10.1.1.3:1933",
    "api_key": "your_api_key_here"
  }
}
```

## 验证连接

在 OpenClaw 节点上测试连接：

```bash
# 测试服务可达性
curl http://10.1.1.3:1933/health

# 预期输出
{"status":"ok","healthy":true,"version":"0.2.13"}
```

## 服务管理

在 wsl-infer 节点上：

```bash
# 查看服务状态
pm2 status

# 查看日志
pm2 logs openviking-server

# 重启服务
pm2 restart openviking-server
```

## 网络要求

确保防火墙允许端口 1933 的访问。
