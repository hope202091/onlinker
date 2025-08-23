#!/usr/bin/env bash
# =============================================================================
# onlinker - ZeroTier 在线安装脚本
# =============================================================================
# 功能：Ubuntu 在线安装 zerotier-one
# 支持：Ubuntu 16.04 LTS 到 24.04 LTS
# 来源：https://install.zerotier.com
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
  die "请使用 root 权限运行此脚本"
fi

set -euo pipefail
trap 'err "脚本执行失败（第 $LINENO 行），请检查错误日志"; exit 1' ERR

ALLOW_REINSTALL="${ALLOW_REINSTALL:-0}"

parse_args(){
  for a in "$@"; do
    case "$a" in
      --reinstall) ALLOW_REINSTALL=1 ;;
      *) die "未知参数：$a" ;;
    esac
  done
}

detect_ubuntu(){
  . /etc/os-release || die "未找到 /etc/os-release。"
  [ "${ID:-}" = "ubuntu" ] || die "当前系统非 Ubuntu（ID=${ID:-unknown}）。"
  CODENAME="${VERSION_CODENAME:-}"
  if [ -z "${CODENAME:-}" ] && command -v lsb_release >/dev/null 2>&1; then
    CODENAME="$(lsb_release -sc || true)"
  fi
  [ -n "${CODENAME:-}" ] || die "无法识别 Ubuntu codename。请检查 /etc/os-release 文件。"
  log "检测到系统：Ubuntu ${VERSION_ID:-?} (${CODENAME}) ($(uname -m))"
}

# ---- 确保网络工具可用 ----
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
  
  if ! command -v jq >/dev/null 2>&1; then
    log "未检测到 jq，尝试安装..."
    if ! apt-get -y -qq install jq >/dev/null; then
      err "jq 安装失败，请检查网络连接或手动安装"
      exit 1
    fi
    ok "已安装 jq。"
  fi
  
  if ! command -v python3 >/dev/null 2>&1; then
    log "未检测到 python3，尝试安装..."
    if ! apt-get -y -qq install python3 >/dev/null; then
      err "python3 安装失败，请检查网络连接或手动安装"
      exit 1
    fi
    ok "已安装 python3。"
  fi
}

# —— 关键修正：只把 "install ok installed" 当成已安装 ——
is_installed(){
  local s
  s="$(dpkg-query -W -f='${Status}\n' zerotier-one 2>/dev/null || true)"
  [ "$s" = "install ok installed" ]
}

run_official(){
  log "执行官方安装脚本..."
  if ! curl -s https://install.zerotier.com | bash; then
    die "官方安装脚本执行失败。请检查网络连接和系统状态。"
  fi
  ok "官方脚本执行完成。"
}

enable_service(){
  systemctl daemon-reload || true
  # 有时候 unit 在但服务未启用/未运行，这里统一 enable+start
  systemctl enable --now zerotier-one || die "启用/启动 zerotier-one 失败（参考：journalctl -u zerotier-one）。"
  if systemctl is-active --quiet zerotier-one; then
    ok "服务已运行：zerotier-one"
  else
    die "服务未处于 active。"
  fi
}

show_token_hint(){
  local t="/var/lib/zerotier-one/authtoken.secret"
  if [ -s "$t" ]; then
    ok "控制器 token：$t"
  else
    warn "尚未生成 token：$t（服务刚启动时稍等片刻）。"
  fi
}

# ---- 统一的服务重启函数 ----
restart_zerotier_service(){
  local max_retries=3
  local retry_count=0
  
  log "重启 ZeroTier 服务..."
  
  while [ $retry_count -lt $max_retries ]; do
    if systemctl restart zerotier-one; then
      ok "ZeroTier 服务重启命令执行成功"
      
      # 等待服务完全启动
      log "等待服务完全启动..."
      sleep 3
      
      # 验证服务状态
      if systemctl is-active --quiet zerotier-one 2>/dev/null; then
        ok "ZeroTier 服务已正常运行"
        return 0
      else
        warn "服务启动异常，尝试重试 ($((retry_count + 1))/$max_retries)"
      fi
    else
      warn "服务重启命令失败，尝试重试 ($((retry_count + 1))/$max_retries)"
    fi
    
    ((retry_count++))
    sleep 2
  done
  
  # 所有重试都失败
  err "ZeroTier 服务重启失败，已重试 $max_retries 次"
  err "请检查服务状态：systemctl status zerotier-one"
  return 1
}

