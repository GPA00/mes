# MES 制造执行系统 Docker 容器化打包与多端编排部署指南

本目录包含 MES 系统的完整容器化配置文件、跨平台（Windows / Linux）自动化脚本与持久化挂载结构。

---

## 一、服务规划与访问入口

| 服务名称 | 对应容器名 | 容器内部端口 | 宿主机映射端口 | 作用说明 |
|---|---|---|---|---|
| **前端 Web 控制台** | `mes-frontend` | 80 | **`1228`** | Vue 3 生产静态界面，反向代理 `/admin-api/` |
| **后端 API 服务** | `mes-backend` | 48080 | `48080` | Spring Boot 3 + JDK 17 单体服务 (`yudao-server`) |
| **核心数据库** | `mes-mysql` | 3306 | **`3307`** (防冲突) | MySQL 8.0 实例，挂载定制表结构与持久化数据 |
| **缓存与会话** | `mes-redis` | 6379 | `6379` | Redis 7.x 实例，挂载 AOF/RDB 持久化缓存 |

---

## 二、首次上线前的关键准备（迁移现有数据）

### 1. 迁移与同步 MySQL 表结构（一键工具）
由于你已经在开发库中对 MES 表结构做过修改：
- **一键导出最新数据库**：
  - **Windows**：双击运行 `docker/mysql/export.bat`（或执行 `docker/mysql/export.bat`），支持从当前 Docker 容器或本地 3306 导出，脚本内部采用原生二进制提取，彻底杜绝 PowerShell/CMD 终端乱码。
  - **Linux**：运行 `./docker/mysql/export.sh`。
  导出的全量 SQL 会自动安全保存在 `docker/mysql/init/01-ruoyi-vue-pro.sql`。
- **一键导入至运行中的容器**：
  - **Windows**：双击运行 `docker/mysql/import.bat`。
  - **Linux**：运行 `./docker/mysql/import.sh`。
  脚本会自动将 SQL 拷贝进容器并原生加载，并校验表总数（349 张表）。
- **首次部署自动初始化**：在首次拉起 Compose 时（`docker/mysql/data/` 目录尚空），MySQL 会自动读取执行 `docker/mysql/init/01-ruoyi-vue-pro.sql`；一旦初始化完成，后续日常启停将永久直接读写 `docker/mysql/data/`，**绝对不会**覆盖日常业务数据。

### 2. 迁移已有的 Redis 缓存数据
由于你当前已有独立运行的 Redis 容器：
1. 在旧 Redis 容器中执行保存落盘：
   ```bash
   docker exec -it <你的旧Redis容器名> redis-cli bgsave
   ```
2. 将快照文件拷出并放入本项目的 `docker/redis/data/` 目录：
   ```bash
   docker cp <你的旧Redis容器名>:/data/dump.rdb docker/redis/data/dump.rdb
   ```
3. 新编排启动时会自动读取并无缝恢复所有现有缓存。

---

## 三、一键打包与镜像构建

### 1. 后端镜像打包（`yudao-server:latest`）
- **Windows 环境**：直接双击运行 `docker/backend/build.bat`。
- **Linux 环境**：
  ```bash
  chmod +x docker/backend/build.sh
  ./docker/backend/build.sh
  ```
> 脚本会自动执行 Maven 编译打包，将提取出的 `yudao-server.jar` 打包进基于 `eclipse-temurin:17-jre-alpine` 的轻量级容器（已内置上海时区与验证码字体库）。

### 2. 前端镜像打包（`yudao-ui:latest`）
- **Windows 环境**：直接双击运行 `docker/frontend/build.bat`。
- **Linux 环境**：
  ```bash
  chmod +x docker/frontend/build.sh
  ./docker/frontend/build.sh
  ```

---

## 四、全套系统启停与运维管理

