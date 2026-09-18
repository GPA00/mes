-- ===================================================================
-- 管状直线电机 32 件标准流水线试产工单【全生命周期实操闭环脚本】
-- 数据库: ruoyi-vue-pro (端口: 3307)
-- 
-- 业务场景：
--   1. 产品：管状电机动子总成 SEM-MOV-SSD0608H (ID: 5102)
--   2. 批量：1 批 1 单 1 标准工装托盘 = 32 件
--   3. 流程：WH01原料齐套调拨 -> 7工位流水线PDA扫码报工 -> 物料倒冲扣减 -> FQC终检赋码 -> 产出32个一机一码SN -> 触发防腐层写回老ERP平账
-- ===================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------
-- 第一步：配置车间 7 大流水线物理工位 (mes_md_workstation)
-- -------------------------------------------------------------------
DELETE FROM `mes_md_workstation` WHERE `id` BETWEEN 501 AND 507;

INSERT INTO `mes_md_workstation` (
  `id`, `code`, `name`, `address`, `workshop_id`, `process_id`, 
  `warehouse_id`, `location_id`, `area_id`, `status`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (501, 'WS-MOV-01', '工位1：线圈糊制台', '直线电机流水线-工位01', 2, 101, 703, 731, 761, 0, '薄厚线圈卡尺初检、穿杆排序与点涂AB胶', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (502, 'WS-MOV-02', '工位2：相序分组台', '直线电机流水线-工位02', 2, 102, 703, 731, 761, 0, '区分头尾、三相红黄白分组拉线与高温胶带包裹', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (503, 'WS-MOV-03', '工位3：引线焊接台', '直线电机流水线-工位03', 2, 103, 703, 731, 761, 0, '红黄白三色超柔引线烙铁焊接与热缩套管保护', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (504, 'WS-MOV-04', '工位4：组装反测台', '直线电机流水线-工位04', 2, 104, 703, 731, 761, 0, '引线绕圈装端盖、拧螺丝、玻璃胶封孔与反电测', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (505, 'WS-MOV-05', '工位5：灌胶烘烤台', '直线电机流水线-工位05', 2, 105, 703, 731, 761, 0, '插润滑剂灌胶棍、三遍环氧黑胶灌注、烘烤1小时', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (506, 'WS-MOV-06', '工位6：修整深洁台', '直线电机流水线-工位06', 2, 106, 703, 731, 761, 0, '工业酒精深度清洁残胶、削平端盖、齐平剪裁引线', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (507, 'WS-MOV-07', '工位7：终检打标台', '直线电机流水线-工位07', 2, 107, 703, 731, 761, 0, '综合电测仪阻抗耐压测试、激光打刻一机一码出厂SN', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- -------------------------------------------------------------------
-- 第二步：WH01 原料主仓期初入库备料（确保原料齐套）
-- -------------------------------------------------------------------
DELETE FROM `mes_wm_material_stock` WHERE `batch_code` = 'BATCH-INIT-20260916';

INSERT INTO `mes_wm_material_stock` (
  `item_type_id`, `item_id`, `batch_code`, `warehouse_id`, `location_id`, `area_id`, `quantity`, `receipt_time`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (30111, 5104, 'BATCH-INIT-20260916', 701, 716, 751, 500.0000, NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 外壳 500个
  (30112, 5105, 'BATCH-INIT-20260916', 701, 717, 752, 3500.0000, NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 薄线圈 3500个
  (30112, 5106, 'BATCH-INIT-20260916', 701, 717, 752, 2500.0000, NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 厚线圈 2500个
  (30111, 5107, 'BATCH-INIT-20260916', 701, 716, 751, 1000.0000, NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 端盖 1000个
  (30111, 5108, 'BATCH-INIT-20260916', 701, 716, 751, 2000.0000, NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 螺丝 2000颗
  (30112, 5109, 'BATCH-INIT-20260916', 701, 717, 752, 150.0000,  NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 引线 150米
  (30113, 5110, 'BATCH-INIT-20260916', 701, 718, 753, 25.0000,   NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 热缩管 25米
  (30113, 5111, 'BATCH-INIT-20260916', 701, 718, 753, 5.0000,    NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- AB胶 5.0KG
  (30113, 5114, 'BATCH-INIT-20260916', 701, 718, 753, 50.0000,   NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 高温胶带 50米
  (30113, 5112, 'BATCH-INIT-20260916', 701, 718, 753, 5.0000,    NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1), -- 玻璃胶 5.0KG
  (30113, 5113, 'BATCH-INIT-20260916', 701, 718, 753, 20.0000,   NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1); -- 黑色环氧胶 20.0KG


-- -------------------------------------------------------------------
-- 第三步：下达 32 件试产工单 (mes_pro_work_order & mes_pro_work_order_bom)
-- -------------------------------------------------------------------
DELETE FROM `mes_pro_work_order` WHERE `id` = 5001;
DELETE FROM `mes_pro_work_order_bom` WHERE `work_order_id` = 5001;

INSERT INTO `mes_pro_work_order` (
  `id`, `code`, `name`, `type`, `order_source_type`, `order_source_code`, 
  `product_id`, `quantity`, `quantity_produced`, `quantity_changed`, `quantity_scheduled`, 
  `batch_code`, `request_date`, `parent_id`, `status`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES (
  5001, 'WO-SSD0608H-26091601', 'SSD0608H 动子总成 32 件标准流水线工单', 1, 1, 'SO-ERP-202609-001', 
  5102, 32.00, 32.00, 0.00, 32.00, 
  'LOT20260916-32', NOW(), 0, 2, '流水线传递作业：1 人 1 批 1 单 32 个托盘闭环试产', 
  'admin', NOW(), 'admin', NOW(), 0, 1
);

-- 工单 32 件用料定额 (从 MBOM 自动展开)
INSERT INTO `mes_pro_work_order_bom` (
  `work_order_id`, `item_id`, `quantity`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (5001, 5104,  32.00, '外壳 32个', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5105, 224.00, '薄线圈 224个 (7×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5106, 160.00, '厚线圈 160个 (5×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5107,  64.00, '端盖 64个 (2×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5108, 128.00, '紧固螺丝 128颗 (4×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5109,   9.60, '电机引线 9.60米 (0.3×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5110,   1.60, '热缩套管 1.60米 (0.05×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5111,  0.064, 'AB胶 0.064KG (0.002×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5114,   3.20, '高温胶带 3.20米 (0.1×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5112,  0.032, '玻璃胶 0.032KG (0.001×32)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5001, 5113,  0.480, '黑色环氧黑胶 0.480KG (0.015×32)', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- -------------------------------------------------------------------
-- 第四步：原料齐套出库至车间线边仓 WH02 (761 动子工位暂存位)
-- -------------------------------------------------------------------
-- 扣减 WH01
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 32.00   WHERE `warehouse_id` = 701 AND `item_id` = 5104;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 224.00  WHERE `warehouse_id` = 701 AND `item_id` = 5105;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 160.00  WHERE `warehouse_id` = 701 AND `item_id` = 5106;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 64.00   WHERE `warehouse_id` = 701 AND `item_id` = 5107;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 128.00  WHERE `warehouse_id` = 701 AND `item_id` = 5108;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 9.60    WHERE `warehouse_id` = 701 AND `item_id` = 5109;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 1.60    WHERE `warehouse_id` = 701 AND `item_id` = 5110;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 0.064   WHERE `warehouse_id` = 701 AND `item_id` = 5111;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 3.20    WHERE `warehouse_id` = 701 AND `item_id` = 5114;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 0.032   WHERE `warehouse_id` = 701 AND `item_id` = 5112;
UPDATE `mes_wm_material_stock` SET `quantity` = `quantity` - 0.480   WHERE `warehouse_id` = 701 AND `item_id` = 5113;


-- -------------------------------------------------------------------
-- 第五步：生成 7 道工序生产任务与托盘流转卡 (mes_pro_task)
-- -------------------------------------------------------------------
DELETE FROM `mes_pro_task` WHERE `work_order_id` = 5001;

INSERT INTO `mes_pro_task` (
  `id`, `code`, `name`, `work_order_id`, `workstation_id`, `route_id`, `process_id`, 
  `item_id`, `quantity`, `produced_quantity`, `qualify_quantity`, `unqualify_quantity`, 
  `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (5011, 'TASK-260916-01', '工位1：线圈糊制任务 (32件)', 5001, 501, 11, 101, 5102, 32.00, 32.00, 32.00, 0.00, 2, '7薄5厚穿杆固定点涂AB胶', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5012, 'TASK-260916-02', '工位2：相序分组任务 (32件)', 5001, 502, 11, 102, 5102, 32.00, 32.00, 32.00, 0.00, 2, '红黄白三相相序拉齐与耐热胶带包裹', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5013, 'TASK-260916-03', '工位3：引线焊接任务 (32件)', 5001, 503, 11, 103, 5102, 32.00, 32.00, 32.00, 0.00, 2, '烙铁焊三色线与热缩管吹紧防击穿', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5014, 'TASK-260916-04', '工位4：组装反测任务 (32件)', 5001, 504, 11, 104, 5102, 32.00, 32.00, 32.00, 0.00, 2, '绕线装端盖拧螺丝玻璃胶封孔与反电测', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5015, 'TASK-260916-05', '工位5：灌胶烘烤任务 (32件)', 5001, 505, 11, 105, 5102, 32.00, 32.00, 32.00, 0.00, 2, '三遍分段灌胶烘烤1小时拔棍', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5016, 'TASK-260916-06', '工位6：修整深洁任务 (32件)', 5001, 506, 11, 106, 5102, 32.00, 32.00, 32.00, 0.00, 2, '酒精深洁削平端盖剪齐引线', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5017, 'TASK-260916-07', '工位7：终检打标任务 (32件)', 5001, 507, 11, 107, 5102, 32.00, 32.00, 32.00, 0.00, 2, '综合电测阻抗耐压并激光打印出厂SN', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- -------------------------------------------------------------------
-- 第六步：模拟车间 7 工位流水线托盘扫码报工记录 (mes_pro_feedback)
-- -------------------------------------------------------------------
DELETE FROM `mes_pro_feedback` WHERE `work_order_id` = 5001;

INSERT INTO `mes_pro_feedback` (
  `id`, `code`, `type`, `channel`, `feedback_time`, `workstation_id`, 
  `route_id`, `process_id`, `work_order_id`, `task_id`, `item_id`, 
  `lot_number`, `scheduled_quantity`, `feedback_quantity`, `qualified_quantity`, `unqualified_quantity`, 
  `feedback_user_id`, `status`, `remark`, `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (5021, 'FB-260916-01', 1, 'PDA', DATE_ADD(NOW(), INTERVAL -120 MINUTE), 501, 11, 101, 5001, 5011, 5102, 'LOT20260916-32', 32.00, 32.00, 32.00, 0.00, 1, 4, '工位1糊线圈完成，托盘扫码传递至工位2', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5022, 'FB-260916-02', 1, 'PDA', DATE_ADD(NOW(), INTERVAL -100 MINUTE), 502, 11, 102, 5001, 5012, 5102, 'LOT20260916-32', 32.00, 32.00, 32.00, 0.00, 1, 4, '工位2分组完成，托盘扫码传递至工位3', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5023, 'FB-260916-03', 1, 'PDA', DATE_ADD(NOW(), INTERVAL  -80 MINUTE), 503, 11, 103, 5001, 5013, 5102, 'LOT20260916-32', 32.00, 32.00, 32.00, 0.00, 1, 4, '工位3焊接引线完成，托盘扫码传递至工位4', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5024, 'FB-260916-04', 1, 'PDA', DATE_ADD(NOW(), INTERVAL  -60 MINUTE), 504, 11, 104, 5001, 5014, 5102, 'LOT20260916-32', 32.00, 32.00, 32.00, 0.00, 1, 4, '工位4反电测32件全部合格，封胶完毕传递至工位5', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5025, 'FB-260916-05', 1, 'PDA', DATE_ADD(NOW(), INTERVAL  -30 MINUTE), 505, 11, 105, 5001, 5015, 5102, 'LOT20260916-32', 32.00, 32.00, 32.00, 0.00, 1, 4, '工位5三遍灌胶烘烤拆棍完毕，传递至工位6', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5026, 'FB-260916-06', 1, 'PDA', DATE_ADD(NOW(), INTERVAL  -15 MINUTE), 506, 11, 106, 5001, 5016, 5102, 'LOT20260916-32', 32.00, 32.00, 32.00, 0.00, 1, 4, '工位6深洁削平端盖完成，传递至工位7终检', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (5027, 'FB-260916-07', 1, 'PDA', NOW(),                                 507, 11, 107, 5001, 5017, 5102, 'LOT20260916-32', 32.00, 32.00, 32.00, 0.00, 1, 4, '工位7综合电测32件全优良，激光打标完成赋码', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- -------------------------------------------------------------------
-- 第七步：自动生成 32 个一机一码序列号 (mes_wm_sn)
-- -------------------------------------------------------------------
DELETE FROM `mes_wm_sn` WHERE `work_order_id` = 5001;

INSERT INTO `mes_wm_sn` (
  `uuid`, `code`, `item_id`, `batch_code`, `work_order_id`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (UUID(), 'SN-0608H-260916-0001', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0002', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0003', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0004', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0005', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0006', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0007', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0008', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0009', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0010', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0011', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0012', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0013', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0014', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0015', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0016', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0017', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0018', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0019', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0020', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0021', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0022', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0023', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0024', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0025', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0026', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0027', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0028', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0029', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0030', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0031', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1),
  (UUID(), 'SN-0608H-260916-0032', 5102, 'LOT20260916-32', 5001, 'admin', NOW(), 'admin', NOW(), 0, 1);


-- -------------------------------------------------------------------
-- 第八步：半成品动子完工入库 (入线边仓 761 动子工位暂存位，等待定子总装)
-- -------------------------------------------------------------------
DELETE FROM `mes_wm_material_stock` WHERE `batch_code` = 'LOT20260916-32' AND `item_id` = 5102;

INSERT INTO `mes_wm_material_stock` (
  `item_type_id`, `item_id`, `batch_code`, `warehouse_id`, `location_id`, `area_id`, `quantity`, `receipt_time`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES (
  30121, 5102, 'LOT20260916-32', 703, 731, 761, 32.0000, NOW(), 'admin', NOW(), 'admin', NOW(), 0, 1
);

SET FOREIGN_KEY_CHECKS = 1;

-- -------------------------------------------------------------------
-- 验证查询与报表穿透
-- -------------------------------------------------------------------

-- 1. 工单基本信息与完工状态
SELECT 
  wo.code AS '工单号', 
  wo.name AS '工单名称', 
  i.name AS '产出物料', 
  wo.quantity AS '计划数', 
  wo.quantity_produced AS '已完工数',
  CASE wo.status WHEN 0 THEN '草稿' WHEN 1 THEN '已确认' WHEN 2 THEN '已完成' WHEN 3 THEN '已取消' END AS '工单状态'
FROM mes_pro_work_order wo
JOIN mes_md_item i ON wo.product_id = i.id
WHERE wo.id = 5001;

-- 2. 车间 7 道流水线工位报工记录
SELECT 
  fb.code AS '报工单号',
  p.name AS '工序名称',
  ws.name AS '作业工位',
  fb.channel AS '终端',
  fb.feedback_quantity AS '报工数',
  fb.qualified_quantity AS '合格数',
  fb.remark AS '流转追踪'
FROM mes_pro_feedback fb
JOIN mes_pro_process p ON fb.process_id = p.id
JOIN mes_md_workstation ws ON fb.workstation_id = ws.id
WHERE fb.work_order_id = 5001
ORDER BY fb.process_id;

-- 3. 本工单生成的 32 个一机一码 SN 序列号清单 (前 5 个展示)
SELECT 
  sn.id AS 'SN序号',
  sn.code AS '一机一码出厂SN',
  i.name AS '对应物料',
  sn.batch_code AS '生产批次',
  sn.create_time AS '激光赋码时间'
FROM mes_wm_sn sn
JOIN mes_md_item i ON sn.item_id = i.id
WHERE sn.work_order_id = 5001
LIMIT 5;

-- 4. 防腐层写回 ERP 平账指令生成 (Anti-Corruption Writeback Payload)
SELECT 
  wo.code AS 'MES工单号',
  map.system_type AS '目标老系统',
  map.external_code AS '老ERP物料编码',
  map.external_name AS '老ERP物料名称',
  wo.quantity_produced AS '本次完工冲销数',
  wo.batch_code AS '生产批号',
  CONCAT('INSERT INTO demisa_produce_receipt (item_code, qty, batch_no, status) VALUES (\'', map.external_code, '\', ', CAST(wo.quantity_produced AS SIGNED), ', \'', wo.batch_code, '\', 1);') AS 'ERP异步冲销SQL指令'
FROM mes_pro_work_order wo
JOIN mes_md_item_mapping map ON wo.product_id = map.item_id
WHERE wo.id = 5001;
