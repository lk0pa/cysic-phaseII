#!/bin/bash

# 发生错误时退出脚本
set -e

# 捕获错误并提示
trap 'echo "发生错误，脚本已退出。";' ERR

# 功能：自动安装缺少的依赖项 (git 和 make)
install_dependencies() {
    for cmd in git make; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd 未安装。正在自动安装 $cmd..."

            # 检测操作系统类型并执行相应的安装命令
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt update
                sudo apt install -y $cmd
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew install $cmd
            else
                echo "不支持的操作系统。请手动安装 $cmd。"
                exit 1
            fi
        fi
    done
    echo "已安装所有依赖项。/ All dependencies have been installed."
}

# 功能：检查并安装 Node.js 和 npm
install_node() {
    echo "检测到未安装 npm。正在安装 Node.js 和 npm..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install node
    else
        echo "不支持的操作系统。请手动安装 Node.js 和 npm。"
        exit 1
    fi

    echo "Node.js 和 npm 安装完成。"
}

# 功能：安装 pm2
install_pm2() {
    if ! command -v npm &> /dev/null; then
        echo "npm 未安装。"
        install_node
    fi

    if ! command -v pm2 &> /dev/null; then
        echo "pm2 未安装。正在安装 pm2..."
        npm install -g pm2
    else
        echo "pm2 已安装。"
    fi
}

# 功能1：下载、解压缩并运行帮助命令
download_and_setup() {

    install_dependencies
    install_node
    install_pm2

    read -p "请输入你的白名单EVM地址(需要带0x): " EVM_ADDRESS

    curl -L https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh > ~/setup_linux.sh && bash ~/setup_linux.sh $EVM_ADDRESS

    cd ~/cysic-verifier/ 

    pm2 start ./start.sh --name Cysic-phase-ll 

    echo "～\.cysic\keys文件夹中的文件，请注意备份，否则无法再次运行验证程序。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}


# 功能2：查看日志
view_logs() {
    pm2 logs Cysic-phase-ll
}

# 功能3: 卸载
delete() {
    pm2 stop Cysic-phase-ll
    pm2 delete Cysic-phase-ll
    rm -rf ~/cysic-verifier/

}

# 主菜单
main_menu() {
    while true; do
        clear
        echo "请选择一个选项:"
        echo "1. 下载并设置"
        echo "2. 查看日志"
        echo "3. 卸载"
        echo "4. 退出"

        read -p "请输入选项 (1-3): " choice

        case $choice in
            1)
                download_and_setup
                ;;
            2)
                view_logs
                ;;
            3)
                delete
                ;;
            4)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 启动主菜单
echo "准备启动主菜单..."
main_menu