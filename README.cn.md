# CD deployments

[English](README.md) | 简体中文

## 介绍
该项目是一个简洁的 CD（持续部署）自动化部署脚本，专为通过 SSH 连接远程服务器而设计。它能够高效地进行 Docker 容器的备份、更新、回滚和故障恢复等操作。项目旨在简化应用部署流程，确保在故障发生时自动回滚至上一个稳定版本，从而保障服务的稳定性和高可用性。通过使用此脚本，用户不仅可以提高工作效率，还能显著减少手动操作带来的出错风险。

## 环境要求
- Linux 操作系统
- 操作系统的 Docker 软件已安装, 并且配置了镜像加速
- SSH访问权限或账号密码访问权限, 且确保提供的账户具备Docker操作权限
- 流水线已配置环境变量

## 注意事项
- 部署前请确保你的 Docker 镜像已经 CI 阶段推送到远程镜像仓库中。

## 使用方法

### 环境变量配置
| 变量名                    | 是否必须 | 描述                                                                                |
|------------------------|-----|-----------------------------------------------------------------------------------|
| DOCKER_IMAGE           | 是   | Docker 镜像地址，包括镜像名称和标签（如：`example_namespace/myapp`），用于拉取并启动指定的应用容器。                |
| CONTAINER_NAME         | 是   | Docker 容器名称（如：`my_container`），在 Docker 中唯一标识该容器，确保不与其他容器冲突。                       |
| SERVER_HOST            | 是   | 远程服务器的主机名或 IP 地址（如：`192.168.1.100`），用于通过 SSH 连接到目标服务器。                            |
| SERVER_USER            | 是   | 服务器登录用户名（如：`root`），确保该用户具备操作 Docker 的权限。                                          |
| DOCKER_USERNAME        | 否   | Docker 仓库的登录账号（如：`mydockeruser`），用于从私有镜像仓库中拉取镜像。                                  |
| DOCKER_PASSWORD        | 否   | Docker 仓库的登录密码（如：`secret_password`），配合 `DOCKER_USERNAME` 使用，用于私有镜像的认证。            |
| DOCKER_REGISTRY_URL    | 否   | Docker 仓库的 URL 地址（如：`https://index.docker.io/v1`）， 若为空，则默认使用 Docker Hub。          |
| DOCKER_IMAGE_TAG       | 否   | 要部署的镜像版本标签（如：`latest`），默认为 `latest`，用于指定 Docker 镜像的版本。                            |
| DOCKER_RUN_PARAMS      | 否   | 启动容器时传递的额外运行参数（如：`-e ENV=prod`），可以包括环境变量、端口映射等。                                   |
| SERVER_PASSWORD        | 否   | 服务器登录密码（如：`mypassword`），仅在 `AUTH_METHOD` 为 `pwd` 时使用。                             |
| SERVER_SSH_PRIVATE_KEY | 否   | SSH 私钥内容（如：`-----BEGIN PRIVATE KEY-----`），用于密钥登录服务器，仅在 `AUTH_METHOD` 为 `key` 时使用。 |


### 脚本运行
**方法1: 不下载直接运行部署脚本**
```bash
curl -fsSL https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh | bash -s -- <AUTH_METHOD> <ACTION>
```
此方法适用于临时执行，不需要将脚本文件保留到本地，直接通过 curl 管道传递给 bash 执行。


**方法2:  下载后运行部署脚本（推荐）**
```bash
curl -o deploy.sh https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <AUTH_METHOD> <ACTION>
```
这种方式更为推荐，脚本文件被下载后可供查看或修改，并可以重复执行。


**Tips:** 
- 以上示例中使用 main 分支作为下载来源，实际使用中建议通过特定的版本 Tag 下载稳定版本的脚本，以确保兼容性和稳定性。
- 如果您在国内服务器运行，推荐使用国内镜像地址以提高下载速度。


**国内镜像地址示例**
```bash
curl -o deploy.sh https://gitee.com/jefferyjob/deployments/raw/main/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <AUTH_METHOD> <ACTION>
```

#### 参数
AUTH_METHOD
- pwd: 使用密码进行身份验证。
- key: 使用密钥进行身份验证。
- skip: 跳过服务器身份验证。

ACTION
- deploy: 部署 Docker 服务。
- remove: 移除 Docker 服务。

## 特性
- **自动备份现有容器和镜像**：每次部署前，都会自动备份当前容器的状态，确保回滚时有保障。
- **自动拉取最新镜像并部署**：通过 `Docker pull` 命令自动更新镜像并启动容器。
- **容器回滚机制**：如果新镜像部署失败，脚本会自动回滚到上一个备份版本。
- **系统清理**：部署成功后，自动清理未使用的镜像和容器。

## License
本库采用 MIT 进行授权。有关详细信息，请参阅 LICENSE 文件。
