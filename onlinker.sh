#!/usr/bin/env bash
# =============================================================================
# onlinker - ZeroTier 自动化部署管理工具
# =============================================================================
# 功能：支持在线/离线安装、ZeroTier 服务、ztncui 管理界面、Moon 节点部署和planet文件下载管理
# 支持：Ubuntu 16.04 LTS 到 24.04 LTS
# 作者：onlinker 项目
# 版本：1.4.0
# =============================================================================

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR"

# 日志颜色
c_info="\033[1;34m[INFO]\033[0m"
c_ok="\033[1;32m[ OK ]\033[0m"
c_warn="\033[1;33m[WARN]\033[0m"
c_err="\033[1;31m[ERR ]\033[0m"

# 日志函数
log() { echo -e "$c_info $*"; }
ok() { echo -e "$c_ok $*"; }
warn() { echo -e "$c_warn $*"; }
err() { echo -e "$c_err $*" >&2; }
die() { err "$*"; exit 1; }

# 配置
PLANET_DOWNLOAD_DIR="${SCRIPT_DIR}/planet-download"
HTTP_PORT=8888
PID_FILE="/tmp/onlinker-http.pid"

# 检查 root 权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "请用 root 运行此脚本"
    fi
}

# 检查 CRLF
check_crlf() {
    if grep -q $'\r' "$0" 2>/dev/null; then
        die "检测到 CRLF，请先转换：sed -i 's/\r\$//' '$0'"
    fi
}

# 在线安装 ZeroTier
install_zerotier_online() {
    log "开始在线安装 ZeroTier 服务..."
    if [ -f "./online/install-zerotier.sh" ]; then
        chmod +x "./online/install-zerotier.sh"
        ./online/install-zerotier.sh "$@"
        ok "ZeroTier 服务在线安装完成"
    else
        die "未找到在线安装脚本: ./online/install-zerotier.sh"
    fi
}

# 在线安装 ztncui
install_ztncui_online() {
    log "开始在线安装 ztncui 管理界面..."
    if [ -f "./online/install-ztncui.sh" ]; then
        chmod +x "./online/install-ztncui.sh"
        ./online/install-ztncui.sh "$@"
        ok "ztncui 管理界面在线安装完成"
    else
        die "未找到在线安装脚本: ./online/install-ztncui.sh"
    fi
}

# 离线安装 ZeroTier
install_zerotier_offline() {
    log "开始离线安装 ZeroTier 服务..."
    if [ -f "./offline/install-zerotier.sh" ]; then
        chmod +x "./offline/install-zerotier.sh"
        ./offline/install-zerotier.sh "$@"
        ok "ZeroTier 服务离线安装完成"
    else
        die "未找到离线安装脚本: ./offline/install-zerotier.sh"
    fi
}

# 离线安装 ztncui
install_ztncui_offline() {
    log "开始离线安装 ztncui 管理界面..."
    if [ -f "./offline/install-ztncui.sh" ]; then
        chmod +x "./offline/install-ztncui.sh"
        ./offline/install-ztncui.sh "$@"
        ok "ztncui 管理界面离线安装完成"
    else
        die "未找到离线安装脚本: ./offline/install-ztncui.sh"
    fi
}

# 拷贝 planet 文件
copy_planet() {
    local src="/var/lib/zerotier-one/planet"
    local dst="${PLANET_DOWNLOAD_DIR}/planet"
    
    if [ -s "$src" ]; then
        mkdir -p "$PLANET_DOWNLOAD_DIR"
        cp -f "$src" "$dst"
        ok "Planet 配置文件已拷贝到: $dst"
        return 0
    else
        warn "Planet 配置文件不存在或为空: $src"
        return 1
    fi
}

