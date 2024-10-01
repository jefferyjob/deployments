# CD deployments

[English](README.md) | 简体中文

## 介绍
该项目是一个简洁的 CD（持续部署） 自动化部署脚本项目，用于通过 SSH 连接远程服务器，进行 Docker 容器的备份、更新与回滚操作。 本项目旨在简化服务器上的应用部署流程，并确保在任何失败情况下自动回滚到上一个版本，保证服务的可用性。

## 环境要求
- Linux 操作系统
- 操作系统的 Docker 软件已安装, 并且配置了镜像加速
- SSH访问权限或账号密码访问权限且确保提供的账户具备root操作权限
- 流水线已配置环境变量

## 注意事项
- 部署前请确保你的 Docker 镜像已经 CI 阶段推送到远程镜像仓库中。
- 如果要拉取私有镜像仓库必须配置 `DOCKER_REGISTRY_URL`、`DOCKER_USERNAME`、`DOCKER_PASSWORD`。

## 使用方法

### 环境变量配置

```bash
# Docker 账号
DOCKER_USERNAME: "example_docker_username"
DOCKER_PASSWORD: "example_docker_password"
DOCKER_REGISTRY_URL: "" # Demo: https://index.docker.io/v1
# Docker 镜像地址
DOCKER_IMAGE: "example_namespace/image"
# Docker 容器启动配置
CONTAINER_NAME: "example_container"
DOCKER_APP_PARAMS: "-e KEY1=VAL1 -e KEY2=VAL2"
# 服务器
SERVER_IP: "example_host"
SERVER_USER: "example_server_user"
SSH_PRIVATE_KEY: "example_ssh_private_key"
```

### 脚本运行

方法1: 不下载直接运行部署脚本
```bash
curl -s https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh | bash -s -- <authMethod> <action>
```

方法2:  下载后运行部署脚本（推荐）
```bash
curl -o deploy.sh https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <authMethod> <action>
```

**Tips:** 此处演示通过main分支下载，实际配置中建议通过版本Tag下载。

### 参数
authMethod
- pwd: 使用密码进行身份验证。
- key: 使用密钥进行身份验证。
- skip: 跳过服务器身份验证。

action
- deploy: 部署 Docker 服务。
- remove: 移除 Docker 服务。

## 特性
- **自动备份现有容器和镜像**：每次部署前，都会自动备份当前容器的状态，确保回滚时有保障。
- **自动拉取最新镜像并部署**：通过 `Docker pull` 命令自动更新镜像并启动容器。
- **容器回滚机制**：如果新镜像部署失败，脚本会自动回滚到上一个备份版本。
- **系统清理**：部署成功后，自动清理未使用的镜像和容器。

## License
本库采用 MIT 进行授权。有关详细信息，请参阅 LICENSE 文件。
