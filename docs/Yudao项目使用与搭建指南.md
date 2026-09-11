# Yudao 项目使用与搭建指南

> 本文档面向公司内部开发和运维人员，系统梳理当前基于"芋道源码"框架搭建的 MES/PMS/AI 一体化平台的架构、环境搭建流程、模块功能说明及日常开发规范。
> 结合《关于公司数字化转型与AI化发展方向的汇报》中提出的"自建开源MES破局 + 逐步AI化赋能"战略，本文档是落地执行层面的技术参考手册。

---

## 一、项目概览

### 1.1 项目定位

本项目基于 **芋道源码（Yudao / ruoyi-vue-pro）** 开源框架进行二次开发，目标是为公司伺服制造业务构建一套覆盖 **MES（制造执行）、PMS（项目管理/知识库）、AI（大模型集成）** 的数字化管理平台。

### 1.2 技术栈一览

| 层级 | 技术 | 说明 |
|------|------|------|
| **后端框架** | Spring Boot 3.5 + Spring Cloud | Java 17，单体模式运行（可选微服务） |
| **前端框架** | Vue 3 + Element Plus + Vite | 管理后台主界面（`yudao-ui-admin-vue3`） |
| **数据库** | MySQL 8.x | 主数据源，数据库名 `ruoyi-vue-pro` |
| **缓存** | Redis | Session、缓存、分布式锁 |
| **ORM** | MyBatis-Plus + Druid 连接池 | 多数据源支持（主从/TDengine 等） |
| **工作流** | Flowable（BPM 模块） | 审批流程引擎 |
| **定时任务** | XXL-JOB | 可选开启 |
| **AI 大模型** | Spring AI 1.1.8 + 多厂商 SDK | OpenAI、通义千问、DeepSeek、文心一言等 12 种 |
| **构建工具** | Maven（后端）/ pnpm（前端） | — |
| **JDK** | OpenJDK 17 | 必须使用 17+ |

### 1.3 项目版本

当前版本号：`2026.08-SNAPSHOT`（定义在根 `pom.xml` 的 `<revision>` 属性中）

---

## 二、项目目录结构

```
d:\mes\mes\                              # 项目根目录
├── pom.xml                              # Maven 根 POM（聚合模块）
├── sql/                                 # 数据库初始化脚本
│   └── mysql/
│       ├── ruoyi-vue-pro.sql            # 主库建表 + 初始数据（约 2MB）
│       └── quartz.sql                   # 定时任务表
│
├── yudao-dependencies/                  # 全局依赖版本管理（BOM）
├── yudao-framework/                     # 基础框架层（16 个 starter）
│   ├── yudao-common/                    #   公共工具类、基础 VO/DTO
│   ├── yudao-spring-boot-starter-web/   #   Web 封装（统一返回、全局异常）
│   ├── yudao-spring-boot-starter-security/ #   权限认证（JWT + RBAC）
│   ├── yudao-spring-boot-starter-mybatis/  #   MyBatis-Plus 封装
│   ├── yudao-spring-boot-starter-redis/    #   Redis 封装
│   ├── yudao-spring-boot-starter-mq/       #   消息队列封装
│   ├── yudao-spring-boot-starter-excel/    #   Excel 导入导出
│   ├── yudao-spring-boot-starter-job/      #   定时任务封装
│   ├── yudao-spring-boot-starter-biz-tenant/ # 多租户支持
│   ├── yudao-spring-boot-starter-websocket/  # WebSocket
│   └── ...                              #   更多 starter
│
├── yudao-server/                        # ★ 主启动模块（打包入口）
│   └── src/main/resources/
│       ├── application.yaml             #   主配置文件
│       ├── application-local.yaml       #   本地开发环境配置
│       └── application-dev.yaml         #   开发/测试环境配置
│
├── yudao-module-system/                 # 系统管理模块（用户、角色、菜单、部门等）
├── yudao-module-infra/                  # 基础设施模块（代码生成、文件管理、API日志等）
├── yudao-module-bpm/                    # 工作流/审批模块（Flowable 引擎）
├── yudao-module-report/                 # 报表模块
│
├── yudao-module-mes/                    # ★ MES 制造执行模块（核心业务）
│   ├── yudao-module-mes-api/            #   MES 对外 API 定义
│   └── yudao-module-mes-server/         #   MES 业务实现
│
├── yudao-module-pms/                    # ★ PMS 项目管理/知识库模块
│   ├── yudao-module-pms-api/
│   └── yudao-module-pms-server/
│
├── yudao-module-ai/                     # ★ AI 大模型集成模块
│   ├── yudao-module-ai-api/
│   └── yudao-module-ai-server/
│
├── yudao-gateway/                       # API 网关（微服务模式时使用）
│
└── yudao-ui/                            # 前端项目集合
    ├── yudao-ui-admin-vue3/             #   ★ Vue3 管理后台（主要使用）
    ├── yudao-ui-admin-vue2/             #   Vue2 旧版后台
    ├── yudao-ui-admin-vben/             #   Vben Admin 版后台
    ├── yudao-ui-admin-uniapp/           #   UniApp 移动端
    └── yudao-ui-mall-uniapp/            #   商城 UniApp
```

