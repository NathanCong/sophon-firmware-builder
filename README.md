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

git clone https://github.com/sophgo/bootloader-arm64.git
git clone https://github.com/sophgo/linux-arm64.git
git clone https://github.com/sophgo/libsophon.git

python3 -m dfss --dflag=gcc_linaro_6.3.1
python3 -m dfss --dflag=distro_focal_28ad82b4cf01327b1f81d3d193923424

#
# 从官网下载 SDK（https://developer.sophgo.com/site/index/material/all/all.html）
#
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

cp -r bootloader-arm64 /workspace/build/

mkdir -p /workspace/build/distro/
cp -r distro_focal_28ad82b4cf01327b1f81d3d193923424.tgz /workspace/build/distro/distro_focal.tgz

cp -r linux-arm64 /workspace/build/

tar -xJvf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz -C /workspace/build/

7z x SDK-26.03.01.zip -o/workspace/build/

cp -r libsophon /workspace/build/
```

### 4. 执行编译构建

```bash
cd /workspace/build

#
# 构建 BSP
#
source bootloader-arm64/scripts/envsetup.sh
build_bsp_without_package

#
# 拷贝 'sophon-mw-soc-sophon-ffmpeg*.deb' 和 'sophon-mw-soc-sophon-opencv*.deb'
#
cp -r release/sophon-mw_20260414_035450/sophon-mw-soc-sophon-ffmpeg_0.15.0_arm64.deb /workspace/build/install/soc_bm1684/bsp-debs
cp -r release/sophon-mw_20260414_035450/sophon-mw-soc-sophon-opencv_0.15.0_arm64.deb /workspace/build/install/soc_bm1684/bsp-debs

#
# 构建 'libsophon*.deb'
#
cp -r /workspace/build/install/soc_bm1684/bsp-debs/linux-headers-5.4.217-bm1684.deb /workspace/build/

mkdir -p soc_kernel
dpkg -x linux-headers-5.4.217-bm1684.deb soc_kernel

export PATH=/workspace/build/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin:$PATH
which aarch64-linux-gnu-gcc

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
# 拷贝 'sophon-soc-driver*.deb' 和 'sophon-soc-libsophon*.deb'
#
cp -r sophon-soc-driver_0.5.3_arm64.deb /workspace/build/install/soc_bm1684/bsp-debs
cp -r sophon-soc-libsophon_0.5.3_arm64.deb /workspace/build/install/soc_bm1684/bsp-debs

#
# 构建 sdcard
#
update-binfmts --enable qemu-aarch64
ls /proc/sys/fs/binfmt_misc/qemu-aarch64

cd /workspace/build/
source bootloader-arm64/scripts/envsetup.sh
build_package
```
