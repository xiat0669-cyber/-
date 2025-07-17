#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}============================================================${NC}"
echo -e "${YELLOW}欢迎来到 Web3 实操顶流 —— 加密狗社区！${NC}"
echo -e "我叫：加密狗，5年老韭菜。"
echo -e "📍 我的 X（推特）: @JiamigouCn"
echo -e "🔗 链接：https://x.com/JiamigouCn"
echo -e "${GREEN}============================================================${NC}"

read -p "请输入你的 Prover ID（在 https://app.nexus.xyz 上获取）: " PROVER_ID
if [ -z "$PROVER_ID" ]; then
    echo "❌ Prover ID 不能为空"
    exit 1
fi

read -p "请输入你的钱包地址（可选，回车跳过）: " WALLET_ADDRESS

LOG_FILE="$HOME/nexus-deploy.log"  # 使用当前用户主目录
echo "部署开始于 $(date)" > $LOG_FILE

log() {
    echo "$1" | tee -a $LOG_FILE
}

log "🧱 更新系统..."
apt update && apt upgrade -y

log "📦 安装依赖..."
apt install -y curl build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip protobuf-compiler

log "🦀 安装 Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup update

log "📁 克隆并构建 Nexus CLI..."
cd ~
rm -rf nexus-cli
git clone https://github.com/nexus-xyz/nexus-cli.git
cd nexus-cli/clients/cli
cargo build --release --no-default-features --bin nexus-network

cp target/release/nexus-network /usr/local/bin/nexus-cli
nexus-cli --version

log "🔐 注册节点（可选）..."
if [ -n "$WALLET_ADDRESS" ]; then
    nexus-cli register-user --wallet-address "$WALLET_ADDRESS"
    nexus-cli register-node
fi

log "⚙️ 创建 systemd 服务..."
cat << EOF > /etc/systemd/system/nexus.service
[Unit]
Description=Nexus CLI Node
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/nexus-cli start --node-id $PROVER_ID
Restart=always
RestartSec=10
StandardOutput=append:/var/log/nexus.log
StandardError=append:/var/log/nexus.err.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl enable nexus.service
systemctl start nexus.service

sleep 5
if systemctl is-active --quiet nexus.service; then
    echo -e "${GREEN}✅ Nexus 节点已成功启动！${NC}"
else
    echo -e "${YELLOW}⚠️ 启动失败，请查看日志：journalctl -u nexus.service -f${NC}"
fi


