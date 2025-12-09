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
| DOCKER_IMAGE | Yes | Docker image address used to pull and start the specified application container. (e.g., `example_ns/myapp`)
| CONTAINER_NAME | Yes | Docker container name, ensuring it doesn't conflict with other containers. (e.g., `my_container`)
| DOCKER_IMAGE_TAG | No | Version tag for image and container deployment, used to specify the version of the Docker image. (e.g., `latest`), defaults to `latest`.
| DOCKER_RUN_PARAMS | No | Additional runtime parameters passed when starting the container (e.g., `-e ENV=prod`), which can include environment variables, port mappings, folder mappings, etc.
| DOCKER_REGISTRY_URL | No | URL address of the Docker private repository. If empty, the official Docker Hub is used by default. (e.g., `https://index.docker.io/v1`) |
| DOCKER_USERNAME | No | Login account for the Docker private repository, used to pull images from the private image repository. |
| DOCKER_PASSWORD | No | Login password for the Docker private repository, used for authenticating private images. |
| BEFORE_FUNC | No | Pre-deployment hook function, used to execute certain shell commands before deployment. (e.g., create log directory, pause traffic, enter maintenance mode) |
| AFTER_FUNC | No | Post-deployment hook function, used to execute certain shell commands after deployment. (e.g., restore traffic, warm up cache, notify the team) |
| SERVER_HOST | No | Server hostname or IP address, used to connect to the target server via SSH. Required when `AUTH_METHOD` is `pwd` or `key`. (e.g., `192.168.1.100`) |
| SERVER_USER | No | Server login username. Ensure this user has permission to operate Docker. Required when `AUTH_METHOD` is `pwd` or `key`. (e.g., `root`) |
| SERVER_PASSWORD | No | Server login password. Required when `AUTH_METHOD` is `pwd`. (e.g., `mypassword`) |
| SERVER_SSH_PRIVATE_KEY | No | Server SSH private key content, used for key-based login to the server. Required when `AUTH_METHOD` is `key`. (e.g., `-----BEGIN PRIVATE KEY-----`) |

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

