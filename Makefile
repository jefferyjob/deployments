# A Self-Documenting Makefile: http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY:test
test: ## 语法错误检测
	shellcheck -e SC2046 -e SC2317 scripts/*.sh

.PHONY:docker
docker: ## 测试Docker容器服务
	docker build -f tests/Dockerfile -t example-deployments .
	docker stop example-deployments || true
	docker rm example-deployments || true
	docker run -d -p 8080:80 --name example-deployments example-deployments

.PHONY:help
.DEFAULT_GOAL:=help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'