@echo off
chcp 65001 >nul
title MES 系统 - 全栈容器一键启动
echo ===================================================================
echo [MES 启动工具] 正在拉起 MES 全套容器集群 (MySQL, Redis, 后端, 前端)...
echo ===================================================================

cd /d "%~dp0"

where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [错误] 未检测到 docker 命令，请确认本地 Docker Desktop 是否已启动!
    pause
    exit /b 1
)

if not exist ".env" (
    if exist ".env.example" (
        echo [提示] 未检测到 .env 配置文件，正在根据 .env.example 自动生成...
        copy /y ".env.example" ".env" >nul
    )
)

echo [1/3] 检查后端镜像 yudao-server:latest...
docker image inspect yudao-server:latest >nul 2>nul
if %errorlevel% equ 0 goto :check_frontend

echo [提示] 本地尚未构建 yudao-server:latest 镜像，正在自动构建后端镜像...
if not exist "backend\yudao-server.jar" (
    echo.
    echo [错误] 未在 docker\backend 目录下找到 yudao-server.jar!
    echo 请先在 docker\backend 目录下运行 build.bat 完成后端镜像构建后再启动。
    pause
    exit /b 1
)
cd /d "%~dp0backend"
cmd /c docker build -t yudao-server:latest .
if %errorlevel% neq 0 (
    echo.
    echo [错误] 后端镜像构建失败!
    pause
    exit /b 1
)
cd /d "%~dp0"
echo [成功] 后端镜像 yudao-server:latest 构建就绪!

:check_frontend
echo [2/3] 检查前端镜像 yudao-ui:latest...
docker image inspect yudao-ui:latest >nul 2>nul
if %errorlevel% equ 0 goto :do_compose

echo [提示] 本地尚未构建前端镜像 yudao-ui:latest...
if not exist "frontend\dist\index.html" (
    echo.
    echo [警告] 未检测到前端静态资源 docker\frontend\dist\index.html!
    echo 请先在 docker\frontend 目录下双击运行 build.bat 完成前端打包。
    echo 否则前端容器将无法启动。
    pause
    exit /b 1
)
cd /d "%~dp0frontend"
cmd /c docker build -t yudao-ui:latest .
if %errorlevel% neq 0 (
    echo.
    echo [错误] 前端镜像构建失败!
    pause
    exit /b 1
)
cd /d "%~dp0"
echo [成功] 前端镜像 yudao-ui:latest 构建就绪!

:do_compose
echo [3/3] 正在启动全套容器服务 (MySQL 8.0, Redis 7, 后端, 前端)...
docker compose up -d
if %errorlevel% neq 0 (
    echo.
    echo [错误] Docker Compose 启动失败，请检查上方日志!
    pause
    exit /b %errorlevel%
)

echo.
echo ===================================================================
echo [成功] MES 系统集群已全部后台启动!
echo.
echo 系统服务访问入口:
echo   - 前端 Web 访问地址 : http://localhost:1228
echo   - 后端 API 接口地址 : http://localhost:48080/admin-api/
echo   - MySQL 数据库端口  : 3307 (账号: root, 密码详见 .env)
echo   - Redis 缓存端口    : 6379
echo ===================================================================
echo.
pause
