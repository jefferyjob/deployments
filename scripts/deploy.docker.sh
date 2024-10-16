#!/bin/bash
set -e

AUTH_METHOD="$1"
ACTION="$2"

print_usage() {
  echo "Usage: $0 <AUTH_METHOD> <ACTION>"
  echo ""
  echo "Parameters:"
  echo "  <AUTH_METHOD>   Authorization method to access the server."
  echo "  <ACTION>        ACTION to perform on the Docker service."
  echo ""
  echo "Valid values for <AUTH_METHOD> are:"
  echo "  pwd       Use password-based authentication."
  echo "  key       Use key-based authentication."
  echo "  skip      Skip server authentication."
  echo ""
  echo "Valid values for <ACTION> are:"
  echo "  deploy    Deploy the Docker service."
  echo "  remove    Remove the Docker service."
  echo ""
  exit 1
}

if [[ "$ACTION" == "--help" ]]; then
  print_usage
  exit 0
fi

if [[ "$ACTION" == "--dry-run" ]]; then
  echo "Dry run: No actions will be performed."
  exit 0
fi

print_env() {
  echo "--------------------------------------------------------------------------"
  echo "  CD Deployment < Initialization Parameters >"
  echo "--------------------------------------------------------------------------"
  echo "  SERVER_HOST: $SERVER_HOST"
  echo "  SERVER_USER: $SERVER_USER"
  [[ -n "$SERVER_PASSWORD" ]] && echo "  SERVER_PASSWORD: ******"
  [[ -n "$SERVER_SSH_PRIVATE_KEY" ]] && echo "  SERVER_SSH_PRIVATE_KEY: ******"
  echo "--------------------------------------------------------------------------"
  echo "  DOCKER_REGISTRY_URL: $DOCKER_REGISTRY_URL"
  echo "  DOCKER_USERNAME: $DOCKER_USERNAME"
  [[ -n "$DOCKER_PASSWORD" ]] && echo "  DOCKER_PASSWORD: ******"
  echo "--------------------------------------------------------------------------"
  echo "  DOCKER_IMAGE: $DOCKER_IMAGE"
  echo "  DOCKER_IMAGE_TAG: $DOCKER_IMAGE_TAG"
  echo "  CONTAINER_NAME: $CONTAINER_NAME"
  echo "  DOCKER_RUN_PARAMS: $DOCKER_RUN_PARAMS"
  echo "--------------------------------------------------------------------------"
  [[ -n "$BEFORE_FUNC" ]] && echo "  BEFORE_FUNC: $BEFORE_FUNC"
  [[ -n "$AFTER_FUNC" ]] && echo "  AFTER_FUNC: $AFTER_FUNC"
  echo "--------------------------------------------------------------------------"
  echo "  AUTH_METHOD: $AUTH_METHOD"
  echo "  ACTION: $ACTION"
  echo "--------------------------------------------------------------------------"
}

print_env


######################################################################
# Shell 脚本运行参数验证
######################################################################
# 检查是否提供了足够的参数
if [ "$#" -lt 2 ]; then
  print_usage
  exit 1
fi

# 检查服务器授权方式
if [[ "$AUTH_METHOD" != "pwd" && "$AUTH_METHOD" != "key" && "$AUTH_METHOD" != "skip" ]]; then
  echo "Error: AUTH_METHOD parameter validation error."
  exit 1
fi

# 检查执行动作
if [[ "$ACTION" != "deploy" && "$ACTION" != "remove" ]]; then
  echo "Error: ACTION parameter validation error."
  exit 1
fi

check_param() {
  local param_name="$1"
  local param_value="$2"
  if [[ -z "$param_value" ]]; then
    echo "Error: $param_name The environment variable parameter cannot be empty"
    exit 1
  fi
}

# 环境变量参数验证
check_param "DOCKER_USERNAME" "$DOCKER_USERNAME"
check_param "DOCKER_PASSWORD" "$DOCKER_PASSWORD"
check_param "DOCKER_IMAGE" "$DOCKER_IMAGE"
check_param "CONTAINER_NAME" "$CONTAINER_NAME"

if [[ "$AUTH_METHOD" == "pwd" ]]; then
  check_param "SERVER_HOST" "$SERVER_HOST"
  check_param "SERVER_USER" "$SERVER_USER"
  check_param "SERVER_PASSWORD" "$SERVER_PASSWORD"
fi

if [[ "$AUTH_METHOD" == "key" ]]; then
  check_param "SERVER_HOST" "$SERVER_HOST"
  check_param "SERVER_USER" "$SERVER_USER"
  check_param "SERVER_SSH_PRIVATE_KEY" "$SERVER_SSH_PRIVATE_KEY"
