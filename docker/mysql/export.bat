@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ===================================================================
echo   MES 制造执行系统 - MySQL 数据库一键导出工具【零乱码安全保障】
echo ===================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "INIT_DIR=%SCRIPT_DIR%init\"
set "DEFAULT_OUTPUT=%INIT_DIR%01-ruoyi-vue-pro.sql"

if not exist "%INIT_DIR%" (
    mkdir "%INIT_DIR%"
)

set "SOURCE_CHOICE=%~1"
if "%SOURCE_CHOICE%"=="" (
    echo 请选择导出数据源:
    echo   [1] 导出当前 Docker 容器数据库【mes-mysql】（推荐，容器内原生导出，零乱码）
    echo   [2] 导出宿主机本地开发 MySQL【端口 3306】
    echo.
    set /p "SOURCE_CHOICE=请输入选项 [默认为 1]: "
)
if "%SOURCE_CHOICE%"=="" set "SOURCE_CHOICE=1"

set "TARGET_FILE=%~2"
if "%TARGET_FILE%"=="" (
    echo.
    set /p "TARGET_FILE=请输入导出目标路径 [直接回车默认: %DEFAULT_OUTPUT%]: "
)
if "%TARGET_FILE%"=="" set "TARGET_FILE=%DEFAULT_OUTPUT%"

echo.
if "%SOURCE_CHOICE%"=="2" goto :export_local

:export_container
echo [1/3] 正在检查 mes-mysql 容器状态...
docker inspect -f "{{.State.Running}}" mes-mysql 2>nul | findstr "true" >nul
if %errorlevel% neq 0 (
    echo [错误] mes-mysql 容器未在运行中，请先启动服务: docker compose up -d mes-mysql
    pause
    exit /b 1
)

echo [2/3] 正在从 mes-mysql 容器内部无损导出 SQL...
docker exec mes-mysql sh -c "mysqldump -uroot -p123456 --default-character-set=utf8mb4 --hex-blob --databases ruoyi-vue-pro -r /tmp/export_dump.sql"
if %errorlevel% neq 0 (
    echo [错误] 容器内 mysqldump 导出失败，请检查数据库状态。
    pause
    exit /b 1
)

echo [3/3] 正在将导出文件无损提取至宿主机: %TARGET_FILE%
docker cp mes-mysql:/tmp/export_dump.sql "%TARGET_FILE%"
docker exec mes-mysql rm -f /tmp/export_dump.sql
goto :finish

:export_local
echo [1/2] 正在检查本地 mysqldump 工具...
where mysqldump >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未在系统 PATH 中找到 mysqldump 命令，请确认已安装 MySQL 或选择 [1] 从容器导出。
    pause
    exit /b 1
)

set "HOST_PORT=3306"
set /p "INPUT_PORT=请输入本地 MySQL 端口 [直接回车默认 3306]: "
if not "%INPUT_PORT%"=="" set "HOST_PORT=%INPUT_PORT%"

set "HOST_USER=root"
set /p "INPUT_USER=请输入本地 MySQL 用户名 [直接回车默认 root]: "
if not "%INPUT_USER%"=="" set "HOST_USER=%INPUT_USER%"

echo [2/2] 正在执行本地导出【强制 -r 参数，杜绝字符乱码】...
mysqldump -h 127.0.0.1 -P %HOST_PORT% -u %HOST_USER% -p --default-character-set=utf8mb4 --hex-blob --databases ruoyi-vue-pro -r "%TARGET_FILE%"
if %errorlevel% neq 0 (
    echo [错误] 本地 mysqldump 导出失败，请检查密码或服务连接。
    pause
    exit /b 1
)

:finish
echo.
echo ===================================================================
echo [成功] 数据库导出完毕！
echo 导出文件: %TARGET_FILE%
for %%F in ("%TARGET_FILE%") do echo 文件大小: %%~zF 字节
echo ===================================================================
echo.
pause
