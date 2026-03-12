#!/usr/bin/env bash
set -euo pipefail

# Dify 一键安装脚本 (中国优化版)
# 使用 Gitee 镜像加速下载
#
# 用法:
#   ./install_cn.sh                  # 交互式配置 (推荐)
#   ./install_cn.sh --yes            # 使用所有推荐的默认值 (无需交互)
#   ./install_cn.sh --help           # 显示帮助
#   curl -sSL https://raw.githubusercontent.com/caoergou/dify-installer/main/install_cn.sh | bash
#
# 特性:
#   - 一行命令安装
#   - 使用 Gitee 镜像加速下载
#   - 自动浅克隆仓库
#   - 交互式配置，智能默认值
#   - 数据库选择 (PostgreSQL/MySQL)
#   - 向量数据库选择 (Weaviate/Qdrant/Milvus/Chroma/pgvector)
#   - 存储选择 (本地/S3/Azure/GCS/阿里云OSS)
#   - 域名和 HTTPS 配置 (使用 nginx 和 certbot)
#   - 邮件服务配置 (SMTP/Gmail/SendGrid/Resend)

# 配置默认值 - 这些需要放在前面以便测试
INTERACTIVE=true
YES_MODE=false
DEPLOY_TYPE="private"  # "private" (localhost/IP) 或 "public" (域名 + SSL)
DOMAIN="localhost"
HTTP_PORT="80"
HTTPS_PORT="443"
NGINX_HTTPS_ENABLED=false
NGINX_SERVER_NAME="_"
NGINX_ENABLE_CERTBOT_CHALLENGE=false
CERTBOT_EMAIL=""
DB_TYPE="postgresql"
VECTOR_STORE="weaviate"
STORAGE_TYPE="opendal"
OPENDAL_SCHEME="fs"
CONFIGURE_EMAIL=false

# Git 仓库配置 - 使用 Gitee 镜像
GITHUB_REPO="langgenius/dify"
GITHUB_BRANCH="main"
INSTALLER_REPO="caoergou/dify-installer"

# Gitee 镜像配置
GITEE_MIRROR="fast-mirrors/dify"  # Gitee 上的 Dify 镜像仓库

# ============================================
# 提前检查帮助 - 在任何其他操作之前
# ============================================
show_help() {
    echo "Dify 一键安装脚本 (中国优化版)"
    echo ""
    echo "用法:"
    echo "  curl -sSL https://raw.githubusercontent.com/${INSTALLER_REPO}/main/install_cn.sh | bash"
    echo "                                      # 交互模式 (推荐)"
    echo ""
    echo "  ./install_cn.sh                 # 交互式配置 (如果已有文件)"
    echo "  ./install_cn.sh --yes           # 使用所有推荐的默认值 (快速)"
    echo "  ./install_cn.sh -y              # 简写形式"
    echo "  ./install_cn.sh --help          # 显示此帮助"
    echo ""
    echo "一行命令安装示例:"
    echo "  curl -sSL https://raw.githubusercontent.com/${INSTALLER_REPO}/main/install_cn.sh | bash"
    echo "  curl -sSL https://raw.githubusercontent.com/${INSTALLER_REPO}/main/install_cn.sh | bash -s -- --yes"
    echo ""
    echo "功能说明:"
    echo "  - 使用 Gitee 镜像加速仓库克隆"
    echo "  - 自动检查并提示配置 Docker 镜像加速"
    echo "  - 浅克隆 Dify 仓库 (快速)"
    echo "  - 检查系统要求"
    echo "  - 引导完成配置"
    echo "  - 自动生成安全密钥"
    echo "  - 启动 Dify 服务"
    echo ""
    echo "Docker 镜像加速配置:"
    echo "  如果拉取镜像速度慢，请配置 Docker 镜像加速器："
    echo "  编辑 /etc/docker/daemon.json 添加："
    echo '  {"registry-mirrors": ["https://docker.1ms.run"]}'
    echo "  然后重启 Docker: sudo systemctl restart docker"
    echo ""
}

# 首先检查帮助
for arg in "$@"; do
    if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
        show_help
        exit 0
    fi
done

# 存储配置变量 (全局作用域)
S3_BUCKET=""
S3_REGION=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""
AZURE_ACCOUNT=""
AZURE_KEY=""
AZURE_CONTAINER=""
GCS_BUCKET=""
GCS_PROJECT=""
ALIYUN_BUCKET=""
ALIYUN_REGION=""
ALIYUN_ACCESS_KEY=""
ALIYUN_SECRET_KEY=""

# 邮件配置变量 (全局作用域)
SMTP_HOST=""
SMTP_PORT=""
SMTP_USER=""
SMTP_PASSWORD=""
SMTP_FROM=""

# ============================================
# 早期函数定义 (设置需要)
# ============================================

# 彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│  Dify 一键安装脚本 (中国优化版)                      │${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
}

print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_step() { echo -e "${PURPLE}➜${NC} $1"; }
print_section() { echo ""; echo -e "${CYAN}─── $1 ─────────────────────────────────────────────${NC}"; echo ""; }

# 检查目录是否安全使用 (由当前用户或 root 拥有)
is_safe_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        return 0  # 目录不存在，将安全创建
    fi

    local dir_owner
    dir_owner="$(stat -c "%u" "$dir" 2>/dev/null || echo "")"
    local current_uid
    current_uid="$(id -u)"

    # 如果由当前用户或 root 拥有则安全
    if [ "$dir_owner" = "$current_uid" ] || [ "$dir_owner" = "0" ]; then
        return 0
    fi

    return 1
}