---

## 三、MES 模块功能详解

MES 模块（`yudao-module-mes`）是公司数字化转型的核心，已实现以下子系统：

### 3.1 子模块一览

| 缩写 | 全称 | 功能说明 | 对应汇报文档中的目标 |
|------|------|---------|-------------------|
| **md** | Master Data（主数据） | 物料（item）、客户（client）、供应商（vendor）、工位（workstation）、编码规则（autocode）、计量单位管理 | 基础数据底座 |
| **pro** | Production（生产管理） | 工序（process）、工艺路线（route）、生产工单（workorder）、生产任务（task）、生产报工（feedback）、流转卡（card）、安灯呼叫（andon）、作业记录（workrecord） | 电子看板与透明化排产 |
| **qc** | Quality Control（质量管理） | 来料检验（IQC）、过程检验（IPQC）、出货检验（OQC）、退货检验（RQC）、检验模板（template）、检验指标（indicator）、缺陷管理（defect）、待检清单（pendinginspect） | 扫码追溯与防呆 |
| **wm** | Warehouse Management（仓库管理） | 仓库（warehouse）、物料库存（materialstock）、到货通知（arrivalnotice）、条码（barcode）、批次（batch）、序列号（sn）、入库/出库/调拨/盘点、生产领料/产出/退料、委外收发、销售出库/退货等 23 个子模块 | 全链路物料追踪 |
| **dv** | Device（设备管理） | 设备台账（machinery）、点检计划（checkplan）、点检记录（checkrecord）、保养记录（maintenrecord）、维修工单（repair）、检测项目（subject） | 设备生命周期管理 |
| **cal** | Calendar（排班日历） | 生产日历（calendar）、班组（team）、排班计划（plan）、节假日（holiday） | 排产辅助 |
| **tm** | Tool Management（工装管理） | 工装工具管理 | 辅助生产 |
| **home** | Dashboard（首页看板） | 首页数据汇总 | 管理驾驶舱 |

### 3.2 与汇报方案的对应关系

| 汇报目标 | 已有模块支撑 | 当前状态 |
|---------|------------|---------|
| 电子看板与透明化排产 | `pro`（工单/任务/报工） + `cal`（排班） | ✅ 已具备基础能力 |
| 扫码追溯与防呆 | `wm`（条码/批次/SN） + `qc`（IQC/IPQC/OQC） | ✅ 已具备基础能力 |
| 审批线上化 | `yudao-module-bpm`（工作流引擎） | ✅ 框架自带 |
| AI 智能排产助手 | `yudao-module-ai`（12 种大模型接入） | 🔧 框架已就绪，待业务适配 |
| AI 技术客服 | `yudao-module-ai` + `pms/kb`（知识库） | 🔧 知识库模块已有，待对接 |

---

## 四、PMS 模块功能详解

PMS 模块（`yudao-module-pms`）包含两大子系统：

| 缩写 | 全称 | 功能说明 |
|------|------|---------|
| **pm** | Project Management | 项目（project）、迭代（iteration）、工作项（workitem）、工作台（workbench） |
| **kb** | Knowledge Base（知识库） | 文档库（library）、文档内容（content）、文档交互（interaction）、回收站（recycle） |

