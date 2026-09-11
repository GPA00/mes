@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ===================================================================
echo   MES 制造执行系统 - MySQL 容器一键安全导入工具【零乱码安全保障】
echo ===================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "INIT_DIR=%SCRIPT_DIR%init\"
set "DEFAULT_SQL=%INIT_DIR%01-ruoyi-vue-pro.sql"

set "SQL_FILE=%~1"
if "%SQL_FILE%"=="" (
    set /p "SQL_FILE=请输入待导入的 SQL 文件路径 [直接回车默认: %DEFAULT_SQL%]: "
)
if "%SQL_FILE%"=="" set "SQL_FILE=%DEFAULT_SQL%"
if not exist "%SQL_FILE%" (
    if exist "%DEFAULT_SQL%" (
        set "SQL_FILE=%DEFAULT_SQL%"
    )
)

if not exist "%SQL_FILE%" (
    echo [错误] 找不到 SQL 文件: %SQL_FILE%
    pause
    exit /b 1
)

echo.
echo [1/4] 检查 mes-mysql 容器运行状态...
docker inspect -f "{{.State.Running}}" mes-mysql 2>nul | findstr "true" >nul
if %errorlevel% neq 0 (
    echo [提示] mes-mysql 容器未运行，正在尝试启动...
    docker compose -f "%SCRIPT_DIR%..\docker-compose.yml" up -d mes-mysql
    echo 等待 MySQL 准备就绪...
    powershell -Command "Start-Sleep -Seconds 10"
)

echo [2/4] 正在将 SQL 文件无损二进制传输至容器内部【/tmp/import_task.sql】...
docker cp "%SQL_FILE%" mes-mysql:/tmp/import_task.sql
if %errorlevel% neq 0 (
    echo [错误] 复制文件至容器失败，请检查 Docker 状态。
    pause
    exit /b 1
)

echo [3/4] 正在容器内安全执行导入【采用容器内部原生 source 引擎】...
docker exec -i mes-mysql mysql -uroot -p123456 --default-character-set=utf8mb4 -e "source /tmp/import_task.sql;"
if %errorlevel% neq 0 (
    echo [错误] 数据库导入中断，请检查 SQL 语法。
    docker exec mes-mysql rm -f /tmp/import_task.sql
    pause
    exit /b 1
)

docker exec mes-mysql rm -f /tmp/import_task.sql

echo [4/4] 验证数据库表结构状态...
docker exec -i mes-mysql mysql -uroot -p123456 -e "SELECT count(*) as total_tables FROM information_schema.tables WHERE table_schema='ruoyi-vue-pro';"

echo.
echo ===================================================================
echo [成功] 数据库导入已完成！
echo ===================================================================
echo.
set "RESTART_BACKEND=Y"
set /p "RESTART_BACKEND=是否立即重启后端服务 mes-backend 以生效数据？[Y/N，默认 Y]: "
if /i "!RESTART_BACKEND!"=="Y" (
    echo 正在重启 mes-backend...
    docker restart mes-backend
    echo [成功] mes-backend 已重启。
)

echo.
pause
