#
# 1. 设置基础镜像
#
FROM ubuntu:20.04

#
# 2. 设置环境变量
#
# DEBIAN_FRONTEND=noninteractive  关闭交互式弹窗、禁用人工交互等待，自动化跑脚本
#
ENV DEBIAN_FRONTEND=noninteractive

#
# 3. 设置全局指令
#
SHELL ["/bin/bash", "-c"]

#
# 4. 替换软件源
#
RUN cp -a /etc/apt/sources.list /etc/apt/sources.list.bak \
&& sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list

#
# 5. 安装依赖包
#
# build-essential       包含 gcc、g++、make 等核心编译工具链，是编译任何 C/C++ 项目的基石
# cmake & ninja-build   跨平台的构建系统生成器。libsophon 等模块使用 CMake 来管理编译流程，Ninja 用于加速编译
# pkg-config            管理库的编译和链接参数（比如告诉编译器去哪里找 libssl 的头文件和库）
# bison & flex          语法分析器生成器。Linux 内核编译和某些底层工具（如 u-boot）需要用它们来处理配置解析
# bc                    任意精度计算器。Linux 内核编译脚本经常用它来进行十六进制/十进制转换计算
#
# qemu-user-static      核心的跨架构模拟器。让 x86 的机器能够直接执行 ARM64 的二进制文件
# binfmt-support        配合 QEMU 使用，向内核注册可执行文件的格式，让系统遇到 ARM64 文件时自动呼叫 QEMU
# debootstrap           用于在指定目录下下载并安装一个基础的 Ubuntu/Debian 根文件系统（Rootfs），用于制作固件
#
# device-tree-compiler  设备树编译器（dtc）。负责将人类可读的 .dts 文件编译成板子启动所需的二进制 .dtb 文件
# u-boot-tools          包含 mkimage 等工具。用于给内核镜像添加 U-Boot 能够识别的头部信息，打包生成 boot.scr 或 .itb 引导文件
# kmod                  提供 insmod、rmmod、depmod 等工具，用于在目标系统的 rootfs 中管理 Linux 内核驱动模块
# dkms                  动态内核模块支持。在编译 libsophon 的 SoC 驱动时，需要它来针对特定内核头文件（linux-headers）编译出 .ko 驱动文件
#
# cpio                  用于创建和解压 .cpio 归档文件。Linux 启动早期的 initramfs 镜像就是用这个格式打包的
# kpartx                用来读取分区的映射设备。在制作完整镜像（如 sdcard.img）时，用来将镜像内的分区映射出来并挂载
# dosfstools            提供 mkfs.fat 等命令。用于将启动分区格式化为 FAT32 格式
# rsync                 强大的文件同步工具。用于将宿主机编译好的文件高效地复制到目标 rootfs 目录中
# fakeroot              模拟 root 权限。在制作 .deb 安装包或复制文件时，用来欺骗系统，让你拥有操作 root 文件的权限，而不需要真正的 sudo
#
# dpkg-dev              提供 dpkg-buildpackage 等工具，用于制作 .deb 软件安装包
# uuid-dev              提供 UUID（通用唯一识别码）相关的库，制作文件系统（如 ext4）和分区表时需要用到
# libssl-dev            OpenSSL 开发库。提供加密和安全通信支持，很多底层库编译时都依赖它
# libxml2-dev           XML 解析库。用于解析板卡的配置文件或硬件描述文件
# libncurses5-dev       提供终端字符图形界面库。bm-smi（板卡管理工具）用它来在终端绘制界面，内核的 make menuconfig 也需要它
# libgflags-dev         Google 提供的 C++ 命令行参数解析库和单元测试框架，libsophon 的代码编译和测试依赖它们
# libgtest-dev          参考 libgflags-dev
#
# sudo                  提供超级用户权限执行命令
# p7zip-full            提供 7z 命令，用于解压某些特殊的或大型的压缩包
# bsdmainutils          包含 hexdump 等工具
#
RUN apt-get update \
&& apt-get upgrade -y \
&& apt-get install -y --no-install-recommends \
build-essential cmake ninja-build pkg-config bison flex bc \
qemu-user-static binfmt-support debootstrap \
device-tree-compiler u-boot-tools kmod dkms \
cpio kpartx dosfstools rsync fakeroot \
dpkg-dev uuid-dev libssl-dev libxml2-dev libncurses5-dev libgflags-dev libgtest-dev \
sudo p7zip-full bsdmainutils \
&& rm -rf /var/lib/apt/lists/*

#
# 6. 设置工作区
#
WORKDIR /workspace