> 知识库模块可作为后续"AI 技术客服"的语料来源：将公司的技术文档、图纸、维修记录等上传至知识库，结合 AI 模块的 RAG（检索增强生成）能力实现智能问答。

---

## 五、环境搭建指南

### 5.1 必备软件

| 软件 | 版本要求 | 用途 |
|------|---------|------|
| JDK | 17+ | 后端编译运行 |
| Maven | 3.8+ | 后端构建 |
| MySQL | 8.0+ | 主数据库 |
| Redis | 5.0+ | 缓存 |
| Node.js | 18+ | 前端构建 |
| pnpm | 9.x | 前端包管理 |
| IntelliJ IDEA | 2024+ | 推荐 IDE |

### 5.2 数据库初始化

```bash
# 1. 创建数据库（字符集必须为 utf8mb4）
CREATE DATABASE `ruoyi-vue-pro` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 2. 导入主库脚本
mysql -u root -p ruoyi-vue-pro < sql/mysql/ruoyi-vue-pro.sql

# 3.（可选）如需定时任务，导入 Quartz 表
mysql -u root -p ruoyi-vue-pro < sql/mysql/quartz.sql
```

### 5.3 后端启动

#### 步骤一：修改配置

编辑 `yudao-server/src/main/resources/application-local.yaml`：

```yaml
# 数据库连接（修改为实际地址和密码）
spring:
  datasource:
    dynamic:
      datasource:
        master:
          url: jdbc:mysql://127.0.0.1:3306/ruoyi-vue-pro?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&nullCatalogMeansCurrent=true&rewriteBatchedStatements=true
          username: root
          password: 你的密码

# Redis 连接（修改为实际地址）
  data:
    redis:
      host: 127.0.0.1
      port: 6379
      database: 0
```

#### 步骤二：Maven 编译

```bash
# 在项目根目录执行（首次编译约需 8-10 分钟）
mvn clean install -Dmaven.test.skip=true
```

#### 步骤三：启动应用

在 IDEA 中找到启动类并运行：
- **路径**：`yudao-server/src/main/java/cn/iocoder/yudao/server/YudaoServerApplication.java`
- **默认端口**：`48080`
- **默认 Profile**：`local`

启动成功后，后端 API 地址为 `http://localhost:48080`。

### 5.4 前端启动

```bash
# 进入前端目录
cd yudao-ui/yudao-ui-admin-vue3

# 安装依赖（首次需执行）
pnpm install

# 如 pnpm 提示 IGNORED_BUILDS 警告，需执行：
pnpm approve-builds

# 启动开发服务器
npm run dev
```

启动成功后，前端地址为 `http://localhost:80`（或控制台显示的端口）。

### 5.5 默认账号

| 账号 | 密码 | 角色 |
|------|------|------|
| admin | admin123 | 超级管理员 |

---

## 六、日常开发流程

### 6.1 新增业务模块的标准流程

芋道框架内置了强大的**代码生成器**，可以大幅减少重复编码：

1. **设计数据库表**：在 MySQL 中创建好业务表
2. **使用代码生成器**：登录管理后台 → 基础设施 → 代码生成 → 导入表 → 生成代码
3. **导入生成的代码**：将生成的 Controller/Service/DAO/VO 代码放到对应模块目录
4. **配置菜单权限**：在系统管理 → 菜单管理中添加对应页面的菜单项

### 6.2 模块的分层架构

每个业务模块遵循统一的分层结构：

```
yudao-module-xxx/
├── yudao-module-xxx-api/           # API 层（对外暴露的 VO、枚举、常量）
└── yudao-module-xxx-server/        # 实现层
    └── src/main/java/.../module/xxx/
        ├── controller/admin/       # RESTful 接口（管理后台）
        ├── service/                # 业务逻辑层
        ├── dal/                    # 数据访问层
        │   ├── dataobject/         #   DO（数据库实体）
        │   └── mysql/              #   Mapper 接口
        └── framework/              # 模块级配置和扩展
```

### 6.3 前端页面开发

前端项目基于 Vue 3 + Element Plus，页面文件位于 `yudao-ui-admin-vue3/src/views/` 目录下，按模块组织。代码生成器同样会生成对应的前端 Vue 页面和 API 调用文件。

