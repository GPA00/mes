# MySQL 初始化脚本目录 (docker/mysql/init/)

## 作用与说明
本目录挂载至 MySQL 容器的 `/docker-entrypoint-initdb.d/` 目录。

> [!IMPORTANT]
> **官方 MySQL 容器运行规则**：
> 1. **首次拉起系统**（即 `docker/mysql/data/` 目录为空时），MySQL 容器会自动按文件名升序执行此目录下的所有 `.sql` 脚本，完成数据库和最新表结构的自动创建。
> 2. **后续日常运行**（即 `docker/mysql/data/` 已有数据后），容器启动时会**永久跳过**此目录，直接读写本地磁盘数据，绝对不会覆盖或损坏已有的生产数据。

---

## 现有已修改 MySQL 表结构导入指南

你当前在本地已经对 MES 的表结构和数据做过了修改。为了将最新结构纳入编排，请按以下步骤导出：

### 1. 从现有本地 MySQL 导出全量 SQL
在终端（或 CMD）中执行以下命令（将现有修改后的数据库导出）：

```bash
# Windows / Linux 推荐导出命令 (务必使用 -r 参数，避免 Windows 重定向 > 导致的 UTF-16LE 乱码问题)：
mysqldump -u root -p --default-character-set=utf8mb4 --hex-blob --databases ruoyi-vue-pro -r "docker/mysql/init/01-ruoyi-vue-pro.sql"
```
*(输入你的本地数据库密码即可)*

### 2. 放置到本目录
将导出的 `01-ruoyi-vue-pro.sql` 文件直接粘贴存放在本目录（`docker/mysql/init/`）下：
```text
docker/mysql/init/
├── README.md
└── 01-ruoyi-vue-pro.sql    <--- 将导出的 SQL 文件放这里
```

在执行 `docker compose up -d` 首次拉起容器时，全新的 MySQL 实例就会自动完整导入你所定制的最新表结构！