# 验证目录是否为有效的 git 仓库且具有预期的远程 URL
# 这可以防止攻击者预先创建恶意目录的 RCE 攻击
verify_git_repository() {
    local dir="$1"
    # 接受 GitHub 和 Gitee 镜像
    local expected_github_url="https://github.com/${GITHUB_REPO}.git"
    local expected_gitee_url="https://gitee.com/${GITEE_MIRROR}.git"

    # 检查是否为 git 仓库
    if [ ! -d "$dir/.git" ]; then
        print_error "目录存在但不是有效的 git 仓库"
        echo "    这可能是安全风险。请删除该目录后重试。"
        return 1
    fi

    # 获取远程 URL
    local remote_url
    remote_url=$(cd "$dir" && git config --get remote.origin.url 2>/dev/null || echo "")

    if [ -z "$remote_url" ]; then
        print_error "目录存在但没有配置远程 origin"
        echo "    这可能是安全风险。请删除该目录后重试。"
        return 1
    fi

    # 验证远程 URL 是否匹配预期的仓库
    # 接受 https、git@ 和 gitee 格式
    local normalized_url="$remote_url"
    if [[ "$remote_url" == git@github.com:* ]]; then
        normalized_url="https://github.com/${remote_url#git@github.com:}"
    elif [[ "$remote_url" == git@gitee.com:* ]]; then
        normalized_url="https://gitee.com/${remote_url#git@gitee.com:}"
    fi

    if [ "$normalized_url" != "$expected_github_url" ] && [ "$normalized_url" != "$expected_gitee_url" ]; then
        print_error "目录存在但远程 URL 不匹配预期的仓库"
        echo "    预期: $expected_github_url 或 $expected_gitee_url"
        echo "    发现: $remote_url"
        echo "    这可能是安全风险。请删除该目录后重试。"
        return 1
    fi

    return 0
}

# 获取仓库的克隆 URL - 优先使用 Gitee 镜像
get_clone_url() {
    # 优先尝试 Gitee 镜像
    if curl -s --connect-timeout 5 -o /dev/null "https://gitee.com/${GITEE_MIRROR}"; then
        echo "https://gitee.com/${GITEE_MIRROR}.git"
    else
        # 回退到 GitHub
        echo "https://github.com/${GITHUB_REPO}.git"
    fi
}

# 检查并提示 Docker 镜像加速配置
check_docker_mirror() {
    echo "检查 Docker 镜像加速配置..."

    # 检查是否配置了镜像加速器
    local daemon_json="/etc/docker/daemon.json"
    if [ -f "$daemon_json" ]; then
        if grep -q "registry-mirrors" "$daemon_json" 2>/dev/null; then
            print_ok "Docker 镜像加速器已配置"
            return 0
        fi
    fi

    # 检查 Docker Desktop 的配置 (macOS/Windows)
    if docker info 2>/dev/null | grep -q "Registry Mirrors"; then
        if docker info 2>/dev/null | grep -A1 "Registry Mirrors" | grep -q "https"; then
            print_ok "Docker 镜像加速器已配置"
            return 0
        fi
    fi

    # 未配置镜像加速器，提示用户
    print_warn "未检测到 Docker 镜像加速器配置"
    echo ""
    echo "在国内拉取 Docker 镜像可能较慢，建议配置镜像加速器。"
    echo ""
    echo "配置方法 (Linux):"
    echo "  1. 编辑 /etc/docker/daemon.json (如不存在请创建)"
    echo "  2. 添加以下内容:"
    echo ""
    echo '  {'
    echo '    "registry-mirrors": ['
    echo '      "https://docker.1ms.run",'
    echo '      "https://docker.xuanyuan.me"'
    echo '    ]'
    echo '  }'
    echo ""
    echo "  3. 重启 Docker 服务:"
    echo "     sudo systemctl daemon-reload"
    echo "     sudo systemctl restart docker"
    echo ""
    echo "Docker Desktop (macOS/Windows) 用户:"
    echo "  在 Docker Desktop 设置 -> Docker Engine 中添加上述配置"
    echo ""

    if [ "$INTERACTIVE" = true ]; then
        read -p "是否继续安装? [Y/n] " choice < /dev/tty
        choice="${choice:-Y}"
        case "$choice" in
            [Nn]*) echo "安装已取消。请配置镜像加速器后重新运行。"; exit 0 ;;
        esac
    fi
    echo ""
}

