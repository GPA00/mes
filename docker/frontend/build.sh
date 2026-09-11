#!/usr/bin/env bash
set -e

# ===================================================================
# Linux / Ubuntu: MES 前端编译与 Docker 镜像构建脚本
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "${SCRIPT_DIR}/../../yudao-ui/yudao-ui-admin-vue3" && pwd)"

echo "==================================================================="
echo "[MES 部署工具] 正在开始前端 yudao-ui 编译与 Docker 镜像构建..."
echo "==================================================================="

cd "${FRONTEND_DIR}"

echo "[1/3] 正在执行前端构建打包 (pnpm / npm)..."
if command -v pnpm &> /dev/null; then
    pnpm run build:prod
elif command -v npm &> /dev/null; then
    npm run build:prod
else
    echo "[错误] 系统未检测到 pnpm 或 npm 命令！"
    exit 1
fi

echo "[2/3] 正在同步 dist 静态文件到 Docker 构建上下文..."
if [ ! -d "dist" ]; then
    echo "[错误] 未在前端目录下找到 dist 打包产物！"
    exit 1
fi

rm -rf "${SCRIPT_DIR}/dist"
cp -r "${FRONTEND_DIR}/dist" "${SCRIPT_DIR}/dist"

echo "[3/3] 正在使用 Docker 构建前端镜像 yudao-ui:latest..."
cd "${SCRIPT_DIR}"
docker build -t yudao-ui:latest .

echo "==================================================================="
echo "[成功] 前端 Docker 镜像 yudao-ui:latest 构建完成！"
echo "==================================================================="