### 1. 一键拉起系统
- **Windows**：双击运行 `docker/start.bat`。
- **Linux**：
  ```bash
  chmod +x docker/start.sh
  ./docker/start.sh
  ```
- 或在 `docker/` 目录下直接执行通用 Docker 命令：
  ```bash
  docker compose up -d
  ```

### 2. 验证访问
容器启动完毕后，在浏览器访问：
- **前端系统界面**：`http://localhost:1228` （或 `http://服务器IP:1228`）
- **后端 Swagger / 接口**：`http://localhost:48080/admin-api/`
- **查看容器运行状态**：
  ```bash
  docker compose ps
  ```
- **查看后端实时日志**：
  ```bash
  docker compose logs -f mes-backend
  ```

### 3. 服务器错误日志存放在哪里？
系统运行产生的日志与异常错误信息分布在以下 **3 个位置**：

1. **宿主机挂载文件日志（永久落盘，推荐排查）**：
   - **宿主机路径**：`docker/backend/logs/yudao-server.log`
   - **说明**：通过挂载卷同步自容器内的 `/root/logs/yudao-server.log`，无需进入容器，在宿主机上即可直接用 VS Code / 文本编辑器打开、全文搜索或跟踪排查。
2. **Docker 控制台标准输出（实时流）**：
   - **命令**：`docker logs -f mes-backend`（实时滚动输出）
   - **过滤异常**：
     - Windows CMD：`docker logs mes-backend | findstr /i "ERROR Exception"`
     - Linux：`docker logs mes-backend 2>&1 | grep -i "error"`
3. **数据库与 Web 管理台（API 错误日志）**：
   - 框架内置的全局异常拦截器会自动将所有 500 系统异常与接口错误持久化记录：
     - **Web 控制台查看**：登录前端界面 `http://localhost:1228` $\rightarrow$ 进入【基础设施】/【系统管理】 $\rightarrow$ 【API 错误日志】，可图形化查看错误堆栈、请求参数与接口地址。
     - **MySQL 数据库表**：`ruoyi-vue-pro.infra_api_error_log` 表。

### 4. 一键安全停止
- **Windows**：双击运行 `docker/stop.bat`。
- **Linux**：`./docker/stop.sh` 或 `docker compose down`。
> 数据存储在本地 `docker/mysql/data/` 与 `docker/redis/data/` 中，停止容器**不会丢失任何数据**。

---

## 五、跨平台迁移交付至车间工控机 / 服务器

当准备将系统迁移到车间新电脑/服务器（无论是 Windows 还是 Ubuntu Linux）时：
1. 将整套 `docker/` 目录打包拷贝至新服务器。
2. 确保 `docker/mysql/init/01-ruoyi-vue-pro.sql` 与 `docker/redis/data/dump.rdb` 已就绪。
3. 在开发机将已构建的镜像导出或在新机上构建：
   ```bash
   docker save yudao-server:latest yudao-ui:latest | gzip > mes-images.tar.gz
   ```
   在车间新服务器上导入镜像：
   ```bash
   docker load < mes-images.tar.gz
   ```
4. 执行 `start.bat` (Windows) 或 `./start.sh` (Linux)，系统即刻在内网离线完整拉起！

---

## 六、历史排错与部署避坑宝典（真实故障复盘与 FAQ）

在整个 MES 系统的容器化与脚本化改造过程中，沉淀出以下典型技术陷阱及规避方案：

### 坑 1：Spring Boot 子模块二次 repackage 导致 Bean 丢失（`ApiErrorLogCommonApi` 缺失崩溃）
* **故障现象**：
  后端容器启动时报严重异常：
  ```text
  Parameter 0 of method globalExceptionHandler in cn.iocoder.yudao.framework.web.config.YudaoWebAutoConfiguration 
  required a bean of type 'cn.iocoder.yudao.framework.common.biz.infra.logger.ApiErrorLogCommonApi' that could not be found.
  ```
