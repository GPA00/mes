@echo off
chcp 65001 >nul
echo =======================================
echo 1. 正在编译打包 Vue 项目...
echo =======================================
call pnpm install
call pnpm run build:prod

echo.
echo =======================================
echo 2. 正在停止并删除旧�?Docker 容器...
echo =======================================
docker stop yudao-ui-admin
docker rm yudao-ui-admin

echo.
echo =======================================
echo 3. 正在构建新的 Docker 镜像...
echo =======================================
docker build -t yudao-ui-admin:latest .

echo.
echo =======================================
echo 4. 正在运行新的 Docker 容器...
echo =======================================
docker run -d -p 80:80 --name yudao-ui-admin yudao-ui-admin:latest

echo.
echo =======================================
echo 部署完成！请在浏览器访问 http://localhost
echo =======================================
pause

