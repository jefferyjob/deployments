#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions 会自动注入这些环境变量
# https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables

if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
  BRANCH="${GITHUB_HEAD_REF}"
else
  BRANCH="${GITHUB_REF_NAME}"
fi

# 输出给调用方使用
echo "$BRANCH"
