-- ===================================================================
-- 伺服与直驱制造 MES 物料产品标准分类体系【短小精炼·一目了然版】
-- 数据库: ruoyi-vue-pro
-- 目标表: mes_md_item_type
-- 特点: 名称精简（2~4字）、层级扁平、彻底告别冗长学术名称、与车间一线和ERP心智完全对齐
-- ===================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. 更新主干节点名称为极简短名
UPDATE `mes_md_item_type` SET `name` = '物料产品分类' WHERE `id` = 200;
UPDATE `mes_md_item_type` SET `name` = '原材料'   WHERE `id` = 272;
UPDATE `mes_md_item_type` SET `name` = '产品'     WHERE `id` = 273;
UPDATE `mes_md_item_type` SET `name` = '半成品'   WHERE `id` = 276;
UPDATE `mes_md_item_type` SET `name` = '产成品'   WHERE `id` = 277;

UPDATE `mes_md_item_type` SET `name` = '电子元件', `sort` = 1 WHERE `id` = 285;
UPDATE `mes_md_item_type` SET `name` = '电气传感', `sort` = 2 WHERE `id` = 284;
UPDATE `mes_md_item_type` SET `name` = '机加五金', `sort` = 3 WHERE `id` = 274;
UPDATE `mes_md_item_type` SET `name` = '胶水绝缘', `sort` = 4 WHERE `id` = 275;
UPDATE `mes_md_item_type` SET `name` = '包装辅料', `sort` = 5 WHERE `id` = 278;

UPDATE `mes_md_item_type` SET `deleted` = 1 WHERE `id` IN (282, 283);

-- 2. 原材料细分（名称极简：2~4字）
INSERT INTO `mes_md_item_type` (`id`, `code`, `name`, `parent_id`, `item_or_product`, `sort`, `status`, `remark`, `deleted`, `tenant_id`)
VALUES
  -- 电子元件 (285)
  (1011, 'RAW_ELEC_CHIP',    '芯片阻容',     285,  'ITEM', 1, 0, 'IC、MCU、阻容MOS管', 0, 1),
  (1012, 'RAW_ELEC_PCB',     'PCB板',        285,  'ITEM', 2, 0, '未贴片印刷电路裸板', 0, 1),

  -- 电气传感 (284)
  (1021, 'RAW_WIRE_COPPER',  '漆包线',       284,  'ITEM', 1, 0, '铜线/漆包线', 0, 1),
  (1022, 'RAW_ENCODER_PARTS','光栅码盘',     284,  'ITEM', 2, 0, '外购玻璃码盘/镀铬码盘/磁环', 0, 1),
  (1023, 'RAW_CABLE_RAW',    '线缆生料',     284,  'ITEM', 3, 0, '成卷电缆/航插端子', 0, 1),

  -- 机加五金 (274)
  (1031, 'RAW_BEARING',      '轴承',         274,  'ITEM', 1, 0, '深沟球/角接触轴承', 0, 1),
  (1032, 'RAW_MAGNET',       '磁铁',         274,  'ITEM', 2, 0, '钕铁硼磁钢/磁瓦', 0, 1),
  (1033, 'RAW_CORE',         '铁芯冲片',     274,  'ITEM', 3, 0, '定转子硅钢片冲片', 0, 1),
  (1034, 'RAW_HOUSING',      '外壳端盖',     274,  'ITEM', 4, 0, '铝机壳/前后端盖', 0, 1),
  (1035, 'RAW_SHAFT',        '转轴机加',     274,  'ITEM', 5, 0, '电机主轴/固定块/机加件', 0, 1),
  (1036, 'RAW_PROFILE',      '型材管料',     274,  'ITEM', 6, 0, '圆钢/钢管/铝型材/钢带', 0, 1),
  (1037, 'RAW_GUIDE_STD',    '导轨标件',     274,  'ITEM', 7, 0, '滚珠导轨/螺钉/销钉/卡簧', 0, 1),

  -- 胶水绝缘 (275)
  (1041, 'RAW_GLUE',         '胶水',         275,  'ITEM', 1, 0, '磁钢胶/灌封胶/密封胶', 0, 1),
  (1042, 'RAW_INSUL',        '绝缘材料',     275,  'ITEM', 2, 0, '含浸漆/绝缘纸/套管', 0, 1),

  -- 包装辅料 (278)
  (1051, 'RAW_PACK_BOX',     '纸箱泡棉',     278,  'ITEM', 1, 0, '纸箱/珍珠棉', 0, 1),
  (1052, 'RAW_LABEL',        '标贴铭牌',     278,  'ITEM', 2, 0, '铭牌/二维码标贴', 0, 1),
  (1053, 'RAW_CONSUM',       '低值耗材',     278,  'ITEM', 3, 0, '高温胶带/润滑脂/无尘布', 0, 1)
