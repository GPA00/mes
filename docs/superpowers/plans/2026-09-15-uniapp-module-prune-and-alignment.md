# Yudao Admin Uniapp 模块裁撤与架构对齐实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `yudao-ui-admin-uniapp` 按照 `yudao-ui-admin-vue3` 的现存业务模块进行裁剪与重构，物理删除 9 个非当前业务分包与 API，注释化解耦构建与路由配置，并在首页工作台实现黑名单过滤。

**Architecture:** 
1. 物理删除无用业务包与 API，阻断死代码与无用体积；
2. 构建配置（Vite subPackages）与 BPM 路径采用代码注释保留，维持可逆性；
3. 首页工作台（`menu.json` + `index.ts`）采用黑名单常量拦截，零改动 JSON 文件实现解耦。

**Tech Stack:** Vue 3, Uni-app, Vite, TypeScript, Pinia, Wot UI

**Spec:** [docs/superpowers/specs/2026-09-15-uniapp-module-prune-and-alignment-design.md](file:///d:/mes/mes/docs/superpowers/specs/2026-09-15-uniapp-module-prune-and-alignment-design.md)

## Global Constraints
- 裁撤模块列表固定为 9 个：`crm`、`erp`、`fms`、`hrm`、`im`、`iot`、`mall`、`member`、`pay`
- 保留核心模块：`system`、`infra`、`bpm`、`mes`、`wms`、`ai`、`mp`、`pages-core`
- 配置文件（`vite.config.ts`、`bpm/utils/index.ts`）只能注释，严禁直接删除配置行
- `menu.json` 保持格式与内容不动，通过 `index.ts` 逻辑过滤

---

### Task 1: 物理删除 9 个业务分包与对应 API 目录

**Files:**
- Delete:
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-crm`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-erp`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-fms`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-hrm`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-im`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-iot`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-mall`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-member`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-pay`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/crm`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/erp`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/fms`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/hrm`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/im`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/iot`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/mall`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/member`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/api/pay`

- [ ] **Step 1: 执行分包目录物理删除**
使用 powershell `Remove-Item -Recurse -Force` 删除 9 个 `pages-*` 目录。

- [ ] **Step 2: 执行 API 目录物理删除**
使用 powershell `Remove-Item -Recurse -Force` 删除 9 个 `api/*` 目录。

- [ ] **Step 3: 验证目录已清除**
验证 `src` 下不再包含被删的 `pages-*` 和 `api/*` 目录。

---

### Task 2: 精简统计中心（`pages-statistics`）子目录

**Files:**
- Delete:
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-statistics/crm`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-statistics/erp`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-statistics/fms`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-statistics/hrm`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-statistics/im`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-statistics/iot`
  - `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-statistics/mall`
- Preserve:
  - `src/pages-statistics/mes`
  - `src/pages-statistics/wms`
  - `src/pages-statistics/infra`
  - `src/pages-statistics/mp`
  - `src/pages-statistics/components`
  - `src/pages-statistics/utils`

- [ ] **Step 1: 删除已废弃模块的统计子页面**
使用 powershell 删除 `pages-statistics` 下的 `crm`, `erp`, `fms`, `hrm`, `im`, `iot`, `mall` 目录。

- [ ] **Step 2: 验证保留的统计目录完整性**
确认 `mes`, `wms`, `infra`, `mp`, `components`, `utils` 完好无损。

---

### Task 3: 注释化更新构建配置与审批路由映射

**Files:**
- Modify: `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/vite.config.ts`
- Modify: `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages-bpm/utils/index.ts`

- [ ] **Step 1: 注释 `vite.config.ts` 中的 `subPackages` 与 `UniKuRoot`**
在 `vite.config.ts` 中，将 `pages-crm`, `pages-iot`, `pages-member`, `pages-pay`, `pages-mall`, `pages-im`, `pages-erp`, `pages-hrm`, `pages-fms` 的声明行添加 `//` 注释，保留中文注释和路径。
将 `UniKuRoot` 中的 `'src/pages-crm/statistics/**'` 改为 `// 'src/pages-crm/statistics/**',`。

- [ ] **Step 2: 注释 `pages-bpm/utils/index.ts` 中的 CRM 表单映射**
将 `PC_TO_MOBILE_PATH_MAP` 中的 CRM 合同与回款映射添加 `//` 注释。

---

### Task 4: 工作台菜单（`index.ts`）黑名单过滤

**Files:**
- Modify: `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src/pages/index/index.ts`

- [ ] **Step 1: 在 `index.ts` 中声明 `DISABLED_MODULE_KEYS` 黑名单常量**
```ts
/**
 * 暂未启用的业务模块黑名单（注释相应项即可恢复展示）
 */
export const DISABLED_MODULE_KEYS = [
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

- [ ] **Step 2: 在 `getMenuGroups()` 中加入黑名单过滤**
在循环遍历 `groupsData` 时：
```ts
    if (DISABLED_MODULE_KEYS.includes(group.key)) {
      continue
    }
```

---

### Task 5: 静态引用检测与验证

**Files:**
- Inspect all files under `d:/mes/mes/yudao-ui/yudao-ui-admin-uniapp/src`

- [ ] **Step 1: 全局排查死引用**
使用 ripgrep 检查是否存在对已删除分包 (`pages-crm`, `api/erp` 等) 的非注释引用。

- [ ] **Step 2: 验证 TypeScript 语法与编译完整性**
确保所有保留模块正常编译，没有任何损坏的导入。
