#!/usr/bin/env bash

#
# 开启严格模式，出错直接退出
#
set -euo pipefail

#
# 设置关闭参数
#
CLOSE_ARG="${1:-}"

#
# 进入项目目录
#
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

#
# 关闭服务
#
COMPOSE=(docker compose -f compose.yaml)

if [[ "${CLOSE_ARG}" == "--no-clean" ]]; then
  "${COMPOSE[@]}" down
else
  "${COMPOSE[@]}" down --rmi all
fi

#
# 输出日志
#
docker ps
