#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Blockmesh.sh"
LOG_FILE="$HOME/blockmesh/blockmesh.log"  # 日志文件路径

# 创建日志文件并重定向输出
exec > >(tee -a "$LOG_FILE") 2>&1

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 部署节点"
        echo "2. 查看日志"
        echo "3. 退出"

        read -p "请输入选项 (1-3): " option

        case $option in
            1)
                deploy_node
                ;;
            2)
                view_logs
                ;;
            3)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新输入。"
                read -p "按任意键继续..."
                ;;
        esac
    done
}

# 部署节点
function deploy_node() {
    echo "正在更新系统..."
    sudo apt update -y && sudo apt upgrade -y

    # 清理旧文件
    rm -rf blockmesh-cli.tar.gz target

    # 如果未安装 Docker，则进行安装
    if ! command -v docker &> /dev/null; then
        echo "正在安装 Docker..."
        apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
    else
        echo "Docker 已安装，跳过安装步骤..."
    fi

    # 安装 Docker Compose
    echo "正在安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # 创建用于解压的目标目录
    mkdir -p target/release

    # 下载并解压最新版 BlockMesh CLI
    echo "下载并解压 BlockMesh CLI..."
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.325/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

    # 验证解压结果
    if [[ ! -f target/release/blockmesh-cli ]]; then
        echo "错误：未找到 blockmesh-cli 可执行文件于 target/release。退出..."
        exit 1
    fi

    # 提示输入邮箱和密码
    read -p "请输入您的 BlockMesh 邮箱: " email
    read -s -p "请输入您的 BlockMesh 密码: " password
    echo

    # 使用 BlockMesh CLI 创建 Docker 容器
    echo "为 BlockMesh CLI 创建 Docker 容器..."
    docker run -it --rm \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

    read -p "按任意键返回主菜单..."
}

# 查看日志
function view_logs() {
    LOG_FILE="/root/blockmesh/blockmesh.log"  # 使用完整路径
    if [ -f "$LOG_FILE" ]; then
        echo "查看日志内容："
        # 使用 Docker 查看日志的最后 100 行
        docker logs --tail 100 blockmesh-cli-container
    else
        echo "日志文件不存在：$LOG_FILE"
    fi
    read -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