# 检查是否在 Dify 仓库的 docker 目录中运行，
# 或者是否需要浅克隆仓库
setup_working_directory() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # 检查是否已在包含所需文件的 docker 目录中
    if [ -f "${script_dir}/.env.example" ] && [ -f "${script_dir}/docker-compose.yaml" ]; then
        if ! is_safe_directory "$script_dir"; then
            print_error "目录 $script_dir 不属于你或 root。出于安全原因中止。"
            exit 1
        fi
        cd "$script_dir"
        SCRIPT_DIR="$script_dir"
        return 0
    fi

    # 检查当前目录是否有所需文件
    if [ -f ".env.example" ] && [ -f "docker-compose.yaml" ]; then
        local current_dir
        current_dir="$(pwd)"
        if ! is_safe_directory "$current_dir"; then
            print_error "目录 $current_dir 不属于你或 root。出于安全原因中止。"
            exit 1
        fi
        SCRIPT_DIR="$current_dir"
        cd "$SCRIPT_DIR"
        return 0
    fi

    # 检查父目录是否有包含所需文件的 docker 子目录
    if [ -d "../docker" ] && [ -f "../docker/.env.example" ] && [ -f "../docker/docker-compose.yaml" ]; then
        local parent_dir
        parent_dir="$(cd .. && pwd)/docker"
        if ! is_safe_directory "$parent_dir"; then
            print_error "目录 $parent_dir 不属于你或 root。出于安全原因中止。"
            exit 1
        fi
        cd "../docker"
        SCRIPT_DIR="$(pwd)"
        return 0
    fi

    # 需要克隆仓库
    echo "正在设置 Dify 安装环境..."
    local install_dir="dify"
    local clone_dir="$install_dir"

    # 检查 dify 目录是否已存在且包含 docker 子目录
    if [ -d "$clone_dir" ] && [ -d "$clone_dir/docker" ] && [ -f "$clone_dir/docker/.env.example" ] && [ -f "$clone_dir/docker/docker-compose.yaml" ]; then
        if ! is_safe_directory "$clone_dir"; then
            print_error "目录 $clone_dir 不属于你或 root。出于安全原因中止。"
            exit 1
        fi
        # 验证这是合法的 Dify 仓库 (防止 RCE 攻击)
        if ! verify_git_repository "$clone_dir"; then
            exit 1
        fi
        cd "$clone_dir/docker"
        SCRIPT_DIR="$(pwd)"
        print_ok "使用现有 Dify 安装目录 $SCRIPT_DIR"
        return 0
    fi

    # 克隆或拉取仓库
    if [ -d "$clone_dir" ]; then
        if ! is_safe_directory "$clone_dir"; then
            print_error "目录 $clone_dir 不属于你或 root。出于安全原因中止。"
            exit 1
        fi

        # 检查是否为完整的仓库 (有 docker 子目录)
        if [ ! -d "$clone_dir/docker" ] || [ ! -f "$clone_dir/docker/.env.example" ]; then
            print_warn "检测到不完整的 Dify 目录，正在重新克隆..."
            rm -rf "$clone_dir"
        else
            # 验证这是合法的 Dify 仓库后再更新 (防止 RCE 攻击)
            if ! verify_git_repository "$clone_dir"; then
                exit 1
            fi
            cd "$clone_dir"
            print_step "正在更新 Dify 仓库..."
            local git_pull_output
            if git_pull_output=$(git pull origin "$GITHUB_BRANCH" 2>&1); then
                print_ok "Dify 仓库已更新"
            else
                print_warn "无法更新仓库:"
                echo "    $git_pull_output"
                echo "    使用现有版本"
            fi
            cd ..
        fi
    fi

    # 如果目录不存在或已被删除，则克隆
    if [ ! -d "$clone_dir" ]; then
        print_header
        echo "正在克隆 Dify 仓库 (浅克隆，将很快完成)..."
        echo ""
        print_step "正在从镜像源克隆..."

        if ! command -v git &> /dev/null; then
            print_error "Git 未安装"
            echo "请先安装 Git 或手动克隆仓库。"
            exit 1
        fi

        # 验证父目录是否安全后再克隆
        local parent_dir
        parent_dir="$(pwd)"
        if ! is_safe_directory "$parent_dir"; then
            print_error "当前目录不属于你或 root。出于安全原因中止。"
            exit 1
        fi

        local clone_url
        clone_url=$(get_clone_url)

        echo "    克隆地址: $clone_url"
        echo ""

        local git_clone_output
        if ! git_clone_output=$(git clone --depth 1 --branch "$GITHUB_BRANCH" "$clone_url" "$clone_dir" 2>&1); then
            print_error "克隆仓库失败:"
            echo "    $git_clone_output"
            echo ""
            echo "请检查网络连接后重试。"
            echo ""
            echo "如果 Gitee 镜像不可用，可以尝试直接从 GitHub 克隆:"
            echo "    git clone --depth 1 https://github.com/${GITHUB_REPO}.git dify"
            exit 1
        fi
        print_ok "Dify 仓库克隆完成"
    fi

    cd "$clone_dir/docker"
    SCRIPT_DIR="$(pwd)"
    echo ""
    print_ok "Dify 文件已准备好在 $SCRIPT_DIR"
    echo ""
}

# 清理陷阱
TEMP_FILES=()
cleanup() {
    for f in "${TEMP_FILES[@]}"; do
        rm -f "$f" 2>/dev/null || true
    done
}
trap cleanup EXIT

# 检查 Docker 镜像加速配置
check_docker_mirror

# 在任何其他操作之前运行工作目录设置
setup_working_directory

# ============================================
# 其余函数定义
# ============================================

# 转义字符串以便在 sed 替换中安全使用
escape_sed() {
    printf '%s\n' "$1" | sed -e ':a' -e '$!N' -e '$!ba' -e 's/[\/&|#$\!`"]/\\&/g'
}

