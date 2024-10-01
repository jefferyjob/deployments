# CD Deployments

English | [简体中文](README.cn.md)

## Introduction
This project is a simple CD (Continuous Deployment) automated deployment script project, used to connect to a remote server via SSH for Docker container backup, update, and rollback operations. The goal of this project is to simplify the application deployment process on the server and ensure automatic rollback to the previous version in case of any failure, guaranteeing service availability.

## Requirements
- Linux operating system
- Docker must be installed on the operating system, and image acceleration configured
- SSH access permission or password access permission, and ensure the provided account has root privileges
- Pipeline environment variables are configured

## Notes
- Before deployment, ensure that your Docker image has already been pushed to the remote image repository during the CI phase.
- If you want to pull images from a private repository, you must configure `DOCKER_REGISTRY_URL`, `DOCKER_USERNAME`, and `DOCKER_PASSWORD`.

## Usage

### Environment Variables Configuration

```bash
# Docker Account
DOCKER_USERNAME: "example_docker_username"
DOCKER_PASSWORD: "example_docker_password"
DOCKER_REGISTRY_URL: "" # Demo: https://index.docker.io/v1
# Docker Image Address
DOCKER_IMAGE: "example_namespace/image"
# Docker Container Startup Configuration
CONTAINER_NAME: "example_container"
DOCKER_APP_PARAMS: "-e KEY1=VAL1 -e KEY2=VAL2"
# Server
SERVER_IP: "example_host"
SERVER_USER: "example_server_user"
SSH_PRIVATE_KEY: "example_ssh_private_key"
```

### Running the Script

Method 1: Run the deployment script directly without downloading
```bash
curl -s https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh | bash -s -- <authMethod> <action>
```

Method 2: Run the deployment script after downloading (recommended)
```bash
curl -o deploy.sh https://raw.githubusercontent.com/jefferyjob/deployments/refs/heads/main/scripts/deploy.docker.sh
chmod +x deploy.sh
./deploy.sh <authMethod> <action>
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

