@echo off
chcp 65001 >nul
title MES 前端编译与 Docker 镜像构建工具
echo ===================================================================
echo [MES 部署工具] 正在开始前端 yudao-ui 编译与 Docker 镜像构建...
echo ===================================================================

set "FRONTEND_DIR=%~dp0..\..\yudao-ui\yudao-ui-admin-vue3"
set "TARGET_DIST=%~dp0dist"

REM 检查是否已有构建产物，优先匹配 vite 生产打包目录 dist-prod，其次兼容 dist
set "SRC_DIST="
if exist "%FRONTEND_DIR%\dist-prod\index.html" set "SRC_DIST=%FRONTEND_DIR%\dist-prod"
if not defined SRC_DIST if exist "%FRONTEND_DIR%\dist\index.html" set "SRC_DIST=%FRONTEND_DIR%\dist"

REM 命令行参数支持
if /i "%1"=="--rebuild" goto :do_build
if /i "%1"=="-r" goto :do_build
if /i "%1"=="--skip-build" goto :copy_dist
if /i "%1"=="-s" goto :copy_dist

REM 如果未检测到任何产物，自动开始执行 npm 编译打包
if not defined SRC_DIST goto :do_build

REM 如果已存在打包产物，提示用户是否复用
echo.
echo -------------------------------------------------------------------
echo [检测提示] 检测到已存在前端打包产物:
echo           %SRC_DIST%
echo.
echo [1] 直接使用现有产物构建 Docker 镜像 (推荐，无需等待打包)
echo [2] 重新执行完整前端编译打包 (npm run build:prod，约需2分钟)
echo -------------------------------------------------------------------
set USER_CHOICE=1
set /p USER_CHOICE="请输入选项编号 [1/2] (直接按回车默认选 1): "

if "%USER_CHOICE%"=="2" goto :do_build
goto :copy_dist

:do_build
echo.
echo [1/3] 正在执行前端构建打包 [npm run build:prod]...
cd /d "%FRONTEND_DIR%"
echo [执行目录] %CD%
echo [执行命令] npm run build:prod
cmd /c npm run build:prod
if %errorlevel% neq 0 (
    echo.
    echo [提示] npm 执行失败，尝试使用 pnpm run build:prod 打包...
    cmd /c pnpm run build:prod
    if %errorlevel% neq 0 (
        echo.
        echo [错误] 前端构建失败，请检查上方控制台报错信息!
        goto :fail
    )
)

REM 打包完成后重新定位产物目录
set "SRC_DIST="
if exist "%FRONTEND_DIR%\dist-prod\index.html" set "SRC_DIST=%FRONTEND_DIR%\dist-prod"
if not defined SRC_DIST if exist "%FRONTEND_DIR%\dist\index.html" set "SRC_DIST=%FRONTEND_DIR%\dist"

:copy_dist
echo.
echo [2/3] 正在同步静态文件到 Docker 构建上下文...
if not defined SRC_DIST (
    echo.
    echo [错误] 未在前端工程中找到 dist-prod 或 dist 打包输出目录!
    goto :fail
)

if not exist "%SRC_DIST%\index.html" (
    echo.
    echo [错误] 打包产物目录中缺少 index.html，前端构建可能未完整结束!
    goto :fail
)

echo [源目录]   %SRC_DIST%
echo [目标目录] %TARGET_DIST%

if exist "%TARGET_DIST%" rd /s /q "%TARGET_DIST%"
md "%TARGET_DIST%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Copy-Item -Path '%SRC_DIST%\*' -Destination '%TARGET_DIST%' -Recurse -Force"

if not exist "%TARGET_DIST%\index.html" (
    echo [提示] 正在使用备用方案同步文件...
    xcopy "%SRC_DIST%" "%TARGET_DIST%\" /s /e /y /i /q >nul
)

if not exist "%TARGET_DIST%\index.html" (
    echo.
    echo [错误] 静态文件同步失败，未在 docker\frontend\dist 中找到 index.html!
    goto :fail
)
echo [成功] 前端静态资源已成功同步到 docker\frontend\dist 目录!

echo.
echo [3/3] 正在使用 Docker 构建前端镜像 yudao-ui:latest...
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [错误] 系统未检测到 docker 命令，请确认本地 Docker Desktop 是否已启动!
    goto :fail
)

cd /d "%~dp0"
cmd /c docker build -t yudao-ui:latest .
if %errorlevel% neq 0 (
    echo.
    echo [错误] Docker 前端镜像构建失败，请检查上方 Docker 构建报错信息!
    goto :fail
)

echo.
echo ===================================================================
echo [成功] 前端 Docker 镜像 yudao-ui:latest 构建完成!
echo ===================================================================
pause
exit /b 0

:fail
echo.
echo ===================================================================
echo [提示] 构建过程发生异常，窗口已保持停留，请查看上方详细日志排查。
echo ===================================================================
pause
exit /b 1