ON DUPLICATE KEY UPDATE 
  `name` = VALUES(`name`),
  `parent_id` = VALUES(`parent_id`),
  `item_or_product` = VALUES(`item_or_product`),
  `sort` = VALUES(`sort`),
  `deleted` = 0;

-- 3. 半成品（自制组件，全部短名）
INSERT INTO `mes_md_item_type` (`id`, `code`, `name`, `parent_id`, `item_or_product`, `sort`, `status`, `remark`, `deleted`, `tenant_id`)
VALUES
  -- 直线自制 (2010)
  (2010, 'SEMI_LINEAR',      '直线组件',     276,  'PRODUCT', 1, 0, '直线自制部件', 0, 1),
  (2011, 'SEMI_FORCER',      '动子总成',     2010, 'PRODUCT', 1, 0, '绕线灌封动子总成', 0, 1),
  (2012, 'SEMI_STATOR_TRACK','定子磁轨',     2010, 'PRODUCT', 2, 0, '贴磁定子板', 0, 1),

  -- 旋转自制 (2020)
  (2020, 'SEMI_ROTARY',      '旋转组件',     276,  'PRODUCT', 2, 0, '旋转自制部件', 0, 1),
  (2021, 'SEMI_STATOR_ASSY', '定子总成',     2020, 'PRODUCT', 1, 0, '绕线嵌线浸漆定子', 0, 1),
  (2022, 'SEMI_ROTOR_ASSY',  '转子总成',     2020, 'PRODUCT', 2, 0, '压轴贴磁动平衡转子', 0, 1),

  -- PCBA板卡 (2030)
  (2030, 'SEMI_PCBA',        'PCBA板',       276,  'PRODUCT', 3, 0, '自制电控板卡', 0, 1),
  (2031, 'SEMI_PCBA_DRIVE',  '驱动板',       2030, 'PRODUCT', 1, 0, '驱动器主板', 0, 1),
  (2032, 'SEMI_PCBA_READ',   '读数头板',     2030, 'PRODUCT', 2, 0, '读数头处理板', 0, 1),
  (2033, 'SEMI_PCBA_INTER',  '细分板',       2030, 'PRODUCT', 3, 0, '插补细分板', 0, 1),

  -- 自制线束 (2040)
  (2040, 'SEMI_HARNESS',     '自制线束',     276,  'PRODUCT', 4, 0, '车间加工线束', 0, 1),
  (2041, 'SEMI_POWER_LINE',  '动力线',       2040, 'PRODUCT', 1, 0, '带航插动力线', 0, 1),
  (2042, 'SEMI_FEEDBACK_LINE','反馈线',       2040, 'PRODUCT', 2, 0, '带航插反馈线', 0, 1),

  -- 编码器自制 (2050)
  (2050, 'SEMI_ENCODER',     '光栅组件',     276,  'PRODUCT', 5, 0, '编码器自制件', 0, 1),
  (2051, 'SEMI_OPT_RING',    '光栅环',       2050, 'PRODUCT', 1, 0, '光栅环(如IESR17)/校准码盘', 0, 1),
  (2052, 'SEMI_READ_HEAD',   '读数头',       2050, 'PRODUCT', 2, 0, '读数头封装总成', 0, 1)
ON DUPLICATE KEY UPDATE 
  `name` = VALUES(`name`),
  `parent_id` = VALUES(`parent_id`),
  `item_or_product` = VALUES(`item_or_product`),
  `sort` = VALUES(`sort`),
  `deleted` = 0;