# ---- 统一的文件复制函数 ----
copy_moon_to_download_dir(){
  local target_file="$1"
  local download_dir="/root/onlinker/planet-download"
  local filename
  
  if [ ! -f "$target_file" ]; then
    warn "Moon 配置文件不存在：$target_file"
    return 1
    fi
  
  filename=$(basename "$target_file")
  
  # 确保下载目录存在
  if [ ! -d "$download_dir" ]; then
    mkdir -p "$download_dir"
    log "创建下载目录：$download_dir"
  fi
  
  # 复制文件
  if cp -f "$target_file" "$download_dir/"; then
    ok "已复制 Moon 配置文件到：$download_dir/$filename"
    return 0
  else
    warn "复制 Moon 配置文件失败：$target_file → $download_dir/"
    return 1
  fi
}

# ---- Moon 节点部署 ----
deploy_moon(){
  local public_ip
  local network_id
  local token
  local node_id
  local api="http://127.0.0.1:9993"
  
  log "开始自动部署 Moon 节点配置..."
  
  # 1. 等待服务启动
  log "等待 ZeroTier 服务完全启动..."
  sleep 3
  
  # 2. 获取认证信息
  token=$(cat /var/lib/zerotier-one/authtoken.secret 2>/dev/null || echo "")
  if [ -z "$token" ]; then
    warn "无法获取认证 token，跳过 Moon 节点部署"
    return 1
  fi
  
  node_id=$(zerotier-cli info 2>/dev/null | awk '{print $3}' || echo "")
  if [ -z "$node_id" ]; then
    warn "无法获取节点 ID，跳过 Moon 节点部署"
    return 1
  fi
  
  ok "获取认证信息成功：节点 ID $node_id"
  
  # 3. 检查是否已有网络，如果没有则创建默认网络
  local networks
  networks=$(zerotier-cli listnetworks 2>/dev/null | grep -E '^200 listnetworks [0-9a-f]{16}' | awk '{print $3}' || echo "")
  
  if [ -z "$networks" ]; then
    log "未检测到网络，创建默认网络..."
    
    # 创建网络（由控制器基于 NODEID 随机生成 NWID）
    network_id=$(curl -s -X POST \
      "${api}/controller/network/${node_id}______" \
      -H "X-ZT1-AUTH: ${token}" -d '{}' | jq -r .id 2>/dev/null || echo "")
    
    if [ -z "$network_id" ]; then
      warn "创建默认网络失败，跳过 Moon 节点部署"
      return 1
    fi
    
    ok "已创建默认网络：$network_id"
    
    # 配置网络参数
    if curl -s -X POST "${api}/controller/network/${network_id}" \
      -H "X-ZT1-AUTH: ${token}" \
      -d '{
        "name": "default",
        "private": true,
        "ipAssignmentPools": [
          {"ipRangeStart":"10.24.0.1","ipRangeEnd":"10.24.0.254"}
        ],
        "routes": [
          {"target":"10.24.0.0/24","via": null}
        ],
        "v4AssignMode": "zt"
      }' >/dev/null 2>&1; then
      ok "默认网络配置完成"
    else
      warn "默认网络配置失败，但网络已创建"
    fi
    
    # 等待网络生效
    sleep 2
    
    # 自动加入刚创建的网络
    log "自动加入刚创建的网络：$network_id"
    if zerotier-cli join "$network_id" >/dev/null 2>&1; then
      ok "已加入网络：$network_id"
      # 等待加入生效
      sleep 3
      
      # 获取本机节点ID
      local node_id=$(zerotier-cli info | grep -o '[0-9a-f]\{10\}' | head -1)
      if [ -n "$node_id" ]; then
        log "本机节点ID: $node_id"
        
        # 设置本机节点IP为 10.24.0.1/24
        log "设置本机节点固定IP为 10.24.0.1/24"
        if curl -s -X POST "${api}/controller/network/${network_id}/member/${node_id}" \
          -H "X-ZT1-AUTH: ${token}" \
          -d '{
            "ipAssignments": ["10.24.0.1"],
            "authorized": true
          }' >/dev/null 2>&1; then
          ok "本机节点固定IP设置成功: 10.24.0.1/24"
        else
          warn "本机节点固定IP设置失败"
        fi
      else
        warn "无法获取本机节点ID"
      fi
    else
      warn "加入网络失败：$network_id"
    fi
  else
    # 使用第一个已存在的网络
    network_id=$(echo "$networks" | head -1)
    log "使用已存在的网络：$network_id"
  fi
  
  # 4. 检查网络状态（简化：只检查网络是否存在，不强制等待 OK 状态）
  local network_status
  
  # 直接获取网络状态，不需要 tail -n +2
  network_status=$(zerotier-cli listnetworks | grep "$network_id" | awk '{print $5}' || echo "")
  
  if [ -n "$network_status" ]; then
    log "网络状态：$network_status（继续 moon 部署）"
  else
    warn "无法获取网络状态，但继续 moon 部署"
  fi
  
  ok "网络 ID 已就绪：$network_id"
  
  # 5. 进入安装目录
  cd /var/lib/zerotier-one/ || die "无法进入 ZeroTier 目录"
  
  # 6. 生成 moon.json
  if ! zerotier-idtool initmoon identity.public > moon.json; then
    warn "生成 moon.json 失败"
    return 1
  fi
  ok "moon.json 文件已生成"
  
  # 7. 获取公网 IP
  public_ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || curl -s --max-time 10 ipinfo.io/ip 2>/dev/null || echo "")
  if [ -z "$public_ip" ]; then
    warn "无法获取公网 IP，使用内网 IP"
    public_ip=$(hostname -I | awk '{print $1}' | head -1)
  fi
  
  # 8. 使用 jq 修改 moon.json，添加公网 IP 到 stableEndpoints
  if ! jq --arg ip "$public_ip" '.roots[0].stableEndpoints = ["\($ip)/9993"]' moon.json > moon_temp.json; then
    warn "修改 moon.json 失败"
    return 1
  fi
  ok "已添加公网 IP 到 stableEndpoints：$public_ip/9993"
  
  # 9. 生成 .moon 文件
  local moon_id
  moon_id=$(jq -r '.id' moon.json)
  if ! zerotier-idtool genmoon moon.json; then
    warn "生成 .moon 文件失败"
    return 1
  fi
  
  # 10. 查找生成的 .moon 文件
  local moon_file
  # 只在当前目录查找，避免在 moons.d 子目录中找到文件
  moon_file=$(find . -maxdepth 1 -name "000000${moon_id}.moon" -type f | head -1)
  if [ -z "$moon_file" ]; then
    warn "未找到生成的 Moon 配置文件"
    return 1
  fi
  
  # 11. 创建 moons.d 目录并移动文件
  mkdir -p moons.d/
  
  # 检查目标文件是否已存在
  local target_file="moons.d/$(basename "$moon_file")"
  

  
  if [ -f "$target_file" ]; then
    # 检查是否为重装模式
    if [ "${ALLOW_REINSTALL:-0}" = "1" ]; then
      # 重装模式：先判断网络ID是否相同
      local existing_filename=$(basename "$target_file")
      local new_filename=$(basename "$moon_file")
      
      if [ "$existing_filename" = "$new_filename" ]; then
        # 文件名相同，说明网络配置没有变化，保留现有文件
        # 但需要先验证现有文件是否真的存在且有效
        if [ -f "$target_file" ] && [ -s "$target_file" ]; then
          rm -f "$moon_file"  # 删除新生成的文件
          ok "重装模式：检测到 Moon 配置网络ID相同，保留现有文件: $existing_filename"
          # 确保 target_file 指向现有的文件
          target_file="moons.d/$existing_filename"
        else
          # 现有文件不存在或为空，需要重新生成
          warn "重装模式：检测到 Moon 配置网络ID相同，但现有文件无效，重新生成配置"
          rm -f "$target_file"  # 删除无效的现有文件
          mv "$moon_file" moons.d/
          ok "重装模式：已重新生成 Moon 配置文件：$target_file"
        fi
      else
        # 文件名不同，说明网络配置发生变化，强制更新
        warn "重装模式：检测到 Moon 配置网络ID不同，强制更新配置"
        rm -f "$target_file"
        mv "$moon_file" moons.d/
        ok "重装模式：已强制更新 Moon 配置文件：$target_file"
      fi
    else
      # 普通模式：提示存在老配置
      warn "检测到已有 Moon 配置，跳过部署"
      warn "如需替换，请使用 --reinstall 参数"
      rm -f "$moon_file"  # 删除新生成的文件
      return 1
    fi
  else
    # 目标文件不存在，直接移动
    mv "$moon_file" moons.d/
    ok "已生成 Moon 配置文件：$target_file"
  fi
  
  # 12. 重启服务
  if ! restart_zerotier_service; then
    warn "服务重启失败，跳过后续操作"
    return 1
  fi
  
  # 13. 复制 moon 文件到 planet-download 目录
  copy_moon_to_download_dir "$target_file"
  
  # 14. 返回 moon 文件路径
  echo "$target_file"
}

