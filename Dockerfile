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
# 网络 & 证书类
# wget                   文件下载工具
# curl                   网络请求 / 下载，脚本里拉源码、API 调用
# rsync                  增量同步文件，打包 rootfs、同步源码、镜像分发必备
# ca-certificates        根证书，https 下载（git clone、wget https）不会报证书错误
#
# 内核 / UBoot 编译必备（BSP 编译核心）
# bc                     内核编译时用于数学计算，`make menuconfig`/ 内核构建依赖
# bison                  语法解析器生成器，内核、设备树编译必备
# flex                   词法分析器，和 bison 成对，内核编译依赖
# build-essential        元包，一次性安装 `gcc,g++,make` 等基础编译工具链
# gcc / g++              C/C++ 编译器，交叉编译配套
# device-tree-compiler   设备树 DTS 编译器，编译 `.dts → .dtb`，Sophon BSP 核心工具
# u-boot-tools           U-Boot 配套工具，mkimage、fitimage 生成，制作 uboot 镜像
# kmod                   内核模块工具，`modinfo` 查看 ko 模块信息
#
# 文件系统 & 镜像打包（rootfs 制作、刷机镜像）
# cpio                   生成 initramfs，Linux 内核初始内存文件系统，固件打包必备
# debootstrap            用来从 0 构建 Debian/Ubuntu arm64 rootfs
# fakeroot               打包 rootfs 时**模拟 root 权限**，不用真正 root 就能设置文件属主，制作 rootfs 镜像神器
# kpartx                 挂载磁盘镜像里的分区（`.img`文件，把刷机镜像分区映射到 loop 设备）
# dosfstools             操作 FAT32 分区（boot 分区常用 FAT）
# exfat-utils            exFAT 文件系统读写
# p7zip-full             7z 压缩解压，打包固件、源码包
# util-linux             一堆底层磁盘工具，losetup、mount、blkid 等，镜像制作必备
# bsdmainutils           包含`hexdump`，调试固件二进制
#
# 跨架构模拟（arm64 rootfs 构建）
# qemu-user / qemu-user-static  用户态模拟器。在 x86_64 容器里执行 arm64 二进制，debootstrap 构建 arm64 rootfs 必须
#
# 开发构建 & CMake 工程
# cmake                  跨平台构建系统，部分 BSP / 工具使用 cmake 编译
# dpkg-dev               构建 deb 软件包，如果你需要打包自制 deb 进 rootfs
# libssl-dev             OpenSSL 开发库，内核、很多工具编译需要 SSL 加密支持
# libxml2 / libxml2-dev  xml 解析库，部分固件、工具解析 xml 配置
#
# 版本控制 & 基础工具
# git                    拉取 BSP、内核、补丁源码，版本管理
# sudo                   容器内支持 sudo 提权
# uuid / uuid-dev        生成 UUID，部分镜像、文件系统制作会用到
#
# Python 开发
# python3-dev            pythonC 扩展开发头文件
# python3-pip            python 包管理器，BSP 里很多辅助 python 脚本依赖
#
# 调试工具
# gdb                    源码调试器，调试内核 / 应用程序
#
RUN apt-get update \
&& apt-get upgrade -y \
&& apt-get install -y --no-install-recommends \
wget curl rsync ca-certificates \
bc bison flex build-essential gcc g++ device-tree-compiler u-boot-tools kmod \
cpio debootstrap fakeroot kpartx dosfstools exfat-utils p7zip-full util-linux bsdmainutils \
qemu-user qemu-user-static \
cmake dpkg-dev libssl-dev libxml2 libxml2-dev \
git sudo uuid uuid-dev \
python3-dev python3-pip \
gdb \
&& rm -rf /var/lib/apt/lists/*

#
# 6. 设置工作目录
#
WORKDIR /workspace
