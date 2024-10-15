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
|------------------------|-----|-----------------------------------------------------------------------------------|
| DOCKER_IMAGE | Yes | Docker image address, including image name and tag (e.g., `example_namespace/myapp`), used to pull and start the specified application container. |
| CONTAINER_NAME | Yes | Docker container name (e.g., `my_container`), uniquely identifies the container in Docker to ensure that it does not conflict with other containers. |
| SERVER_HOST | Yes | The host name or IP address of the remote server (e.g., `192.168.1.100`), used to connect to the target server via SSH. |
| SERVER_USER | Yes | Server login username (e.g., `root`), ensure that the user has the permission to operate Docker. |
| DOCKER_USERNAME | No | Docker repository login account (e.g. `mydockeruser`), used to pull images from private image repositories. |
| DOCKER_PASSWORD | No | Docker repository login password (e.g. `secret_password`), used with `DOCKER_USERNAME` for private image authentication. |
| DOCKER_REGISTRY_URL | No | Docker repository URL (e.g. `https://index.docker.io/v1`), if empty, Docker Hub is used by default. |
| DOCKER_IMAGE_TAG | No | Image version tag to deploy (e.g. `latest`), defaults to `latest`, used to specify the version of the Docker image. |
| DOCKER_RUN_PARAMS | No | Additional run parameters passed when starting the container (e.g. `-e ENV=prod`), which can include environment variables, port mappings, etc. |
| SERVER_PASSWORD | No | Server login password (e.g., `mypassword`), only used when `AUTH_METHOD` is `pwd`. |
| SERVER_SSH_PRIVATE_KEY | No | SSH private key content (e.g., `-----BEGIN PRIVATE KEY-----`), used for key login to the server, only used when `AUTH_METHOD` is `key`. |
| BEFORE_FUNC | No | Run script before deployment |
| AFTER_FUNC | No | Run script after deployment |

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

