# 德米萨 ERP 与自研 MES 数据孤岛打通落地方案

**文档版本**：v1.0  
**适用对象**：系统架构师、全栈开发人员、数字化项目负责人  
**最后更新**：2026年9月  
**核心目标**：在不依赖外部厂商配合、防范外部接口漫天要价与推诿的前提下，打通封闭的德米萨 ERP 系统，实现生产数据双向流通，并具备面向未来无缝接入官方 WebService 的扩展架构。

---

## 一、 项目背景与设计原则

### 1.1 现状与痛点
*   **ERP 现状**：公司运行的“德米萨 ERP”承载着客户订单、采购进销存和财务基础数据，但系统封闭，缺乏现成的开放 API，车间现场排产依赖人工导出 Excel，数据流通严重滞后。
*   **合作不确定性**：向德米萨官方索要 WebService 接口可能面临**高额接口开发费（数万元）**、**技术响应周期漫长（数月）**甚至**老旧版本无法提供**的风险。
*   **核心挑战**：既要在**零外部支持**的情况下立刻把车间数据流跑通，又不能写死逻辑，一旦未来官方接口就绪，必须能**平滑切换、零业务重构**。

### 1.2 核心设计原则
1.  **防御性解耦（防腐层模式）**：MES 业务层绝对不与具体的 ERP 抓取技术（读数据库、读 Excel 或调用 WebService）强绑定。
2.  **渐进式演进**：以“局域网底库只读直连”为主打方案先行破局，以“Excel/RPA 文件监听”作为极限兜底，以“标准 WebService 客户端”作为未来升级路径。
3.  **生产与财务安全第一**：严禁未经官方许可向 ERP 底层数据库执行 `INSERT/UPDATE` 操作，数据回传严格采用受控机制。

---

## 二、 顶层架构：防腐层（ACL）与适配器设计

系统在 MES 后端（Spring Boot）抽象出统一的 **ERP 适配防腐层**。MES 的工单模块、报工模块、大屏模块只与 `ErpSyncService` 交互，完全不知道数据从何而来。

```
                              ┌──────────────────────────────────────────────┐
                              │          MES 核心业务层 (Yudao MES)           │
                              │  工单排产 / 工位扫码 / 一机一码SN / 报工看板   │
                              └──────────────────────┬───────────────────────┘
                                                     │ 依赖注入通用接口
                                                     ▼
                              ┌──────────────────────────────────────────────┐
                              │         ERP 防腐层 (ErpSyncService)          │
                              │  syncMaterials() / syncOrders() / feedback() │
                              └──────┬───────────────┼───────────────┬───────┘
                                     │               │               │
               ┌─────────────────────┴──┐    ┌───────┴────────┐   ┌──┴─────────────────────┐
               ▼                        ▼    ▼                ▼   ▼                        ▼
   ┌───────────────────────┐ ┌───────────────────────┐ ┌───────────────────────┐
   │ 适配器 A: DB 只读直连  │ │ 适配器 B: Excel/RPA   │ │ 适配器 C: 官方 WebService│
   │ (当前主推·无需厂商配合)│ │ (极限兜底·零代码侵入) │ │ (未来升级·标准协议接入)│
   └───────────────────────┘ └───────────────────────┘ └───────────────────────┘
```

通过配置驱动适配器切换（`application.yml`）：
```yaml
erp:
  # 可选模式: direct-db (数据库直连) | excel-file (Excel/RPA监听) | webservice (官方接口)
  adapter-type: direct-db
  direct-db:
    url: jdbc:mysql://192.168.1.X:3306/demisa_erp?useSSL=false&serverTimezone=Asia/Shanghai
    username: mes_sync_readonly
    password: ${ERP_DB_PASSWORD:MesSync@2026}
  excel-file:
    watch-dir: /data/erp_exchange/inbox
  webservice:
    wsdl-url: http://192.168.1.X:8080/services/ErpService?wsdl
```

---

## 三、 核心数据流通全景与业务权责边界

必须牢固确立**“ERP 管进销存与财务，MES 管车间工艺与制造执行”**的边界：

| 业务分类 | 数据实体 | 流向 | 传输频率 / 触发条件 | 关键字段 |
| :--- | :--- | :---: | :--- | :--- |
| **物料主数据** | 伺服电机零部件、编码、规格、单位 | **ERP ➔ MES** | 每日凌晨定时增量拉取 | `material_code`, `name`, `spec`, `unit`, `update_time` |
| **BOM 清单** | 伺服产品装配结构、子件定额 | **ERP ➔ MES** | 定时拉取或变更触发 | `parent_code`, `child_code`, `qty`, `version` |
| **生产订单** | 销售订单生成的生产任务单 | **ERP ➔ MES** | 每 15~30 分钟近实时拉取 | `order_no`, `product_code`, `plan_qty`, `plan_date`, `status` |
| **生产领料** | 车间工位扫码扣料 | **MES ➔ ERP** | 工位领料扫码确认后 | `order_no`, `material_code`, `actual_qty`, `operator` |
| **完工入库** | 终检测试合格、绑定 SN 码的成品 | **MES ➔ ERP** | 成品包装下线扫码后 | `order_no`, `product_code`, `sn_list`, `qualified_qty` |