# 拷贝 moon 文件
copy_moon() {
    local src_dir="/var/lib/zerotier-one/moons.d"
    local dst_dir="${PLANET_DOWNLOAD_DIR}"
    
    if [ -d "$src_dir" ]; then
        mkdir -p "$dst_dir"
        local moon_files=($(find "$src_dir" -name "*.moon" -type f))
        
        if [ ${#moon_files[@]} -gt 0 ]; then
            for moon_file in "${moon_files[@]}"; do
                local filename=$(basename "$moon_file")
                local dst_file="${dst_dir}/${filename}"
                cp -f "$moon_file" "$dst_file"
                ok "Moon 配置文件已拷贝到: ${dst_file}"
            done
            return 0
        else
            warn "未找到 Moon 配置文件"
            return 1
        fi
    else
        warn "Moon 配置目录不存在: $src_dir"
        return 1
    fi
}

# 配置 zerotier-cli 别名
configure_alias() {
    log "配置 zerotier-cli 别名..."
    
    # 检查是否已存在别名
    if alias zc 2>/dev/null | grep -q "zerotier-cli"; then
        ok "别名 'zc' 已配置"
        return 0
    fi
    
    # 检查 zerotier-cli 是否可用
    if ! command -v zerotier-cli >/dev/null 2>&1; then
        warn "zerotier-cli 命令不可用，跳过别名配置"
        return 1
    fi
    
    # 为当前用户配置别名
    local user_shell=""
    local alias_file=""
    
    # 检测用户shell类型
    if [ -n "${SUDO_USER:-}" ]; then
        # 如果通过sudo运行，为原用户配置
        local user="$SUDO_USER"
        user_shell=$(getent passwd "$user" | cut -d: -f7)
        case "$user_shell" in
            */bash)
                alias_file="/home/$user/.bashrc"
                ;;
            */zsh)
                alias_file="/home/$user/.zshrc"
                ;;
            */fish)
                alias_file="/home/$user/.config/fish/config.fish"
                ;;
            *)
                warn "不支持的shell类型: $user_shell，跳过别名配置"
                return 1
                ;;
        esac
    else
        # 直接root运行，为root配置
        user_shell="$SHELL"
        case "$user_shell" in
            */bash)
                alias_file="/root/.bashrc"
                ;;
            */zsh)
                alias_file="/root/.zshrc"
                ;;
            */fish)
                alias_file="/root/.config/fish/config.fish"
                ;;
            *)
                warn "不支持的shell类型: $user_shell，跳过别名配置"
                return 1
                ;;
        esac
    fi
    
    # 检查别名文件是否存在
    if [ ! -f "$alias_file" ]; then
        warn "别名文件不存在: $alias_file，跳过别名配置"
        return 1
    fi
    
    # 检查是否已存在别名配置
    if grep -q "alias zc=" "$alias_file"; then
        ok "别名 'zc' 已在 $alias_file 中配置"
        return 0
    fi
    
    # 添加别名配置
    echo "" >> "$alias_file"
    echo "# ZeroTier CLI 别名配置 (由 onlinker 自动添加)" >> "$alias_file"
    echo "alias zc='zerotier-cli'" >> "$alias_file"
    
    # 设置文件权限
    if [ -n "${SUDO_USER:-}" ]; then
        chown "$SUDO_USER:$SUDO_USER" "$alias_file" 2>/dev/null || true
    fi
    
    ok "别名 'zc' 已添加到 $alias_file"
    log "请重新加载shell配置或重新登录以使用别名"
    log "或者执行: source $alias_file"
    
    return 0
}

# 验证安装结果
verify_installation() {
    log "验证安装结果和系统状态..."
    
    # 验证 ZeroTier 服务状态
    if [ -z "$component" ] || [ "$component" = "zerotier" ]; then
        if systemctl is-active --quiet zerotier-one; then
            ok "ZeroTier 服务运行状态：正常"
        else
            warn "ZeroTier 服务运行状态：异常"
        fi
    fi
    
    # 验证 ztncui 服务状态
    if [ -z "$component" ] || [ "$component" = "ztncui" ]; then
        if systemctl is-active --quiet ztncui; then
            ok "ztncui 管理界面运行状态：正常"
            # 检查端口监听
            if ss -tlnp | grep -q ":3000\|:3443"; then
                ok "ztncui 端口监听状态：正常"
            else
                warn "ztncui 端口监听状态：异常"
            fi
        else
            warn "ztncui 管理界面运行状态：异常"
        fi
    fi
    
    # 验证 planet 文件
    if [ -f "/var/lib/zerotier-one/planet" ]; then
        ok "Planet 配置文件状态：已就绪"
    else
        warn "Planet 配置文件状态：未就绪"
    fi
    
    # 验证 moon 文件
    local moon_count=$(find /var/lib/zerotier-one/moons.d -name "*.moon" -type f 2>/dev/null | wc -l)
    if [ "$moon_count" -gt 0 ]; then
        ok "Moon 配置文件状态：已就绪 ($moon_count 个)"
    else
        warn "Moon 配置文件状态：未就绪"
    fi
    
    # 自动配置别名
    configure_alias
}

