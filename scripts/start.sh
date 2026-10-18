#!/usr/bin/env bash

#
# 开启严格模式，出错直接退出
#
set -euo pipefail

#
# 设置启动参数
#
START_ARG="${1:-}"

#
# 进入项目目录
#
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

#
# 启动服务
#
COMPOSE=(docker compose -f compose.yaml)

if [[ "${START_ARG}" != "--no-build" ]]; then
  "${COMPOSE[@]}" build
fi

"${COMPOSE[@]}" up -d --no-build

#
# 输出日志
#
docker ps
