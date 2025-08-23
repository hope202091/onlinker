#!/usr/bin/env bash
# =============================================================================
# onlinker - ztncui 在线安装脚本
# =============================================================================
# 功能：Ubuntu 在线安装 ztncui
# 支持：Ubuntu 16.04 LTS 到 24.04 LTS（仅 amd64）
# 来源：https://s3-us-west-1.amazonaws.com/key-networks/deb/ztncui/1/x86_64/ztncui_0.8.14_amd64.deb
# 作者：onlinker 项目
# =============================================================================

# ---- 日志统一 ----
c_info="\033[1;34m[INFO]\033[0m"; c_ok="\033[1;32m[ OK ]\033[0m"
c_warn="\033[1;33m[WARN]\033[0m"; c_err="\033[1;31m[ERR ]\033[0m"
log() { echo -e "$c_info $*"; }
ok() { echo -e "$c_ok $*"; }
warn() { echo -e "$c_warn $*"; }
err() { echo -e "$c_err $*" >&2; }
die() { err "$*"; exit 1; }

# ---- 基础检查 ----
if grep -q $'\r' "$0" 2>/dev/null; then
  die "检测到 CRLF，请先转换：sed -i 's/\r\$//' '$0'"
fi
if [ "$(id -u)" -ne 0 ]; then
  die "请用 root 运行。"
fi

set -euo pipefail
trap 'err "脚本执行失败（第 $LINENO 行），请检查错误日志"; exit 1' ERR

# ---- 常量 ----
DOWNLOAD_URL="https://s3-us-west-1.amazonaws.com/key-networks/deb/ztncui/1/x86_64/ztncui_0.8.14_amd64.deb"
DL="/tmp/ztncui_0.8.14_amd64.deb"
HTTPS_PORT="${HTTPS_PORT:-3443}"
ALLOW_REINSTALL="${ALLOW_REINSTALL:-0}"

# ---- 参数解析 ----
parse_args(){
  for a in "$@"; do
    case "$a" in
      --reinstall) ALLOW_REINSTALL=1 ;;
      *) die "未知参数：$a" ;;
    esac
  done
}

# ---- 检测系统（Ubuntu + amd64）----
detect_ubuntu_amd64(){
  . /etc/os-release || die "未找到 /etc/os-release。"
  [ "${ID:-}" = "ubuntu" ] || die "当前系统非 Ubuntu（ID=${ID:-unknown}）。"
  case "$(uname -m)" in
    x86_64) : ;;
    *) die "ztncui 官方仅提供 amd64 .deb；当前架构不支持（$(uname -m)）。" ;;
  esac
  log "检测到系统：Ubuntu ${VERSION_ID:-?} (${VERSION_CODENAME:-?}) (x86_64 -> amd64)"
}

# ---- 依赖工具 ----
ensure_net_tools(){
  if ! command -v curl >/dev/null 2>&1; then
    log "未检测到 curl，尝试安装..."
    if ! apt-get -y -qq update >/dev/null; then
      err "apt 更新失败，请检查网络连接"
      exit 1
    fi
    if ! apt-get -y -qq install curl ca-certificates >/dev/null; then
      err "curl 安装失败，请检查网络连接或手动安装"
      exit 1
    fi
    ok "已安装 curl。"
  fi
}

# ---- 下载 deb ----
download_deb(){
  log "下载 ztncui deb → $DL"
  if ! curl -fsSL -o "$DL" "$DOWNLOAD_URL"; then
    die "下载失败：$DOWNLOAD_URL"
  fi
  [ -s "$DL" ] || die "下载文件为空：$DL"
  ok "下载完成。"
}

# ---- 安装状态判断（精准口径）----
is_installed(){
  local s
  s="$(dpkg-query -W -f='${Status}\n' ztncui 2>/dev/null || true)"
  [ "$s" = "install ok installed" ]
}

# ---- 安装 ----
install_deb(){
  [ -s "$DL" ] || { die "缺少安装包：$DL"; exit 3; }
  export DEBIAN_FRONTEND=noninteractive
  
  # 参考离线脚本：直接使用 dpkg 安装，避免 apt 的 needrestart 问题
  if ! dpkg -i "$DL" >/dev/null 2>&1; then
    # 检查 ZeroTier 运行状态
    if ! systemctl is-active --quiet zerotier-one 2>/dev/null; then
      die "安装失败：ztncui 依赖运行中的 ZeroTier 服务"
    fi
    die "dpkg -i 失败（可能缺依赖）。请检查依赖后重试。"
  fi
  
  # 修复可能的依赖问题
  apt-get -f install -y -qq >/dev/null 2>&1 || true
  
  ok "ztncui 安装完成。"
}