print_success() {
    echo ""
    echo -e "${GREEN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│  安装完成！                                         │${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${GREEN}Dify 正在启动！${NC}"
    echo ""

    local protocol="http"
    if [ "$NGINX_HTTPS_ENABLED" = true ]; then
        protocol="https"
    fi
    local access_url="${protocol}://${DOMAIN}"
    if [ "$protocol" = "http" ] && [ "$HTTP_PORT" != "80" ]; then
        access_url="${access_url}:${HTTP_PORT}"
    elif [ "$protocol" = "https" ] && [ "$HTTPS_PORT" != "443" ]; then
        access_url="${access_url}:${HTTPS_PORT}"
    fi

    echo "下一步:         在浏览器中打开 ${access_url}/install"
    echo "                完成初始设置。"
    echo ""
    echo "访问地址:     ${access_url}"
    echo ""
    echo "常用命令:"
    echo "  (在以下目录运行: $SCRIPT_DIR)"
    echo "  查看日志:       docker compose logs -f"
    echo "  停止服务:       docker compose down"
    echo "  启动服务:       docker compose up -d"
    echo "  查看状态:       docker compose ps"
    echo ""
    echo "配置信息:"
    echo "  工作目录: $SCRIPT_DIR"
    echo "  配置文件: $SCRIPT_DIR/.env"
    if [ -n "${BACKUP_FILE:-}" ]; then
        echo "  备份文件: $BACKUP_FILE"
    fi
    echo ""
    if [ "$DEPLOY_TYPE" = "public" ] && [ "$NGINX_HTTPS_ENABLED" = true ] && [ "$NGINX_ENABLE_CERTBOT_CHALLENGE" = true ]; then
        echo "SSL 证书:"
        echo "  要启用 Certbot HTTPS，请确保:"
        echo "  1. 你的域名 ${DOMAIN} 指向此服务器"
        echo "  2. 端口 80 和 443 对外开放"
        echo "  3. 运行: docker compose --profile certbot up -d"
        echo ""
    fi
    echo "需要帮助?"
    echo "  文档:   https://docs.dify.ai"
    echo "  问题:   https://github.com/langgenius/dify/issues"
    echo ""
    echo "云托管:"
    echo "  如果自托管太复杂，可以尝试 Dify Cloud:"
    echo "  https://cloud.dify.ai"
    echo ""
}

# 询问函数
# 对于带默认值的可选字段 - 显示 [默认值] 并接受空输入
ask() {
    local prompt="$1"
    local default="$2"
    local result
    # 直接输出到终端以避免缓冲
    echo -n "$prompt [$default]: " > /dev/tty
    read result < /dev/tty
    echo "${result:-$default}"
}

# 对于必填字段 - 显示 * 标记，拒绝空输入，提供示例
ask_required() {
    local prompt="$1"
    local example="$2"
    local result

    while true; do
        echo ""
        echo -n "* $prompt" > /dev/tty
        if [ -n "$example" ]; then
            echo "" > /dev/tty
            echo "  示例: $example" > /dev/tty
        fi
        echo -n "  > " > /dev/tty
        read result < /dev/tty

        if [ -n "$result" ]; then
            echo "$result"
            return
        fi

        print_warn "此字段为必填项。请输入值。"
    done
}

ask_choice() {
    local prompt="$1"
    local default="$2"
    shift 2
    local options=("$@")

    echo "$prompt" > /dev/tty
    for i in "${!options[@]}"; do
        echo "  [$((i+1))] ${options[$i]}" > /dev/tty
    done

    local result
    read -p "请选择: [$default] " result < /dev/tty
    result="${result:-$default}"

    if ! [[ "$result" =~ ^[0-9]+$ ]] || [ "$result" -lt 1 ] || [ "$result" -gt "${#options[@]}" ]; then
        result="$default"
    fi

    echo "$result"
}

ask_yes_no() {
    local prompt="$1"
    local default="$2"
    local default_display="$([ "$default" = true ] && echo "Y/n" || echo "y/N")"

    local result
    # 直接输出到终端以避免缓冲
    echo -n "$prompt [$default_display] " > /dev/tty
    read result < /dev/tty
    result="${result:-$([ "$default" = true ] && echo "y" || echo "n")}"

    case "$result" in
        [Yy]*) echo "true" ;;
        *) echo "false" ;;
    esac
}

# 密钥生成 - 使用安全随机生成和适当的回退
generate_secret_key() {
    # 优先尝试 openssl (最常见)
    if command -v openssl &> /dev/null; then
        openssl rand -base64 42
        return
    fi

    # 尝试 Python 的 secrets 模块 (安全)
    if command -v python3 &> /dev/null; then
        python3 -c "import secrets; import base64; print(base64.b64encode(secrets.token_bytes(32)).decode())"
        return
    fi

    # 尝试 /dev/urandom (大多数类 Unix 系统可用)
    if [ -c /dev/urandom ]; then
        # 如果 uuencode 可用
        if command -v uuencode &> /dev/null; then
            head -c 48 /dev/urandom 2>/dev/null | uuencode -m - | tail -n +2 | tr -d '\n'
            return
        fi

        # 如果 base64 可用
        if command -v base64 &> /dev/null; then
            head -c 48 /dev/urandom 2>/dev/null | base64 | tr -d '\n'
            return
        fi
    fi

    # 最后手段: 如果到了这里，无法生成安全密钥
    print_error "无法生成安全密钥: 没有找到安全随机源"
    echo "请安装 openssl 或 Python 3.6+ 后重试。"
    exit 1
}

generate_password() {
    local length=${1:-16}

    # 优先尝试 openssl
    if command -v openssl &> /dev/null; then
        openssl rand -base64 "$((length * 2))" 2>/dev/null | tr -d '/+=' | cut -c1-"$length"
        return
    fi

    # 尝试 Python 的 secrets 模块
    if command -v python3 &> /dev/null; then
        python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range($length)))"
        return
    fi

    # 尝试 /dev/urandom
    if [ -c /dev/urandom ]; then
        tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c "$length"
        return
    fi

    # 最后手段
    print_error "无法生成安全密码: 没有找到安全随机源"
    echo "请安装 openssl 或 Python 3.6+ 后重试。"
    exit 1
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if command -v lsof &> /dev/null; then
        if lsof -i :"$port" &> /dev/null; then
            return 1
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$port " &> /dev/null; then
            return 1
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$port " &> /dev/null; then
            return 1
        fi
    fi
    return 0
}

