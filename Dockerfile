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
# 5. 更新软件包
#
RUN apt-get update \
&& apt-get upgrade -y \
&& rm -rf /var/lib/apt/lists/*

#
# 6. 设置工作区
#
WORKDIR /workspace