---

## 四、 三套实现方案深度技术细则

### 4.1 方案 A（当前主推）：局域网底库只读直连（Read-Only DB）

德米萨 ERP 通常采用本地 MySQL 架构（部署于厂区老 Win7 电脑中）。只要有局域网物理访问权限，这是**成本最低、稳定性最高、数据最实时**的方案。

#### 1. 德米萨主机安全加固与只读授权
在德米萨运行的 MySQL 中建立专用的只读用户，严禁写权限：
```sql
-- 仅开放物料、订单、BOM 关联表的查询权限
CREATE USER 'mes_sync_readonly'@'192.168.1.%' IDENTIFIED BY 'MesSync@2026';
GRANT SELECT ON demisa_erp.goods TO 'mes_sync_readonly'@'192.168.1.%';
GRANT SELECT ON demisa_erp.orders TO 'mes_sync_readonly'@'192.168.1.%';
GRANT SELECT ON demisa_erp.bom TO 'mes_sync_readonly'@'192.168.1.%';
FLUSH PRIVILEGES;
```

#### 2. MES 端增量抽取机制（Watermark 水位线算法）
为防范全量拉取给老 Win7 电脑带来 CPU 负载，采用**时间戳增量抽取**：
*   MES 本地维护一张同步记录表 `mes_erp_sync_log`，记录上一次同步的最大更新时间戳 `last_sync_time`；
*   抽取 SQL 模板：
    ```sql
    SELECT id, goods_no, goods_name, spec, unit, update_time 
    FROM demisa_erp.goods 
    WHERE update_time >= #{lastSyncTime} 
    ORDER BY update_time ASC 
    LIMIT 500;
    ```
*   落入 MES 中间暂存表，清洗字段后更新 MES 物料档案。

---

### 4.2 方案 B（极限兜底）：Python RPA / Excel 自动监听管道

若无法获取数据库访问权限，启动文件交换管道：

```
┌─────────────────────────┐
│ 德米萨 ERP 客户端        │
│ (人工导出 / Python 模拟)│
└────────────┬────────────┘
             │ 导出 .xlsx
             ▼
┌─────────────────────────┐
│ 局域网共享热文件夹 (NAS) │ ───► [WatchService 自动感知新文件]
│ \\192.168.1.X\erp_sync  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│ MES 后端解析与数据校验  │ ───► 校验失败 ──► 企微/钉钉机器人标红预警
│ (Alibaba EasyExcel 异步)│ ───► 校验成功 ──► 写入 MES 工单库并归档 Excel
└─────────────────────────┘
```

1. **热文件夹监听**：MES 后端通过 Java NIO `WatchService` 或 Spring 定时轮询监控指定目录；
2. **容错机制**：
   *   文件未完全写完时的冲突锁检测（检测文件大小连续 3 秒不变后再读取）；
   *   导入历史 MD5 去重校验，防止重复处理同一个文件；
   *   处理完毕后将文件移动至 `archive/` 备份目录，出错则移动至 `error/` 目录并触发告警。

---

### 4.3 方案 C（面向未来）：官方 WebService / OpenAPI 接入

当未来取得德米萨官方 WebService 接口文档（WSDL 地址与鉴权 Token）时，通过以下步骤接入：

1. **客户端构建**：使用轻量级工具（如 Hutool `SoapClient`）或 Apache CXF 动态客户端调用，无需繁琐的代码生成：
   ```java
   SoapClient client = SoapClient.create("http://192.168.1.X:8080/services/ErpService?wsdl")
       .setMethod("getProductionOrders")
       .setParam("token", "DemisaSecretToken")
       .setParam("beginTime", lastSyncTimeStr);
   String responseXml = client.send();
   ```
2. **异步补偿机制（Outbox Pattern）**：
   *   任何 MES 回传 ERP 的 WebService 调用，均先记录到 `mes_outbox_message` 表；
   *   通过后台守护线程异步推送，支持指数退避重试（10s, 30s, 2m）；
   *   连续 3 次失败自动标记为人工处理，保障现场工位扫码不因 ERP 接口缓慢而卡顿。

---

## 五、 数据逆向回写 ERP 的安全防护机制

> [!CAUTION]
> **红线原则**：在没有官方数据库字典与存储过程文档的前提下，**绝对禁止直接用 SQL 往德米萨数据库 INSERT/UPDATE 财务与库存数据！** 否则一旦导致 ERP 账实不符、出入库成本加权平均计算错乱，将引发重大责任事故。

### 5.1 受控回写三级策略

