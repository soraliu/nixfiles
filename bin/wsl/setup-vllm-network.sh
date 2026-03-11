#!/usr/bin/env bash
# WSL2 vLLM 服务局域网访问配置脚本
# 用途：配置 Windows 防火墙规则和端口转发，使 vLLM 服务可被局域网访问

set -e

PORT=8000
SERVICE_NAME="vLLM-API-Server"

echo "🔧 配置 WSL2 vLLM 服务局域网访问..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 获取 WSL2 IP 地址
WSL_IP=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "📍 WSL2 IP: $WSL_IP"

# 获取 Windows 主机 IP（通过默认网关）
WIN_IP=$(ip route | grep default | awk '{print $3}')
echo "📍 Windows IP: $WIN_IP"

# 生成 PowerShell 脚本
PS_SCRIPT=$(cat <<'EOF'
# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ 需要管理员权限！请以管理员身份运行 PowerShell" -ForegroundColor Red
    exit 1
}

$PORT = 8000
$SERVICE_NAME = "vLLM-API-Server"
$WSL_IP = "WSL_IP_PLACEHOLDER"

Write-Host "🔧 配置 Windows 防火墙和端口转发..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. 删除旧的防火墙规则（如果存在）
Write-Host "🗑️  清理旧规则..." -ForegroundColor Yellow
netsh advfirewall firewall delete rule name="$SERVICE_NAME" 2>$null

# 2. 添加新的防火墙规则（允许入站连接）
Write-Host "🛡️  添加防火墙规则..." -ForegroundColor Green
netsh advfirewall firewall add rule name="$SERVICE_NAME" dir=in action=allow protocol=TCP localport=$PORT

# 3. 删除旧的端口转发规则（如果存在）
Write-Host "🗑️  清理旧端口转发..." -ForegroundColor Yellow
netsh interface portproxy delete v4tov4 listenport=$PORT listenaddress=0.0.0.0 2>$null

# 4. 添加端口转发规则（将 Windows 端口转发到 WSL2）
Write-Host "🔀 配置端口转发 (0.0.0.0:$PORT -> $WSL_IP:$PORT)..." -ForegroundColor Green
netsh interface portproxy add v4tov4 listenport=$PORT listenaddress=0.0.0.0 connectport=$PORT connectaddress=$WSL_IP

# 5. 显示当前配置
Write-Host ""
Write-Host "✅ 配置完成！" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""
Write-Host "📋 当前端口转发规则：" -ForegroundColor Cyan
netsh interface portproxy show v4tov4
Write-Host ""
Write-Host "📋 防火墙规则：" -ForegroundColor Cyan
netsh advfirewall firewall show rule name="$SERVICE_NAME"
Write-Host ""
Write-Host "💡 访问方式：" -ForegroundColor Yellow
Write-Host "   - 本机访问: http://localhost:$PORT"
Write-Host "   - 局域网访问: http://<Windows主机IP>:$PORT"
Write-Host "   - WSL2 内访问: http://$WSL_IP:$PORT"
Write-Host ""
Write-Host "🔍 查看 Windows 主机 IP："
Write-Host "   ipconfig | findstr IPv4"
Write-Host ""
EOF
)

# 替换 WSL IP 占位符
PS_SCRIPT="${PS_SCRIPT//WSL_IP_PLACEHOLDER/$WSL_IP}"

# 保存到临时文件
TEMP_PS1="/tmp/setup-vllm-network.ps1"
echo "$PS_SCRIPT" > "$TEMP_PS1"

echo ""
echo "📝 PowerShell 脚本已生成: $TEMP_PS1"
echo ""
echo "⚠️  请在 Windows 上以管理员身份运行以下命令："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "powershell.exe -ExecutionPolicy Bypass -File $(wslpath -w "$TEMP_PS1")"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 或者复制以下命令到 Windows PowerShell（管理员）："
echo ""
echo "$PS_SCRIPT"
echo ""
