#!/usr/bin/env bash
set -e

# ===================================================================
# Linux / Ubuntu: MES 移动端 (Uniapp) 编译与 Docker 镜像构建脚本
# ===================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(cd "${SCRIPT_DIR}/../../yudao-ui/yudao-ui-admin-uniapp" && pwd)"

echo "==================================================================="
echo "[MES 部署工具] 正在开始移动端 yudao-ui-admin-uniapp 编译与 Docker 镜像构建..."
echo "==================================================================="

cd "${FRONTEND_DIR}"

echo "[1/3] 正在执行移动端构建打包 (pnpm / npm)..."
if [ ! -d "node_modules" ]; then
    echo "[检测提示] 未检测到 node_modules 依赖库，正在自动执行 pnpm install..."
    pnpm install || npm install
fi

if command -v pnpm &> /dev/null; then
    pnpm run build:h5:prod || pnpm run build:h5
elif command -v npm &> /dev/null; then
    npm run build:h5:prod || npm run build:h5
else
    echo "[错误] 系统未检测到 pnpm 或 npm 命令！"
    exit 1
fi

echo "[2/3] 正在同步 dist 静态文件到 Docker 构建上下文..."
SRC_DIST=""
if [ -d "dist/build/h5" ]; then
    SRC_DIST="${FRONTEND_DIR}/dist/build/h5"
elif [ -d "dist-prod" ]; then
    SRC_DIST="${FRONTEND_DIR}/dist-prod"
elif [ -d "dist" ]; then
    SRC_DIST="${FRONTEND_DIR}/dist"
else
    echo "[错误] 未在前端目录下找到 H5 打包产物目录！"
    exit 1
fi

rm -rf "${SCRIPT_DIR}/dist"
mkdir -p "${SCRIPT_DIR}/dist"
cp -r "${SRC_DIST}/"* "${SCRIPT_DIR}/dist/"

echo "[3/3] 正在使用 Docker 构建移动端镜像 yudao-ui-uniapp:latest..."
cd "${SCRIPT_DIR}"
docker build -t yudao-ui-uniapp:latest .

echo "==================================================================="
echo "[成功] 移动端 Docker 镜像 yudao-ui-uniapp:latest 构建完成！"
echo "==================================================================="