main(){
  parse_args "$@"
  detect_ubuntu
  ensure_net_tools

  # 先刷新 systemd 视图，避免"non-native service"提示
  systemctl daemon-reload || true

  if is_installed; then
    if [ "$ALLOW_REINSTALL" = "1" ]; then
      log "检测到已安装，执行强制重装（--reinstall）..."
      apt-get -y purge zerotier-one >/dev/null 2>&1 || true
      run_official
    else
      # 综合检测：服务状态 + planet文件 + moon文件
      local service_running=false
      local planet_exists=false
      local moon_exists=false
      
      # 检测服务状态
      if systemctl is-active --quiet zerotier-one 2>/dev/null; then
        service_running=true
      fi
      
      # 检测planet文件
      if [ -f "/var/lib/zerotier-one/planet" ] && [ -s "/var/lib/zerotier-one/planet" ]; then
        planet_exists=true
      fi
      
      # 检测moon文件
      if [ -d "/var/lib/zerotier-one/moons.d" ] && [ -n "$(find /var/lib/zerotier-one/moons.d -name '*.moon' -type f 2>/dev/null)" ]; then
        moon_exists=true
      fi
      
      # 根据检测结果显示相应信息
      if [ "$service_running" = true ] && [ "$planet_exists" = true ] && [ "$moon_exists" = true ]; then
        ok "检测到已部署 zerotier (planet + moon)，跳过部署"
        ok "如需重装：--reinstall"
        # 完整部署，跳过后续操作
        return 0
      elif [ "$service_running" = true ] && [ "$planet_exists" = true ]; then
        ok "检测到已部署 zerotier (planet)，跳过 ZeroTier 安装，继续部署 Moon 节点..."
        # 部分部署，继续执行moon部署
      elif [ "$service_running" = true ] && [ "$planet_exists" = false ]; then
        warn "检测到 zerotier 服务运行但缺少 planet 文件，需要重新安装"
        warn "执行强制重装以修复配置..."
        apt-get -y purge zerotier-one >/dev/null 2>&1 || true
        run_official
        # 重新安装后继续执行moon部署
      else
        warn "检测到 zerotier 安装状态异常，需要重新安装"
        warn "执行强制重装以修复配置..."
        apt-get -y purge zerotier-one >/dev/null 2>&1 || true
        run_official
        # 重新安装后继续执行moon部署
      fi
    fi
  else
    # 未安装：直接跑官方安装
    run_official
  fi

  enable_service
  show_token_hint
  
  # 自动部署 moon 节点
  deploy_moon
  
  ok "完成。"
}

main "$@"