# 获取占用端口的进程
get_port_process() {
    local port=$1
    if command -v lsof &> /dev/null; then
        lsof -i :"$port" -t 2>/dev/null | head -1 | xargs ps -p 2>/dev/null | tail -1 || echo ""
    elif command -v ss &> /dev/null; then
        local pid=$(ss -tulnp 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[0-9]+' | head -1)
        if [ -n "$pid" ]; then
            ps -p "$pid" -o comm= 2>/dev/null || echo "PID $pid"
        fi
    fi
}

# 检查并处理端口冲突
check_and_handle_port() {
    local port=$1
    local port_name=$2

    if check_port "$port"; then
        return 0  # 端口可用
    fi

    local process=$(get_port_process "$port")
    print_warn "端口 $port ($port_name) 已被占用"
    if [ -n "$process" ]; then
        echo "    进程: $process"
    fi

    if [ "$INTERACTIVE" = true ]; then
        echo ""
        local choice
        read -p "输入 $port_name 的其他端口，或按 Enter 继续使用当前端口: " choice < /dev/tty
        if [ -n "$choice" ] && [[ "$choice" =~ ^[0-9]+$ ]]; then
            eval "${port_name}_PORT=$choice"
            print_ok "将为 $port_name 使用端口 $choice"
            return 0
        fi
        print_warn "继续使用冲突端口。服务可能无法启动。"
    else
        print_warn "继续使用冲突端口。服务可能无法启动。"
    fi
    return 1
}

# 先决条件检查
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装"
        echo "请先安装 Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_ok "Docker 已安装 (v$docker_version)"
}

check_docker_compose() {
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose 未安装"
        echo "请先安装 Docker Compose"
        exit 1
    fi
    local compose_version=$(docker compose version | awk '{print $4}' | sed 's/,//')
    print_ok "Docker Compose 已安装 (v$compose_version)"
}

check_system_resources() {
    local cpu_cores
    if [[ "$(uname)" == "Darwin" ]]; then
        cpu_cores=$(sysctl -n hw.ncpu)
    else
        cpu_cores=$(nproc)
    fi

    if [ "$cpu_cores" -lt 2 ]; then
        print_warn "仅检测到 $cpu_cores 个 CPU 核心。Dify 至少需要 2 个核心。"
        echo "    建议使用 Dify Cloud 获得更好的性能: https://cloud.dify.ai"
    else
        print_ok "CPU: $cpu_cores 核心 (最少需要 2 核)"
    fi

    local total_ram
    if [[ "$(uname)" == "Darwin" ]]; then
        total_ram=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    else
        total_ram=$(free -g 2>/dev/null | awk '/Mem:/ {print $2}' || echo 0)
        if [ "$total_ram" -eq 0 ]; then
            total_ram=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo 2>/dev/null || echo 4)
        fi
    fi

    if [ "$total_ram" -lt 4 ]; then
        print_warn "仅检测到 ${total_ram}GB 内存。Dify 至少需要 4GB。"
        echo "    建议使用 Dify Cloud 获得更好的性能: https://cloud.dify.ai"
    else
        print_ok "内存: ${total_ram}GB (最少需要 4GB)"
    fi
}

check_ports() {
    if ! check_port "$HTTP_PORT"; then
        print_warn "端口 $HTTP_PORT 已被占用"
    fi
    if [ "$NGINX_HTTPS_ENABLED" = true ] && ! check_port "$HTTPS_PORT"; then
        print_warn "端口 $HTTPS_PORT 已被占用"
    fi
}

check_prerequisites() {
    echo "正在检查系统环境..."
    check_docker
    check_docker_compose
    check_system_resources
    echo ""
}

# 存储配置
configure_s3() {
    echo ""
    echo "AWS S3 配置:"
    S3_BUCKET=$(ask "S3 Bucket 名称" "")
    S3_REGION=$(ask "S3 区域" "us-east-1")
    S3_ACCESS_KEY=$(ask "AWS Access Key ID" "")
    S3_SECRET_KEY=$(ask "AWS Secret Access Key" "")
}

configure_azure() {
    echo ""
    echo "Azure Blob 存储配置:"
    AZURE_ACCOUNT=$(ask "Azure 账户名" "")
    AZURE_KEY=$(ask "Azure 账户密钥" "")
    AZURE_CONTAINER=$(ask "Azure 容器名" "")
}

configure_gcs() {
    echo ""
    echo "Google Cloud 存储配置:"
    GCS_BUCKET=$(ask "GCS Bucket 名称" "")
    GCS_PROJECT=$(ask "GCP 项目 ID" "")
    echo "请将服务账号密钥文件放在当前目录，命名为 gcs-credentials.json"
}

configure_aliyun() {
    echo ""
    echo "阿里云 OSS 配置:"
    ALIYUN_BUCKET=$(ask "OSS Bucket 名称" "")
    ALIYUN_REGION=$(ask "OSS 区域" "oss-cn-hangzhou")
    ALIYUN_ACCESS_KEY=$(ask "Access Key ID" "")
    ALIYUN_SECRET_KEY=$(ask "Access Key Secret" "")
}

