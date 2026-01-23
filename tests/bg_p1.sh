#!/bin/bash
set -e

# ----------------------------
# 配置区
# ----------------------------
NGINX_CONF="./nginx.conf.d/app.conf"   # nginx server 配置文件路径
UPSTREAM_BLUE="app_blue"               # 蓝色 upstream 名称
UPSTREAM_GREEN="app_green"             # 绿色 upstream 名称
PROXY_LINE_PATTERN="proxy_pass"        # 匹配 proxy_pass 行
HEALTHCHECK_URL_BLUE="http://127.0.0.1:8081/health"
HEALTHCHECK_URL_GREEN="http://127.0.0.1:8082/health"

echo "NGINX_CONF: $NGINX_CONF"
echo "UPSTREAM_BLUE: $UPSTREAM_BLUE"
echo "UPSTREAM_GREEN: $UPSTREAM_GREEN"
echo "=========================================="

# ----------------------------
# 跨平台 sed
# ----------------------------
sed_i() {
  if sed --version >/dev/null 2>&1; then
    sudo sed -i "$@"
  else
    sudo sed -i '' "$@"
  fi
}

# ----------------------------
# 获取当前 proxy_pass 指向 upstream
# ----------------------------
get_current_upstream() {
  grep -E "^[[:space:]]*$PROXY_LINE_PATTERN" "$NGINX_CONF" | awk '{print $2}' | sed 's/;//'
}

# ----------------------------
# 健康检查函数
# ----------------------------
check_health() {
  local url="$1"
  echo "检查健康状态: $url"
  if curl -sf --connect-timeout 2 --max-time 3 "$url"; then
    echo "健康检查通过"
    return 0
  else
    echo "健康检查失败"
    return 1
  fi
}

# ----------------------------
# 蓝绿切换函数
# ----------------------------
switch_proxy_pass() {
  local current next

  current=$(get_current_upstream)
  echo "[=== BEGIN ===] 当前 proxy_pass 指向: $current"

  if [[ "$current" == "$UPSTREAM_BLUE" ]]; then
    next="$UPSTREAM_GREEN"
  else
    next="$UPSTREAM_BLUE"
  fi

  echo "[=== BEGIN ===] 切换到: $next"

  # 替换 proxy_pass
  replace_proxy_pass "$next"

  echo "[=== END ===] proxy_pass 更新完成"
  echo "------------------------------------------"
  echo "更新后的 proxy_pass:"
  grep "$PROXY_LINE_PATTERN" "$NGINX_CONF"
  echo "------------------------------------------"
}


# ----------------------------
# 执行蓝绿切换
# ----------------------------
switch_proxy_pass
