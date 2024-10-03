# CD deployments

[English](README.md) | 简体中文

## 介绍
该项目是一个简洁的 CD（持续部署） 自动化部署脚本项目，用于通过 SSH 连接远程服务器，进行 Docker 容器的备份、更新与回滚操作。 本项目旨在简化服务器上的应用部署流程，并确保在任何失败情况下自动回滚到上一个版本，保证服务的可用性。

## 环境要求
- Linux 操作系统
- 操作系统的 Docker 软件已安装, 并且配置了镜像加速
- SSH访问权限或账号密码访问权限, 且确保提供的账户具备Docker操作权限
- 流水线已配置环境变量

## 注意事项
- 部署前请确保你的 Docker 镜像已经 CI 阶段推送到远程镜像仓库中。

## 使用方法

### 环境变量配置

| 变量名                    | 是否必须 | 描述                                                         |
|------------------------|-----|------------------------------------------------------------|
| DOCKER_IMAGE           | 是   | 要部署的 Docker 镜像地址，包括镜像名称和标签，示例：`example_namespace/myapp` |
| CONTAINER_NAME         | 是   | 要部署的 Docker 容器名称，用于在 Docker 中唯一标识该容器               |
| SERVER_HOST            | 是   | 远程服务器主机名或 IP 地址，用于服务器连接                          |
| SERVER_USER            | 是   | 服务器登录用户名，确保该用户有 Docker 操作权限                      |
| DOCKER_USERNAME        | 否   | Docker 账号，用于拉取私有镜像                                     |
| DOCKER_PASSWORD        | 否   | Docker 密码，配合 `DOCKER_USERNAME` 使用                       |
| DOCKER_REGISTRY_URL    | 否   | Docker 私有镜像仓库的 URL，示例：`https://index.docker.io/v1` 。如果为空，则默认使用 Docker Hub |
| DOCKER_IMAGE_TAG       | 否   | 要部署的 Docker 镜像版本标签，默认为 `latest`。示例值包括：`latest`、`v1.0.0` |
| DOCKER_RUN_PARAMS      | 否   | 启动容器时需要传递的环境变量或其他运行参数                           |
| SERVER_PASSWORD        | 否   | 服务器登录密码，仅在 `AUTH_METHOD` 为 pwd 时使用                    |
| SERVER_SSH_PRIVATE_KEY | 否   | SSH 私钥，用于无密码登录服务器，仅在 `AUTH_METHOD` 为 key 时使用      |


### 脚本运行

方法1: 不下载直接运行部署脚本
```bash
curl -s https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh | bash -s -- <AUTH_METHOD> <ACTION>
```

方法2:  下载后运行部署脚本（推荐）
```bash
curl -o deploy.sh https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <AUTH_METHOD> <ACTION>
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