```
┌─────────────────────────────────────────────────────────────┐
│              车间终检合格 / 伺服电机包装扫码入库              │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│          生成 MES 待过账单据 (MesErpPendingPost)            │
└──────────────────────────────┬──────────────────────────────┘
                               │
        ┌──────────────────────┴──────────────────────┐
        ▼                                             ▼
【模式 1：无官方 API 时】                       【模式 2：官方 WebService 具备时】
自动生成《标准完工入库表.xlsx》                   后台自动调 API 提交 ERP 草稿单据
仓库管理员在德米萨一键“批量导入”                  ERP 系统内部审核流校验通过
(由业务人员终审，规避开发责任)                    (全自动化流通，零人工介入)
```

1. **无接口时期（半自动防错）**：MES 每天下午 17:00 自动汇总结算，生成完全匹配德米萨 ERP 导入模板的 Excel。仓管员核对无误后在 ERP 界面点击“导入数据”。**既为仓管节省了 90% 的手打时间，又将数据审核责任留在业务部门。**
2. **有接口时期（全自动流通）**：通过 WebService 生成 ERP 的**“待审核出入库单”**，不直接操作生效状态，保留财务或车间主任在 ERP 内点击“确认审核”的操作节点。

---

## 六、 落地代码架构示例（Spring Boot）

### 6.1 定义防腐层接口
```java
public interface ErpSyncService {
    /** 增量拉取物料主数据 */
    List<ErpMaterialDTO> syncMaterials(LocalDateTime lastSyncTime);
    
    /** 增量拉取生产计划/工单 */
    List<ErpProductionOrderDTO> syncProductionOrders(LocalDateTime lastSyncTime);
    
    /** 完工入库回传/反馈 */
    ErpFeedbackResult feedbackFinishedGoods(ErpFinishedGoodsDTO finishedGoodsDTO);
}
```

### 6.2 数据库直连实现（方案 A）
```java
@Slf4j
@Service
@ConditionalOnProperty(name = "erp.adapter-type", havingValue = "direct-db", matchIfMissing = true)
public class DirectDbErpAdapter implements ErpSyncService {

    @Resource(name = "erpDataSource")
    private DataSource erpDataSource;

    @Override
    public List<ErpProductionOrderDTO> syncProductionOrders(LocalDateTime lastSyncTime) {
        log.info("【ERP同步-DB模式】开始从德米萨数据库增量拉取工单，水位线: {}", lastSyncTime);
        // 使用 JdbcTemplate 查询只读从库，字段映射转为 DTO
        // ...
        return Collections.emptyList();
    }

    @Override
    public ErpFeedbackResult feedbackFinishedGoods(ErpFinishedGoodsDTO finishedGoodsDTO) {
        log.info("【ERP同步-DB模式】生成本地待导入中转单: {}", finishedGoodsDTO.getOrderNo());
        // 落地到本地中转表，等待导出为德米萨 Excel 模板
        return ErpFeedbackResult.success("已生成待导入单据");
    }
}
```

---

## 七、 实施推进排期表（1~2周落地闭环）

| 阶段 | 周期 | 核心工作内容 | 关键交付物 |
| :--- | :--- | :--- | :--- |
| **第一步：现场调研与摸底** | Day 1 ~ Day 2 | 1. 登录老 Win7 电脑，确认德米萨安装路径及数据库端口；<br>2. 验证 Navicat/DBeaver 能否内网只读连通；<br>3. 梳理物料表、BOM表、订单表字段映射字典。 | 《德米萨 ERP-MES 字段映射表》 |
| **第二步：MES 适配层搭建** | Day 3 ~ Day 4 | 1. 在 MES 中创建 `erp-integration` 适配层与中间表；<br>2. 配置第二数据源（只读），实现物料主数据定时同步；<br>3. 实现增量水位线（Watermark）同步调度任务。 | `ErpSyncService` 基础代码与同步定时任务 |
| **第三步：生产订单拉取试点** | Day 5 ~ Day 7 | 1. 实现德米萨生产订单自动拉取并转换为 MES 工单；<br>2. 在 MES 界面上展示第一批从 ERP 流转过来的真实工单；<br>3. 向车间主任演示“无需重复录单”的便利性。 | MES 界面自动呈现 ERP 生产工单 |
| **第四步：完工回写与闭环** | Day 8 ~ Day 10 | 1. 跑通装配质检扫码完成后的完工汇总；<br>2. 自动生成德米萨标准入库导入 Excel；<br>3. 协调仓管员完成首次批量导入闭环验证。 | 生产全流程数据流转闭环 |
| **第五步：向老板成果汇报** | Day 11 | 结合车间 GoView 大屏，向管理层展示从“ERP 订单拉取 ➔ 车间扫码 ➔ 大屏实时跳动”的完整数字化闭环。 | 数字化转型首期里程碑汇报 |
