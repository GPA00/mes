# MES 系统 Docker 后端打包与跨平台全栈容器编排实施计划 (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建针对 MES 制造执行系统（Spring Boot 3.5.x + JDK 17 + Vue 3）的标准化 Docker 后端轻量打包流水线与跨平台（Windows / Linux）一键式 Docker Compose 全栈编排套件。

**Architecture:** 采用“宿主机 Maven 编译 + 极简 JRE 17 镜像构建”模式生成后端镜像；编排 `mes-backend`、`mes-frontend` (端口1228)、`mes-mysql` (8.0)、`mes-redis` (7.0) 四大服务；通过 POSIX 相对路径卷挂载保证用户已修改的 MySQL 表结构与 Redis 现有业务数据平滑迁移与绝对持久化；提供 Windows (`.bat`) 与 Linux (`.sh`) 双端启停自动化脚本。

**Tech Stack:** Docker, Docker Compose, Eclipse-Temurin JRE 17 Alpine, Nginx Alpine, MySQL 8.0, Redis 7 Alpine, Bash, Windows Batch.

**Spec:** [docs/superpowers/specs/2026-09-10-docker-backend-and-orchestration-design.md](file:///d:/mes/mes/docs/superpowers/specs/2026-09-10-docker-backend-and-orchestration-design.md)

## Global Constraints
- 前端对外暴露端口：**`1228`**（反代 `/admin-api/` 到后端 `48080`）。
- 后端服务端口：**`48080`**。
- MySQL 端口：**`3306`**，强制 `lower_case_table_names=1`，字符集 `utf8mb4`。
- Redis 端口：**`6379`**，开启 `appendonly yes`。
- 换行符约束：所有配置文件（`.cnf`, `.conf`, `.yml`）与 Linux Shell 脚本（`.sh`）严格使用 **`LF`**；Windows 批处理（`.bat`）严格使用 **`CRLF`**。
- 目录位置：所有部署相关资产严格归集于项目根目录 `docker/` 下。

---

### Task 1: 创建部署根环境与基础配置 (`.env`, `.env.example`, `.gitattributes`)

**Files:**
- Create: `docker/.env.example`
- Create: `docker/.env`
- Create: `docker/.gitattributes`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: Spec 中的环境变量规范与跨系统换行符要求。
- Produces: 后续 Docker Compose 和容器共享的统一环境变量与 Git 换行符控制。

- [ ] **Step 1: 编写 `docker/.env.example` 与 `docker/.env`**
定义系统端口、数据库账号密码、时区与 JVM 堆内存参数：
```properties
# ===================================================================
# MES 全栈容器编排环境变量配置
# ===================================================================

# 端口映射配置
FRONTEND_PORT=1228
BACKEND_PORT=48080
MYSQL_PORT=3306
REDIS_PORT=6379

# MySQL 数据库配置
MYSQL_ROOT_PASSWORD=123456
MYSQL_DATABASE=ruoyi-vue-pro

# Redis 密码配置（留空表示无密码）
REDIS_PASSWORD=

# 后端 JVM 启动参数（车间工控机/服务器高并发调优）
JAVA_OPTS=-Xms1g -Xmx2g -XX:+UseG1GC -Dfile.encoding=UTF-8
```

- [ ] **Step 2: 编写 `docker/.gitattributes` 锁定换行符**
防止 Windows 开发者检出代码时将 Linux 脚本转为 CRLF：
```gitattributes
# 强制保持 LF 换行符，防止 Linux 容器内报错
*.sh text eol=lf
*.conf text eol=lf
*.cnf text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
Dockerfile text eol=lf

# 批处理脚本必须使用 CRLF
*.bat text eol=crlf
```

- [ ] **Step 3: 更新根目录 `.gitignore`**
确保 `docker/mysql/data/`、`docker/redis/data/` 物理数据库文件及 `docker/.env` 私密配置不被误提交进代码库。

---

### Task 2: 配置 MySQL 8.0 挂载与表结构平滑迁移环境

**Files:**
- Create: `docker/mysql/conf/my.cnf`
- Create: `docker/mysql/init/README.md`

**Interfaces:**
- Consumes: MySQL 8.0 针对内网调优的参数；用户已修改的 MySQL 表结构导出规范。
- Produces: 提供给 `mes-mysql` 服务的配置挂载与初始化自动执行钩子。

- [ ] **Step 1: 编写 `docker/mysql/conf/my.cnf` (LF换行)**
```ini
[mysqld]
user=mysql
default-storage-engine=INNODB
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-time-zone='+08:00'
max_connections=500
max_connect_errors=1000
wait_timeout=28800
interactive_timeout=28800

# 表名不区分大小写，消除跨平台兼容隐患
lower_case_table_names=1

# SQL 模式兼容
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION

[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4
```

- [ ] **Step 2: 创建 `docker/mysql/init/README.md`**
详细记录将开发机已修改表结构一键导出并放入 `docker/mysql/init/01-ruoyi-vue-pro.sql` 的完整命令与注意事项。

---

### Task 3: 配置 Redis 7 挂载与现有缓存数据迁移环境

**Files:**
- Create: `docker/redis/conf/redis.conf`
- Create: `docker/redis/data/README.md`

**Interfaces:**
- Consumes: Redis 7 持久化要求与用户已有 Redis 容器的 `dump.rdb`。
- Produces: 提供给 `mes-redis` 服务的持久化运行环境。

- [ ] **Step 1: 编写 `docker/redis/conf/redis.conf` (LF换行)**
```conf
bind 0.0.0.0
protected-mode no
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no

# 开启 AOF 与 RDB 双持久化
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

dir /data
dbfilename dump.rdb

# 内存上限与淘汰策略
maxmemory 1024mb
maxmemory-policy volatile-lru
```

- [ ] **Step 2: 创建 `docker/redis/data/README.md`**
指导用户如何将现有 Redis 容器中的 `dump.rdb` 通过 `docker cp` 放入此目录，并在启动时自动加载原有数据。

---

### Task 4: 构建后端 Dockerfile 与自动化打包流水线

**Files:**
- Create: `docker/backend/Dockerfile`
- Create: `docker/backend/build.bat`
- Create: `docker/backend/build.sh`

**Interfaces:**
- Consumes: 根目录多模块 Maven 结构中的 `yudao-server` 模块打包产物。
- Produces: 本地 Docker 镜像 `yudao-server:latest`。

- [ ] **Step 1: 编写 `docker/backend/Dockerfile` (LF换行)**
```dockerfile
FROM eclipse-temurin:17-jre-alpine

# 安装时区和基础字库（彻底杜绝图形验证码/EasyExcel报表字体缺失导致的NullPointerException）
RUN apk add --no-cache tzdata fontconfig ttf-dejavu && \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

WORKDIR /app

# 拷贝预编译好的 jar 包
COPY yudao-server.jar app.jar

# 声明暴露端口
EXPOSE 48080

# 启动命令：支持通过 JAVA_OPTS 动态注入内存和GC参数
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
```

- [ ] **Step 2: 编写 Windows 一键编译与打包脚本 `docker/backend/build.bat` (CRLF换行)**
```bat
@echo off
chcp 65001 >nul
echo ========================================================
echo [MES 部署工具] 正在编译后端 yudao-server 并构建 Docker 镜像...
echo ========================================================

cd /d "%~dp0..\.."

echo [1/3] 执行 Maven 编译打包 (跳过测试)...
call mvn clean package -DskipTests -pl yudao-server -am
if %errorlevel% neq 0 (
    echo [错误] Maven 编译失败，请检查代码或依赖！
    pause
    exit /b %errorlevel%
)

echo [2/3] 提取 yudao-server.jar 到 docker/backend 目录...
copy /y "yudao-server\target\yudao-server.jar" "docker\backend\yudao-server.jar"
if %errorlevel% neq 0 (
    echo [错误] 复制 jar 包失败，请确认 yudao-server.jar 是否正常生成！
    pause
    exit /b %errorlevel%
)

echo [3/3] 构建 Docker 镜像 yudao-server:latest...
cd /d "%~dp0"
docker build -t yudao-server:latest .
if %errorlevel% neq 0 (
    echo [错误] Docker 镜像构建失败！
    pause
    exit /b %errorlevel%
)

echo ========================================================
echo [成功] yudao-server:latest 镜像构建完成！
echo ========================================================
pause
```

- [ ] **Step 3: 编写 Linux 一键编译与打包脚本 `docker/backend/build.sh` (LF换行)**
包含对应的 bash 命令逻辑并赋予可执行权限说明。

---

### Task 5: 配置前端 Nginx 反向代理与 Dockerfile

**Files:**
- Create: `docker/frontend/Dockerfile`
- Create: `docker/frontend/nginx.conf`
- Create: `docker/frontend/build.bat`
- Create: `docker/frontend/build.sh`

**Interfaces:**
- Consumes: 前端 `yudao-ui/yudao-ui-admin-vue3` 打包生成的 `dist` 目录。
- Produces: 监听 `80` 端口、对外映射 `1228` 端口的前端反向代理镜像。

- [ ] **Step 1: 编写 `docker/frontend/nginx.conf` (LF换行)**
包含对 Vue Router History 模式的支持，以及将 `/admin-api/` 反向代理至容器名 `mes-backend:48080`：
```nginx
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
    client_max_body_size 100M;

    server {
        listen       80;
        server_name  localhost;

        # 前端静态页面
        location / {
            root   /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
            index  index.html index.htm;
        }

        # 后端接口反向代理
        location /admin-api/ {
            proxy_pass http://mes-backend:48080/admin-api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_read_timeout 300s;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
```

- [ ] **Step 2: 编写 `docker/frontend/Dockerfile`**
基于 `nginx:alpine`，复制定制的 `nginx.conf` 与 `dist` 静态资源目录。

- [ ] **Step 3: 编写前端一键构建脚本 `docker/frontend/build.bat` 与 `build.sh`**
自动进入 `yudao-ui/yudao-ui-admin-vue3` 执行 `pnpm build`，并复制 `dist` 构建 `yudao-ui:latest` 镜像。

---

### Task 6: 编写核心全栈 Docker Compose 编排与双端启停脚本

**Files:**
- Create: `docker/docker-compose.yml`
- Create: `docker/start.bat`
- Create: `docker/start.sh`
- Create: `docker/stop.bat`
- Create: `docker/stop.sh`
- Create: `docker/README.md`

**Interfaces:**
- Consumes: Task 1-5 建立的所有容器配置、镜像定义、数据挂载卷与网络命名。
- Produces: 完整一键拉起或停止整套 MES 系统的编排闭环。

- [ ] **Step 1: 编写 `docker/docker-compose.yml` (LF换行)**
包含四个服务定义，配合健康检查与网络互联：
```yaml
version: '3.8'

networks:
  mes-net:
    driver: bridge

services:
  mes-mysql:
    image: mysql:8.0
    container_name: mes-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}" # 数据库密码，读取 .env 配置，默认即为 123456
      MYSQL_DATABASE: "ruoyi-vue-pro"
      TZ: "Asia/Shanghai"
    ports:
      - "${MYSQL_PORT}:3306"
    volumes:
      - ./mysql/conf/my.cnf:/etc/mysql/conf.d/my.cnf:ro
      - ./mysql/init:/docker-entrypoint-initdb.d:ro
      - ./mysql/data:/var/lib/mysql
    networks:
      - mes-net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  mes-redis:
    image: redis:7-alpine
    container_name: mes-redis
    restart: always
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - ./redis/conf/redis.conf:/usr/local/etc/redis/redis.conf:ro
      - ./redis/data:/data
    networks:
      - mes-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  mes-backend:
    image: yudao-server:latest
    container_name: mes-backend
    restart: always
    environment:
      TZ: "Asia/Shanghai"
      JAVA_OPTS: "${JAVA_OPTS}"
      SPRING_PROFILES_ACTIVE: "local"
      SPRING_DATASOURCE_DYNAMIC_DATASOURCE_MASTER_URL: "jdbc:mysql://mes-mysql:3306/ruoyi-vue-pro?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true&rewriteBatchedStatements=true"
      SPRING_DATASOURCE_DYNAMIC_DATASOURCE_MASTER_USERNAME: "root"
      SPRING_DATASOURCE_DYNAMIC_DATASOURCE_MASTER_PASSWORD: "${MYSQL_ROOT_PASSWORD}" # 保持与 MySQL 密码完全一致 (123456)
      SPRING_DATA_REDIS_HOST: "mes-redis"
      SPRING_DATA_REDIS_PORT: 6379
      SPRING_DATA_REDIS_PASSWORD: "${REDIS_PASSWORD}"
    ports:
      - "${BACKEND_PORT}:48080"
    depends_on:
      mes-mysql:
        condition: service_healthy
      mes-redis:
        condition: service_healthy
    networks:
      - mes-net

  mes-frontend:
    image: yudao-ui:latest
    container_name: mes-frontend
    restart: always
    ports:
      - "${FRONTEND_PORT}:80"
    depends_on:
      - mes-backend
    networks:
      - mes-net
```

- [ ] **Step 2: 编写双端控制脚本**
- `start.bat` / `stop.bat` (CRLF，直接双击运行 `docker compose up -d` / `down`)
- `start.sh` / `stop.sh` (LF，Linux 环境启动与停止)

- [ ] **Step 3: 编写 `docker/README.md` 操作手册**
提供从 0 到 1 的开发机导出数据、车间新服务器拉起、日常启停与故障排查完整指引。

---

### Task 7: 完整性与跨平台换行符校验

**Files:**
- Inspect: All created files under `docker/`

- [ ] **Step 1: 换行符检查**
确认 `.sh`、`.conf`、`.cnf`、`.yml` 均采用 LF 换行，`.bat` 采用 CRLF。

- [ ] **Step 2: 编排语法校验**
验证 `docker-compose.yml` 语法结构合规，环境变量引用无缺漏。

- [ ] **Step 3: 生成变更总结与上线指引**
编写清晰的用户交付文档。
