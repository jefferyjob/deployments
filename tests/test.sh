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


# 计算“下一次部署端口”（蓝 ⇄ 绿）
detect_next_port() {
  if [[ "$ACTIVE_APP_PORT" == "$APP_PORT_A" ]]; then
    NEXT_APP_PORT="$APP_PORT_B"
  else
    NEXT_APP_PORT="$APP_PORT_A"
  fi

  echo "本次部署端口: $NEXT_APP_PORT"
}

# 启动新容器（绑定 NEXT 端口）
deploy_run_container() {
  detect_active_port
  detect_next_port

  NEW_CONTAINER_NAME="${CONTAINER_NAME_PREFIX}_${NEXT_APP_PORT}"

  echo "启动新容器: $NEW_CONTAINER_NAME"

  # 清理可能存在的旧 Green/Blue 容器
  sudo docker rm -f "$NEW_CONTAINER_NAME" >/dev/null 2>&1 || true

  if ! sudo docker run -d \
    --name "$NEW_CONTAINER_NAME" \
    -p "${NEXT_APP_PORT}:8080" \
    $DOCKER_RUN_PARAMS \
    "$DOCKER_IMAGE:$DOCKER_IMAGE_TAG"; then
    echo "新容器启动失败"
    return 1
  fi

  export NEW_CONTAINER_NAME
  export NEXT_APP_PORT
  return 0
}

# 切换 Nginx upstream（核心中的核心）
nginx_switch_upstream() {
  echo "切换 Nginx upstream → ${NEXT_APP_PORT}"

  cat <<EOF | sudo tee "$NGINX_UPSTREAM_CONF" >/dev/null
upstream ${NGINX_UPSTREAM_NAME} {
    server 127.0.0.1:${NEXT_APP_PORT};
    keepalive 64;
}
EOF

  if ! sudo nginx -t; then
    echo "Nginx 配置校验失败"
    return 1
  fi

  sudo nginx -s reload
  echo "Nginx upstream 切换完成"
}

# 安全下线旧容器（蓝/绿）
deploy_stop_old_container() {
  OLD_CONTAINER_NAME="${CONTAINER_NAME_PREFIX}_${ACTIVE_APP_PORT}"

  echo "准备下线旧容器: $OLD_CONTAINER_NAME"

  if sudo docker inspect "$OLD_CONTAINER_NAME" >/dev/null 2>&1; then
    sudo docker stop -t 40 "$OLD_CONTAINER_NAME"
    sudo docker rm "$OLD_CONTAINER_NAME"
  else
    echo "旧容器不存在，跳过"
  fi
}

#1. detect_active_port
#2. detect_next_port
#3. docker run 新容器（NEXT_PORT）
#4. HTTP health check
#5. nginx upstream 切到 NEXT_PORT
#6. sleep 2（连接自然迁移）
#7. docker stop -t 40 旧容器





# 核心回滚函数（统一入口）
deploy_rollback_blue_green() {
  echo "⚠️ 触发蓝绿发布回滚流程..."

  # 确保我们知道当前状态
  detect_active_port
  detect_next_port

  OLD_CONTAINER_NAME="${CONTAINER_NAME_PREFIX}_${ACTIVE_APP_PORT}"
  NEW_CONTAINER_NAME="${CONTAINER_NAME_PREFIX}_${NEXT_APP_PORT}"

  echo "回滚目标端口: $ACTIVE_APP_PORT"
  echo "新容器（待清理）: $NEW_CONTAINER_NAME"

  # -----------------------------
  # 1. 确保 upstream 指向旧端口
  # -----------------------------
  nginx_rollback_upstream

  # 给连接一点时间自然回流
  sleep 2

  # -----------------------------
  # 2. 停止并删除新容器
  # -----------------------------
  if sudo docker inspect "$NEW_CONTAINER_NAME" >/dev/null 2>&1; then
    echo "停止新容器..."
    sudo docker stop -t 10 "$NEW_CONTAINER_NAME"
    sudo docker rm "$NEW_CONTAINER_NAME"
  else
    echo "新容器不存在，跳过清理"
  fi

  echo "✅ 蓝绿回滚完成，流量已恢复至端口 ${ACTIVE_APP_PORT}"
}

# Nginx upstream 回滚函数（核心）
nginx_rollback_upstream() {
  echo "回滚 Nginx upstream → ${ACTIVE_APP_PORT}"

  cat <<EOF | sudo tee "$NGINX_UPSTREAM_CONF" >/dev/null
upstream ${NGINX_UPSTREAM_NAME} {
    server 127.0.0.1:${ACTIVE_APP_PORT};
    keepalive 64;
}
EOF

  if ! sudo nginx -t; then
    echo "❌ Nginx 配置校验失败（回滚失败）"
    exit 1
  fi

  sudo nginx -s reload
  echo "Nginx upstream 已回滚"
}
