#!/usr/bin/env bash
set -e

# ===================================================================
# Linux / Ubuntu: MES 后端编译与 Docker 镜像构建脚本
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "==================================================================="
echo "[MES 部署工具] 正在开始后端 yudao-server 编译与 Docker 镜像构建..."
echo "==================================================================="

cd "${PROJECT_ROOT}"

echo "[1/3] 正在执行 Maven 快速编译打包 (跳过单元测试与测试编译)..."
mvn clean package -Dmaven.test.skip=true -pl yudao-server -am

echo "[2/3] 正在提取 yudao-server.jar 到构建上下文目录..."
if [ ! -f "yudao-server/target/yudao-server.jar" ]; then
    echo "[错误] 未在 yudao-server/target 目录下找到 yudao-server.jar 文件！"
    exit 1
fi

cp -f "yudao-server/target/yudao-server.jar" "${SCRIPT_DIR}/yudao-server.jar"

echo "[3/3] 正在使用 Docker 构建后端镜像 yudao-server:latest..."
cd "${SCRIPT_DIR}"
docker build -t yudao-server:latest .

echo "==================================================================="
echo "[成功] 后端 Docker 镜像 yudao-server:latest 构建完成！"
echo "==================================================================="