# ---- 写 .env ----
write_env(){
  mkdir -p /opt/key-networks/ztncui
  local token_file="/var/lib/zerotier-one/authtoken.secret"
  local token="__FILL_ME__"
  if [ -s "$token_file" ]; then
    token="$(cat "$token_file")"
  else
    warn "未找到 ZeroTier token：$token_file；已写入占位符。"
  fi

  local env="/opt/key-networks/ztncui/.env"

  cat >"$env" <<EOF
ZT_TOKEN=${token}
HTTPS_PORT=${HTTPS_PORT}
NODE_ENV=production
# 如需限制监听到某个 IP，请取消下一行注释并填入 IP：
# HTTPS_HOST=12.34.56.78
EOF

  chmod 400 "$env"
  chown ztncui:ztncui "$env" 2>/dev/null || warn "chown 失败（用户 ztncui 可能尚未创建），可忽略。"
  ok "写入 .env：$env"
}

# ---- 启用并检查服务 ----
enable_service(){
  # 修改 systemd 服务文件，添加环境变量配置
  local service_file="/usr/lib/systemd/system/ztncui.service"
  if [ -f "$service_file" ]; then
    # 备份原服务文件
    cp "$service_file" "${service_file}.bak"
    
    # 在 [Service] 段添加 EnvironmentFile 配置
    if ! grep -q "EnvironmentFile" "$service_file"; then
      sed -i '/^\[Service\]/a EnvironmentFile=/opt/key-networks/ztncui/.env' "$service_file"
      log "已添加环境变量配置到 systemd 服务文件"
    fi
    
    # 重新加载 systemd 配置
    systemctl daemon-reload
    
    # 如果服务已经在运行，需要重启以应用新的环境变量配置
    if systemctl is-active --quiet ztncui 2>/dev/null; then
      log "重启服务以应用新的环境变量配置..."
      systemctl restart ztncui
      sleep 2
    fi
  fi
  
  systemctl enable --now ztncui || die "启用/启动 ztncui 失败（参考：journalctl -u ztncui）。"
  systemctl is-active --quiet ztncui || die "服务未处于 active。"
  
  # 等待服务完全启动并验证端口监听
  log "等待服务完全启动..."
  sleep 3
  
  # 检查是否同时监听了 HTTP 和 HTTPS 端口
  local http_port=$(ss -tlnp 2>/dev/null | grep ztncui | grep ":3000" | wc -l)
  local https_port=$(ss -tlnp 2>/dev/null | grep ztncui | grep ":3443" | wc -l)
  
  if [ "$http_port" -gt 0 ] && [ "$https_port" -gt 0 ]; then
    ok "服务已运行：ztncui (HTTP:3000, HTTPS:3443)"
  else
    warn "服务启动异常，端口监听状态异常"
    warn "HTTP 端口: $http_port, HTTPS 端口: $https_port"
  fi
}



# ---- 主流程 ----
main(){
  parse_args "$@"
  detect_ubuntu_amd64
  ensure_net_tools

  if is_installed; then
    if [ "$ALLOW_REINSTALL" = "1" ]; then
      log "检测到已安装，执行强制重装（--reinstall）..."
      apt-get -y -qq purge ztncui >/dev/null 2>&1 || true
      download_deb
      install_deb
    else
      # 综合检测：服务状态 + 配置文件 + 端口监听
      local service_running=false
      local config_exists=false
      local ports_listening=false
      
      # 检测服务状态
      if systemctl is-active --quiet ztncui 2>/dev/null; then
        service_running=true
      fi
      
      # 检测配置文件
      if [ -f "/opt/key-networks/ztncui/.env" ] && [ -s "/opt/key-networks/ztncui/.env" ]; then
        config_exists=true
      fi
      
      # 检测端口监听
      local http_port=$(ss -tlnp 2>/dev/null | grep ztncui | grep ":3000" | wc -l)
      local https_port=$(ss -tlnp 2>/dev/null | grep ztncui | grep ":3443" | wc -l)
      if [ "$http_port" -gt 0 ] && [ "$https_port" -gt 0 ]; then
        ports_listening=true
      fi
      
      # 根据检测结果显示相应信息
      if [ "$service_running" = true ] && [ "$config_exists" = true ] && [ "$ports_listening" = true ]; then
        ok "检测到已部署 ztncui (服务运行 + 配置完整 + 端口监听)，跳过部署"
        ok "如需重装：--reinstall"
        # 完整部署，跳过后续操作
        return 0
      elif [ "$service_running" = true ] && [ "$config_exists" = true ]; then
        ok "检测到已部署 ztncui (服务运行 + 配置完整)，跳过配置写入，继续服务检查..."
        # 部分部署，继续执行服务检查
      elif [ "$service_running" = true ] && [ "$config_exists" = false ]; then
        warn "检测到 ztncui 服务运行但缺少配置文件，需要重新配置"
        warn "继续执行配置写入和服务配置..."
        # 继续执行配置写入
      else
        warn "检测到 ztncui 安装状态异常，需要重新配置"
        warn "继续执行配置写入和服务配置..."
        # 继续执行配置写入
      fi
    fi
  else
    download_deb
    install_deb
  fi

  write_env
  enable_service
  ok "完成。"
}
main "$@"
