#!/bin/bash
set -e

# --------------------------
# 蓝绿部署参数
BLUE_PORT="${BLUE_PORT:-8080}"
GREEN_PORT="${GREEN_PORT:-8081}"
NGINX_UPSTREAM_CONF="${NGINX_UPSTREAM_CONF:-/etc/nginx/conf.d/upstream.conf}"
UPSTREAM_NAME="${UPSTREAM_NAME:-backend_app}"
HEALTHCHECK_RETRIES="${HEALTHCHECK_RETRIES:-3}"
HEALTHCHECK_INTERVAL="${HEALTHCHECK_INTERVAL:-1}"
# --------------------------

deploy_run_container() {
  echo "启动新容器 $CONTAINER_NAME on port $1"
  if ! sudo docker run -d --name "$CONTAINER_NAME" -p "$1":80 $DOCKER_RUN_PARAMS "$DOCKER_IMAGE:$DOCKER_IMAGE_TAG"; then
    log_error "容器启动失败"
    return 1
  fi
}

# --------------------------
# 蓝绿端口切换 + Nginx upstream 热切
switch_blue_green() {
  local active_port passive_port
  # 检查哪个端口在用
  if curl -sf --connect-timeout 1 "http://127.0.0.1:$BLUE_PORT" >/dev/null 2>&1; then
    active_port="$BLUE_PORT"
    passive_port="$GREEN_PORT"
  else
    active_port="$GREEN_PORT"
    passive_port="$BLUE_PORT"
  fi
  log_info "当前活跃端口: $active_port, 即将部署端口: $passive_port"

  # 启动新容器
  deploy_run_container "$passive_port" || { log_error "启动失败, 回滚"; deploy_rollback; exit 1; }

  # 健康检查
  HEALTHCHECK_URL="http://127.0.0.1:$passive_port/health"
  deploy_healthcheck || { log_error "健康检查失败, 回滚"; deploy_rollback; exit 1; }

  # 更新 Nginx upstream 热切
  if [[ -f "$NGINX_UPSTREAM_CONF" ]]; then
    sudo sed -i "/$CONTAINER_NAME/d" "$NGINX_UPSTREAM_CONF"
    echo "server 127.0.0.1:$passive_port max_fails=3 fail_timeout=10s;" | sudo tee -a "$NGINX_UPSTREAM_CONF"
    sudo nginx -s reload
    log_info "Nginx upstream 热切完成，切换到端口 $passive_port"
  fi

  # 停止旧容器
  if sudo docker ps -q --filter "publish=$active_port" >/dev/null 2>&1; then
    sudo docker stop $(sudo docker ps -q --filter "publish=$active_port") || true
  fi
}