* **技术根因**：
  - 本项目 Docker 单体部署采用 `yudao-server` 聚合所有业务模块（`infra`、`system`、`mes` 等）。
  - 各子模块（如 `yudao-module-infra-server`、`yudao-module-system-server`）的 `pom.xml` 中若直接使用了 `spring-boot-maven-plugin:repackage` 且**未配置** `<skip>true</skip>`，子模块会被打包成 Spring Boot 可执行 Fat Jar，导致其所有 `.class` 文件被挪入内层的 `BOOT-INF/classes/` 目录。
  - 当 `yudao-server` 引入它们作为依赖打入外层主包的 `BOOT-INF/lib/*.jar` 时，Spring Boot 的 `LaunchedURLClassLoader` **只扫描依赖 Jar 根目录，无法穿透扫描嵌套的 `BOOT-INF/classes/`**！
  - 结果：`ApiErrorLogApiImpl` 及其它 Service/Controller 变成“隐形类”，Spring 容器完全扫不到它们，导致依赖注入失败、服务崩溃。
* **彻底解法**：
  在所有被 `yudao-server` 聚合依赖的子模块 `*-server/pom.xml` 中，给 `spring-boot-maven-plugin` 配置跳过打包：
  ```xml
  <plugin>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-maven-plugin</artifactId>
      <configuration>
          <skip>true</skip>
      </configuration>
  </plugin>
  ```
  保证子模块输出标准的类库 Jar 包（类位于根路径），仅保留主启动模块 `yudao-server` 执行 `repackage`。

---

### 坑 2：宿主机 MySQL 3306 端口占用与容器内外网络认知偏差
* **故障现象**：
  Docker Compose 启动报错：
  ```text
  Ports are not available: listen tcp 0.0.0.0:3306: bind: Only one usage of each socket address is normally permitted.
  ```
* **技术根因**：
  开发者本地电脑已安装了原生 MySQL 8.0 Windows 服务并设置为开机自启，牢牢占用了宿主机的 `3306` 端口。
* **彻底解法与关键认知**：
  1. 将 `docker/.env` 中的 `MYSQL_PORT` 修改为 **`3307`**，即映射为 `3307:3306`。
  2. **重要避坑认知（网络隔离）**：
     - **外部访问**：开发者使用 Navicat / DBeaver 从宿主机连接 Docker 里的 MySQL 时，端口需填写 **`3307`**。
     - **内部访问**：在 Docker 内部桥接网络（`mes-net`）中，后端 `mes-backend` 连接 `mes-mysql` 时，走的是容器内部虚拟网络，端口依然是 **`3306`**，JDBC URL 为：
       `jdbc:mysql://mes-mysql:3306/ruoyi-vue-pro`
       **绝不能将容器内部连接端口也改为 3307**！

---

### 坑 3：Windows 批处理脚本（`.bat`）乱码与“无声闪退”
* **故障现象**：
  双击批处理脚本控制台输出一堆乱码（如 `姝ｅ湪...`），或者黑框一闪而过立刻关闭，没有任何报错信息。
* **技术根因分析**：
  1. **字符编码乱码**：Windows CMD 默认代码页为 GBK (936)，若 `.bat` 文件保存为 UTF-8 且未显式指定代码页，中文将全部乱码。
  2. **换行符导致解析崩溃**：跨平台编辑器（VSCode / Git）将脚本保存成了 Linux 风格的 `LF` 换行符，Windows 的 `cmd.exe` 对 LF 换行解析极易产生截断与多行混淆，直接闪退。
  3. **复合语句括号陷阱（致命）**：在批处理中写 `if (...)` 或 `for (...)` 复合代码块时，如果内部 `echo`、注释或变量中含有半角圆括号 `( )`，CMD 解释器会将其提前误认为代码块闭合标签 `)`，引发语法错误并瞬间闪退。
