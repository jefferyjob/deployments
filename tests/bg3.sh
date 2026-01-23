#!/bin/bash
set -e

# ----------------------------
# 配置区
# ----------------------------
NGINX_UPSTREAM_CONF="./nginx.conf.d/app_upstream.conf"  # upstream 配置文件路径
UPSTREAM_NAME="app_backend"                             # upstream 名称
BLUE_PORT=8081                                          # 蓝端口
GREEN_PORT=8082                                         # 绿端口

echo "NGINX_UPSTREAM_CONF: $NGINX_UPSTREAM_CONF"
echo "UPSTREAM_NAME: $UPSTREAM_NAME"
echo "BLUE_PORT: $BLUE_PORT"
echo "GREEN_PORT: $GREEN_PORT"
echo "=========================================="

# ----------------------------
# 跨平台 sed
# ----------------------------
sed_i() {
  if sed --version >/dev/null 2>&1; then
    # GNU sed (Linux)
    sudo sed -i "$@"
  else
    # BSD sed (macOS)
    sudo sed -i '' "$@"
  fi
}

# ----------------------------
# 获取当前活跃端口（未注释的端口行）
# ----------------------------
get_active_port() {
  grep -E '^[[:space:]]*server[[:space:]]+127\.0\.0\.1:[0-9]+;' "$NGINX_UPSTREAM_CONF" | \
    awk -F: '{gsub(/;/,"",$2); print $2}' | head -n1
}

# ----------------------------
# 选择下一个端口
# ----------------------------
select_next_port() {
  local current
  current=$(get_active_port)
  if [[ "$current" == "$BLUE_PORT" ]]; then
    echo "$GREEN_PORT"
  else
    echo "$BLUE_PORT"
  fi
}

# ----------------------------
# 蓝绿切换函数
# ----------------------------
switch_upstream() {
  local current next

  current=$(get_active_port)
  next=$(select_next_port)

  echo "[=== BEGIN ===] 当前活动端口: $current"
  echo "[=== BEGIN ===] 下一端口: $next"

  # 注释掉当前端口
  sed_i -E "s|^[[:space:]]*server[[:space:]]+127\.0\.0\.1:$current;|    # server 127.0.0.1:$current;|" "$NGINX_UPSTREAM_CONF"

  # 新端口是否已存在
  if grep -q "127.0.0.1:$next" "$NGINX_UPSTREAM_CONF"; then
    # 解注释
    sed_i -E "s|^[[:space:]]*# server[[:space:]]+127\.0\.0\.1:$next;|    server 127.0.0.1:$next;|" "$NGINX_UPSTREAM_CONF"
  else
    # 插入到 upstream 块内
    if sed --version >/dev/null 2>&1; then
      # Linux GNU sed
      sed_i -E "/upstream[[:space:]]+$UPSTREAM_NAME[[:space:]]*\{/a \    server 127.0.0.1:$next;" "$NGINX_UPSTREAM_CONF"
    else
      # macOS BSD sed, a 命令后必须换行
      sed_i "/upstream[[:space:]]+$UPSTREAM_NAME[[:space:]]*{/a\\
    server 127.0.0.1:$next;" "$NGINX_UPSTREAM_CONF"
    fi
  fi

  echo "[=== END ===] upstream 更新完成"
  echo "------------------------------------------"
  echo "更新后的 upstream 配置:"
  grep 'server 127.0.0.1' "$NGINX_UPSTREAM_CONF"
  echo "------------------------------------------"

  # Nginx 热切换（可开启）
  # sudo nginx -s reload
}

# ----------------------------
# 执行蓝绿切换
# ----------------------------
switch_upstream
