#!/bin/bash

# 脚本出错时立即退出
set -e

# --- 交互式菜单函数 (兼容旧版 Bash 且相对定位) ---
show_menu() {
    local options_count=${#model_options[@]}
    
    # 为菜单和提示语预留空间
    for ((i=0; i<options_count+1; i++)); do echo ""; done
    tput cuu $((options_count + 1))

    # 隐藏光标
    tput civis
    trap "tput cnorm; exit" SIGINT

    local key
    while true; do
        # 重置光标到菜单起点
        tput cuu $((options_count + 1))
        
        for i in "${!model_options[@]}"; do
            tput el
            if [ "$i" -eq "$current_selection" ]; then
                echo "  > ${model_options[i]}"
            else
                echo "    ${model_options[i]}"
            fi
        done

        tput el
        echo "Use ↑/↓ to navigate, Enter to select｜使用 ↑/↓ 方向键选择，回车键确认"

        read -s -r -n 1 key
        if [[ $key == $'\x1b' ]]; then
            read -s -r -n 2 rest
            key+="$rest"
        fi

        case "$key" in
            $'\x1b[A') # 上箭头
                current_selection=$(( (current_selection - 1 + options_count) % options_count ))
                ;;
            $'\x1b[B') # 下箭头
                current_selection=$(( (current_selection + 1) % options_count ))
                ;;
            "") # Enter 键
                # 清理菜单和提示语占用的空间
                tput cuu $((options_count + 1))
                for ((i=0; i<options_count+1; i++)); do tput el; tput cud 1; done
                tput cuu $((options_count + 1))
                tput cnorm # 恢复光标
                break
                ;;
        esac
    done
}


# 安装 Node.js 的函数
install_nodejs() {
    local platform=$(uname -s)
    
    case "$platform" in
        Linux|Darwin)
            echo "🚀 Installing Node.js on Unix/Linux/macOS｜安装 Node.js..."
            echo "📥 Downloading and installing nvm｜安装 nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
            echo "🔄 Loading nvm environment｜加载 nvm 环境变量..."
            \. "$HOME/.nvm/nvm.sh"
            echo "📦 Downloading and installing Node.js v22｜安装 Node.js v22..."
            nvm install 22
            echo -n "✅ Node.js installation completed! Version｜Node.js 已安装，当前版本: "
            node -v
            echo -n "✅ Current nvm version｜当前 nvm 版本: "
            nvm current
            echo -n "✅ npm version｜npm 版本: "
            npm -v
            ;;
        *)
            echo "Unsupported platform｜暂不支持的系统: $platform"
            exit 1
            ;;
    esac
}

# 检查 Node.js
if command -v node >/dev/null 2>&1; then
    current_version=$(node -v | sed 's/v//')
    major_version=$(echo "$current_version" | cut -d. -f1)
    
    if [ "$major_version" -ge 18 ]; then
        echo "Node.js is already installed｜Node.js 已安装: v$current_version"
    else
        echo "Node.js v$current_version is installed but version < 18. Upgrading｜Node.js 版本升级中..."
        install_nodejs
    fi
else
    echo "Node.js not found. Installing｜Node.js 未安装，开始安装..."
    install_nodejs
fi

# --- 修正：统一的 Claude Code 安装/更新流程 ---

# 设置一个标志来决定是否需要执行安装/更新操作
NEEDS_INSTALL=false

if command -v claude >/dev/null 2>&1; then
    echo "✅ Claude Code is already installed. Checking for updates...｜Claude Code 已安装，正在检查更新..."
    # 使用 npm outdated 检查更新，即使出错也继续执行
    outdated_info=$(npm outdated -g @anthropic-ai/claude-code || true)

    if [ -n "$outdated_info" ]; then
        # 如果有更新
        current_version=$(echo "$outdated_info" | awk 'NR==2 {print $2}')
        latest_version=$(echo "$outdated_info" | awk 'NR==2 {print $4}')
        echo "✨ A new version is available: $latest_version (you have $current_version)."
        echo "✨ 检测到新版本: $latest_version (当前版本: $current_version)。"
        read -p "Do you want to upgrade? (y/N)｜是否要升级？(y/N) " -n 1 -r
        echo # 换行
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            NEEDS_INSTALL=true
        else
            echo "👍 Skipping upgrade.｜跳过升级。"
        fi
    else
        # 如果没有更新
        current_version=$(claude --version | awk '{print $1}' | cut -d'/' -f2)
        echo "✅ You are running the latest version ($current_version).｜您正在运行最新版本 ($current_version)。"
    fi
else
    # 如果命令不存在，则标记为需要安装
    echo "Claude Code not found or installation is broken.｜Claude Code 未安装或安装已损坏。"
    NEEDS_INSTALL=true
fi

