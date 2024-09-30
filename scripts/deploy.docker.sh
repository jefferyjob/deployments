#!/bin/bash
set -e

######################################################################
# 输出部分环境变量信息
######################################################################
print_env() {
  echo "----------------------------------------------------------------------"
  echo "  SERVER_IP: $SERVER_IP"
  echo "  SERVER_USER: $SERVER_USER"
  echo "----------------------------------------------------------------------"
  echo "  DOCKER_REGISTRY_URL: $DOCKER_REGISTRY_URL"
  echo "  DOCKER_USERNAME: $DOCKER_USERNAME"
  echo "----------------------------------------------------------------------"
  echo "  DOCKER_IMAGE: $DOCKER_IMAGE"
  echo "  CONTAINER_NAME: $CONTAINER_NAME"
  echo "  DOCKER_APP_PARAMS: $DOCKER_APP_PARAMS"
  echo "----------------------------------------------------------------------"
}

print_env




######################################################################
# Shell 脚本运行参数验证
######################################################################
print_usage() {
  echo "Usage: $0 <authMethod> <action>"
  echo ""
  echo "Parameters:"
  echo "  <authMethod>    Authorization method to access the server."
  echo "  <action>        Action to perform on the Docker service."
  echo ""
  echo "Valid values for <authMethod> are:"
  echo "  pwd       Use password-based authentication."
  echo "  key       Use key-based authentication."
  echo "  skip      Skip server authentication."
  echo ""
  echo "Valid values for <action> are:"
  echo "  deploy    Deploy the Docker service."
  echo "  remove    Remove the Docker service."
  echo ""
  exit 1
}

# 检查是否提供了足够的参数
if [ "$#" -lt 2 ]; then
  print_usage
  exit 1
fi

# 服务器授权方式
AuthMethod="$1"
if [[ "$AuthMethod" != "pwd" && "$AuthMethod" != "key" && "$AuthMethod" != "skip" ]]; then
  echo "Error: AuthMethod parameter validation error."
  exit 1
fi

# 检查参数2
Action="$2"
if [[ "$Action" != "deploy" && "$Action" != "remove" ]]; then
  echo "Error: Action parameter validation error."
  exit 1
fi


echo "Server authorization method: $AuthMethod"
echo "Server deployment method: $Action"


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

if [[ "$AuthMethod" == "pwd" ]]; then
  check_param "SERVER_IP" "$SERVER_IP"
  check_param "SERVER_USER" "$SERVER_USER"
  check_param "SERVER_PWD" "$SERVER_PWD"
fi

if [[ "$AuthMethod" == "key" ]]; then
  check_param "SERVER_IP" "$SERVER_IP"
  check_param "SERVER_USER" "$SERVER_USER"
  check_param "SSH_PRIVATE_KEY" "$SSH_PRIVATE_KEY"
fi

echo "----------------------------------------------------------------------"
echo "所有参数均已验证完毕，准备继续执行..."
echo "----------------------------------------------------------------------"



######################################################################
# Docker 服务部署
deploy_key_server() {
  local action_func="$1"

  echo "启动SSH代理并添加私钥..."
  eval "$(ssh-agent -s)"
  echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  ssh-keyscan -H "$SERVER_IP" >> ~/.ssh/known_hosts

  echo "执行远程服务器部署流程..."

  ssh -o StrictHostKeyChecking=no "$SERVER_USER@$SERVER_IP" \
    "export DOCKER_USERNAME='$DOCKER_USERNAME'; \
    export DOCKER_PASSWORD='$DOCKER_PASSWORD'; \
    export DOCKER_REGISTRY_URL='$DOCKER_REGISTRY_URL'; \
    export DOCKER_IMAGE='$DOCKER_IMAGE'; \
    export CONTAINER_NAME='$CONTAINER_NAME'; \
    export DOCKER_APP_PARAMS='$DOCKER_APP_PARAMS'; \
    $(typeset -f); $action_func"
}

