-- ===================================================================
-- 管状直线电机试点主力机型【车间物理三级仓位与精益工艺路线 MBOM 初始化脚本】
-- 数据库: ruoyi-vue-pro (端口: 3307)
-- 
-- 依据现场真实 SOP (0608制作流程及注意事项.xlsx) 与流水线实操标准：
--   1. 流水线传递作业：1 人 1 批 1 单 32 件托盘流转
--   2. 动子总成 7 道标准工序 (101~107) 严格对齐工位责任与防呆质检
--   3. 定子磁轴 3 道工序 (108~110: 穿磁定位 -> 外协无心磨精磨 -> 表磁终检)
--   4. 整机总装 1 道工序 (111: 动定子滑行丝滑度配合全检与出厂包装)
--   5. 工序投料 (MBOM) 精准对应工步，完工自动倒冲扣减对应线边库存
-- ===================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------
-- 一、 Task 3: 物理三级仓位模型配置 (厂 - 库 - 区 - 位)
-- -------------------------------------------------------------------

-- 1. 仓库主数据 (mes_wm_warehouse)
UPDATE `mes_wm_warehouse` SET `name` = 'WH01 原料主仓', `remark` = '存放铝机壳、端盖、钢管、漆包线圈、化学胶水及强磁' WHERE `id` = 701;
UPDATE `mes_wm_warehouse` SET `name` = 'WH04 成品立库', `remark` = '存放 SSD0608H-145L 成套检验合格待发运整机' WHERE `id` = 702;
UPDATE `mes_wm_warehouse` SET `code` = 'WH-WIP', `name` = 'WH02 直线装配线边仓', `remark` = '车间工位周转暂存，托盘流转卡线边暂存位' WHERE `id` = 703;

