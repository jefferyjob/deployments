# CD Deployments

English | [简体中文](README.cn.md)

## Introduction
This project is a simple CD (Continuous Deployment) automated deployment script project, used to connect to a remote server via SSH for Docker container backup, update, and rollback operations. The goal of this project is to simplify the application deployment process on the server and ensure automatic rollback to the previous version in case of any failure, guaranteeing service availability.

## Requirements
- Linux operating system
- The Docker software of the operating system has been installed, and image acceleration has been configured
- SSH access rights or account and password access rights, and ensure that the provided account has Docker operation permissions
- The pipeline has configured environment variables

## Notes
- Before deployment, ensure that your Docker image has already been pushed to the remote image repository during the CI phase.

## Usage

### Environment Variables Configuration
- **DOCKER_USERNAME**: [Optional] Docker account, used to pull private images
- **DOCKER_PASSWORD**: [Optional] Docker password, used with `DOCKER_USERNAME`
- **DOCKER_REGISTRY_URL**: [Optional] The URL of the Docker private image repository, example: `https://index.docker.io/v1`. If empty, Docker Hub is used by default
- **DOCKER_IMAGE**: [Required] The Docker image address to be deployed, including the image name and tag, example: `example_namespace/myapp`
- **DOCKER_IMAGE_TAG**: [Optional] The Docker image version tag to deploy, defaults to `latest`. Example values include: `latest`, `v1.0.0`
- **CONTAINER_NAME**: [Required] Docker container name to deploy, used to uniquely identify the container in Docker
- **DOCKER_RUN_PARAMS**: [Optional] Environment variables or other runtime parameters that need to be passed when starting the container
- **SERVER_HOST**: [Required] Remote server host name or IP address, used for server connection
- **SERVER_USER**: [Required] Server login username, make sure the user has Docker operation permissions
- **SERVER_PASSWORD**: [Optional] Server login password, only used when `AUTH_METHOD` is pwd
- **SERVER_SSH_PRIVATE_KEY**: [Optional] SSH private key, used to log in to the server without a password, only used when `AUTH_METHOD` is key

### Running the Script

Method 1: Run the deployment script directly without downloading
```bash
curl -s https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh | bash -s -- <AUTH_METHOD> <ACTION>
```

Method 2: Run the deployment script after downloading (recommended)
```bash
curl -o deploy.sh https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <AUTH_METHOD> <ACTION>
```

**Tips:** This demonstrates downloading through the main branch. In actual configuration, it is recommended to download through the version tag.

### Parameters
authMethod
- pwd: Use password-based authentication.
- key: Use key-based authentication.
- skip: Skip server authentication.

action
- deploy: Deploy the Docker service.
- remove: Remove the Docker service.

## Features
- **Automatic backup of existing containers and images**: Before each deployment, the current container state is automatically backed up to ensure rollback security.
- **Automatic image pulling and deployment**: Automatically updates images via the `Docker pull` command and starts the container.
- **Container rollback mechanism**: If the new image deployment fails, the script will automatically roll back to the previous backup version.
- **System cleanup**: After successful deployment, the script will automatically clean up unused images and containers.

## License
This library is licensed under the MIT. See the LICENSE file for details.

