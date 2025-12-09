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
#### Docker 部署所需环境变量
| 变量名                    | 必须 | 描述                                                                                                            |
|------------------------|----|---------------------------------------------------------------------------------------------------------------|
| DOCKER_IMAGE           | 是  | Docker 镜像地址，用于拉取并启动指定的应用容器。（示例：`example_ns/myapp` 或私有配置 `registry.cn-hangzhou.aliyuncs.com/example_ns/myapp`） |
| CONTAINER_NAME         | 是  | Docker 容器名称，确保不与其他容器冲突。（示例：`my_container`）                                                                    |
| DOCKER_IMAGE_TAG       | 否  | 镜像和容器部署的版本标签，用于指定 Docker 镜像的版本，默认为 `latest`。                                                                  |
| DOCKER_RUN_PARAMS      | 否  | 启动容器时传递的额外运行参数，可以包括环境变量、端口映射、文件夹映射等。（示例：`-e ENV=prod -e TZ=Asia/Shanghai`）                                    |
| DOCKER_REGISTRY_URL    | 否  | Docker 私有仓库的 URL 地址，若为空，则默认使用官方的 DockerHub。（示例：`registry.cn-hangzhou.aliyuncs.com`）                           |
| DOCKER_USERNAME        | 否  | Docker 私有仓库的登录账号，用于从私有镜像仓库中拉取镜像。                                                                              |
| DOCKER_PASSWORD        | 否  | Docker 私有仓库的登录密码，用于私有镜像的认证。                                                                                   |
| BEFORE_FUNC | 否  | 部署前钩子函数，用于部署前执行某些shell命令。（如：创建日志目录、暂停流量、进入维护模式）                                                               |
| AFTER_FUNC | 否  | 部署后钩子函数，用于部署后执行某些shell命令。（如：恢复流量、预热缓存、通知团队）                                                                   |
| SERVER_HOST            | 否  | 服务器的主机名或 IP 地址，用于通过 SSH 连接到目标服务器。在 `AUTH_METHOD` 为 `pwd` 或 `key` 时必填。（示例：`192.168.1.100`）                     |
| SERVER_USER            | 否  | 服务器登录用户名，清确保该用户具备操作 Docker 的权限。在 `AUTH_METHOD` 为 `pwd` 或 `key` 时必填。（示例：`root`）                                |
| SERVER_PASSWORD        | 否  | 服务器登录密码，在 `AUTH_METHOD` 为 `pwd` 时必填。 （示例：`mypassword`）                                                        |
| SERVER_SSH_PRIVATE_KEY | 否  | 服务器SSH 私钥内容，用于密钥登录服务器。在 `AUTH_METHOD` 为 `key` 时必填。（示例：`-----BEGIN PRIVATE KEY----- xxx`）                      |

`BEFORE_FUNC` 和 `AFTER_FUNC` 示例代码

```bash
BEFORE_FUNC=$(cat <<'EOF'
  echo "I am before function"
EOF
)
```

### 脚本运行
**方法1: 不下载直接运行部署脚本**
```bash
curl -fsSL https://gitee.com/jefferyjob/deployments/raw/v1.1.0/scripts/deploy.docker.sh | bash -s -- <AUTH_METHOD> <ACTION>
```
此方法适用于临时执行，不需要将脚本文件保留到本地，直接通过 curl 管道传递给 bash 执行。


**方法2:  下载后运行部署脚本（推荐）**
```bash
curl -o deploy.sh https://gitee.com/jefferyjob/deployments/raw/v1.1.0/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <AUTH_METHOD> <ACTION>
```
这种方式更为推荐，脚本文件被下载后可供查看或修改，并可以重复执行。


**Tips:** 
- 建议通过特定的版本 Tag 下载稳定版本的脚本，以确保兼容性和稳定性。
- 如果您在中国境内服务器运行，推荐使用 [镜像加速](https://gitee.com/jefferyjob/deployments) 以提高下载速度。


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