INSERT INTO `mes_wm_warehouse` (
  `id`, `code`, `name`, `address`, `area`, `charge_user_id`, `frozen`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (704, 'WH-OSP', 'WH03 委外在途仓', '外协机加商中转', 500.00, 1, 0, '用于管理送往机加商无心磨精磨外圆的在制定子磁轴，划分责任资产边界', 'admin', NOW(), 'admin', NOW(), 0, 1)
ON DUPLICATE KEY UPDATE 
  `name` = VALUES(`name`),
  `remark` = VALUES(`remark`),
  `deleted` = 0;

-- 2. 库区主数据 (mes_wm_warehouse_location)
DELETE FROM `mes_wm_warehouse_location` WHERE `id` IN (716, 717, 718, 719, 731, 732, 733, 734);

INSERT INTO `mes_wm_warehouse_location` (
  `id`, `code`, `name`, `warehouse_id`, `area`, `frozen`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  -- WH01 原料仓库区
  (716, 'LOC-RAW-WJ',  '五金机械库区',   701, 300.00, 0, '存放铝机壳、端盖、微型螺丝、精密钢管、端子堵头', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (717, 'LOC-RAW-DQ',  '电气线缆库区',   701, 200.00, 0, '存放 7薄5厚漆包线圈组、三色超柔引线', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (718, 'LOC-RAW-HG',  '胶水绝缘库区',   701, 150.00, 0, '存放 AB胶、玻璃胶、黑色环氧灌封胶、瞬干胶、热缩套管、高温胶带', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (719, 'LOC-RAW-MAG', '磁材特管库区',   701,  80.00, 0, '高价值钕铁硼强磁钢专柜(high_value=1)，防磁防盗单件严格管控', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- WH02 直线装配线边仓库区
  (731, 'LOC-WIP-LIN', '直线装配周转区', 703, 200.00, 0, '工位物料周转暂存，托盘齐套领料存放', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- WH03 委外在途仓库区
  (732, 'LOC-OSP-MACH','外协机加在途区', 704, 150.00, 0, '定子磁轴送往机加商无心磨精磨外圆及端部车槽在制品', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- WH04 成品立库库区
  (733, 'LOC-FIN-QUAL','合格品良品区',   702, 400.00, 0, 'FQC检验合格的 SSD0608H-145L 成套电机待发货区', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (734, 'LOC-FIN-INSP','终检待检区',     702, 100.00, 0, '组装完成待 FQC 电性能终检或复测隔离区', 'admin', NOW(), 'admin', NOW(), 0, 1);

-- 3. 库位主数据 (mes_wm_warehouse_area)
DELETE FROM `mes_wm_warehouse_area` WHERE `id` IN (751, 752, 753, 754, 761, 762, 771, 781, 782);

INSERT INTO `mes_wm_warehouse_area` (
  `id`, `code`, `name`, `location_id`, `area`, `max_load`, `status`, `frozen`, 
  `allow_item_mixing`, `allow_batch_mixing`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  -- 原料库位
  (751, 'AREA-RAW-WJ-01',  '五金货架01',     716, 30.00, 2000.00, 0, 0, 1, 1, '机壳、端盖、钢管货位', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (752, 'AREA-RAW-DQ-01',  '线圈货架01',     717, 20.00, 1000.00, 0, 0, 1, 0, '自粘线圈薄厚分层货位', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (753, 'AREA-RAW-HG-01',  '化学品柜01',     718, 15.00,  500.00, 0, 0, 1, 0, '灌封树脂、瞬干胶控温货位', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (754, 'AREA-RAW-MAG-01', '防磁保险柜01',   719, 10.00, 1000.00, 0, 0, 0, 0, '强磁环专用高保密货位', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 线边周转库位
  (761, 'AREA-WIP-MOV-01', '动子工位暂存位', 731, 20.00,  800.00, 0, 0, 1, 1, '32件动子装配托盘暂存', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (762, 'AREA-WIP-STA-01', '定子穿磁暂存位', 731, 20.00,  800.00, 0, 0, 1, 1, '定子穿磁前线边物料配盘', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 外协中转库位
  (771, 'AREA-OSP-MACH-01','机加外发待出库', 732, 30.00, 1000.00, 0, 0, 1, 1, '定子磁轴装箱外发交接位', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 成品库位
  (781, 'AREA-FIN-SSD06',  '管状成品货架01', 733, 40.00, 3000.00, 0, 0, 1, 1, 'SSD0608H-145L 包装成箱货位', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (782, 'AREA-FIN-INSPECT','FQC复测隔离位',  734, 15.00, 1000.00, 0, 0, 1, 1, '待质检复核或异常隔离', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- -------------------------------------------------------------------
-- 二、 Task 4: 精益工艺路线与工序投料 MBOM (完全对齐现场 SOP 7道工步)
-- -------------------------------------------------------------------

-- 1. 制造工序主数据 (mes_pro_process)
-- 动子: 101~107; 定子: 108~110; 整机: 111
DELETE FROM `mes_pro_process` WHERE `id` IN (101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111);

INSERT INTO `mes_pro_process` (
  `id`, `code`, `name`, `attention`, `status`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  -- 动子流水线 7 道工序 (对应工位 1 ~ 7)
  (101, 'PROC-MOV-01', '步骤一：线圈糊制', 
   '卡尺测薄厚(薄5.8~5.9,厚6.0)，严格按“三薄三厚三薄二厚一薄(7薄5厚)”穿杆固定，点涂AB胶(严禁全涂满预留胶道)，固化尺寸严格控制在71.5~72mm。', 
   0, '工位1：线圈排列与AB胶粘结', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (102, 'PROC-MOV-02', '步骤二：线圈分组', 
   '明确区分头尾方向，尾部统一归集；头部按三相分组拉出：3/6/9/12拉红线、2/5/8/11拉黄线、1/4/7/10拉白线；使用耐高温绝缘胶带严密包裹。', 
   0, '工位2：相序分组与绝缘包裹', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (103, 'PROC-MOV-03', '步骤三：引线焊接', 
   '红黄白三色超柔引线分别焊接牢固，严禁虚焊假焊；套入黑色热缩套管完全覆盖焊点裸铜，热风枪吹紧吹实。', 
   0, '工位3：引线烙铁焊接与套管热缩', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (104, 'PROC-MOV-04', '步骤四：组装与固定', 
   '线圈套入机壳，引线在顶部端盖内侧缠绕一圈后再装端盖防松脱；紧固螺丝严禁压线；出线孔打玻璃胶密封防漏胶；专用反电测仪测反电势波动。', 
   0, '工位4：穿壳装端盖/玻璃胶封孔/反电测', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (105, 'PROC-MOV-05', '步骤五：灌胶与烘烤', 
   '灌胶棍涂润滑剂装入；三遍分段灌注环氧树脂黑胶(中孔溢出固定->侧孔放置15min->满灌)；烤箱烘烤1小时，趁热初清残胶，专用工装拆卸灌胶棍。', 
   0, '工位5：环氧黑胶灌注/烘烤固化/拆棍', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (106, 'PROC-MOV-06', '步骤六：成品清理整理', 
   '工业酒精搭配无尘擦拭纸整体深度清洁；专用工具削平两侧端盖多余凸起；统一齐平剪裁三色引线；拆换工艺螺丝并检查螺纹孔无滑牙。', 
   0, '工位6：外壳深洁/削平端盖/剪齐引线', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (107, 'PROC-MOV-07', '步骤七：成品终检打标', 
   '接入综合电测仪跑0608专用程序(测U/V/W相电阻、电感、耐压)；合格品由激光打标机在指定位置打刻一机一码序列号(SN)条码。', 
   0, '工位7：电性能终检与激光打刻SN', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 定子工序 (穿磁点胶 -> 外协机加 -> 终检)
  (108, 'PROC-STA-ASSY', '定子穿磁与定位', 
   '1.不锈钢管内穿入16粒钕铁硼强磁与端子；2.使用401/406瞬干胶快速点胶定位，防止强磁反弹相斥。', 
   0, '定子厂内粗装，批次交接外发', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (109, 'PROC-STA-OSP', '定子外协机加工', 
   '送外协机加工商无心磨全长精磨外圆，公差控制在微米级，车铣两端安装螺纹堵头。', 
   0, '工序委外，生成外协交接单，机加服务费核算', 'admin', NOW(), 'admin', NOW(), 0, 1),

  (110, 'PROC-STA-INSPECT', '定子检验与表磁测试', 
   '全检外协送回定子磁轴：1.全长直线度与外径跳动度；2.多极表面磁场强度(高斯值)；3.表面无磕碰划伤。', 
   0, '外协来料质检关卡，合格入库', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 整机成套总装工序
  (111, 'PROC-PRD-ASSY', '整机滑行配合与包装', 
   '1.动子与定子磁轴成套插入装配工装；2.前后手动推移，全程必须丝滑无卡顿无干涉摩擦；3.贴防伪合格证，装入专用珍珠棉与出厂包装盒。', 
   0, '整机成套总装与出厂包装', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- 2. 工艺路线主表 (mes_pro_route)
DELETE FROM `mes_pro_route` WHERE `id` IN (11, 12, 13);

INSERT INTO `mes_pro_route` (
  `id`, `code`, `name`, `description`, `status`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (11, 'ROUTE-MOV-SSD06', 'SSD0608H 动子总成流水线精益工艺', '对齐现场 0608 SOP，7个工位流水线传递，32件一单按盘流转', 0, '动子7工序流水线', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (12, 'ROUTE-STA-SS06',  'SS06-145L 定子磁轴精益制造工艺', '定子穿磁点胶定位、外协无心磨精磨外圆与回厂表磁终检', 0, '定子工艺路线', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (13, 'ROUTE-PRD-SSD06', 'SSD0608H-145L 管状电机成套配对总装工艺', '动定子装配滑行丝滑度配合检验、出厂贴标与包装入库', 0, '整机总装路线', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- 3. 工艺路线工序关联表 (mes_pro_route_process)
DELETE FROM `mes_pro_route_process` WHERE `route_id` IN (11, 12, 13);

INSERT INTO `mes_pro_route_process` (
  `route_id`, `process_id`, `sort`, `next_process_id`, `link_type`, 
  `prepare_time`, `wait_time`, `color_code`, `key_flag`, `check_flag`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  -- 动子流水线: 101 -> 102 -> 103 -> 104 -> 105 -> 106 -> 107
  (11, 101, 1, 102, 3,  5,  0, '#409EFF', b'1', b'0', '步骤一：线圈糊制(7薄5厚，控总长71.5~72mm)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 102, 2, 103, 3,  5,  0, '#36CFC9', b'1', b'0', '步骤二：线圈分组(三相相序拉出，高温胶带包裹)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 103, 3, 104, 3,  5,  0, '#597EF7', b'1', b'0', '步骤三：引线焊接(三色线焊接，套管热缩防击穿)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 104, 4, 105, 3, 10,  0, '#E6A23C', b'1', b'1', '步骤四：组装固定(绕线装端盖，玻璃胶封孔，强制反电测)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 105, 5, 106, 3, 10, 60, '#F56C6C', b'1', b'0', '步骤五：灌胶烘烤(三遍分段灌黑胶，烤箱固化1小时，工装拆棍)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 106, 6, 107, 3,  5,  0, '#909399', b'0', b'0', '步骤六：清理整理(酒精深洁表面，削平端盖，剪齐引线)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 107, 7, NULL,3,  5,  0, '#67C23A', b'1', b'1', '步骤七：终检打标(综合电测阻抗/电感/耐压，激光打刻一机一码SN)', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 定子路线工序: 108 -> 109 -> 110
  (12, 108, 1, 109, 3,  5,   0, '#E6A23C', b'0', b'0', '定子钢管穿磁与瞬干胶快速定型', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (12, 109, 2, 110, 3,  0, 2880, '#909399', b'1', b'0', '外发机加商精磨无心磨外圆(委外加工)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (12, 110, 3, NULL, 3,  5,   0, '#67C23A', b'1', b'1', '外协送回尺寸跳动与表磁强度全检', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 整机总装工序: 111
  (13, 111, 1, NULL, 3,  5,   0, '#00AEF3', b'1', b'1', '动定子滑行丝滑度全检、配对包装入库', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- 4. 工艺路线产品关联表 (mes_pro_route_product)
-- 流水线 1 人 1 批 1 单 32 件标准托盘流转
DELETE FROM `mes_pro_route_product` WHERE `route_id` IN (11, 12, 13);

INSERT INTO `mes_pro_route_product` (
  `route_id`, `item_id`, `quantity`, `production_time`, `time_unit_type`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  (11, 5102, 32, 120.00, 'MINUTE', 'SSD0608H 动子总成 (标准工装托盘 32件/批 流转)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (12, 5103, 32, 240.00, 'MINUTE', 'SS06-145L 定子磁轴 (外协周转 32件/箱 流转)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (13, 5101,  1,  10.00, 'MINUTE', 'SSD0608H-145L 管状电机整机 (单台包装出库)', 'admin', NOW(), 'admin', NOW(), 0, 1);


-- 5. 工艺路线工序投料 MBOM (mes_pro_route_product_bom)
-- 明确原辅料在 7 道流水线工步的精准投料消耗点，报工时自动倒冲扣减对应库位库存
DELETE FROM `mes_pro_route_product_bom` WHERE `route_id` IN (11, 12, 13);

INSERT INTO `mes_pro_route_product_bom` (
  `route_id`, `process_id`, `product_id`, `item_id`, `quantity`, `remark`, 
  `creator`, `create_time`, `updater`, `update_time`, `deleted`, `tenant_id`
) VALUES
  -- 动子步骤一 (101: 线圈糊制) 投料：薄线圈、厚线圈、AB胶
  (11, 101, 5102, 5105, 7.0000, '薄线圈(5.8~5.9mm) 7个/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 101, 5102, 5106, 5.0000, '厚线圈(6.0mm) 5个/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 101, 5102, 5111, 0.0020, '线圈糊制 A/B 胶 0.002 KG/件', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 动子步骤二 (102: 线圈分组) 投料：耐高温绝缘胶带
  (11, 102, 5102, 5114, 0.1000, '分组绝缘高温胶带 0.10 米/件', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 动子步骤三 (103: 引线焊接) 投料：三色超柔引线、热缩套管
  (11, 103, 5102, 5109, 0.3000, '三色电机引线 0.30 米/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 103, 5102, 5110, 0.0500, '黑色热缩套管 0.05 米/件', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 动子步骤四 (104: 组装与固定) 投料：铝机壳、前后端盖、螺丝、玻璃胶
  (11, 104, 5102, 5104, 1.0000, '铝合金外壳 1 个/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 104, 5102, 5107, 2.0000, '前后端盖副 2 个/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 104, 5102, 5108, 4.0000, '端盖紧固螺丝 4 颗/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (11, 104, 5102, 5112, 0.0010, '出线孔密封玻璃胶 0.001 KG/件', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 动子步骤五 (105: 灌胶与烘烤) 投料：黑色环氧树脂灌封胶
  (11, 105, 5102, 5113, 0.0150, '黑色环氧灌封胶 0.015 KG/件', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 步骤六 (106: 清理) 辅料由工位按周领用，不按单件扣减
  -- 步骤七 (107: 终检打标) 赋码产出，无物料消耗

  -- 定子工序 108 (定子穿磁与定位) 消耗 4 项原辅料
  (12, 108, 5103, 5115, 1.0000, '精密不锈钢管 1 根/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (12, 108, 5103, 5116, 2.0000, '两端密封端子 2 个/件', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (12, 108, 5103, 5117, 16.0000,'钕铁硼强磁钢 16 个/件 (高价值管控)', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (12, 108, 5103, 5118, 0.0020, '定位瞬干胶 0.002 KG/件', 'admin', NOW(), 'admin', NOW(), 0, 1),

  -- 整机工序 111 (整机滑行配合与包装) 消耗动定子半成品成套
  (13, 111, 5101, 5102, 1.0000, '动子总成半成品 1 个', 'admin', NOW(), 'admin', NOW(), 0, 1),
  (13, 111, 5101, 5103, 1.0000, '定子磁轴半成品 1 根', 'admin', NOW(), 'admin', NOW(), 0, 1);

SET FOREIGN_KEY_CHECKS = 1;

-- -------------------------------------------------------------------
-- 执行验证自检
-- -------------------------------------------------------------------
SELECT 
  r.code AS '工艺路线编码',
  r.name AS '工艺路线名称',
  p.id AS '工序号',
  p.name AS '工序名称',
  rp.sort AS '流转顺序',
  IF(rp.key_flag = b'1', '是', '否') AS '关键工序',
  IF(rp.check_flag = b'1', '是', '否') AS '质检关卡',
  rp.remark AS '控制说明'
FROM mes_pro_route_process rp
JOIN mes_pro_route r ON rp.route_id = r.id
JOIN mes_pro_process p ON rp.process_id = p.id
ORDER BY rp.route_id, rp.sort;