fi

# DOCKER_REGISTRY_URL 被配置了则 DOCKER_USERNAME 和 DOCKER_PASSWORD 必须被配置
if [[ -n "$DOCKER_REGISTRY_URL" && (-z "$DOCKER_USERNAME" || -z "$DOCKER_PASSWORD") ]]; then
    echo "Error: 环境变量中，设置 DOCKER_REGISTRY_URL 时 DOCKER_USERNAME 和 DOCKER_PASSWORD 不能为空"
    exit 1
fi

# 判断 DOCKER_IMAGE_TAG 是否为空，如果为空则赋值为 "latest"
: "${DOCKER_IMAGE_TAG:="latest"}"


echo "--------------------------------------------------------------------------"
echo "All parameters have been validated and are ready to continue execution... "
echo "--------------------------------------------------------------------------"

######################################################################
# Docker 服务部署
######################################################################
deploy_key_server() {
  local action_func="$1"

  echo "启动SSH代理并添加私钥..."
  eval "$(ssh-agent -s)"
  echo "$SERVER_SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  ssh-keyscan -H "$SERVER_HOST" >> ~/.ssh/known_hosts

  echo "执行远程服务器部署流程..."

  # 读取本机环境变量
  EXPORTED_ENV_VARS=$(export_env_vars)

  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$SERVER_USER@$SERVER_HOST" \
    "$EXPORTED_ENV_VARS
    $(typeset -f); $action_func"
}

deploy_pwd_server() {
  local action_func="$1"

  echo "执行远程服务器部署流程..."

  # 读取本机环境变量
  EXPORTED_ENV_VARS=$(export_env_vars)

  sshpass -p "$SERVER_PASSWORD" ssh -t -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
    "$SERVER_USER@$SERVER_HOST" \
    "$EXPORTED_ENV_VARS
    $(typeset -f); $action_func"
}


# 远程服务器上执行的部署逻辑
deploy_server() {
  set -e # 确保脚本遇到错误时退出
  sudo -i # 切换到root用户

  # 部署前运行脚本
  deploy_before_func

  # 备份现有的容器和镜像
  deploy_backup_container

  # 如果存在则停止并删除现有容器
  deploy_stop_container

  # 拉取最新的 Docker 镜像并部署
  deploy_login_docker
  deploy_new_container
  deploy_logout_docker

  # 如果部署成功，删除备份镜像并清理系统
  # deploy_cleanup

  # 部署后运行脚本
  deploy_after_func
}

# 读取并导出所需的环境变量
export_env_vars() {
  echo "
  export DOCKER_USERNAME='$DOCKER_USERNAME'; \
  export DOCKER_PASSWORD='$DOCKER_PASSWORD'; \
  export DOCKER_REGISTRY_URL='$DOCKER_REGISTRY_URL'; \
  export DOCKER_IMAGE='$DOCKER_IMAGE'; \
  export DOCKER_IMAGE_TAG='$DOCKER_IMAGE_TAG'; \
  export CONTAINER_NAME='$CONTAINER_NAME'; \
  export DOCKER_RUN_PARAMS='$DOCKER_RUN_PARAMS'; \
  export BEFORE_FUNC='$BEFORE_FUNC'; \
  export AFTER_FUNC='$AFTER_FUNC'; \
  "
}

# 登陆Docker镜像仓库
deploy_login_docker() {
  if [[ -z "$DOCKER_REGISTRY_URL" ]]; then
    echo "未配置 DOCKER_REGISTRY_URL 跳过登陆Docker镜像仓库"
    return
  fi

  echo "登陆Docker镜像仓库..."
  if ! echo "$DOCKER_PASSWORD" | sudo docker login --username "$DOCKER_USERNAME" --password-stdin "$DOCKER_REGISTRY_URL"; then
    echo "Error: Docker登陆镜像仓库失败"
    exit 1
  fi
}

# 退出登陆Docker镜像仓库
deploy_logout_docker() {
  if [[ -z "$DOCKER_REGISTRY_URL" ]]; then
    echo "未配置 DOCKER_REGISTRY_URL 跳过退出登陆Docker镜像仓库"
    return
  fi

  echo "退出登陆Docker镜像仓库..."
  sudo docker logout "$DOCKER_REGISTRY_URL" || true
}