* **彻底解法**：
  1. **编码规范**：文件第一行统一加上 `chcp 65001 >nul`（指定 UTF-8 代码页）。
  2. **换行符规范**：文件必须强制保存为 Windows 专属的 **CRLF (`\r\n`)** 换行符。项目中通过 `docker/.gitattributes` 文件锁定 `*.bat text eol=crlf`。
  3. **语法规范**：坚决弃用复杂的嵌套 `if (...) else (...)` 复合块，改用全线性的**标签与 `goto` 跳转**；在所有退出节点添加友好的错误提示与 `pause`，杜绝无声闪退。

---

### 坑 4：前端 Vite 打包 CSS 语法不兼容与产物路径丢失
* **故障现象 1**：
  前端执行 `npm run build:prod` 时，报 `[lightningcss minify] Unexpected token Semicolon`，定位在 `*zoom: 1;` 处构建中断。
* **故障现象 2**：
  构建 Docker 镜像时报 `COPY failed: stat dist: file does not exist`。
* **技术根因**：
  1. 现代 Vite 使用了基于 Rust 的超高速 CSS 压缩引擎 `lightningcss`，无法识别老旧的 IE Hack 兼容语法（如带有 `*` 前缀的属性）。
  2. Vite 针对生产环境模式的输出目录被配置为了 `dist-prod`，而传统 Dockerfile 或脚本往往固定写死查找 `dist` 目录。