# 完全清理 ZeroTier
clear_zerotier() {
    log "开始完全清理 ZeroTier 服务..."
    
    # 停止服务
    if systemctl is-active --quiet zerotier-one 2>/dev/null; then
        log "停止 ZeroTier 服务..."
        systemctl stop zerotier-one 2>/dev/null || true
        ok "ZeroTier 服务已停止"
    fi
    
    # 禁用服务
    if systemctl is-enabled --quiet zerotier-one 2>/dev/null; then
        log "禁用 ZeroTier 服务..."
        systemctl disable zerotier-one 2>/dev/null || true
        ok "ZeroTier 服务已禁用"
    fi
    
    # 移除包
    if dpkg-query -W -f='${Status}\n' zerotier-one 2>/dev/null | grep -q "install ok installed"; then
        log "移除 ZeroTier 包..."
        apt-get purge -y zerotier-one >/dev/null 2>&1 || true
        ok "ZeroTier 包已移除"
    fi
    
    # 清理配置文件和目录
    if [ -d "/var/lib/zerotier-one" ]; then
        log "清理 ZeroTier 配置目录..."
        rm -rf /var/lib/zerotier-one
        ok "ZeroTier 配置目录已清理"
    fi
    
    # 清理 planet-download 中的相关文件
    if [ -d "$PLANET_DOWNLOAD_DIR" ]; then
        log "清理 planet-download 中的 ZeroTier 文件..."
        rm -f "$PLANET_DOWNLOAD_DIR"/planet
        rm -f "$PLANET_DOWNLOAD_DIR"/*.moon
        ok "planet-download 中的 ZeroTier 文件已清理"
    fi
    
    ok "ZeroTier 服务完全清理完成"
}

# 完全清理 ztncui
clear_ztncui() {
    log "开始完全清理 ztncui 管理界面..."
    
    # 停止服务
    if systemctl is-active --quiet ztncui 2>/dev/null; then
        log "停止 ztncui 服务..."
        systemctl stop ztncui 2>/dev/null || true
        ok "ztncui 服务已停止"
    fi
    
    # 禁用服务
    if systemctl is-enabled --quiet ztncui 2>/dev/null; then
        log "禁用 ztncui 服务..."
        systemctl disable ztncui 2>/dev/null || true
        ok "ztncui 服务已禁用"
    fi
    
    # 移除包
    if dpkg-query -W -f='${Status}\n' ztncui 2>/dev/null | grep -q "install ok installed"; then
        log "移除 ztncui 包..."
        apt-get purge -y ztncui >/dev/null 2>&1 || true
        ok "ztncui 包已移除"
    fi
    
    # 清理配置文件和目录
    if [ -d "/opt/key-networks/ztncui" ]; then
        log "清理 ztncui 配置目录..."
        rm -rf /opt/key-networks/ztncui
        ok "ztncui 配置目录已清理"
    fi
    
    # 清理 systemd 服务文件备份
    if [ -f "/usr/lib/systemd/system/ztncui.service.bak" ]; then
        log "清理 ztncui systemd 服务文件备份..."
        rm -f /usr/lib/systemd/system/ztncui.service.bak
        ok "ztncui systemd 服务文件备份已清理"
    fi
    
    # 重新加载 systemd
    systemctl daemon-reload 2>/dev/null || true
    
    ok "ztncui 管理界面完全清理完成"
}

# 完全清理所有组件
clear_all() {
    log "开始完全清理所有组件和服务..."
    clear_zerotier
    clear_ztncui
    ok "所有组件和服务清理完成"
}

# 启动 HTTP 服务器
start_http_server() {
    # 检查PID文件中的进程是否真的在运行
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            # 检查进程是否真的是我们的HTTP服务器
            if ps -p "$pid" -o cmd | grep -q "python3 -m http.server $HTTP_PORT"; then
                warn "HTTP 服务器已在运行 (PID: $pid)"
                
                # 显示下载链接
                local server_ip=""
                
                # 尝试获取公网IP（优先）或内网IP
                if command -v curl >/dev/null 2>&1; then
                    server_ip=$(curl -s --max-time 5 https://ipinfo.io/ip 2>/dev/null || curl -s --max-time 5 https://ifconfig.me 2>/dev/null || curl -s --max-time 5 https://icanhazip.com 2>/dev/null)
                fi
                
                # 如果获取公网IP失败，使用内网IP
                if [ -z "$server_ip" ]; then
                    server_ip=$(hostname -I | awk '{print $1}')
                    warn "无法获取公网IP，使用内网IP: $server_ip"
                else
                    ok "获取到公网IP: $server_ip"
                fi
                
                # 显示下载链接
                if [ -f "${PLANET_DOWNLOAD_DIR}/planet" ]; then
                    log "Planet 配置文件下载地址: http://${server_ip}:${HTTP_PORT}/planet"
                fi
                
                # 显示 moon 文件下载链接
                local moon_files=($(find "${PLANET_DOWNLOAD_DIR}" -name "*.moon" -type f))
                if [ ${#moon_files[@]} -gt 0 ]; then
                    for moon_file in "${moon_files[@]}"; do
                        local filename=$(basename "$moon_file")
                        log "Moon 配置文件下载地址: http://${server_ip}:${HTTP_PORT}/${filename}"
                    done
                fi
                
                return 0
            else
                # PID存在但进程不是我们的HTTP服务器，清理PID文件
                warn "发现无效的PID文件，清理中..."
                rm -f "$PID_FILE"
            fi
        else
            # 进程不存在，清理PID文件
            rm -f "$PID_FILE"
        fi
    fi
    
    # 确保下载目录存在并清空旧文件
    mkdir -p "$PLANET_DOWNLOAD_DIR"
    rm -f "${PLANET_DOWNLOAD_DIR}"/*.moon
    rm -f "${PLANET_DOWNLOAD_DIR}/planet"
    
    # 拷贝 planet 文件
    copy_planet
    
    # 拷贝 moon 文件
    copy_moon
    
    # 停止可能存在的旧进程
    pkill -f "python3 -m http.server $HTTP_PORT" 2>/dev/null || true
    
    # 启动HTTP服务器，确保在正确的目录下运行
    cd "$PLANET_DOWNLOAD_DIR"
    python3 -m http.server "$HTTP_PORT" >/dev/null 2>&1 &
    local new_pid=$!
    echo "$new_pid" > "$PID_FILE"
    
    # 等待服务器启动
    sleep 2
    
    # 验证服务器是否成功启动
    if kill -0 "$new_pid" 2>/dev/null; then
        ok "HTTP 文件下载服务器已启动 (端口: $HTTP_PORT)"
        
        # 获取公网IP（优先）或内网IP
        local server_ip=""
        
        # 尝试获取公网IP
        if command -v curl >/dev/null 2>&1; then
            server_ip=$(curl -s --max-time 5 https://ipinfo.io/ip 2>/dev/null || curl -s --max-time 5 https://ifconfig.me 2>/dev/null || curl -s --max-time 5 https://icanhazip.com 2>/dev/null)
        fi
        
        # 如果获取公网IP失败，使用内网IP
        if [ -z "$server_ip" ]; then
            server_ip=$(hostname -I | awk '{print $1}')
            warn "无法获取公网IP，使用内网IP: $server_ip"
        else
            ok "获取到公网IP: $server_ip"
        fi
        
        # 显示下载链接
        if [ -f "${PLANET_DOWNLOAD_DIR}/planet" ]; then
            log "Planet 配置文件下载地址: http://${server_ip}:${HTTP_PORT}/planet"
        fi
        
        # 显示 moon 文件下载链接
        local moon_files=($(find . -name "*.moon" -type f))
        if [ ${#moon_files[@]} -gt 0 ]; then
            for moon_file in "${moon_files[@]}"; do
                local filename=$(basename "$moon_file")
                log "Moon 配置文件下载地址: http://${server_ip}:${HTTP_PORT}/${filename}"
            done
        fi
    else
        err "HTTP 服务器启动失败"
        rm -f "$PID_FILE"
        return 1
    fi
}

# 停止 HTTP 服务器
stop_http_server() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            ok "HTTP 文件下载服务器已停止"
        else
            rm -f "$PID_FILE"
            warn "HTTP 文件下载服务器未运行"
        fi
    else
        warn "HTTP 服务器 PID 文件不存在"
    fi
}

# 显示系统状态
show_system_status() {
    echo -e "\n=============================="
    echo -e " ZeroTier 系统状态报告"
    echo -e "=============================="
    
    # 安装状态
    echo -e "\n安装状态"
    echo -e "--------------------------------"
    
    # ZeroTier 状态
    if dpkg-query -W -f='${Status}\n' zerotier-one 2>/dev/null | grep -q "install ok installed"; then
        local zerotier_version=$(dpkg-query -W -f='${Version}' zerotier-one 2>/dev/null || echo "未知")
        echo -e "ZeroTier    | 已安装 (v$zerotier_version)"
        
        # Moon 支持状态
        if [ -d "/var/lib/zerotier-one/moons.d" ] && [ -n "$(find /var/lib/zerotier-one/moons.d -name '*.moon' -type f 2>/dev/null)" ]; then
            local moon_count=$(find /var/lib/zerotier-one/moons.d -name '*.moon' -type f 2>/dev/null | wc -l)
            echo -e " - Moon     | 已支持 ($moon_count 个节点)"
        else
            echo -e " - Moon     | 未支持"
        fi
    else
        echo -e "ZeroTier    | 未安装"
        echo -e " - Moon     | 未支持"
    fi
    
    # ztncui 状态
    if dpkg-query -W -f='${Status}\n' ztncui 2>/dev/null | grep -q "install ok installed"; then
        local ztncui_version=$(dpkg-query -W -f='${Version}' ztncui 2>/dev/null || echo "未知")
        echo -e "ztncui      | 已安装 (v$ztncui_version)"
        
        # Web UI 状态
        local local_ip=$(hostname -I | awk '{print $1}' | head -1)
        if systemctl is-active --quiet ztncui 2>/dev/null; then
            local http_port=$(ss -tlnp 2>/dev/null | grep ztncui | grep ":3000" | wc -l)
            local https_port=$(ss -tlnp 2>/dev/null | grep ztncui | grep ":3443" | wc -l)
            
            if [ "$https_port" -gt 0 ]; then
                echo -e " - Web UI   | http://$local_ip:3443"
            elif [ "$http_port" -gt 0 ]; then
                echo -e " - Web UI   | http://$local_ip:3000"
            else
                echo -e " - Web UI   | 未启动"
            fi
        else
            echo -e " - Web UI   | 服务未运行"
        fi
    else
        echo -e "ztncui      | 未安装"
        echo -e " - Web UI   | 不可用"
    fi
    
    # 网络配置
    echo -e "\n网络配置"
    echo -e "--------------------------------"
    
    if systemctl is-active --quiet zerotier-one 2>/dev/null; then
        # 获取所有网络信息
        local network_info=$(zerotier-cli listnetworks 2>/dev/null)
        if [ -n "$network_info" ]; then
            # 查找第一个已加入的网络（跳过表头行，查找包含16位十六进制ID的行）
            local networks=$(echo "$network_info" | grep -v "listnetworks <nwid>" | grep -E '^200.*[0-9a-f]{16}' | head -1 | awk '{print $3}')
            if [ -n "$networks" ]; then
                echo -e "默认网络    | $networks"
                
                # 获取本机IP - 使用更可靠的方法
                local local_ip=$(echo "$network_info" | grep "$networks" | awk '{print $9}' | head -1)
                if [ -n "$local_ip" ] && [ "$local_ip" != "-" ] && [ "$local_ip" != "?" ]; then
                    echo -e "本机 IP     | $local_ip"
                else
                    # 尝试从网络状态获取IP
                    local status_info=$(zerotier-cli listnetworks 2>/dev/null | grep "$networks" -A 5)
                    local assigned_ip=$(echo "$status_info" | grep "Managed IPs" | awk '{print $3}' | head -1)
                    if [ -n "$assigned_ip" ] && [ "$assigned_ip" != "-" ]; then
                        echo -e "本机 IP     | $assigned_ip"
                    else
                        echo -e "本机 IP     | 未分配"
                    fi
                fi
            else
                echo -e "默认网络    | 未创建"
                echo -e "本机 IP     | 未分配"
            fi
        else
            echo -e "默认网络    | 未创建"
            echo -e "本机 IP     | 未分配"
        fi
    else
        echo -e "默认网络    | 服务未运行"
        echo -e "本机 IP     | 不可用"
    fi
    
    # 下载访问状态
    local server_ip=""
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            if ps -p "$pid" -o cmd | grep -q "python3 -m http.server $HTTP_PORT"; then
                # 服务开启状态
                echo -e "\n下载访问 (ON)"
                echo -e "--------------------------------"
                
                # 获取服务器IP
                if command -v curl >/dev/null 2>&1; then
                    server_ip=$(curl -s --max-time 5 https://ipinfo.io/ip 2>/dev/null || curl -s --max-time 5 https://ifconfig.me 2>/dev/null || curl -s --max-time 5 https://icanhazip.com 2>/dev/null)
                fi
                if [ -z "$server_ip" ]; then
                    server_ip=$(hostname -I | awk '{print $1}')
                fi
                
                # 检查文件是否存在
                if [ -f "${PLANET_DOWNLOAD_DIR}/planet" ]; then
                    echo -e "Planet      | http://${server_ip}:${HTTP_PORT}/planet"
                else
                    echo -e "Planet      | none"
                fi
                
                # Moon 文件状态
                if [ -d "$PLANET_DOWNLOAD_DIR" ] && [ -n "$(find "$PLANET_DOWNLOAD_DIR" -name "*.moon" -type f)" ]; then
                    local moon_files=($(find "$PLANET_DOWNLOAD_DIR" -name "*.moon" -type f))
                    for moon_file in "${moon_files[@]}"; do
                        local filename=$(basename "$moon_file")
                        echo -e "Moon        | http://${server_ip}:${HTTP_PORT}/${filename}"
                    done
                else
                    echo -e "Moon        | none"
                fi
            else
                # 服务关闭状态
                echo -e "\n下载访问 (OFF)"
                echo -e "--------------------------------"
                
                # 服务关闭时显示 none
                echo -e "Planet      | none"
                echo -e "Moon        | none"
            fi
        else
            # 服务关闭状态
            echo -e "\n下载访问 (OFF)"
            echo -e "--------------------------------"
            
            # 服务关闭时显示 none
            echo -e "Planet      | none"
            echo -e "Moon        | none"
        fi
    else
        # 服务关闭状态
        echo -e "\n下载访问 (OFF)"
        echo -e "--------------------------------"
        
        # 服务关闭时显示 none
        echo -e "Planet      | none"
        echo -e "Moon        | none"
    fi
    
    echo -e "\n=============================="
}

# 显示帮助信息
show_help() {
    cat << EOF_HELP
onlinker.sh - ZeroTier 自动化部署管理工具

用法: $0 [选项] [组件] [参数]

选项:
  --online         在线安装模式
  --offline        离线安装模式
  --download on|off  开启/关闭文件下载服务（planet + moon）
  --clear [组件]   完全清理指定组件（zerotier/ztncui，不指定则清理所有）
  --status         显示系统状态报告
  --alias          配置 zerotier-cli 别名 (zc)
  --help           显示此帮助信息

注意:
  - ZeroTier 安装完成后会自动部署 Moon 节点配置
  - 系统会自动创建默认网络并分配固定 IP

组件:
  zerotier         仅安装 ZeroTier
  ztncui           仅安装 ztncui
  (不指定)         安装 ZeroTier + ztncui

参数:
  --reinstall      强制重装

示例:
  # 在线安装
  $0 --online                      # 安装 ZeroTier 服务 + ztncui 管理界面
  $0 --online zerotier             # 仅安装 ZeroTier 服务
  $0 --online ztncui               # 仅安装 ztncui 管理界面
  $0 --online --reinstall          # 强制重装所有组件

  # 离线安装
  $0 --offline                     # 安装 ZeroTier 服务 + ztncui 管理界面
  $0 --offline zerotier            # 仅安装 ZeroTier 服务
  $0 --offline ztncui              # 仅安装 ztncui 管理界面
  $0 --offline --reinstall         # 强制重装所有组件

  # 文件下载管理
  $0 --download on                 # 开启文件下载服务（planet + moon）
  $0 --download off                # 关闭文件下载服务

  # 组合使用
  $0 --online zerotier --reinstall # 在线重装 ZeroTier 服务
  $0 --offline ztncui --reinstall  # 离线重装 ztncui 管理界面

  # 清理功能
  $0 --clear                       # 清理所有组件和服务
  $0 --clear zerotier              # 仅清理 ZeroTier 服务
  $0 --clear ztncui                # 仅清理 ztncui 管理界面

  # 状态检查
  $0 --status                      # 显示系统状态报告
  
  # 别名配置
  $0 --alias                       # 配置 zerotier-cli 别名 (zc)
  # 配置完成后可以使用: zc listnetworks, zc join <network_id> 等

注意:
  - 需要 root 权限运行
  - 确保网络连接正常（在线模式）
  - 确保离线包完整（离线模式）
  - 清理功能会完全移除组件，包括配置和数据
  - 建议在生产环境使用前先在测试环境验证
  - 别名配置后需要重新加载shell配置或重新登录
  - 支持 bash、zsh、fish 等主流shell
EOF_HELP
}

# 主函数
main() {
    # 基础检查
    check_crlf
    check_root
    
    # 如果没有参数，显示帮助
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local mode=""
    local component=""
    local reinstall_flag=""
    
    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --status)
                show_system_status
                exit 0
                ;;
            --alias)
                configure_alias
                exit 0
                ;;
            --online)
                mode="online"
                shift
                ;;
            --offline)
                mode="offline"
                shift
                ;;
            --clear)
                if [ -n "${2:-}" ]; then
                    case "$2" in
                        zerotier)
                            clear_zerotier
                            exit 0
                            ;;
                        ztncui)
                            clear_ztncui
                            exit 0
                            ;;
                        *)
                            die "无效的 clear 参数: $2 (使用 'zerotier', 'ztncui' 或不指定参数清理所有)"
                            ;;
                    esac
                else
                    clear_all
                    exit 0
                fi
                ;;
            --download)
                if [ "$2" = "on" ]; then
                    log "开启文件下载服务（planet + moon）..."
                    start_http_server
                    ok "文件下载服务已开启"
                elif [ "$2" = "off" ]; then
                    log "关闭文件下载服务（planet + moon）..."
                    stop_http_server
                    ok "文件下载服务已关闭"
                else
                    die "无效的 download 参数: $2 (使用 'on' 或 'off')"
                fi
                exit 0
                ;;
            zerotier)
                component="zerotier"
                shift
                ;;
            ztncui)
                component="ztncui"
                shift
                ;;
            --reinstall)
                reinstall_flag="--reinstall"
                shift
                ;;
            *)
                die "未知参数: $1 (使用 --help 查看帮助信息)"
                ;;
        esac
    done
    
    # 检查模式
    if [ -z "$mode" ]; then
        die "请指定安装模式: --online 或 --offline"
    fi
    
    # 执行安装
    case "$mode" in
        "online")
            if [ "$component" = "zerotier" ]; then
                install_zerotier_online $reinstall_flag
            elif [ "$component" = "ztncui" ]; then
                install_ztncui_online $reinstall_flag
            else
                # 安装两个组件
                install_zerotier_online $reinstall_flag
                install_ztncui_online $reinstall_flag
            fi
            ;;
        "offline")
            if [ "$component" = "zerotier" ]; then
                install_zerotier_offline $reinstall_flag
            elif [ "$component" = "ztncui" ]; then
                install_ztncui_offline $reinstall_flag
            else
                # 安装两个组件
                install_zerotier_offline $reinstall_flag
                install_ztncui_offline $reinstall_flag
            fi
            ;;
        *)
            die "无效的安装模式: $mode (使用 --online 或 --offline)"
            ;;
    esac
    
    # 验证安装结果
    verify_installation
    
    ok "所有操作完成！系统已准备就绪。"
}

# 执行主函数
main "$@"
