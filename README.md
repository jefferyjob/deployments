# CD Deployments

English | [简体中文](README.cn.md)

## Introduction
This project is a neat CD (Continuous Deployment) automated deployment script designed for connecting to remote servers via SSH. It can efficiently perform operations such as backup, update, rollback and failure recovery of Docker containers. The project aims to simplify the application deployment process and ensure automatic rollback to the previous stable version when a failure occurs, thereby ensuring the stability and high availability of services. By using this script, users can not only improve their work efficiency, but also significantly reduce the risk of errors caused by manual operations.

## Requirements
- Linux operating system
- The Docker software of the operating system has been installed, and image acceleration has been configured
- SSH access rights or account and password access rights, and ensure that the provided account has Docker operation permissions
- The pipeline has configured environment variables

## Notes
- Before deployment, ensure that your Docker image has already been pushed to the remote image repository during the CI phase.

## Usage

### Environment Variables Configuration
| Variable Name | Required | Description |
|-----------------------|-----|-----------------------------------------------------------------------------------|
| DOCKER_IMAGE | Yes | Docker image address used to pull and start the specified application container. (Example: `example_ns/myapp` or private configuration `registry.cn-hangzhou.aliyuncs.com/example_ns/myapp`)
| CONTAINER_NAME | Yes | Docker container name, ensuring it doesn't conflict with other containers. (Example: `my_container`)
| DOCKER_IMAGE_TAG | No | Version tag for image and container deployment, used to specify the Docker image version, defaults to `latest`.
| DOCKER_RUN_PARAMS | No | Additional runtime parameters passed when starting the container, which may include environment variables, port mappings, folder mappings, etc. (Example: `-e ENV=prod -e TZ=Asia/Shanghai`) |
| DOCKER_REGISTRY_URL | No | The URL of the Docker private repository. If empty, the official DockerHub is used by default. (Example: `registry.cn-hangzhou.aliyuncs.com`) |
| DOCKER_USERNAME | No | The login account for the Docker private repository, used to pull images from the private image repository. |
| DOCKER_PASSWORD | No | The login password for the Docker private repository, used for authenticating private images. |
| BEFORE_FUNC | No | A pre-deployment hook function used to execute certain shell commands before deployment. (e.g., creating a log directory, pausing traffic, entering maintenance mode) |
| AFTER_FUNC | No | A post-deployment hook function used to execute certain shell commands after deployment. (e.g., restoring traffic, preheating cache, notifying the team) |
| SERVER_HOST | No | The server's hostname or IP address, used to connect to the target server via SSH. Required when `AUTH_METHOD` is `pwd` or `key`. (Example: `192.168.1.100`) |
| SERVER_USER | No | The server login username. Ensure this user has permission to operate Docker. Required when `AUTH_METHOD` is `pwd` or `key`. (Example: `root`) |
| SERVER_PASSWORD | No | The server login password. Required when `AUTH_METHOD` is `pwd`. (Example: `mypassword`) |
| SERVER_SSH_PRIVATE_KEY | No | The server's SSH private key, used for key-based login to the server. Required when `AUTH_METHOD` is a `key`. (Example: `-----BEGIN PRIVATE KEY----- xxx`)

`BEFORE_FUNC` and `AFTER_FUNC` example code

```bash
BEFORE_FUNC=$(cat <<'EOF'
  echo "I am before function"
EOF
)
```


### Running the Script
**Method 1: Run the deployment script directly without downloading**
```bash
curl -fsSL https://raw.githubusercontent.com/jefferyjob/deployments/refs/tags/v1.1.0/scripts/deploy.docker.sh | bash -s -- <AUTH_METHOD> <ACTION>
```
This method is suitable for temporary execution. It does not need to save the script file locally and directly passes it to bash for execution through the curl pipeline.


**Method 2: Run the deployment script after downloading (recommended)**
```bash
curl -o deploy.sh https://raw.githubusercontent.com/jefferyjob/deployments/refs/tags/v1.1.0/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <AUTH_METHOD> <ACTION>
```
This method is more recommended. After the script file is downloaded, it can be viewed or modified and can be executed repeatedly.


**Tips:**
- It is recommended to download the stable version of the script through a specific version tag to ensure compatibility and stability.
- If you are running on a domestic server, it is recommended to use a [domestic mirror](https://gitee.com/jefferyjob/deployments) to increase download speed.


#### Parameters
AUTH_METHOD
- pwd: Use password-based authentication.
- key: Use key-based authentication.
- skip: Skip server authentication.

ACTION
- deploy: Deploy the Docker service.
- remove: Remove the Docker service.

## Features
- **Automatic backup of existing containers and images**: Before each deployment, the current container state is automatically backed up to ensure rollback security.
- **Automatic image pulling and deployment**: Automatically updates images via the `Docker pull` command and starts the container.
- **Container rollback mechanism**: If the new image deployment fails, the script will automatically roll back to the previous backup version.
- **System cleanup**: After successful deployment, the script will automatically clean up unused images and containers.

## License
This library is licensed under the MIT. See the LICENSE file for details.

