#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Blockmesh.sh"

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

        read -p "请输入选项 (1-2): " option

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

    # 安装 Docker 和 Docker Compose
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装 Docker..."

        # 移除可能存在的 Docker 相关包
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
            sudo apt-get remove -y $pkg
        done

        # 安装必要的依赖
        sudo apt-get install -y ca-certificates curl gnupg

        # 添加 Docker 的 GPG 密钥
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # 添加 Docker 的 APT 源
        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # 更新 APT 源并安装 Docker
        sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

        # 检查 Docker 版本
        echo "Docker 安装完成，版本为：$(docker --version)"
    else
        echo "Docker 已安装，版本为：$(docker --version)"
    fi

    # 安装 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose 未安装，正在安装 Docker Compose..."

        # 下载 Docker Compose 的最新版本
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

        # 赋予可执行权限
        sudo chmod +x /usr/local/bin/docker-compose

        # 检查 Docker Compose 版本
        echo "Docker Compose 安装完成，版本为：$(docker-compose --version)"
    else
        echo "Docker Compose 已安装，版本为：$(docker-compose --version)"
    fi

    # 创建 blockmesh 目录
    BLOCKMESH_DIR="$HOME/blockmesh"

    # 检查 blockmesh 目录是否存在
    if [ -d "$BLOCKMESH_DIR" ]; then
        echo "目录 $BLOCKMESH_DIR 已存在，正在删除..."
        rm -rf "$BLOCKMESH_DIR"
    fi

    # 创建新的 blockmesh 目录
    mkdir -p "$BLOCKMESH_DIR"
    echo "创建目录：$BLOCKMESH_DIR"

    # 下载 blockmesh-cli
    echo "正在下载 blockmesh-cli..."
    curl -L "https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.316/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz" -o "$BLOCKMESH_DIR/blockmesh-cli.tar.gz"

    # 解压缩并删除压缩包
    echo "正在解压缩 blockmesh-cli..."
    tar -xzf "$BLOCKMESH_DIR/blockmesh-cli.tar.gz" -C "$BLOCKMESH_DIR"
    rm "$BLOCKMESH_DIR/blockmesh-cli.tar.gz"
    echo "blockmesh-cli 下载并解压完成。"

    # 输出 blockmesh-cli 的路径
    BLOCKMESH_CLI_PATH="$BLOCKMESH_DIR/blockmesh-cli"
    echo "blockmesh-cli 路径：$BLOCKMESH_CLI_PATH"

    # 获取用户输入的 BlockMesh 邮箱和密码
    read -p "请输入您的 BlockMesh 邮箱: " BLOCKMESH_EMAIL
    read -sp "请输入您的 BlockMesh 密码: " BLOCKMESH_PASSWORD
    echo

    # 创建 Docker 容器并运行 blockmesh-cli
    echo "正在启动 Docker 容器并运行 blockmesh-cli..."
    if ! docker run --name blockmesh-container --rm -e BLOCKMESH_EMAIL="$BLOCKMESH_EMAIL" -e BLOCKMESH_PASSWORD="$BLOCKMESH_PASSWORD" -v "$BLOCKMESH_DIR":/data ubuntu:22.04 /bin/bash -c "cd /data && chmod +x ./blockmesh-cli && ./blockmesh-cli"; then
        echo "无法启动 blockmesh-cli，请检查镜像和命令。"
    fi
    
    echo "脚本执行完成。"
    read -p "按任意键返回主菜单..."
}

# 查看 Docker 日志
function view_logs() {
    echo "正在查看 Docker 容器日志..."
    if [ "$(docker ps -q -f name=blockmesh-container)" ]; then
        docker logs blockmesh-container
    else
        echo "没有找到名为 blockmesh-container 的运行容器。"
    fi
    read -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
