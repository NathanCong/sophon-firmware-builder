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
# 宿主环境下，进入 extern 目录并下载资源
#
cd volumes/extern

#
# 下载 bsp 构建相关仓库
#
git clone https://github.com/sophgo/bootloader-arm64.git
git clone https://github.com/sophgo/linux-arm64.git
git clone https://github.com/sophgo/libsophon.git

#
# 下载 88x2bu 构建相关仓库
#
git clone https://github.com/morrownr/88x2bu-20210702.git

#
# 下载 ubuntu 镜像 + gcc 编译工具
#
python3 -m dfss --dflag=gcc_linaro_6.3.1
python3 -m dfss --dflag=distro_focal_28ad82b4cf01327b1f81d3d193923424

#
# 从官网下载 SDK（https://developer.sophgo.com/site/index/material/all/all.html）
#
ls SDK-26.03.01.zip

#
# 从网站下载 debs（https://launchpad.net/ubuntu/focal/arm64/network-manager/1.22.10-1ubuntu2.4）
#
ls network-manager_1.22.10-1ubuntu2.4_arm64.deb
```

### 3. 配置容器环境

```bash
#
# 宿主环境下，启动服务并进入容器
#
sudo bash scripts/start.sh
sudo docker exec -it sophon-firmware-builder /bin/bash

#
# 容器环境下，准备构建环境
#
cd /workspace/extern

#
# 拷贝源码
#
# bootloader-arm64
# linux-arm64
# libsophon
# 88x2bu-20210702
#
cp -r bootloader-arm64 linux-arm64 libsophon 88x2bu-20210702 /workspace/build/

#
# 拷贝软件包
#
# network-manager_1.22.10-1ubuntu2.4_arm64.deb
#
mkdir -p /workspace/build/debs/
cp -r network-manager_1.22.10-1ubuntu2.4_arm64.deb /workspace/build/debs

#
# 拷贝系统镜像
#
mkdir -p /workspace/build/distro/
cp -r distro_focal_28ad82b4cf01327b1f81d3d193923424.tgz /workspace/build/distro/distro_focal.tgz

#
# 解压编译工具
#
tar -xJvf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz -C /workspace/build/

#
# 解压 SophonSDK
#
7z x SDK-26.03.01.zip -o/workspace/build/
```

### 4. 执行编译构建

```bash
#
# 进入构建目录
#
cd /workspace/build

#
# 设置环境变量
#
export PATH=/workspace/build/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin:$PATH
which aarch64-linux-gnu-gcc

#
# 激活模拟器
#
update-binfmts --enable qemu-aarch64
ls /proc/sys/fs/binfmt_misc/qemu-aarch64

#
# 执行 bsp 构建
#
source bootloader-arm64/scripts/envsetup.sh
build_bsp_without_package

#
# 执行 'libsophon*.deb' 构建
#
mkdir -p soc_kernel
dpkg -x /workspace/build/install/soc_bm1684/bsp-debs/linux-headers-5.4.217-bm1684.deb soc_kernel
cd /workspace/build/libsophon
mkdir build && cd build
cmake \
-DPLATFORM=soc \
-DSOC_LINUX_DIR=/workspace/build/soc_kernel/usr/src/linux-headers-5.4.217-bm1684/ \
-DLIB_DIR=/workspace/build/libsophon/3rdparty/soc/ \
-DCROSS_COMPILE_PATH=/workspace/build/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu \
-DCMAKE_TOOLCHAIN_FILE=/workspace/build/libsophon/toolchain-aarch64-linux.cmake \
-DCMAKE_INSTALL_PREFIX=$PWD/../install ..
make
make driver
make vpu_driver
make jpu_driver
make package

#
# 执行 88x2bu.ko 构建
#
cd /workspace/build/88x2bu-20210702
make -j$(nproc) \
ARCH=arm64 \
CROSS_COMPILE=/workspace/build/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- \
KSRC=/workspace/build/linux-arm64/build/bm1684/normal \
CONFIG_POWER_SAVING=n

#
# 拷贝相关包到 bsp-debs
#
# sophon-soc-libsophon*.deb
# sophon-mw-soc-sophon-ffmpeg*.deb
# sophon-mw-soc-sophon-opencv*.deb
# 88x2bu.ko
# network-manager_1.22.10-1ubuntu2.4_arm64.deb
#
cd /workspace/build/
cp -r libsophon/build/sophon-soc-libsophon_0.5.3_arm64.deb /workspace/build/install/soc_bm1684/bsp-debs
cp -r release/sophon-mw_20260414_035450/sophon-mw-soc-sophon-ffmpeg_0.15.0_arm64.deb /workspace/build/install/soc_bm1684/bsp-debs
cp -r release/sophon-mw_20260414_035450/sophon-mw-soc-sophon-opencv_0.15.0_arm64.deb /workspace/build/install/soc_bm1684/bsp-debs
cp -r 88x2bu-20210702/88x2bu.ko /workspace/build/install/soc_bm1684/bsp-debs
cp -r debs /workspace/build/install/soc_bm1684

#
# 构建 sdcard
#
cd /workspace/build/
source bootloader-arm64/scripts/envsetup.sh
build_package
```
