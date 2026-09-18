-- ===================================================================
-- 管状直线电机试点主力机型【物料主数据、多级 BOM 与防腐映射初始化脚本】
-- 数据库: ruoyi-vue-pro (端口: 3307)
-- 
-- 业务背景与依据：
--   1. 试点单品：SSD0608H-145L（老 ERP 账面负库存 -10,289 套之全厂出货第一主力）
--   2. 工艺依据：《0608管状电机制作流程及注意事项.xlsx》（动子 7 步 SOP + 定子穿磁外协机加）
--   3. 对应产品架构：
--      - 产成品整机: 管状直线电机整机 (PRD-SSD0608H-145L)
--      - 自制半成品: 管状电机动子总成 (SEM-MOV-SSD0608H)
--      - 自制半成品: 管状电机定子磁轴 (SEM-STA-SS06-145L)
--      - 动子子件: 铝外壳、线圈(薄/厚)、端盖、螺丝、电机引线、套管、AB胶、高温胶带、玻璃胶、环氧灌封胶
--      - 定子子件: 精密钢管、端子堵头、环形强磁钢、瞬干胶 (后道转外协精磨机加)
-- ===================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------
-- 0. 创建独立防腐映射表 (mes_md_item_mapping)，保持核心主表 100% 领域纯洁
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mes_md_item_mapping` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `item_id` bigint NOT NULL COMMENT 'MES内部标准物料主键 (关联 mes_md_item.id)',
  `system_type` varchar(32) NOT NULL COMMENT '外部系统标识 (如: DEMISA_ERP, SAP, PLM, CUSTOMER)',
  `external_code` varchar(64) NOT NULL COMMENT '外部系统编码/图号',
  `external_name` varchar(255) DEFAULT NULL COMMENT '外部系统原始品名描述',
  `is_primary` tinyint NOT NULL DEFAULT '1' COMMENT '是否为主映射 (处理历史一物多码)',
  `remark` varchar(500) DEFAULT NULL COMMENT '映射清洗备注',
  `creator` varchar(64) DEFAULT 'admin' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT 'admin' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_system_ext_code` (`system_type`, `external_code`),
  KEY `idx_item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='物料异构系统防腐映射表';


-- -------------------------------------------------------------------
-- 1. 注入 SSD0608H-145L 系列物料主数据 (mes_md_item)
-- -------------------------------------------------------------------
INSERT INTO `mes_md_item` (
  `id`, `code`, `name`, `specification`, `unit_measure_id`, `item_type_id`, 
  `status`, `safe_stock_flag`, `min_stock`, `max_stock`, `high_value`, `batch_flag`, 
  `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  -- 1.1 产成品整机 (分类 30131: 直线电机整机, 单位 202: PCS/套)
  (5101, 'PRD-SSD0608H-145L', '管状直线电机', 'SSD0608H-145L (整套配对)', 202, 30131, 
   0, 0, 0, 0, 1, 1, '全厂第一主力机型：外径8mm/行程85mm/总长145mm，动定子成套整机，用于冲抵老ERP万台负库存', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 1.2 自制半成品组件 (分类 2011: 动子总成 / 2012: 定子磁轨)
  (5102, 'SEM-MOV-SSD0608H', '管状电机动子', 'SSD0608H', 202, 2011, 
   0, 0, 0, 0, 1, 1, '动子总成：铝壳+12线圈(7薄5厚)+引出线+三次真空灌胶成型+端盖修平', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5103, 'SEM-STA-SS06-145L', '管状电机定子', 'SS06-145L', 202, 2012, 
   0, 0, 0, 0, 1, 1, '定子磁轴：精密钢管Φ6*145L+钕铁硼强磁+瞬干胶定位，经外协无心磨精磨成型', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 1.3 动子端原材料及辅料 (ITEM)
  (5104, 'MAT-WJ-CASE-0608', '外壳', 'Φ8 动子铝合金外壳 (SSD0608H专用)', 202, 1034, 
   0, 0, 0, 0, 0, 0, '动子铝机壳，SOP检查无划伤、磕碰与变形', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5105, 'MAT-DQ-COIL-0608T', '线圈(薄)', 'Φ6系列自粘铜漆包线圈 薄型 (5.8~5.9mm)', 202, 1021, 
   0, 0, 0, 0, 0, 1, 'SOP步骤一原料：每套动子用量7个，管控批次与线圈阻抗', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5106, 'MAT-DQ-COIL-0608H', '线圈(厚)', 'Φ6系列自粘铜漆包线圈 厚型 (6.0mm)', 202, 1021, 
   0, 0, 0, 0, 0, 1, 'SOP步骤一原料：每套动子用量5个，三薄三厚三薄二厚一薄顺序排布', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5107, 'MAT-WJ-CAP-0608', '端盖', 'Φ8 动子前后端盖副 (含顶部绕线端盖)', 202, 1034, 
   0, 0, 0, 0, 0, 0, '动子铝端盖/副，装配需绕线一圈防脱', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5108, 'MAT-WJ-SCREW-M1', '紧固螺丝', '微型端盖专用紧固螺钉', 202, 1037, 
   0, 0, 0, 0, 0, 0, '端盖配对紧固螺丝，SOP防呆严防螺丝压到线圈或打深打浅', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5109, 'MAT-DQ-WIRE-3C', '电机引线', '耐高温超柔三色电机线 (红/黄/白 3色组)', 204, 1023, 
   0, 0, 0, 0, 0, 0, '动力三相引出线，按米计量，红(3/6/9/12)、黄(2/5/8/11)、白(1/4/7/10)', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5110, 'MAT-JC-TUBE-HEAT', '热缩套管', '黑色绝缘阻燃微型热缩管', 204, 1042, 
   0, 0, 0, 0, 0, 0, '引线焊点绝缘包裹套管，按米计量，SOP防呆必须完全包裹焊点', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5111, 'MAT-HG-GLUE-AB', 'A/B胶', '线圈糊制点涂定位胶水 (A/B组份)', 200, 1041, 
   0, 1, 1.0, 10.0, 0, 1, 'SOP步骤一辅料：点涂固定线圈，严禁涂满，控制总长71.5~72mm', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5112, 'MAT-HG-GLUE-GLASS', '玻璃胶', '端部出线孔密封固定玻璃胶', 200, 1041, 
   0, 1, 1.0, 10.0, 0, 1, 'SOP步骤四辅料：固定端部出线孔，关键防呆防止灌胶漏胶', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5113, 'MAT-HG-GLUE-EP06', '环氧灌封胶', '黑色电子灌封环氧树脂 (黑白胶 1:1.1)', 200, 1041, 
   0, 1, 5.0, 50.0, 0, 1, 'SOP步骤五原料：三次灌胶成型，按KG管控保质期', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5114, 'MAT-CL-TAPE-HIGH', '高温胶带', '线圈分组绝缘耐高温胶带', 204, 1053, 
   0, 0, 0, 0, 0, 0, 'SOP步骤二辅料：分组线圈绝缘包裹，防高压不过', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 1.4 定子端原材料及辅料 (ITEM)
  (5115, 'MAT-WJ-PIPE-06-145', '钢管', '精密无缝不锈钢管 Φ6*145mm', 202, 1036, 
   0, 0, 0, 0, 0, 1, '定子磁轴精密外管，微米级直线度，管控来料批次', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5116, 'MAT-WJ-PLUG-06', '端子', 'Φ6 磁轴两端密封堵头端子', 202, 1035, 
   0, 0, 0, 0, 0, 0, '定子钢管两端密封及安装端子', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5117, 'MAT-WJ-MAG-06', '磁钢', 'Φ6 环形钕铁硼强磁体 (N48H/N52)', 202, 1032, 
   0, 0, 0, 0, 1, 1, '定子钕铁硼强磁环，高价值物料(high_value=1)，强制管控批次与表磁', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (5118, 'MAT-HG-GLUE-SG01', '瞬干胶', '磁轴穿磁点胶定位瞬干胶 (401/406)', 200, 1041, 
   0, 1, 0.5, 10.0, 0, 1, '定子穿磁专用快干胶水，秒级定位防强磁相斥反弹，按KG/支管控', 'admin', NOW(), 'admin', NOW(), 0, 1)

ON DUPLICATE KEY UPDATE 
  `code` = VALUES(`code`),
  `name` = VALUES(`name`),
  `specification` = VALUES(`specification`),
  `unit_measure_id` = VALUES(`unit_measure_id`),
  `item_type_id` = VALUES(`item_type_id`),
  `status` = 0,
  `batch_flag` = VALUES(`batch_flag`),
  `high_value` = VALUES(`high_value`),
  `remark` = VALUES(`remark`),
  `deleted` = 0;


-- -------------------------------------------------------------------
-- 2. 注入多级制造 BOM 结构 (mes_md_product_bom)
-- -------------------------------------------------------------------
DELETE FROM `mes_md_product_bom` WHERE `item_id` IN (5001, 5002, 5003, 5101, 5102, 5103);

INSERT INTO `mes_md_product_bom` (
  `id`, `item_id`, `bom_item_id`, `quantity`, `status`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  -- 2.1 产成品整机 (5101: PRD-SSD0608H-145L) BOM：成套配对出厂
  (6101, 5101, 5102, 1.0000, 0, '管状电机动子总成 SSD0608H 1个', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6102, 5101, 5103, 1.0000, 0, '管状电机定子磁轴 SS06-145L 1根', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 2.2 半成品动子总成 (5102: SEM-MOV-SSD0608H) BOM：车间 7 步装配灌封线
  (6111, 5102, 5104, 1.0000, 0, '动子铝外壳 1个', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6112, 5102, 5105, 7.0000, 0, '薄线圈(5.8~5.9mm) 7个 [SOP步骤一: 7薄]', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6113, 5102, 5106, 5.0000, 0, '厚线圈(6.0mm) 5个 [SOP步骤一: 5厚]', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6114, 5102, 5107, 2.0000, 0, '前后端盖 各1个(共2个)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6115, 5102, 5108, 4.0000, 0, '端盖紧固螺丝 4颗', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6116, 5102, 5109, 0.3000, 0, '超柔三色电机引线 0.3米', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6117, 5102, 5110, 0.0500, 0, '黑色绝缘热缩套管 0.05米', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6118, 5102, 5111, 0.0020, 0, '线圈糊制定位 A/B 胶 0.002 KG (2克)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6119, 5102, 5114, 0.1000, 0, '线圈分组绝缘高温胶带 0.1米', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6120, 5102, 5112, 0.0010, 0, '出线孔密封玻璃胶 0.001 KG (1克)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6121, 5102, 5113, 0.0150, 0, '黑色环氧灌封胶 0.015 KG (15克)', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 2.3 半成品定子磁轴 (5103: SEM-STA-SS06-145L) BOM：穿轴定位 ➔ 外协精磨
  (6131, 5103, 5115, 1.0000, 0, '精密不锈钢管 1根 (Φ6*145mm)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6132, 5103, 5116, 2.0000, 0, '密封端子堵头 2个 (两端)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6133, 5103, 5117, 16.0000, 0, 'Φ6 钕铁硼环形强磁体 16个 (高价值管控)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (6134, 5103, 5118, 0.0020, 0, '穿磁定位瞬干胶 0.002 KG (2克)', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- -------------------------------------------------------------------
-- 3. 注入老 ERP 防腐映射数据 (mes_md_item_mapping)
-- -------------------------------------------------------------------
DELETE FROM `mes_md_item_mapping` WHERE `system_type` = 'DEMISA_ERP' AND `external_code` IN ('SSD0608H-145L', 'SSD0608H', 'SS06-145L');

INSERT INTO `mes_md_item_mapping` (
  `item_id`, `system_type`, `external_code`, `external_name`, `is_primary`, `remark`, `creator`, `create_time`, `updater`, `update_time`
) VALUES
  (5101, 'DEMISA_ERP', 'SSD0608H-145L', '管状电机 SSD0608H-145L (整机)', 1, '德米萨ERP历史负库存 -10,289 套之主力冲销型号', 'admin', NOW(), 'admin', NOW()),
  (5102, 'DEMISA_ERP', 'SSD0608H', '管状电机动子 SSD0608H', 1, '动子自制半成品映射 (ERP原始对应物料)', 'admin', NOW(), 'admin', NOW()),
  (5103, 'DEMISA_ERP', 'SS06-145L', '管状电机定子 SS06-145L', 1, '定子自制磁轴映射 (ERP原始对应物料)', 'admin', NOW(), 'admin', NOW());

SET FOREIGN_KEY_CHECKS = 1;


-- -------------------------------------------------------------------
-- 4. 执行自检验证查询语句
-- -------------------------------------------------------------------
SELECT 
  p.code AS '产成品/半成品编码',
  p.name AS '品名',
  p.specification AS '型号规格',
  b.quantity AS '子件用量',
  c.code AS '子件物料编码',
  c.name AS '子件名称',
  c.specification AS '子件规格',
  b.remark AS '工艺控制要点说明'
FROM mes_md_product_bom b
JOIN mes_md_item p ON b.item_id = p.id
JOIN mes_md_item c ON b.bom_item_id = c.id
ORDER BY b.item_id, b.id;