# 邮件配置
configure_email() {
    echo ""
    echo "邮件服务配置:"
    MAIL_PROVIDER=$(ask_choice "邮件服务商" "1" \
        "SMTP 服务器 (通用)" \
        "Gmail" \
        "SendGrid" \
        "Resend")

    case $MAIL_PROVIDER in
        1)
            SMTP_HOST=$(ask "SMTP 服务器" "")
            SMTP_PORT=$(ask "SMTP 端口" "587")
            SMTP_USER=$(ask "SMTP 用户名" "")
            SMTP_PASSWORD=$(ask "SMTP 密码" "")
            SMTP_FROM=$(ask "发件人邮箱" "$SMTP_USER")
            ;;
        2)
            SMTP_HOST="smtp.gmail.com"
            SMTP_PORT="587"
            SMTP_USER=$(ask "Gmail 地址" "")
            SMTP_PASSWORD=$(ask "Gmail 应用专用密码" "")
            SMTP_FROM="$SMTP_USER"
            ;;
        3)
            SMTP_HOST="smtp.sendgrid.net"
            SMTP_PORT="587"
            SMTP_USER="apikey"
            SMTP_PASSWORD=$(ask "SendGrid API Key" "")
            SMTP_FROM=$(ask "发件人邮箱" "")
            ;;
        4)
            SMTP_HOST="smtp.resend.com"
            SMTP_PORT="587"
            SMTP_USER="resend"
            SMTP_PASSWORD=$(ask "Resend API Key" "")
            SMTP_FROM=$(ask "发件人邮箱" "")
            ;;
    esac
}

# 交互式配置
interactive_config() {
    print_header
    echo "我将询问几个简单问题。按 Enter 接受默认值 (推荐)。"
    echo ""

    print_section "部署类型"

    DEPLOY_CHOICE=$(ask_choice "部署类型" "1" \
        "私有 / 本地 (推荐 - localhost/IP，无 SSL)" \
        "公开 / 生产环境 (使用域名，可选 SSL)")

    if [ "$DEPLOY_CHOICE" = "2" ]; then
        DEPLOY_TYPE="public"
        print_section "域名和网络"

        DOMAIN=$(ask_required "域名 (例如: dify.example.com)" "dify.example.com")
        NGINX_SERVER_NAME="$DOMAIN"

        HTTP_PORT=$(ask "HTTP 端口" "80")
        HTTPS_PORT=$(ask "HTTPS 端口" "443")

        print_section "SSL 证书"

        SSL_CHOICE=$(ask_choice "SSL 证书选项" "1" \
            "无 SSL (仅使用 HTTP) - 推荐测试使用" \
            "启用 SSL (使用 Let's Encrypt / Certbot)" \
            "启用 SSL (自定义证书)")

        case $SSL_CHOICE in
            1)
                NGINX_HTTPS_ENABLED=false
                ;;
            2)
                NGINX_HTTPS_ENABLED=true
                NGINX_ENABLE_CERTBOT_CHALLENGE=true
                CERTBOT_EMAIL=$(ask "Let's Encrypt 通知邮箱" "")
                ;;
            3)
                NGINX_HTTPS_ENABLED=true
                echo ""
                echo "注意: 你需要将 SSL 证书放在 ./nginx/ssl/ 目录"
                echo "  - 证书: ./nginx/ssl/dify.crt"
                echo "  - 私钥: ./nginx/ssl/dify.key"
                ;;
        esac
    else
        DEPLOY_TYPE="private"
        print_section "网络配置"

        DOMAIN=$(ask "IP 地址或主机名" "localhost")
        HTTP_PORT=$(ask "HTTP 端口" "80")
        NGINX_SERVER_NAME="$DOMAIN"
        NGINX_HTTPS_ENABLED=false
    fi

    print_section "数据库选择"

    DB_CHOICE=$(ask_choice "主数据库" "1" \
        "PostgreSQL (推荐 - 支持最好，最可靠)" \
        "MySQL")

    case $DB_CHOICE in
        1) DB_TYPE="postgresql" ;;
        2) DB_TYPE="mysql" ;;
    esac

    print_section "向量数据库选择"

    VECTOR_CHOICE=$(ask_choice "向量数据库" "1" \
        "Weaviate (推荐 - 与 Dify 配合测试最充分)" \
        "Qdrant (轻量级，快速)" \
        "Milvus (企业级，功能强大)" \
        "Chroma (简单，适合开发)" \
        "pgvector (使用 PostgreSQL，服务更少)")

    case $VECTOR_CHOICE in
        1) VECTOR_STORE="weaviate" ;;
        2) VECTOR_STORE="qdrant" ;;
        3) VECTOR_STORE="milvus" ;;
        4) VECTOR_STORE="chroma" ;;
        5) VECTOR_STORE="pgvector" ;;
    esac

    print_section "存储选择"

    STORAGE_CHOICE=$(ask_choice "文件存储" "1" \
        "本地文件系统 (推荐 - 最简单)" \
        "AWS S3" \
        "Azure Blob 存储" \
        "Google Cloud 存储" \
        "阿里云 OSS")

    case $STORAGE_CHOICE in
        1) STORAGE_TYPE="opendal"; OPENDAL_SCHEME="fs" ;;
        2) STORAGE_TYPE="s3"; configure_s3 ;;
        3) STORAGE_TYPE="azure"; configure_azure ;;
        4) STORAGE_TYPE="gcs"; configure_gcs ;;
        5) STORAGE_TYPE="aliyun"; configure_aliyun ;;
    esac

    print_section "邮件服务 (可选)"

    CONFIGURE_EMAIL=$(ask_yes_no "配置邮件服务? (用于密码重置等)" false)

    if [ "$CONFIGURE_EMAIL" = true ]; then
        configure_email
    fi

    print_section "确认配置"

    echo "你的配置:"
    echo "  - 部署类型: $([ "$DEPLOY_TYPE" = "public" ] && echo "公开 (使用域名)" || echo "私有 / 本地")"
    echo "  - 域名/IP: $DOMAIN"
    if [ "$DEPLOY_TYPE" = "public" ]; then
        echo "  - SSL: $([ "$NGINX_HTTPS_ENABLED" = true ] && echo "已启用" || echo "未启用")"
    fi
    echo "  - HTTP 端口: $HTTP_PORT"
    if [ "$NGINX_HTTPS_ENABLED" = true ]; then
        echo "  - HTTPS 端口: $HTTPS_PORT"
    fi
    echo "  - 数据库: $DB_TYPE"
    echo "  - 向量数据库: $VECTOR_STORE"
    echo "  - 存储: $([ "$STORAGE_TYPE" = "opendal" ] && echo "本地文件系统" || echo "$STORAGE_TYPE")"
    echo "  - 邮件: $([ "$CONFIGURE_EMAIL" = true ] && echo "已配置" || echo "未配置")"
    echo ""
    echo "所有密钥将自动生成，安全且唯一。"
    echo ""

    read -p "按 Enter 开始安装，或 Ctrl+C 取消。 "
    echo ""
}

