#!/bin/bash
set -e

export NGINX_UPSTREAM_CONF="./nginx.conf.d/app_upstream.conf"
export BLUE_PORT=8081
export GREEN_PORT=8082
export HEALTHCHECK_URL="http://127.0.0.1:{PORT}/health"


######################################################################
# 蓝绿部署配置
######################################################################
# Nginx upstream 配置文件路径
# 例: /etc/nginx/conf.d/upstream.conf
# upstream app {
#     server 127.0.0.1:8081;
#     server 127.0.0.1:8082;
# }
#NGINX_UPSTREAM_CONF="${NGINX_UPSTREAM_CONF:-}"

# 蓝绿端口定义（必须提供）
#BLUE_PORT="${BLUE_PORT:-8081}"
#GREEN_PORT="${GREEN_PORT:-8082}"

# 健康检查 URL 自动切换端口
# 如果 HEALHCHECK_URL 包含 {PORT}，会被替换为实际端口
# 例如: http://127.0.0.1:{PORT}/health
######################################################################


echo "  NGINX_UPSTREAM_CONF: $NGINX_UPSTREAM_CONF"
echo "  BLUE_PORT: $BLUE_PORT"
echo "  GREEN_PORT: $GREEN_PORT"
echo "=========================================="

sed_i() {
  if sed --version >/dev/null 2>&1; then
    # GNU sed (Linux)
    sudo sed -i "$@"
  else
    # BSD sed (macOS)
    sudo sed -i '' "$@"
  fi
}


# 蓝绿端口选择
select_next_port() {
  # 检查当前 Nginx upstream 使用哪个端口
  if [[ -n "$NGINX_UPSTREAM_CONF" && -f "$NGINX_UPSTREAM_CONF" ]]; then
    if grep -q "$BLUE_PORT" "$NGINX_UPSTREAM_CONF"; then
      NEXT_PORT="$GREEN_PORT"
    else
      NEXT_PORT="$BLUE_PORT"
    fi
  else
    NEXT_PORT="$BLUE_PORT"
  fi
  echo "$NEXT_PORT"
}

function switch_test() {
  local port
  port=$(select_next_port)

  # 热切 Nginx upstream
  if [[ -n "$NGINX_UPSTREAM_CONF" && -f "$NGINX_UPSTREAM_CONF" ]]; then
    echo "[=== BEGIN ===] 更新 Nginx upstream..."
    sed_i "/$BLUE_PORT\|$GREEN_PORT/s/^/#/" "$NGINX_UPSTREAM_CONF"
    sed_i "/$port/s/^#//" "$NGINX_UPSTREAM_CONF"
    # sudo nginx -s reload
    echo "Nginx upstream 已切换到端口: $port"
  fi

  return 0
}

switch_test

# 启动新容器并指定蓝绿端口
deploy_run_container() {
  echo "[=== BEGIN ===] 启动新容器..."
  local port
  port=$(select_next_port)
  DOCKER_RUN_PARAMS="$DOCKER_RUN_PARAMS -p $port:80"
  if ! sudo docker run -d --name "$CONTAINER_NAME" $DOCKER_RUN_PARAMS "$DOCKER_IMAGE:$DOCKER_IMAGE_TAG"; then
    echo "[ERROR] 启动新容器失败, 错误日志: $(sudo docker logs "$CONTAINER_NAME" 2>&1)"
    return 1
  fi
  echo "镜像名称: $DOCKER_IMAGE:$DOCKER_IMAGE_TAG"
  echo "容器名称: $CONTAINER_NAME"
  echo "启动端口: $port"
  echo "启动参数: $DOCKER_RUN_PARAMS"

  # 热切 Nginx upstream
  if [[ -n "$NGINX_UPSTREAM_CONF" && -f "$NGINX_UPSTREAM_CONF" ]]; then
    echo "[=== BEGIN ===] 更新 Nginx upstream..."
    sudo sed -i "/$BLUE_PORT\|$GREEN_PORT/s/^/#/" "$NGINX_UPSTREAM_CONF"
    sudo sed -i "/$port/s/^#//" "$NGINX_UPSTREAM_CONF"
    sudo nginx -s reload
    echo "Nginx upstream 已切换到端口: $port"
  fi

  return 0
}

