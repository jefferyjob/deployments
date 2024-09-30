# deployments
该项目是一个简洁的自动化部署脚本项目，用于通过 SSH 连接远程服务器，进行 Docker 容器的备份、更新与回滚操作。 本项目旨在简化服务器上的应用部署流程，并确保在任何失败情况下自动回滚到上一个版本，保证服务的可用性。

## 特性
- **自动备份现有容器和镜像**：每次部署前，都会自动备份当前容器的状态，确保回滚时有保障。
- **自动拉取最新镜像并部署**：通过 Docker pull 命令自动更新镜像并启动容器。
- **容器回滚机制**：如果新镜像部署失败，脚本会自动回滚到上一个备份版本。
- **系统清理**：部署成功后，自动清理未使用的镜像和容器。

## 环境要求
- Linux 系统
- Docker 已安装
- SSH 访问权限

## 使用方法

### 环境变量配置

```bash
# Docker 账号
DOCKER_USERNAME: "example_docker_username"
DOCKER_PASSWORD: "example_docker_password"
DOCKER_REGISTRY_URL: ""
# Docker 服务
DOCKER_IMAGE: "example_namespace/image"
CONTAINER_NAME: "example_container"
# Docker 启动参数参数
DOCKER_APP_PARAMS: "-e KEY1=VAL1 -e KEY2=VAL2"
# 服务器
SERVER_IP: "example_host"
SERVER_USER: "example_server_user"
SSH_PRIVATE_KEY: "example_ssh_private_key"
```

### 脚本运行

```bash
curl -o deploy.sh https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh
```


## 注意事项
- 部署前请确保你的 Docker 镜像已经在远程仓库中准备好。
- 回滚功能依赖于上次成功的镜像备份，请确保部署前有备份。

## License
This library is licensed under the MIT. See the LICENSE file for details.