deploy_pwd_server() {
  local action_func="$1"

  echo "执行远程服务器部署流程..."

  sshpass -p "$SERVER_PWD" ssh -t -o StrictHostKeyChecking=no \
    "$SERVER_USER@$SERVER_IP" \
    "export DOCKER_USERNAME='$DOCKER_USERNAME'; \
    export DOCKER_PASSWORD='$DOCKER_PASSWORD'; \
    export DOCKER_REGISTRY_URL='$DOCKER_REGISTRY_URL'; \
    export DOCKER_IMAGE='$DOCKER_IMAGE'; \
    export CONTAINER_NAME='$CONTAINER_NAME'; \
    export DOCKER_APP_PARAMS='$DOCKER_APP_PARAMS'; \
    $(typeset -f); $action_func"
}


# 远程服务器上执行的部署逻辑
deploy_server() {
  # 确保脚本遇到错误时退出
  set -e

  # 切换到root用户
  sudo -i

  # 备份现有的容器和镜像
  deploy_backup_container

  # 如果存在则停止并删除现有容器
  deploy_stop_container

  # 拉取最新的 Docker 镜像并部署
  deploy_login_docker
  deploy_new_container
  deploy_logout_docker

  # 如果部署成功，删除备份镜像并清理系统
  deploy_cleanup
}

# 登陆Docker镜像仓库
deploy_login_docker() {
  if [[ -z "$DOCKER_REGISTRY_URL" ]]; then
    return
  fi

  echo "登陆Docker镜像仓库..."
  echo "$DOCKER_PASSWORD" | sudo docker login --username "$DOCKER_USERNAME" --password-stdin "$DOCKER_REGISTRY_URL"
}

# 退出登陆Docker镜像仓库
deploy_logout_docker() {
  if [[ -z "$DOCKER_REGISTRY_URL" ]]; then
    return
  fi

  echo "退出登陆Docker镜像仓库..."
  sudo docker logout "$DOCKER_REGISTRY_URL" || true
}

# 备份现有的容器
deploy_backup_container() {
  echo "备份现有容器..."
  HAS_BACKUP_IMAGE=false
  if sudo docker inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    sudo docker commit "$CONTAINER_NAME" "$DOCKER_IMAGE":backup
    HAS_BACKUP_IMAGE=true
    echo "备份现有的镜像: <$CONTAINER_NAME> ======> <$DOCKER_IMAGE:backup>"
  else
    echo "没有可备份的镜像, Not found docker container <$CONTAINER_NAME>"
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
  if ! sudo docker pull "$DOCKER_IMAGE":latest; then
    echo "拉取新镜像失败，回滚到上一个版本."
    deploy_rollback
  fi

  echo "Docker镜像拉取成功 "

  echo "启动新容器..."
  # shellcheck disable=SC2086
  if ! sudo docker run -d --name $CONTAINER_NAME $DOCKER_APP_PARAMS $DOCKER_IMAGE:latest; then
    echo "无法启动新容器，回滚到上一个版本."
    echo "错误日志: $(sudo docker logs "$CONTAINER_NAME" 2>&1)"
    deploy_rollback
  fi

  echo "Docker镜像部署成功"
}

# 镜像回滚方法
deploy_rollback() {
  echo "镜像回滚..."

  if [[ "$HAS_BACKUP_IMAGE" != true ]]; then
    echo "没有备份镜像，无法回滚"
    exit 1
  fi

  # shellcheck disable=SC2086
  if sudo docker run -d --name $CONTAINER_NAME $DOCKER_APP_PARAMS $DOCKER_IMAGE:backup; then
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
  sudo docker rmi "$DOCKER_IMAGE":backup || true
  sudo docker system prune -f || true
}


######################################################################
# Docker 服务部署
######################################################################
case $AuthMethod in
  key) # 密钥登陆服务器
    if [[ "$Action" == "deploy" ]]; then
      deploy_key_server deploy_server
    else
      deploy_key_server deploy_stop_container
    fi

    ;;
  pwd) # 账号密码登陆服务器
    if [[ "$Action" == "deploy" ]]; then
      deploy_pwd_server deploy_server
    else
      deploy_pwd_server deploy_stop_container
    fi
    ;;
  skip) # 跳过服务器认证，直接部署
    if [[ "$Action" == "deploy" ]]; then
      deploy_server
    else
      deploy_stop_container
    fi
    ;;
  *)
    echo "authMethod invalid failed"
    exit 1
    ;;
esac


######################################################################
# 成功
######################################################################
echo "🚀🚀🚀 CD Deploy 自动化脚本执行成功"