# 生成密钥
generate_secrets() {
    echo "正在生成安全密钥..."
    SECRET_KEY=$(generate_secret_key)
    DB_PASSWORD=$(generate_password)
    REDIS_PASSWORD=$(generate_password)
    SANDBOX_API_KEY=$(generate_secret_key)
    PLUGIN_DAEMON_KEY=$(generate_secret_key)
    PLUGIN_DIFY_INNER_API_KEY=$(generate_secret_key)
    print_ok "SECRET_KEY 已生成"
    print_ok "DB_PASSWORD 已生成"
    print_ok "REDIS_PASSWORD 已生成"
    print_ok "SANDBOX_API_KEY 已生成"
    print_ok "PLUGIN_DAEMON_KEY 已生成"
    print_ok "PLUGIN_DIFY_INNER_API_KEY 已生成"
    echo ""
}

# 更新 .env 文件，正确转义
update_env() {
    local key="$1"
    local value="$2"
    local file="$3"
    sed -i.bak "s|^${key}=.*|${key}=$(escape_sed "$value")|" "$file"
    TEMP_FILES+=("$file.bak")
}

# 创建 .env 文件
create_env_file() {
    echo "正在创建配置..."

    if [ -f ".env" ]; then
        BACKUP_FILE=".env.backup-$(date +%Y%m%d-%H%M%S)"
        cp ".env" "$BACKUP_FILE"
        # 同时为备份设置限制权限
        chmod 600 "$BACKUP_FILE" 2>/dev/null || true
        print_ok "已备份现有 .env 到 $BACKUP_FILE"
    fi

    if [ ! -f ".env.example" ]; then
        print_error "未找到 .env.example！"
        exit 1
    fi
    cp ".env.example" ".env"

    local protocol="http"
    if [ "$NGINX_HTTPS_ENABLED" = true ]; then
        protocol="https"
    fi
    local base_url="${protocol}://${DOMAIN}"
    if [ "$protocol" = "http" ] && [ "$HTTP_PORT" != "80" ]; then
        base_url="${base_url}:${HTTP_PORT}"
    elif [ "$protocol" = "https" ] && [ "$HTTPS_PORT" != "443" ]; then
        base_url="${base_url}:${HTTPS_PORT}"
    fi

    # 正确构建 FILES_URL - 只使用域名不带外部端口
    local files_protocol="$protocol"
    local files_host="$DOMAIN"
    local files_url="${files_protocol}://${files_host}:5001"

    update_env "SECRET_KEY" "$SECRET_KEY" ".env"
    update_env "DB_PASSWORD" "$DB_PASSWORD" ".env"
    update_env "REDIS_PASSWORD" "$REDIS_PASSWORD" ".env"
    update_env "SANDBOX_API_KEY" "$SANDBOX_API_KEY" ".env"
    update_env "PLUGIN_DAEMON_KEY" "$PLUGIN_DAEMON_KEY" ".env"
    update_env "PLUGIN_DIFY_INNER_API_KEY" "$PLUGIN_DIFY_INNER_API_KEY" ".env"

    update_env "CONSOLE_API_URL" "$base_url" ".env"
    update_env "CONSOLE_WEB_URL" "$base_url" ".env"
    update_env "SERVICE_API_URL" "$base_url" ".env"
    update_env "APP_WEB_URL" "$base_url" ".env"
    update_env "FILES_URL" "$files_url" ".env"
    update_env "INTERNAL_FILES_URL" "http://api:5001" ".env"

    update_env "DB_TYPE" "$DB_TYPE" ".env"
    update_env "VECTOR_STORE" "$VECTOR_STORE" ".env"
    update_env "COMPOSE_PROFILES" "$VECTOR_STORE,$DB_TYPE" ".env"

    update_env "NGINX_SERVER_NAME" "$NGINX_SERVER_NAME" ".env"
    update_env "NGINX_HTTPS_ENABLED" "$NGINX_HTTPS_ENABLED" ".env"
    update_env "NGINX_PORT" "$HTTP_PORT" ".env"
    update_env "NGINX_SSL_PORT" "$HTTPS_PORT" ".env"
    update_env "EXPOSE_NGINX_PORT" "$HTTP_PORT" ".env"
    update_env "EXPOSE_NGINX_SSL_PORT" "$HTTPS_PORT" ".env"

    if [ "$NGINX_HTTPS_ENABLED" = true ] && [ -n "$CERTBOT_EMAIL" ]; then
        update_env "NGINX_ENABLE_CERTBOT_CHALLENGE" "true" ".env"
        update_env "CERTBOT_EMAIL" "$CERTBOT_EMAIL" ".env"
        update_env "CERTBOT_DOMAIN" "$DOMAIN" ".env"
    fi

    update_env "STORAGE_TYPE" "$STORAGE_TYPE" ".env"
    if [ "$STORAGE_TYPE" = "opendal" ]; then
        update_env "OPENDAL_SCHEME" "$OPENDAL_SCHEME" ".env"
    fi

    if [ "$STORAGE_TYPE" = "s3" ]; then
        update_env "S3_BUCKET_NAME" "$S3_BUCKET" ".env"
        update_env "S3_REGION" "$S3_REGION" ".env"
        update_env "S3_ACCESS_KEY" "$S3_ACCESS_KEY" ".env"
        update_env "S3_SECRET_KEY" "$S3_SECRET_KEY" ".env"
    elif [ "$STORAGE_TYPE" = "azure" ]; then
        update_env "AZURE_BLOB_ACCOUNT_NAME" "$AZURE_ACCOUNT" ".env"
        update_env "AZURE_BLOB_ACCOUNT_KEY" "$AZURE_KEY" ".env"
        update_env "AZURE_BLOB_CONTAINER_NAME" "$AZURE_CONTAINER" ".env"
    elif [ "$STORAGE_TYPE" = "aliyun" ]; then
        update_env "ALIYUN_OSS_BUCKET_NAME" "$ALIYUN_BUCKET" ".env"
        update_env "ALIYUN_OSS_REGION" "$ALIYUN_REGION" ".env"
        update_env "ALIYUN_OSS_ACCESS_KEY_ID" "$ALIYUN_ACCESS_KEY" ".env"
        update_env "ALIYUN_OSS_ACCESS_KEY_SECRET" "$ALIYUN_SECRET_KEY" ".env"
    fi

    if [ "$CONFIGURE_EMAIL" = true ]; then
        update_env "MAIL_TYPE" "smtp" ".env"
        update_env "SMTP_HOST" "$SMTP_HOST" ".env"
        update_env "SMTP_PORT" "$SMTP_PORT" ".env"
        update_env "SMTP_USER" "$SMTP_USER" ".env"
        update_env "SMTP_PASSWORD" "$SMTP_PASSWORD" ".env"
        update_env "MAIL_FROM_ADDRESS" "$SMTP_FROM" ".env"
    fi

    # 为 .env 文件设置限制权限 (仅所有者可读写)
    chmod 600 ".env"
    print_ok "已创建 .env 配置文件"
    echo ""
}