---

## 七、部署指南

### 7.1 后端打包

```bash
# 在项目根目录执行
mvn clean package -Dmaven.test.skip=true

# 产物位于
yudao-server/target/yudao-server.jar
```

运行方式：
```bash
java -jar yudao-server.jar --spring.profiles.active=dev
```

### 7.2 前端打包

```bash
cd yudao-ui/yudao-ui-admin-vue3

# 生产环境打包
pnpm run build:prod

# 产物位于 dist/ 目录，部署至 Nginx
```

### 7.3 Docker 部署（前端）

前端已配置好 Docker 支持，详见项目中的 `Dockerfile` 和 `nginx.conf`。更多踩坑细节请参阅 [部署踩坑记录.md](file:///d:/mes/mes/yudao-ui/yudao-ui-admin-vue3/docs/部署踩坑记录.md)。

---

## 八、已知问题与注意事项

### 8.1 AI 模块依赖版本冲突

- Spring Cloud Alibaba 会隐式将 `spring-ai-core` 降级到 `1.0.2`，导致运行时报 `NoClassDefFoundError`
- **已修复**：在 `yudao-dependencies/pom.xml` 中显式引入了 `spring-ai-bom` 并锁定为 `1.1.8`

### 8.2 AI 多模型冲突

- `ChatClientAutoConfiguration` 要求容器中只有 1 个 `ChatModel`，但项目注册了 12 个
- **已修复**：在 `YudaoServerApplication` 启动类中通过 `excludeName` 排除了该自动装配类

### 8.3 pnpm 严格模式拦截

- pnpm 9.x 默认拦截 `esbuild` 等依赖的 postinstall 脚本
- **解决方案**：执行 `pnpm approve-builds` 将必要构建脚本加入白名单

> 更多已踩过的坑，参见 [部署踩坑记录.md](file:///d:/mes/mes/yudao-ui/yudao-ui-admin-vue3/docs/部署踩坑记录.md)

---

## 九、与数字化转型战略的衔接

### 第一阶段（0-3 个月）：打通孤岛，跑通 MVP

| 任务 | 依赖的项目能力 | 负责模块 |
|------|-------------|---------|
| 德米萨 ERP 数据导出自动化 | Python 脚本 / RPA + MES 数据导入接口 | `yudao-module-mes` (md) |
| 工单下发与车间报工 | 生产工单 + 生产任务 + 报工反馈 | `yudao-module-mes` (pro) |
| 单条产线试点 | 工位管理 + 排班日历 | `yudao-module-mes` (md + cal) |

### 第二阶段（3-6 个月）：完善 MES，深化应用

| 任务 | 依赖的项目能力 | 负责模块 |
|------|-------------|---------|
| 物料管控 & 扫码追溯 | 条码/批次/SN + 入库/出库/领料 | `yudao-module-mes` (wm) |
| 质量检验全链路 | IQC/IPQC/OQC + 检验模板 | `yudao-module-mes` (qc) |
| 审批流线上化 | 工作流引擎 | `yudao-module-bpm` |
| 技术文档知识库 | 文档管理 + 权限控制 | `yudao-module-pms` (kb) |

### 第三阶段（半年以后）：引入 AI，赋能提效

| 任务 | 依赖的项目能力 | 负责模块 |
|------|-------------|---------|
| AI 智能排产助手 | 大模型 API + MES 工单数据 | `yudao-module-ai` + `mes` |
| AI 技术客服 | 大模型 RAG + 知识库语料 | `yudao-module-ai` + `pms/kb` |
| AI 数据分析 | 大模型 + 数据库直连 | `yudao-module-ai` |

---

## 十、常用命令速查

```bash
# 后端全量编译
mvn clean install -Dmaven.test.skip=true

# 后端单独编译 yudao-server（含依赖模块）
mvn clean package -Dmaven.test.skip=true -pl yudao-server -am

# 前端安装依赖
pnpm install

# 前端开发模式
npm run dev

# 前端生产打包
pnpm run build:prod

# 查看 Maven 依赖树（排查冲突）
mvn dependency:tree -Dincludes=org.springframework.ai
```

---

*文档维护人：开发部*
*最后更新：2026-09-09*
