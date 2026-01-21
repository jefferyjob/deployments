#!/bin/bash
set -e

# 蓝绿端口定义
APP_PORT_A=8080
APP_PORT_B=8081
# 当前活跃端口（由脚本自动判断/维护）
ACTIVE_APP_PORT=
# Nginx upstream
NGINX_UPSTREAM_NAME=app_backend
# upstream 配置文件路径
NGINX_UPSTREAM_CONF=./nginx.conf.d/upstream-app_backend.conf
# Docker 容器名前缀
CONTAINER_NAME_PREFIX=app



# 识别当前活跃端口（读 Nginx upstream）
detect_active_port() {
  if [[ ! -f "$NGINX_UPSTREAM_CONF" ]]; then
    echo "Error: Nginx upstream 配置不存在"
    exit 1
  fi

  ACTIVE_APP_PORT=$(grep -oE 'server\s+127\.0\.0\.1:[0-9]+' "$NGINX_UPSTREAM_CONF" | awk -F: '{print $2}')

  if [[ -z "$ACTIVE_APP_PORT" ]]; then
    echo "未检测到活跃端口，默认使用 APP_PORT_A"
    ACTIVE_APP_PORT="$APP_PORT_A"
  fi

  echo "当前活跃端口: $ACTIVE_APP_PORT"
}


detect_active_port