# 备份现有的容器
deploy_backup_container() {
  echo "备份现有容器..."
  BACKUP_IMAGE_EXISTS=0
  if sudo docker inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    sudo docker commit "$CONTAINER_NAME" "$DOCKER_IMAGE":backup
    BACKUP_IMAGE_EXISTS=1
    echo "备份现有的镜像, 容器名称: $CONTAINER_NAME  -->  备份镜像名称: $DOCKER_IMAGE:backup"
  else
    echo "没有可备份的镜像, Not found docker container name: $CONTAINER_NAME"
  fi
}

# 停止并删除现有容器
deploy_stop_container() {
  echo "停止并删除现有容器..."
  sudo docker stop "$CONTAINER_NAME" || true
  sudo docker rm "$CONTAINER_NAME" || true
}

# 拉取最新镜像并部署新容器
deploy_new_container() {
  echo "拉取最新镜像..."
  if ! sudo docker pull "$DOCKER_IMAGE":"$DOCKER_IMAGE_TAG"; then
    echo "拉取新镜像失败，回滚到上一个版本."
    deploy_rollback
  fi

  echo "启动新容器..."

  # shellcheck disable=SC2086
  if ! sudo docker run -d --name $CONTAINER_NAME $DOCKER_RUN_PARAMS $DOCKER_IMAGE:$DOCKER_IMAGE_TAG; then
    echo "无法启动新容器，回滚到上一个版本."
    echo "错误日志: $(sudo docker logs "$CONTAINER_NAME" 2>&1)"
    deploy_rollback
  fi

  echo "容器健康状态检查..."

  # 检查容器健康状态
  HEALTH_STATUS=$(sudo docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME")
  echo "容器状态: $HEALTH_STATUS"
  if [ "$HEALTH_STATUS" != "running" ]; then
      echo "容器未启动成功. Status: $HEALTH_STATUS"
      deploy_rollback
  fi

  echo "Docker镜像部署成功"
}

# 镜像回滚方法
deploy_rollback() {
  echo "镜像回滚..."

  if [[ "$BACKUP_IMAGE_EXISTS" == 0 ]]; then
    echo "没有备份镜像，无法回滚"
    exit 1
  fi

  # shellcheck disable=SC2086
  if sudo docker run -d --name $CONTAINER_NAME $DOCKER_RUN_PARAMS $DOCKER_IMAGE:backup; then
    echo "镜像回滚成功"
    exit 1
  else
    echo "镜像回滚失败"
    exit 1
  fi
}

# 清理未使用的镜像和容器
deploy_cleanup() {
  echo "清理备份镜像和未使用的资源..."
  # 清理备份的容器
  sudo docker rmi "$DOCKER_IMAGE":backup || true
  # 删除所有未使用的容器、网络、镜像（未被容器引用）和构建缓存
  sudo docker system prune -a -f || true
}

deploy_before_func() {
  if [[ -z "$BEFORE_FUNC" ]]; then
    echo "未配置 BEFORE_FUNC 方法，跳过执行"
    return
  fi

  echo "准备运行 BEFORE_FUN 方法..."
  eval "$BEFORE_FUNC"
}

deploy_after_func() {
  if [[ -z "$AFTER_FUNC" ]]; then
    echo "未配置 AFTER_FUNC 方法，跳过执行"
    return
  fi

  echo "准备运行 AFTER_FUNC 方法..."
  eval "$AFTER_FUNC"
}

######################################################################
# Docker 服务部署
######################################################################
case $AUTH_METHOD in
  key) # 密钥登陆服务器
    if [[ "$ACTION" == "deploy" ]]; then
      deploy_key_server deploy_server
    else
      deploy_key_server deploy_stop_container
    fi

    ;;
  pwd) # 账号密码登陆服务器
    if [[ "$ACTION" == "deploy" ]]; then
      deploy_pwd_server deploy_server
    else
      deploy_pwd_server deploy_stop_container
    fi
    ;;
  skip) # 跳过服务器认证，直接部署
    if [[ "$ACTION" == "deploy" ]]; then
      deploy_server
    else
      deploy_stop_container
    fi
    ;;
  *)
    echo "Error: Invalid AUTH_METHOD provided."
    exit 1
    ;;
esac




######################################################################
# CD Deployments 执行完毕
######################################################################
log_info() {
  echo -e "\033[0;32m\033[1m $1 \033[0m"
}
log_warn() {
  echo -e "\033[1;33m $1 \033[0m"
}
log_error() {
  echo -e "\033[0;31m $1 \033[0m"
}
log_notice() {
  echo -e "\033[0;36m $1 \033[0m"
}
log_info "🚀🚀🚀 CD Deployment 执行完毕"

