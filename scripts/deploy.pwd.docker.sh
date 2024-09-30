#!/bin/bash
# 确保脚本遇到错误时退出
set -e

print_env() {
  echo "----------------------------------------------------------------------"
  echo "  SERVER_IP: $SERVER_IP"
  echo "  SERVER_USER: $SERVER_USER"
  echo "----------------------------------------------------------------------"
  echo "  DOCKER_REGISTRY_URL: $DOCKER_REGISTRY_URL"
  echo "  DOCKER_IMAGE: $DOCKER_IMAGE"
  echo "  CONTAINER_NAME: $CONTAINER_NAME"
  echo "  DOCKER_APP_PARAMS: $DOCKER_APP_PARAMS"
  echo "----------------------------------------------------------------------"
}

print_env

# 部署Docker容器
# shellcheck disable=SC2087
sshpass -p "$SERVER_PWD" ssh -t -o StrictHostKeyChecking=no "$SERVER_USER"@"$SERVER_IP" <<EOF
  set -e

  # 备份现有的容器和镜像
  HAS_BACKUP_IMAGE=false
  if sudo docker inspect $CONTAINER_NAME > /dev/null 2>&1; then
    sudo docker commit $CONTAINER_NAME ${DOCKER_IMAGE}:backup
    HAS_BACKUP_IMAGE=true
    echo "备份现有的镜像: $CONTAINER_NAME => ${DOCKER_IMAGE}:backup"
  else
    echo "没有可备份的镜像"
  fi

  # 容器回滚方法
  CMD_ROLL_BACK() {
    if [ "$HAS_BACKUP_IMAGE" != true ]; then
      echo "没有备份镜像，无法回滚"
      exit 1
    fi

    if sudo docker run -d --name $CONTAINER_NAME $DOCKER_APP_PARAMS ${DOCKER_IMAGE}:backup; then
        echo "镜像回滚成功"
    else
        echo "镜像回滚失败"
    fi

     exit 1
  }

  # 如果存在则停止并删除现有容器
  sudo docker stop "$CONTAINER_NAME" || true
  sudo docker rm "$CONTAINER_NAME" || true

  # 拉取最新的 Docker 镜像
  if ! sudo docker pull "$DOCKER_IMAGE":latest; then
    echo "拉取新镜像失败，回滚到上一个版本."

    CMD_ROLL_BACK

  fi

  echo "🚀🚀🚀 Docker镜像拉取成功 "

  # 运行新版本的 Docker 容器
  if ! sudo docker run -d --name $CONTAINER_NAME $DOCKER_APP_PARAMS ${DOCKER_IMAGE}:latest; then
    echo "无法启动新容器，回滚到上一个版本."
    echo "错误日志: $(docker logs "$CONTAINER_NAME" 2>&1)"

    CMD_ROLL_BACK

  fi

  echo " 🎉🎉🎉 Docker镜像部署成功"

  # 如果新的部署成功，删除备份镜像
  sudo docker rmi ${DOCKER_IMAGE}:backup || true

  # 清理未使用的镜像和容器
  sudo docker system prune -f || true

EOF