# 集中处理安装/更新逻辑
if [ "$NEEDS_INSTALL" = true ]; then
    echo "🔄 Preparing environment by cleaning up previous versions (if any)...｜正在清理旧版本以准备环境..."
    # 关键修复：在安装前，先尝试卸载以清理任何残留文件。忽略可能出现的错误。
    npm uninstall -g @anthropic-ai/claude-code > /dev/null 2>&1 || true
    
    echo "📦 Installing/Updating @anthropic-ai/claude-code..."
    npm install -g @anthropic-ai/claude-code
    echo "✅ Claude Code installed/updated successfully.｜Claude Code 安装/更新成功。"
fi


# 配置 Claude Code
echo "Configuring Claude Code to skip onboarding｜免除 Claude Code 的 onboarding 环节..."
node --eval '
    const fs = require("fs");
    const os = require("os");
    const path = require("path");
    const homeDir = os.homedir(); 
    const filePath = path.join(homeDir, ".claude.json");
    try {
        let config = {};
        if (fs.existsSync(filePath)) {
            config = JSON.parse(fs.readFileSync(filePath, "utf-8"));
        }
        config.hasCompletedOnboarding = true;
        fs.writeFileSync(filePath, JSON.stringify(config, null, 2), "utf-8");
    } catch (e) {}'

# --- 环境变量检查与配置 ---
current_shell=$(basename "$SHELL")
case "$current_shell" in
    bash) rc_file="$HOME/.bashrc" ;;
    zsh) rc_file="$HOME/.zshrc" ;;
    *) rc_file="$HOME/.profile" ;;
esac

api_key=""
if [ -f "$rc_file" ] && grep -E -q 'export[[:space:]]+ANTHROPIC_BASE_URL=["'\'']?https://code\.newcli\.com/claude/droid/?["'\'']?' "$rc_file"; then
    echo ""
    echo "✅ Detected existing configuration. Using saved API Key.｜检测到已有配置，将使用已保存的 API Key。"
    api_key=$(grep -E 'export[[:space:]]+ANTHROPIC_API_KEY=' "$rc_file" | head -n1 | cut -d'=' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
fi

if [ -z "$api_key" ]; then
    echo ""
    echo "🔑 Please enter your BigModel API Key｜设置你的 BigModel API Key:"
    echo "   You can get your API Key from｜可访问右边地址获取 API Key: https://foxcode.rjj.cc/auth/register?aff=31NS1"
    echo "   Note: The input is hidden for security. Please paste your API Key directly.｜注意：输入的内容不会显示在屏幕上，请直接输入"
    echo ""
    read -s api_key
    echo ""

    if [ -z "$api_key" ]; then
        echo "⚠️  API Key cannot be empty. Please run the script again.｜API Key 未正确设置，请重新运行脚本"
        exit 1
    fi
fi

# --- 模型选择 ---
echo ""
echo "🤖 Please select a model to use｜请选择需要使用的模型:"

model_options=(
    "claude-opus-4-5"
    "claude-sonnet-4-5"
    "claude-opus-4-6"
    "claude-sonnet-4-6"
    "Custom (enter your own model)｜自定义 (手动输入模型)"
)
current_selection=0

show_menu

custom_option_index=$((${#model_options[@]} - 1))

if [ "$current_selection" -eq "$custom_option_index" ]; then
    echo ""
    echo "✍️ Please enter the custom model name｜请输入自定义模型名称:"
    read -r custom_model_name
    
    if [ -z "$custom_model_name" ]; then
        echo "⚠️ Model name cannot be empty. Exiting.｜模型名称不能为空，脚本退出。"
        exit 1
    fi
    selected_model="$custom_model_name"
else
    selected_model=${model_options[$current_selection]}
fi

echo ""
echo "✅ You have selected｜已选择模型: $selected_model"


# --- 更新环境变量 ---
echo ""
echo "📝 Updating environment variables in $rc_file...｜正在更新环境变量到 $rc_file"

if [ -f "$rc_file" ]; then
    temp_file=$(mktemp)
    grep -v -e "# Claude Code environment variables" \
            -e "export ANTHROPIC_BASE_URL" \
            -e "export ANTHROPIC_API_KEY" \
            -e "export ANTHROPIC_MODEL" \
            -e "export ANTHROPIC_SMALL_FAST_MODEL" "$rc_file" > "$temp_file"
    mv "$temp_file" "$rc_file"
fi

echo "" >> "$rc_file"
echo "# Claude Code environment variables" >> "$rc_file"
echo "export ANTHROPIC_BASE_URL=https://code.newcli.com/claude/droid" >> "$rc_file"
echo "export ANTHROPIC_API_KEY=$api_key" >> "$rc_file"
echo "export ANTHROPIC_MODEL=$selected_model" >> "$rc_file"
echo "export ANTHROPIC_SMALL_FAST_MODEL=$selected_model" >> "$rc_file"
echo "✅ Environment variables successfully updated in $rc_file"

echo ""
echo "🎉 Configuration completed successfully｜配置已完成 🎉"
echo ""
echo "🔄 Please restart your terminal or run｜重新启动终端并运行:"
echo "   source $rc_file"
echo ""
echo "🚀 Then you can start using Claude Code with｜使用下面命令进入 Claude Code:"
echo "   claude"