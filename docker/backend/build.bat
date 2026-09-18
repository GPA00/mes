@echo off
chcp 65001 >nul
title MES 后端编译与 Docker 镜像构建工具
echo ===================================================================
echo [MES 部署工具] 正在开始后端 yudao-server 编译与 Docker 镜像构建...
echo ===================================================================

set "PROJECT_ROOT=%~dp0..\.."
set "BACKEND_DIR=%~dp0"
set "TARGET_JAR=%BACKEND_DIR%yudao-server.jar"

REM 检查是否已有编译好的 jar 包，优先检测 docker\backend\yudao-server.jar，其次检测 target 目录
set "SRC_JAR="
if exist "%TARGET_JAR%" set "SRC_JAR=%TARGET_JAR%"
if not defined SRC_JAR if exist "%PROJECT_ROOT%\yudao-server\target\yudao-server.jar" set "SRC_JAR=%PROJECT_ROOT%\yudao-server\target\yudao-server.jar"

REM 命令行参数支持
if /i "%1"=="--rebuild" goto :do_build
if /i "%1"=="-r" goto :do_build
if /i "%1"=="--skip-build" goto :copy_jar
if /i "%1"=="-s" goto :copy_dist

REM 如果不存在现成的 jar 包，直接执行 Maven 编译打包
if not defined SRC_JAR goto :do_build

REM 如果已存在 jar 包，提示用户自主选择是否复用
echo.
echo -------------------------------------------------------------------
echo [检测提示] 检测到已存在后端 jar 包产物:
echo           %SRC_JAR%
echo.
echo [1] 直接使用现有 jar 包构建 Docker 镜像 (推荐，无需重复编译)
echo [2] 重新执行完整 Maven 编译打包 (mvn clean package，约需数分钟)
echo -------------------------------------------------------------------
set USER_CHOICE=1
set /p USER_CHOICE="请输入选项编号 [1/2] (直接按回车默认选 1): "

if "%USER_CHOICE%"=="2" goto :do_build
goto :copy_jar

:do_build
echo.
echo [1/3] 正在检查 Maven 与 JDK 环境并执行后端编译打包...
cd /d "%PROJECT_ROOT%"

REM 自动补全 JAVA_HOME (JDK 17)
if not defined JAVA_HOME (
    if exist "D:\java\jdk-17.0.20+8\bin\java.exe" set "JAVA_HOME=D:\java\jdk-17.0.20+8"
)
if defined JAVA_HOME (
    set "PATH=%JAVA_HOME%\bin;%PATH%"
)

REM 自动补全 MAVEN_HOME
where mvn >nul 2>nul
if %errorlevel% equ 0 goto :run_mvn

if not defined MAVEN_HOME (
    if exist "D:\maven\apache-maven-3.9.16-bin\apache-maven-3.9.16\bin\mvn.cmd" set "MAVEN_HOME=D:\maven\apache-maven-3.9.16-bin\apache-maven-3.9.16"
)
if defined MAVEN_HOME if exist "%MAVEN_HOME%\bin\mvn.cmd" (
    set "PATH=%MAVEN_HOME%\bin;%PATH%"
)

where mvn >nul 2>nul
if %errorlevel% equ 0 goto :run_mvn

echo.
echo [提示] 系统环境变量中未检测到 mvn 命令。
echo [错误] 重新编译打包需要 Maven 环境。
echo 请确保已配置 MAVEN_HOME / PATH，或在 IntelliJ IDEA 的 Maven 窗口中执行 package 打包。
goto :fail

:run_mvn
echo [执行目录] %CD%
echo [执行命令] mvn clean package -Dmaven.test.skip=true -pl yudao-server -am
echo -------------------------------------------------------------------
cmd /c mvn clean package -Dmaven.test.skip=true -pl yudao-server -am
if %errorlevel% neq 0 (
    echo -------------------------------------------------------------------
    echo [错误] Maven 编译打包失败，请检查上方控制台报错信息!
    goto :fail
)
echo -------------------------------------------------------------------

set "SRC_JAR=%PROJECT_ROOT%\yudao-server\target\yudao-server.jar"

:copy_jar
echo.
echo [2/3] 正在同步 yudao-server.jar 到 Docker 构建上下文...
if not defined SRC_JAR (
    echo.
    echo [错误] 未找到任何可用的 yudao-server.jar 文件!
    goto :fail
)

if not exist "%SRC_JAR%" (
    echo.
    echo [错误] 指定的 jar 包不存在: %SRC_JAR%
    goto :fail
)

REM 如果源文件就是 docker\backend\yudao-server.jar，则无需重复自我复制
if /i "%SRC_JAR%"=="%TARGET_JAR%" (
    echo [成功] docker\backend\yudao-server.jar 已就绪，无需重复复制。
    goto :do_docker
)

echo [源文件]   %SRC_JAR%
echo [目标文件] %TARGET_JAR%
copy /y "%SRC_JAR%" "%TARGET_JAR%" >nul
if %errorlevel% neq 0 (
    echo.
    echo [错误] 复制 jar 包到 docker\backend 目录失败!
    goto :fail
)
echo [成功] yudao-server.jar 已成功同步到 docker\backend 目录!

:do_docker
echo.
echo [3/3] 正在使用 Docker 构建后端镜像 yudao-server:latest...
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [错误] 系统未检测到 docker 命令，请确认本地 Docker Desktop 是否已启动!
    goto :fail
)

cd /d "%BACKEND_DIR%"
cmd /c docker build -t yudao-server:latest .
if %errorlevel% neq 0 (
    echo.
    echo [错误] Docker 后端镜像构建失败，请检查上方 Docker 构建报错信息!
    goto :fail
)

echo.
echo ===================================================================
echo [成功] 后端 Docker 镜像 yudao-server:latest 构建完成!
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
