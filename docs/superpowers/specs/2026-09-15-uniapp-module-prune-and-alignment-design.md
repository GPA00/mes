# Yudao Admin Uniapp 模块裁撤与架构对齐设计文档 (2026-09-15)

## 1. 背景与目标

当前项目作为智能制造 MES 落地工程，管理端前端包含两个工程：
- PC 端管理后台：`yudao-ui-admin-vue3`
- 移动/PDA 端后台：`yudao-ui-admin-uniapp`

在前期开发和沉淀中，PC 端（Vue3）已经完成精简，聚焦于系统制造核心（MES、WMS、BPM、AI、系统与基础监控），裁撤了如 CRM、旧 ERP、商城、财务会计等非当前主线模块。
然而移动端工程 `yudao-ui-admin-uniapp` 仍包含大量未经清理的历史业务模块与接口定义，导致代码包袱重、分包冗余、工作台菜单杂乱且存在潜在的无效路由链接。

**重构目标**：
1. 以 `yudao-ui-admin-vue3` 的现存模块为基准，对 `yudao-ui-admin-uniapp` 进行深度瘦身与架构对齐。
2. 物理删除 9 个无用业务分包与对应的 API 目录，精简统计中心。
3. 遵循用户“配置部分仅注释，不直接删除”的原则，对构建配置与路由映射进行注释化解耦，保持未来按需恢复的能力。
4. 在工作台菜单（`menu.json` 与 `index.ts`）采用“零侵入黑名单过滤”，不修改原 JSON 格式，保持系统最低耦合度。

---

## 2. 模块精简与裁撤矩阵

### 2.1 物理删除分包（`src/pages-*`）
彻底物理删除以下 9 个分包目录：
- `src/pages-crm`（客户关系管理）
- `src/pages-erp`（老系统 ERP 业务模块）
- `src/pages-fms`（财务管理与凭证）
- `src/pages-hrm`（人力资源与薪酬）
- `src/pages-im`（IM 即时通讯）
- `src/pages-iot`（物联网与物模型）
- `src/pages-mall`（商城、分销与营销活动）
- `src/pages-member`（会员中心）
- `src/pages-pay`（移动支付与钱包）

### 2.2 物理删除接口目录（`src/api/*`）
对应物理删除以下 9 个 API 目录：
- `src/api/crm/`
- `src/api/erp/`
- `src/api/fms/`
- `src/api/hrm/`
- `src/api/im/`
- `src/api/iot/`
- `src/api/mall/`
- `src/api/member/`
- `src/api/pay/`

### 2.3 统计中心精简（`src/pages-statistics/*`）
- **物理删除**：`crm/`、`erp/`、`fms/`、`hrm/`、`im/`、`iot/`、`mall/`
- **保留并维护**：
  - `mes/`：MES 工作台与制造 KPI 监控看板
  - `wms/`：WMS 仓储库存监控看板
  - `infra/`：基础设施监控（如 Redis 缓存状态）
  - `mp/`：公众号统计看板
  - `components/` 与 `utils/`：统计通用组件与图表工具

### 2.4 最终保留的合法分包结构
1. `pages-core`：核心通用页面（登录、注册、短信登录、三方回调、404、仅 PC 访问提示）
2. `pages-mes`：制造执行核心（车间主数据、工单排产、工序路线、工位报工、安灯、质检、设备维护、排班、工装等）
3. `pages-wms`：仓储物流中心（物料分类、仓库货位、出入库单据、盘点、库存记录等）
4. `pages-bpm`：工作流协同（OA 请假、流程定义、审批待办/已办/抄送）
5. `pages-ai`：工业 AI 智能助手与知识库问答
6. `pages-statistics`：精简后的 MES/WMS/运维数据看板
7. `pages-system`：系统管理（组织架构、用户、角色、字典、操作日志、通知公告等）
8. `pages-infra`：基础设施管理（配置、定时任务、代码生成等移动端适配视图）
9. `pages-mp`：微信公众号管理

---

## 3. 配置解耦与注释化策略