* **彻底解法**：
  1. 清理样式表中过时的 IE Hack 属性（如删除 `*zoom: 1;`）。
  2. 在前端构建脚本 [docker/frontend/build.bat](file:///d:/mes/mes/docker/frontend/build.bat) 中加入智能适配逻辑：优先检测 `dist-prod` 目录，一旦生成自动同步拷贝至 `docker/frontend/dist`，确保与 Nginx Dockerfile 完美契合。

---

### 坑 5：构建脚本静默复用“已损坏的旧 Jar 包”
* **故障现象**：
  开发者明明在代码或 POM 中修补了问题，重新运行构建脚本后启动容器，报错依然存在，完全没有生效。
* **技术根因**：
  自动化脚本为了提高构建速度，通常会检测本地是否存在旧的 `yudao-server.jar`；如果用户默认按回车，或者脚本在检测不到 `mvn` 命令时自动静默降级，就会继续打包数天前编译出来的旧产物。
* **彻底解法**：
  优化后端构建脚本 [docker/backend/build.bat](file:///d:/mes/mes/docker/backend/build.bat)：
  - 当检测到已存在 Jar 包时，给出清晰的人机交互选项：
    - `[1] 直接使用现有 jar 包构建 Docker 镜像 (无需重新编译)`
    - `[2] 重新执行完整 Maven 编译打包 (mvn clean package)`
  - 若用户选择了重新编译或传入了 `-r / --rebuild` 参数，如遇到环境缺失会直接报错并给出配置指导，坚决不再隐式静默降级复用旧包。

---

### 坑 6：Windows 下 Maven 与 JDK 工具链环境变量未展开
* **故障现象**：
  系统明明安装了 Maven 和 JDK，但是在命令行或双击批处理时依然提示 `未检测到 mvn 命令`。
* **技术根因**：
  Windows 的系统环境变量 `PATH` 中写入了 `%MAVEN_HOME%\bin`，但在非登录 Shell 或特定子进程中，嵌套变量不会被自动二次展开；或者变量仅配置在管理员/当前用户的局部变量中。
* **彻底解法**：
  在构建脚本 [docker/backend/build.bat](file:///d:/mes/mes/docker/backend/build.bat) 中注入自愈探测逻辑：
  1. 先查当前 `where mvn`；若未找到，主动从 Windows 注册表（`HKLM` 与 `HKCU`）中读取 `MAVEN_HOME` 与 `JAVA_HOME`。
  2. 探测常见磁盘路径（如 `D:\maven\...`、`D:\java\jdk-17...`）。
  3. 发现有效路径后，动态补充注入到当前批处理会话的 `PATH` 中，保障打包命令一次性成功执行。

---

### 坑 7：Maven 打包报 testCompile 编译错误（`-DskipTests` 与 `-Dmaven.test.skip=true` 差异）
* **故障现象 1**：
  执行 Maven 编译打包时在 `yudao-module-report-server` 模块报错中断：
  ```text
  [ERROR] Failed to execute goal ...:testCompile on project yudao-module-report-server:
  [ERROR] GoViewDataServiceImplTest.java:[3,47] 程序包cn.iocoder.yudao.framework.test.core.ut不存在
  ```
* **故障现象 2**：
  若手动解除 POM 中单测依赖注释，Maven 报依赖版本丢失：
  ```text
  [ERROR] 'dependencies.dependency.version' for cn.iocoder.cloud:yudao-spring-boot-starter-test:jar is missing.
  ```
* **技术根因**：
  1. `yudao-spring-boot-starter-test` 在项目根 BOM 中并未受控管理版本，所以不能直接声明引入；因此所有子模块统一将其注释屏蔽。
  2. **参数认知陷阱**：使用 `-DskipTests` **只跳过测试运行，依然会触发 `testCompile` 编译测试代码**，导致缺少测试依赖报错。
* **彻底解法**：
  1. 各子模块维持对测试 starter 的注释不变。
  2. 将打包脚本中的 Maven 参数统一替换为 **`-Dmaven.test.skip=true`**，彻底跳过测试编译与运行阶段，既提速数十秒又免除单测编译干扰。

---

### 坑 8：Docker Redis 未设密码时传入空字符串环境变量导致 Redisson 鉴权崩溃
* **故障现象**：
  后端启动初始化 `OAuth2AccessTokenRedisDAO` 失败，底层报错：
  ```text
  Caused by: org.redisson.client.RedisException: ERR AUTH <password> called without any password configured for the default user.
  ```
* **技术根因**：
  - `docker/redis/conf/redis.conf` 未配置 `requirepass`，Redis 运行在无密码模式。
  - 在 `docker-compose.yml` 中若配置了 `SPRING_DATA_REDIS_PASSWORD: "${REDIS_PASSWORD}"`，当 `.env` 中的 `REDIS_PASSWORD` 为空时，Docker Compose 会给容器注入空字符串 `""`（非 null）。
  - Redisson 判定密码不为 null 便向 Redis 发送 `AUTH ""` 尝试认证，Redis 7.x 拒绝空密码认证并抛出异常，导致 `StringRedisTemplate` 初始化失败。
* **彻底解法**：
  在 `docker/docker-compose.yml` 中，如果 Redis 未配置 `requirepass`，移除向后端注入的 `SPRING_DATA_REDIS_PASSWORD` 环境变量，让 Spring Boot 默认使用 null 密码直连。

---

### 坑 9：Flowable 工作流引擎启动报主键冲突 (`Duplicate entry 'eventregistry.schema.version'`)
* **故障现象**：
  后端启动初始化 `ProcessEngineFactoryBean` 时抛出 SQL 异常：
  ```text
  Caused by: java.sql.SQLIntegrityConstraintViolationException: Duplicate entry 'eventregistry.schema.version' for key 'act_ge_property.PRIMARY'
  ```
* **技术根因**：
  初始化 SQL 文件中已经预置了完整的 Flowable 表和默认属性行。若 Spring Boot 配置了 `flowable.database-schema-update: true`（默认值），引擎启动时会尝试再次执行内置 DDL 和初始化插入脚本，导致主键重复冲突。
* **彻底解法**：
  在 `docker/docker-compose.yml` 的 `mes-backend` 环境变量中增加：
  ```yaml
  FLOWABLE_DATABASE_SCHEMA_UPDATE: "false"
  ```
  关闭启动时的重复 schema 初始化，直接安全复用现有数据结构。




