# sophon-firmware-builder

Sophon（算能）微型服务器固件构建工具

## Scripts

### 服务启动

```bash
#
# 服务启动之前，执行 Dockerfile 构建
#
sudo bash scripts/start.sh

#
# 服务直接启动，忽略 Dockerfile 构建
#
sudo bash scripts/start.sh --no-build
```

### 服务停止

```bash
#
# 关闭服务，清理所有和服务相关的镜像
#
sudo bash scripts/close.sh

#
# 关闭服务，保留所有和服务相关的镜像
#
sudo bash scripts/close.sh --no-clean
```

### 服务重启

```bash
#
# 重新构建 Dockerfile 并启动服务
#
sudo bash scripts/close.sh && sudo bash scripts/start.sh

#
# 跳过构建 Dockerfile 并启动服务
#
sudo bash scripts/close.sh --no-clean && sudo bash scripts/start.sh --no-build
```

## Usage

### 1. 配置宿主环境（eg. Fedora 44 x86_64）

```bash
#
# 安装 python 工具
#
sudo dnf install python3-pip
python3 -m pip install --upgrade pip setuptools setuptools_rust dfss -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 2. 下载相关资源

```bash
#
# 进入三方目录
#
cd ./volumes/extern
#
# 下载资源
#
git clone https://github.com/sophgo/bootloader-arm64.git
python3 -m dfss --dflag=gcc_linaro_6.3.1
python3 -m dfss --dflag=distro_focal_28ad82b4cf01327b1f81d3d193923424
git clone https://github.com/sophgo/linux-arm64.git
```