### 3.1 `vite.config.ts` 构建配置
在 `subPackages` 列表中，将已被删除的 9 个分包路径以 TypeScript 单行注释 `//` 的形式保留，避免编译插件扫描不存在的目录，同时保留未来反注释直接恢复的能力：
```ts
subPackages: [
  'src/pages-core', // 这个是相对必要的路由，尽量留着（登录页、注册页、404页等）
  'src/pages-system', // “系统管理”模块
  'src/pages-infra', // “基础设施”模块
  'src/pages-bpm', // “工作流程”模块
  // 'src/pages-crm', // “客户管理”模块（已裁撤，注释保留）
  'src/pages-statistics', // “统计中心”模块
  // 'src/pages-iot', // “物联网”模块（已裁撤，注释保留）
  // 'src/pages-member', // “会员中心”模块（已裁撤，注释保留）
  // 'src/pages-pay', // “支付管理”模块（已裁撤，注释保留）
  'src/pages-mp', // “公众号管理”模块
  // 'src/pages-mall', // “商城管理”模块（已裁撤，注释保留）
  'src/pages-mes', // “生产制造”模块
  'src/pages-ai', // “人工智能”模块
  // 'src/pages-im', // “即时通讯”模块（已裁撤，注释保留）
  // 'src/pages-erp', // “ERP 管理”模块（已裁撤，注释保留）
  // 'src/pages-hrm', // “人力资源管理”模块（已裁撤，注释保留）
  // 'src/pages-fms', // “财务会计”模块（已裁撤，注释保留）
  'src/pages-wms', // “仓储管理”模块
],
```
在 `UniKuRoot` 的 `excludePages` 中：
```ts
UniKuRoot({
  excludePages: [
    '**/components/**/**.*',
    '**/sections/**/**.*',
    // 'src/pages-crm/statistics/**', // 已裁撤，注释保留
  ],
}),
```

### 3.2 审批表单路径映射 `src/pages-bpm/utils/index.ts`
在 `PC_TO_MOBILE_PATH_MAP` 中注释 CRM 相关路由，避免生成死链：
```ts
const PC_TO_MOBILE_PATH_MAP: Record<string, string> = {
  // OA 请假（同分包，内嵌）
  '/bpm/oa/leave/create': '/pages-bpm/oa/leave/create/index',
  '/bpm/oa/leave/detail': '/pages-bpm/oa/leave/detail/index',
  // CRM 合同审批（跨分包，仅详情，已裁撤，注释保留）
  // '/crm/contract/detail': '/pages-crm/contract/detail/index',
  // CRM 回款审批（跨分包，仅详情，已裁撤，注释保留）
  // '/crm/receivable/detail': '/pages-crm/receivable/detail/index',
}
```

### 3.3 工作台菜单零侵入黑名单过滤 `src/pages/index/index.ts`
- **保持 `menu.json` 原样**：不对 `menu.json` 进行任何破坏性修改或语法变更，确保 JSON 规范合法；
- **在 `src/pages/index/index.ts` 中配置黑名单常量**：
```ts
/**
 * 暂未启用的业务模块黑名单（注释即可恢复展示）
 */
const DISABLED_MODULE_KEYS = [
  'crm',      // CRM 客户管理
  'erp',      // ERP 进销存
  'fms',      // FMS 财务管理
  'hrm',      // HRM 人力资源
  'im',       // IM 即时通讯
  'iot',      // IoT 物联网
  'mall',     // 商城交易
  'member',   // 会员中心
  'pay',      // 支付管理
]
```
- **在 `getMenuGroups()` 中自动过滤**：
```ts
export function getMenuGroups(): MenuGroup[] {
  const { hasAccessByCodes } = useAccess()
  const result: MenuGroup[] = []
  for (const group of groupsData) {
    // 过滤已注销/停用的模块组
    if (DISABLED_MODULE_KEYS.includes(group.key)) {
      continue
    }
    // ... 原有二级分组与权限过滤逻辑保持不变 ...
```
- **联动效应**：
  - `getAllMenuItems()`、`getMenuItemByKey()`、`getSearchableMenus()` 会自动基于过滤后的 `getMenuGroups()` 派生；
  - 搜索结果池自动剔除被停用的模块；
  - 常用与最近访问由于具备 `.filter(Boolean)` 兜底容错，本地即使残留老缓存也不会引发异常。

---

## 4. 验证方案

1. **静态引用完整性检测**：
   - 全局搜索被裁撤模块分包名（如 `pages-crm`、`api/erp` 等），确保无保留文件出现死引用。
2. **构建与热更新验证**：
   - 验证配置修改后无 TypeScript 语法错误；
   - 检查 `subPackages` 是否正确收敛。
3. **工作台渲染测试**：
   - 启动或检查工作台初始化逻辑，确认仅显示 MES、WMS、工作流、AI、统计中心、系统设置等核心制造模块。