-- 4. 产成品（五大核心品类，全短名，彻底解决混杂）
INSERT INTO `mes_md_item_type` (`id`, `code`, `name`, `parent_id`, `item_or_product`, `sort`, `status`, `remark`, `deleted`, `tenant_id`)
VALUES
  -- 4.1 电机 (3010)
  (3010, 'PROD_MOTOR',         '电机',         277,  'PRODUCT', 1, 0, '电机整机及套件', 0, 1),
  (3011, 'PROD_SERVO',         '伺服电机',     3010, 'PRODUCT', 1, 0, '60/80/130等旋转伺服', 0, 1),
  
  (3012, 'PROD_DDR',           'DD马达',       3010, 'PRODUCT', 2, 0, '直驱力矩电机', 0, 1),
  (30121,'PROD_DDR_WHOLE',     'DD马达整机',   3012, 'PRODUCT', 1, 0, '带壳轴承整机(台)', 0, 1),
  (30122,'PROD_DDR_KIT',       '动定子套件',   3012, 'PRODUCT', 2, 0, '无框动定子成套(套)', 0, 1),
  (30123,'PROD_DDR_PARTS',     '定子/线圈',    3012, 'PRODUCT', 3, 0, '独立外售定子/线圈散件', 0, 1),

  (3013, 'PROD_LINEAR',        '直线电机',     3010, 'PRODUCT', 3, 0, '直线电机', 0, 1),
  (30131,'PROD_LIN_WHOLE',     '直线电机整机', 3013, 'PRODUCT', 1, 0, '成套直线电机整机', 0, 1),
  (30132,'PROD_LIN_FORCER',    '动子',         3013, 'PRODUCT', 2, 0, '外售动子总成', 0, 1),
  (30133,'PROD_LIN_STATOR',    '定子',         3013, 'PRODUCT', 3, 0, '外售定子磁轨', 0, 1),

  (3014, 'PROD_VCM',           '音圈电机',     3010, 'PRODUCT', 4, 0, 'VCM音圈电机', 0, 1),
  (3015, 'PROD_MAG_SPRING',    '磁弹簧',       3010, 'PRODUCT', 5, 0, '磁力重力平衡件', 0, 1),

  -- 4.2 模组平台 (3020)
  (3020, 'PROD_STAGE',         '模组平台',     277,  'PRODUCT', 2, 0, '系统级模组平台', 0, 1),
  (3021, 'PROD_STAGE_LIN',     '直线模组',     3020, 'PRODUCT', 1, 0, '直驱滑台模组', 0, 1),
  (3022, 'PROD_STAGE_SCREW',   '丝杆模组',     3020, 'PRODUCT', 2, 0, '单轴丝杆模组', 0, 1),
  (3023, 'PROD_STAGE_PLAT',    '平台模组',     3020, 'PRODUCT', 3, 0, '多轴/龙门对位平台', 0, 1),

  -- 4.3 驱动系统 (3030)
  (3030, 'PROD_DRIVE',         '驱动系统',     277,  'PRODUCT', 3, 0, '驱动与细分器', 0, 1),
  (3031, 'PROD_SERVO_DRIVE',   '驱动器',       3030, 'PRODUCT', 1, 0, '伺服驱动器整机', 0, 1),
  (3032, 'PROD_INTER_BOX',     '细分盒',       3030, 'PRODUCT', 2, 0, '插补细分器整机', 0, 1),

  -- 4.4 编码器 (3040) —— 完全对齐ERP，增加工具压块
  (3040, 'PROD_SENSOR',        '编码器',       277,  'PRODUCT', 4, 0, '光栅/磁栅测量系统', 0, 1),
  (3041, 'PROD_OPT_ROTARY',    '圆光栅',       3040, 'PRODUCT', 1, 0, 'OE16/ORD130等圆光栅整机', 0, 1),
  (3042, 'PROD_OPT_SCALE',     '光栅尺',       3040, 'PRODUCT', 2, 0, '光栅标尺与读数头整机', 0, 1),
  (3043, 'PROD_MAG_ROTARY',    '圆磁环',       3040, 'PRODUCT', 3, 0, '磁环编码器整机', 0, 1),
  (3044, 'PROD_MAG_SCALE',     '磁栅尺',       3040, 'PRODUCT', 4, 0, '磁栅标尺与读数头整机', 0, 1),
  (3045, 'PROD_ENCODER_TOOL',  '编码器工具',   3040, 'PRODUCT', 5, 0, '压块/限位/零位/安装校准工具', 0, 1),

  -- 4.5 成品线缆 (3050)
  (3050, 'PROD_CABLE',         '成品线缆',     277,  'PRODUCT', 5, 0, '外售成品电缆', 0, 1),
  (3051, 'PROD_POWER_CABLE',   '动力延长线',   3050, 'PRODUCT', 1, 0, '成品动力电缆', 0, 1),
  (3052, 'PROD_FEED_CABLE',    '反馈延长线',   3050, 'PRODUCT', 2, 0, '成品反馈电缆', 0, 1)
ON DUPLICATE KEY UPDATE 
  `code` = VALUES(`code`),
  `name` = VALUES(`name`),
  `parent_id` = VALUES(`parent_id`),
  `item_or_product` = VALUES(`item_or_product`),
  `sort` = VALUES(`sort`),
  `deleted` = 0;

-- 清理冗余节点（光栅旧节点及产成品下重复的动子/定子，统一归入半成品）
UPDATE `mes_md_item_type` SET `deleted` = 1 WHERE `id` IN (30411, 30412, 30421, 30422, 30132, 30133);

SET FOREIGN_KEY_CHECKS = 1;
