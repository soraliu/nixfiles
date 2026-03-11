# vLLM 服务局域网访问配置指南

## 背景

在 WSL2 环境下，vLLM 服务默认只能在 WSL2 内部访问。要让局域网其他设备访问，需要配置 Windows 防火墙和端口转发。

## 快速开始

### 1. 运行网络配置脚本

在 WSL2 中执行：

```bash
just vllm-setup-network
```

这会生成一个 PowerShell 脚本并显示执行命令。

### 2. 在 Windows 上配置（需要管理员权限）

复制脚本输出的 PowerShell 命令，在 **Windows PowerShell（管理员）** 中执行。

或者直接运行：

```powershell
powershell.exe -ExecutionPolicy Bypass -File \\wsl$\Ubuntu\tmp\setup-vllm-network.ps1
```

### 3. 启动 vLLM 服务

```bash
just vllm-serve
```

### 4. 验证访问

- **WSL2 内访问**: `http://localhost:8000`
- **Windows 主机访问**: `http://localhost:8000`
- **局域网其他设备访问**: `http://<Windows主机IP>:8000`

查看 Windows 主机 IP：

```powershell
ipconfig | findstr IPv4
```

## 配置说明

### 防火墙规则

允许 TCP 端口 8000 的入站连接：

```powershell
netsh advfirewall firewall add rule name="vLLM-API-Server" dir=in action=allow protocol=TCP localport=8000
```

### 端口转发

将 Windows 的 8000 端口转发到 WSL2：

```powershell
netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=<WSL2_IP>
```

## 查看当前配置

### 查看端口转发规则

```powershell
netsh interface portproxy show v4tov4
```

### 查看防火墙规则

```powershell
netsh advfirewall firewall show rule name="vLLM-API-Server"
```

## 清理配置

### 删除防火墙规则

```powershell
netsh advfirewall firewall delete rule name="vLLM-API-Server"
```

### 删除端口转发

```powershell
netsh interface portproxy delete v4tov4 listenport=8000 listenaddress=0.0.0.0
```

## 故障排查

### 1. 无法访问服务

- 检查 vLLM 服务是否正常运行：`curl http://localhost:8000/v1/models`
- 检查 Windows 防火墙是否允许端口 8000
- 检查端口转发规则是否正确配置
- 确认 WSL2 IP 地址是否变化（WSL2 重启后 IP 可能变化）

### 2. WSL2 IP 地址变化

WSL2 每次重启后 IP 可能变化，需要重新运行配置脚本：

```bash
just vllm-setup-network
```

### 3. 局域网设备无法访问

- 确认 Windows 主机和目标设备在同一局域网
- 检查 Windows 主机的网络配置（公共网络 vs 专用网络）
- 尝试临时关闭 Windows 防火墙测试（不推荐长期使用）

## 技术细节

### vLLM 服务配置

服务已配置为监听所有网络接口（`--host 0.0.0.0`），端口 8000。

配置文件：`home/modules/ai/vllm/flake.nix:49`

### WSL2 网络架构

```
局域网设备 (192.168.31.xxx)
    ↓
Windows 主机 (192.168.31.xxx)
    ↓ (端口转发 8000 → WSL2_IP:8000)
WSL2 虚拟机 (172.x.x.x)
    ↓
vLLM 服务 (0.0.0.0:8000)
```

## 安全建议

1. **仅在可信网络使用**：不要在公共网络暴露 vLLM 服务
2. **添加认证**：考虑在 vLLM 前添加反向代理（如 nginx）并配置认证
3. **限制访问 IP**：可以修改防火墙规则，仅允许特定 IP 段访问

## 参考资料

- [vLLM OpenAI Compatible Server](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html)
- [WSL2 网络配置](https://learn.microsoft.com/zh-cn/windows/wsl/networking)