# 检查服务健康状态
check_service_health() {
    local services=$(docker compose ps --format json 2>/dev/null)
    if [ -z "$services" ]; then
        return 1
    fi

    if command -v jq &> /dev/null; then
        # 使用 jq 检查是否有服务不健康/未运行
        # 比较实际输出字符串 "true" 或 "false"，而不是退出码
        local result
        result=$(echo "$services" | jq -s 'map(select(.State != "running" and .State != "created")) | length == 0' 2>/dev/null)
        if [ "$result" = "true" ]; then
            return 0
        fi
    else
        # 不使用 jq 的简单检查 - 统计不健康的服务
        local unhealthy=$(docker compose ps 2>/dev/null | grep -v "NAME" | grep -v -E "Up\s+\(healthy\)|Up\s+\(starting\)|Up|running|created" | wc -l)
        if [ "$unhealthy" -eq 0 ]; then
            return 0
        fi
    fi
    return 1
}

# 启动服务，正确处理错误和健康检查
start_services() {
    echo "正在启动 Dify..."
    print_step "正在拉取镜像 (可能需要几分钟)"
    if ! docker compose pull; then
        print_error "拉取镜像失败"
        echo "请检查上面的错误信息后重试。"
        echo ""
        echo "如果镜像拉取速度很慢，请确保已配置 Docker 镜像加速器。"
        echo "配置方法: 编辑 /etc/docker/daemon.json 添加镜像加速器"
        echo ""
        echo "如果自托管太复杂，可以尝试 Dify Cloud:"
        echo "  https://cloud.dify.ai"
        exit 1
    fi
    print_ok "镜像拉取完成"

    print_step "正在启动容器"
    if ! docker compose up -d; then
        print_error "启动容器失败"
        echo "请检查上面的错误信息后重试。"
        echo ""
        echo "如果自托管太复杂，可以尝试 Dify Cloud:"
        echo "  https://cloud.dify.ai"
        exit 1
    fi
    print_ok "容器启动完成"

    print_step "等待服务就绪..."
    local max_wait=180
    local waited=0
    local healthy=false

    while [ $waited -lt $max_wait ]; do
        if check_service_health; then
            healthy=true
            break
        fi
        echo -n "."
        sleep 5
        waited=$((waited + 5))
    done
    echo ""

    if [ "$healthy" = true ]; then
        print_ok "服务正在启动"
    else
        print_warn "服务可能仍在启动中。请使用 docker compose ps 检查状态"
        echo ""
        echo "如果问题持续，可以考虑使用 Dify Cloud:"
        echo "  https://cloud.dify.ai"
    fi
    echo ""
}

# 主安装流程
main() {
    if [ "$INTERACTIVE" = true ]; then
        interactive_config
        check_prerequisites
        check_ports
    else
        print_header
        check_prerequisites
        check_ports
        echo "使用所有推荐的默认值 (非交互模式)"
        echo ""
        if [ "$YES_MODE" = false ]; then
            read -p "继续安装? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "安装已取消。"
                exit 0
            fi
            echo ""
        fi
    fi

    generate_secrets
    create_env_file
    start_services
    print_success
}

# ============================================
# 函数定义结束
# ============================================

# 解析命令行参数 (在所有函数定义之后)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --interactive|-i) INTERACTIVE=true; YES_MODE=false; shift ;;
        --yes|-y|--default) YES_MODE=true; INTERACTIVE=false; shift ;;
        --help|-h) show_help; exit 0 ;;
        *) echo "未知选项: $1"; show_help; exit 1 ;;
    esac
done

# 运行安装
main
