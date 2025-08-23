```
             _ _       _             
            | (_)     | |            
  ___  _ __ | |_ _ __ | | _____ _ __ 
 / _ \| '_ \| | | '_ \| |/ / _ \ '__|
| (_) | | | | | | | | |   <  __/ |   
 \___/|_| |_|_|_|_| |_|_|\_\___|_|   
                                     
                                                                                                                                                              
```

# 🚀 onlinker - ZeroTier 自动化部署管理工具

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/ubuntu-16.04+-orange.svg)](https://ubuntu.com/)
[![Architecture](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-blue.svg)](https://en.wikipedia.org/wiki/Comparison_of_ARM_processors)
[![Status](https://img.shields.io/badge/status-fully%20tested-brightgreen.svg)](https://github.com/your-repo/onlinker)
[![Features](https://img.shields.io/badge/features-planet%20download%20%7C%20http%20server%20%7C%20moon%20deploy-blue.svg)](https://github.com/your-repo/onlinker)

> 🎯 **一键部署 ZeroTier 网络，让网络管理变得简单有趣！**

onlinker 是一个**超级酷炫**的 ZeroTier 网络工具自动化部署工具集 🎉，提供在线和离线两种安装方式。通过简单的命令行界面，您可以快速部署、管理和配置 ZeroTier 网络服务和 ztncui 管理界面。

✨ **新功能亮点**: 现在支持 Planet 文件自动下载服务、智能 Moon 节点部署、一键清理管理、智能部署检测，让网络部署变得超级简单！

## 🌟 核心特性

> 🎉 **让网络部署变得像玩游戏一样简单！**

### 🚀 双模式部署

- **在线安装**: 自动下载官方包并安装，适合有网络环境
- **离线安装**: 使用本地预打包文件，适合内网/隔离环境
- **智能检测**: 自动识别 Ubuntu 版本和系统架构
- **一键安装**: 简化的安装流程，支持重装和升级

### 🛡️ 安全可靠

- **权限检查**: 自动检查 root 权限和系统要求
- **错误处理**: 完善的错误捕获和日志记录机制
- **状态验证**: 双重验证确保服务正确部署
- **配置备份**: 自动备份现有配置文件

### 🎨 用户友好

- **彩色输出**: 智能颜色检测和状态提示
- **进度显示**: 实时显示安装和配置进度
- **友好错误**: 清晰的错误信息和操作指导
- **完整帮助**: 详细的命令参数和使用示例

### 🔧 功能完整

- **ZeroTier 服务**: 完整的网络虚拟化服务部署
- **ztncui 界面**: 专业的 Web 管理界面
- **服务管理**: 自动启用和启动系统服务
- **配置管理**: 智能配置文件生成和环境变量管理
- **架构支持**: 支持 amd64 和 arm64 双架构

### 🌐 Planet 下载服务

- **HTTP 服务器**: 内置 Python HTTP 服务器 (端口 8888)
- **自动拷贝**: 安装完成后自动拷贝 planet 文件
- **一键下载**: 客户端可通过 HTTP 直接下载 planet 和 moon 文件
- **服务管理**: 支持开启/关闭下载服务
- **智能检测**: 自动检测服务状态和进程管理

### 🌙 智能 Moon 节点部署

- **Moon 节点配置**: 自动生成 moon.json 配置文件
- **公网 IP 配置**: 自动获取公网 IP 并添加到 stableEndpoints
- **Moon 文件生成**: 自动生成 .moon 文件并部署到 moons.d/
- **网络初始化**: 自动创建默认 ZeroTier 网络 (10.24.0.0/24)
- **节点配置**: 自动加入网络并分配固定 IP (10.24.0.1/24)
- **服务应用**: 自动重启 ZeroTier 服务应用配置

### 🧹 一键清理管理

- **单组件清理**: 支持单独清理 ZeroTier 或 ztncui
- **全组件清理**: 一键清理所有组件和配置
- **智能清理**: 自动停止服务、移除包、清理配置文件
- **清理后部署**: 支持清理后重新部署，确保环境干净

### 🧠 智能部署检测

- **状态检测**: 自动检测已部署组件的运行状态
- **配置验证**: 验证配置文件的完整性和有效性
- **智能跳过**: 避免重复安装和配置，提高效率
- **强制重装**: 支持 `--reinstall` 参数强制重新部署

## 📋 系统要求

#### 💻 支持的操作系统

- ✅ **Ubuntu 16.04 LTS (xenial)**
- ✅ **Ubuntu 18.04 LTS (bionic)**
- ✅ **Ubuntu 20.04 LTS (focal)**
- ✅ **Ubuntu 22.04 LTS (jammy)**
- ✅ **Ubuntu 24.04 LTS (noble)**

#### 🏗️ 硬件架构支持

- **ZeroTier**: ✅ **amd64 (x86_64)** + ✅ **arm64 (aarch64)**
- **ztncui**: ❌ **仅 amd64 (x86_64)** - 官方限制

#### 📦 软件依赖

- **Bash**: 4.0+
- **curl**: 网络下载工具
- **jq**: JSON 处理工具
- **python3**: HTTP 服务器（用于文件下载服务）
- **dpkg**: Debian 包管理器
- **systemd**: 服务管理系统

## 🚀 快速开始

#### 📥 1. 克隆项目

```bash
git clone <repository-url>
cd onlinker
```

#### 🎯 2. 使用主管理脚本（推荐）

```bash
# 在线安装 ZeroTier + ztncui
sudo ./onlinker.sh --online

# 离线安装 ZeroTier + ztncui
sudo ./onlinker.sh --offline

# 仅安装 ZeroTier
sudo ./onlinker.sh --online zerotier
sudo ./onlinker.sh --offline zerotier

# 仅安装 ztncui
sudo ./onlinker.sh --online ztncui
sudo ./onlinker.sh --offline ztncui
```

#### 🌐 3. Planet 文件下载服务

```bash
# 开启下载服务
sudo ./onlinker.sh --download on

# 关闭下载服务
sudo ./onlinker.sh --download off

# 查看帮助
./onlinker.sh --help
```

#### 🧹 4. 一键清理管理

```bash
# 清理所有组件
sudo ./onlinker.sh --clear

# 仅清理 ZeroTier
sudo ./onlinker.sh --clear zerotier

# 仅清理 ztncui
sudo ./onlinker.sh --clear ztncui
```

#### 📦 5. 直接调用安装脚本

```bash
# 在线安装（推荐首次使用）
sudo ./online/install-zerotier.sh
sudo ./online/install-ztncui.sh

# 离线安装（内网环境）
sudo ./offline/install-zerotier.sh
sudo ./offline/install-ztncui.sh
```

#### 🔄 6. 强制重装

```bash
# 使用管理脚本重装
sudo ./onlinker.sh --online --reinstall
sudo ./onlinker.sh --offline --reinstall

# 直接调用安装脚本重装
sudo ./online/install-zerotier.sh --reinstall
sudo ./online/install-ztncui.sh --reinstall
```

#### 🌐 7. 访问管理界面

```bash
# 默认端口 3443
https://YOUR_SERVER_IP:3443

# 自定义端口
HTTPS_PORT=8443 sudo ./online/install-ztncui.sh
```

## 📖 详细使用说明

### 🎯 主管理脚本 (onlinker.sh)

`onlinker.sh` 是我们新推出的**超级智能**主管理脚本，集成了所有功能！

```bash
# 基本用法
./onlinker.sh [选项] [组件] [参数]

# 查看完整帮助
./onlinker.sh --help
```

#### 🚀 安装管理

```bash
# 在线安装
./onlinker.sh --online                      # 安装 ZeroTier + ztncui
./onlinker.sh --online zerotier             # 仅安装 ZeroTier
./onlinker.sh --online ztncui               # 仅安装 ztncui

# 离线安装
./onlinker.sh --offline                     # 安装 ZeroTier + ztncui
./onlinker.sh --offline zerotier            # 仅安装 ZeroTier
./onlinker.sh --offline ztncui              # 仅安装 ztncui

# 强制重装
./onlinker.sh --online --reinstall          # 在线重装所有组件
./onlinker.sh --offline zerotier --reinstall # 离线重装 ZeroTier
```

#### 🌐 配置下载管理

```bash
# 开启下载服务
./onlinker.sh --download on

# 关闭下载服务
./onlinker.sh --download off
```

#### 📊 系统状态检查

```bash
# 查看系统状态报告
./onlinker.sh --status
**执行结果示例**：
```bash
==============================
 ZeroTier 系统状态报告
==============================

安装状态
--------------------------------
ZeroTier    | 已安装 (v1.14.2)
 - Moon     | 已支持 (2 个节点)
ztncui      | 已安装 (v0.8.14)
 - Web UI   | http://192.168.1.100:3443

网络配置
--------------------------------
默认网络    | 2001db8c5b9a0000
本机 IP     | 10.24.0.1

下载访问 (ON)
--------------------------------
Planet      | http://YOUR_SERVER_IP:8888/planet
Moon        | http://YOUR_SERVER_IP:8888/00000032b53ad024.moon
==============================
```

#### 🌐 配置下载管理

```bash
# 开启下载服务
./onlinker.sh --download on

# 关闭下载服务
./onlinker.sh --download off
```

#### 📥 下载服务管理

```bash
# 开启下载服务
./onlinker.sh --download on

# 关闭下载服务
./onlinker.sh --download off

# 服务会自动：
# ✅ 拷贝 planet 文件到 planet-download/ 目录
# ✅ 启动 Python HTTP 服务器 (端口 8888)
# ✅ 提供文件下载服务
```

#### 🧹 清理管理

```bash
# 清理所有组件
./onlinker.sh --clear

# 仅清理 ZeroTier
./onlinker.sh --clear zerotier

# 仅清理 ztncui
./onlinker.sh --clear ztncui
```

#### 🔧 安装脚本概览

```bash
# ZeroTier 安装
./online/install-zerotier.sh [--reinstall]
./offline/install-zerotier.sh [--reinstall]

# ztncui 安装
./online/install-ztncui.sh [--reinstall]
./offline/install-ztncui.sh [--reinstall]
```

#### 🔧 在线安装流程

```bash
# 1. 系统检测
- 检查 Ubuntu 版本
- 验证系统架构
- 确认 root 权限

# 2. 依赖安装
- 自动安装 curl 工具
- 下载官方软件包

# 3. 服务部署
- 安装软件包
- 配置环境变量
- 启用系统服务
```

#### 📦 离线安装流程

```bash
# 1. 系统检测
- 检查 Ubuntu 版本
- 验证系统架构
- 定位离线包路径

# 2. 包管理
- 选择对应版本包
- 安装软件包
- 处理依赖关系

# 3. 服务配置
- 生成配置文件
- 启动系统服务
- 验证服务状态
```

#### 🌙 Moon 节点部署流程

```bash
# 1. Moon 节点配置
- 生成 moon.json 配置文件
- 自动获取公网 IP
- 添加到 stableEndpoints 配置

# 2. Moon 文件生成
- 使用 zerotier-idtool 生成 .moon 文件
- 部署到 moons.d/ 目录
- 复制到 planet-download/ 供下载

# 3. 网络初始化
- 检查现有网络
- 自动创建默认网络 (10.24.0.0/24)
- 自动加入网络并分配固定 IP (10.24.0.1/24)

# 4. 服务应用
- 重启 ZeroTier 服务
- 应用 Moon 节点配置
- 验证网络连接状态
```

#### ⚙️ 配置管理

```bash
# 查看 ZeroTier token
cat /var/lib/zerotier-one/authtoken.secret

# 查看 ztncui 配置
cat /opt/key-networks/ztncui/.env

# 修改 ztncui 端口
HTTPS_PORT=8443 sudo ./online/install-ztncui.sh --reinstall
```

## ⚙️ 配置说明

#### 📋 默认配置

- **ZeroTier 端口**: 9993 (UDP)
- **ztncui 端口**: 3443 (HTTPS)
- **ZeroTier 版本**: 1.14.2
- **ztncui 版本**: 0.8.14

#### 📁 目录结构

```
onlinker/
├── README.md                    # 📖 项目说明文档
├── onlinker.sh                 # 🎯 主管理脚本 (新增！)
├── planet-download/            # 🌐 Planet 下载目录 (新增！)
│   └── planet                  # 📦 Planet 文件
├── online/                     # 🚀 在线安装脚本
│   ├── install-zerotier.sh    # ZeroTier 在线安装 (105行)
│   └── install-ztncui.sh      # ztncui 在线安装 (160行)
└── offline/                    # 📦 离线安装脚本
    ├── install-zerotier.sh    # ZeroTier 离线安装 (132行)
    ├── install-ztncui.sh      # ztncui 离线安装 (139行)
    └── packages/              # 离线软件包 (58MB)
        ├── zerotier/          # ZeroTier 包 (38MB)
        │   └── deb/
        │       ├── xenial/    # Ubuntu 16.04
        │       ├── bionic/    # Ubuntu 18.04
        │       ├── focal/     # Ubuntu 20.04
        │       ├── jammy/     # Ubuntu 22.04
        │       └── noble/     # Ubuntu 24.04
        │           ├── zerotier-one_1.14.2_amd64.deb
        │           └── zerotier-one_1.14.2_arm64.deb
        └── ztncui/            # ztncui 包 (20MB)
            └── deb/amd64/
                └── ztncui_0.8.14_amd64.deb
```

#### 🔧 环境变量

```bash
# ztncui 配置
HTTPS_PORT=3443              # Web 管理界面端口
ZT_TOKEN=auto                # ZeroTier token (自动获取)
NODE_ENV=production          # 运行环境

# 安装控制
ALLOW_REINSTALL=1            # 允许重装

# Planet 下载服务配置
HTTP_PORT=8888               # HTTP 下载服务端口
PLANET_DOWNLOAD_DIR=./planet-download  # Planet 文件下载目录

# Moon 节点配置
NETWORK_CIDR=10.24.0.0/24   # 默认网络 CIDR
NODE_IP=10.24.0.1           # 默认节点 IP
```

#### 🌐 Planet 文件管理

**Planet 文件** 是 ZeroTier 的核心配置文件，用于连接私有网络：

```bash
# 默认 planet 文件位置
/var/lib/zerotier-one/planet

# 安装时自动拷贝到
/home/planet

# 客户端需要替换的路径
Linux:   /var/lib/zerotier-one/planet
macOS:   /Library/Application Support/ZeroTier/One/planet
Windows: C:\ProgramData\ZeroTier\One\planet
```

**获取私有 planet 文件**：
- 从已配置的 ZeroTier 服务器复制
- 通过 ztncui 管理界面下载
- 联系网络管理员获取

#### 📱 客户端加入私有网络步骤

> 🎯 **重要提示**: 加入私有网络前，必须先替换默认的 planet 和 moon 文件！

#### 🍎 macOS 客户端

```bash
# 1. 进入 ZeroTier 配置目录
sudo cd "/Library/Application Support/ZeroTier/One"

# 2. 删除默认配置文件
sudo rm -rf planet
sudo rm -rf moons.d/*.moon

# 3. 下载私有配置文件
sudo curl -O "http://YOUR_SERVER_IP:8888/planet"
sudo curl -O "http://YOUR_SERVER_IP:8888/YOUR_MOON_ID.moon"

# 4. 重启 ZeroTier 服务
sudo kill $(cat zerotier-one.pid)

# 5. 重新打开 ZeroTier 应用，使用私有网络 ID 加入网络
```

#### 🐧 Linux 客户端

```bash
# 1. 进入 ZeroTier 配置目录
sudo cd /var/lib/zerotier-one

# 2. 删除默认配置文件
sudo rm -rf planet
sudo rm -rf moons.d/*.moon

# 3. 下载私有配置文件
sudo wget "http://YOUR_SERVER_IP:8888/planet"
sudo wget "http://YOUR_SERVER_IP:8888/YOUR_MOON_ID.moon"

# 4. 重启 ZeroTier 服务
sudo systemctl restart zerotier-one

# 5. 加入私有网络
sudo zerotier-cli join YOUR_NETWORK_ID
```

#### 🪟 Windows 客户端

```cmd
# 1. 以管理员身份运行 CMD，进入配置目录
cd /d "C:\ProgramData\ZeroTier\One"

# 2. 删除默认配置文件
del planet
rmdir /s /q moons.d

# 3. 下载私有配置文件
powershell -Command "Invoke-WebRequest -Uri 'http://YOUR_SERVER_IP:8888/planet' -OutFile 'planet'"
powershell -Command "Invoke-WebRequest -Uri 'http://YOUR_SERVER_IP:8888/YOUR_MOON_ID.moon' -OutFile 'YOUR_MOON_ID.moon'"

# 4. 重启 ZeroTier 服务
# 按 Win+R，输入 services.msc，找到 "ZeroTier One Service"，右键重启
# 或者使用命令行：
net stop "ZeroTier One Service"
net start "ZeroTier One Service"

# 5. 重新打开 ZeroTier 应用，使用私有网络 ID 加入网络
```

#### 🐳 NAS (Docker) 客户端

```bash
# 1. 进入 Docker 容器映射的本地目录
cd /path/to/your/zerotier/mapping/var/lib/zerotier-one

# 2. 删除默认配置文件
rm -rf planet
rm -rf moons.d/*.moon

# 3. 下载私有配置文件
wget "http://YOUR_SERVER_IP:8888/planet"
wget "http://YOUR_SERVER_IP:8888/YOUR_MOON_ID.moon"

# 4. 重启 Docker 容器中的 ZeroTier 服务
docker exec -it zerotier-container systemctl restart zerotier-one

# 5. 加入私有网络
docker exec -it zerotier-container zerotier-cli join YOUR_NETWORK_ID
```

#### 📱 iStoreOS 客户端

```bash
# 1. 打开 iStore，搜索并安装 ZeroTier
# 2. 先不要启用 ZeroTier 服务

# 3. 进入配置目录
cd /etc/config/zero/

# 4. 替换配置文件
rm -rf planet
rm -rf moons.d/*.moon
wget "http://YOUR_SERVER_IP:8888/planet"
wget "http://YOUR_SERVER_IP:8888/YOUR_MOON_ID.moon"

# 5. 在 iStore 中启用 ZeroTier 服务

# 6. 使用私有网络 ID 加入网络
```

#### 🔗 下载链接获取

启动下载服务后，会显示类似以下的下载链接：

```bash
[INFO] Planet 配置文件下载地址: http://YOUR_SERVER_IP:8888/planet
[INFO] Moon 配置文件下载地址: http://YOUR_SERVER_IP:8888/YOUR_MOON_ID.moon
```

**替换说明**：
- `YOUR_SERVER_IP` → 替换为你的服务器公网 IP
- `YOUR_MOON_ID.moon` → 替换为实际的 moon 文件名
- `YOUR_NETWORK_ID` → 替换为实际的网络 ID (16位十六进制字符串)

## 🔍 故障排除

#### 🚫 常见问题

##### 1. 权限不足

```bash
[ERR] 请用 root 运行。
```

**解决方案**: 使用 sudo 运行脚本

```bash
sudo ./online/install-zerotier.sh
```

##### 2. ztncui HTTPS 端口问题

```bash
# 问题：ztncui 只监听 HTTP 端口 3000，没有 HTTPS 端口 3443
# 原因：systemd 环境变量配置问题

# 解决方案：脚本已自动修复
# ✅ 自动修改 systemd 服务文件
# ✅ 添加 EnvironmentFile 配置
# ✅ 重启服务应用新配置
```

##### 3. 架构不支持

```bash
[ERR] ztncui 官方仅提供 amd64 .deb；当前架构 arm64 不支持离线安装。
```

**解决方案**: 在 amd64 架构上安装 ztncui

##### 4. 服务启动失败

```bash
[ERR] 服务未处于运行状态
```

**解决方案**: 检查服务状态和日志

```bash
# 查看服务状态
systemctl status zerotier-one
systemctl status ztncui

# 查看日志
journalctl -u zerotier-one -f
journalctl -u ztncui -f
```

##### 5. 网络连接问题

- 检查防火墙设置
- 验证端口是否开放
- 确认网络配置正确

##### 6. Planet 下载服务问题

```bash
# 错误：HTTP 服务无法启动
[ERR] HTTP 服务器启动失败

# 解决方案：
# 1. 检查端口 8888 是否被占用
ss -tlnp | grep :8888

# 2. 检查 Python3 是否安装
python3 --version

# 3. 手动启动服务
cd planet-download && python3 -m http.server 8888

# 4. 检查文件权限
ls -la planet-download/planet
```

##### 7. 主管理脚本问题

```bash
# 错误：脚本权限不足
[ERR] 请用 root 运行此脚本

# 解决方案：
sudo ./onlinker.sh --help

# 错误：未知参数
[ERR] 未知参数: --invalid

# 解决方案：查看帮助
./onlinker.sh --help
```

##### 8. Moon 节点部署问题

```bash
# 问题：Moon 节点配置失败
# 原因：公网 IP 获取失败或网络配置问题

# 解决方案：
# 1. 检查网络连接
curl -s ifconfig.me

# 2. 检查 ZeroTier 服务状态
systemctl status zerotier-one

# 3. 查看部署日志
journalctl -u zerotier-one -f

# 4. 手动重新部署
./onlinker.sh --online zerotier --reinstall
```

##### 9. 客户端无法加入私有网络

```bash
# 常见错误：无法连接到网络
[ERR] 无法连接到网络

# 解决方案：
# 1. 确认 planet 文件已正确替换
# 2. 检查网络 ID 是否正确
# 3. 重启 ZeroTier 服务
# 4. 验证服务器端网络配置
```

##### 10. Planet 文件相关问题

```bash
# 错误：planet 文件权限问题
[ERR] 无法读取 planet 文件

# 解决方案：
# 1. 检查文件权限 (Linux/macOS: 644, Windows: 可读)
# 2. 确认文件完整性
# 3. 重新复制 planet 文件
# 4. 重启 ZeroTier 服务
```

#### 📊 日志分析

```bash
# ZeroTier 日志
journalctl -u zerotier-one -f

# ztncui 日志
journalctl -u ztncui -f

# 系统日志
tail -f /var/log/syslog
```

#### 🔍 手动诊断

```bash
# 检查端口监听
ss -tlnp | grep -E "(9993|3443)"

# 检查服务状态
systemctl is-active zerotier-one
systemctl is-active ztncui

# 检查配置文件
ls -la /var/lib/zerotier-one/
ls -la /opt/key-networks/ztncui/
```

## 🔐 安全注意事项

#### 🏭 生产环境建议

1. **网络安全**: 配置防火墙规则，限制端口访问
2. **访问控制**: 使用强密码和访问控制
3. **定期更新**: 及时更新 ZeroTier 和 ztncui
4. **监控日志**: 定期检查访问和错误日志
5. **备份配置**: 备份重要的配置文件和密钥

#### 🌐 网络安全

- 确保 ZeroTier 网络配置安全
- 限制 ztncui 管理界面访问
- 定期审查网络策略和路由

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

#### 🛠️ 开发环境

1. Fork 本项目
2. 创建特性分支: `git checkout -b feature/amazing-feature`
3. 提交更改: `git commit -m 'Add amazing feature'`
4. 推送分支: `git push origin feature/amazing-feature`
5. 创建 Pull Request

#### 📝 代码规范

- 使用 2 空格缩进
- 添加适当的注释和错误处理
- 遵循现有的命名约定
- 确保兼容多个 Ubuntu 版本

## 📊 项目统计

- **主要语言**: bash
- **支持架构**: amd64 + arm64
- **支持版本**: Ubuntu 16.04-24.04 LTS
- **核心功能**: 智能部署 + Moon 节点 + 一键清理 + 文件下载服务

详细的版本更新记录请查看 [changelog.md](changelog.md) 文件。

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [ZeroTier](https://github.com/zerotier/ZeroTierOne) - 开源网络虚拟化平台
- [ztncui](https://github.com/key-networks/ztncui) - ZeroTier 网络控制器界面
- [Ubuntu](https://ubuntu.com/) - 优秀的 Linux 发行版

## 📞 支持

如果您遇到问题或有任何建议，请：

1. 查看 [故障排除](#-故障排除) 部分
2. 搜索已有的 [Issues](../../issues)
3. 创建新的 [Issue](../../issues/new)

---

**快速链接**: [安装](#-快速开始) | [主管理脚本](#-主管理脚本-onlinkersh) | [Moon 部署](#-moon-节点部署流程) | [清理管理](#-一键清理管理) | [使用说明](#-详细使用说明) | [故障排除](#-故障排除) | [贡献](#-贡献指南)

---

> 🎯 **准备好开始你的 ZeroTier 网络之旅了吗？**
> 
> 🚀 **开始使用**: `sudo ./onlinker.sh --online`
> 
> 💡 **查看帮助**: `./onlinker.sh --help`
