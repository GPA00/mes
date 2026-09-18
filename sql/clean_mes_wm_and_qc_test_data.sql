-- ===================================================================
-- MES 仓储出入库 8 大单据与前置质检单【测试数据深度清洗脚本】
-- 执行模式：方案 A（清理业务单据与前置质检记录，安全保留库存现有量与台账）
-- 适用数据库: ruoyi-vue-pro (MySQL 8.0)
-- 创建时间: 2026-09-17
-- ===================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------
-- 第一部分：清洗前置质检单据模块（IQC 来料检验、OQC 出货检验、RQC 退货检验）
-- 说明：严格保留 IPQC 过程检验（生产车间工位巡检实绩数据不予破坏）
-- -------------------------------------------------------------------

-- 1.1 清理对应质检类型的指标检测明细与检测主记录 (1=IQC, 3=OQC, 4=RQC)
DELETE d FROM `mes_qc_indicator_result_detail` d
INNER JOIN `mes_qc_indicator_result` r ON d.`result_id` = r.`id`
WHERE r.`qc_type` IN (1, 3, 4);

DELETE FROM `mes_qc_indicator_result` WHERE `qc_type` IN (1, 3, 4);

-- 1.2 清理对应质检类型的缺陷记录 (1=IQC, 3=OQC, 4=RQC)
DELETE FROM `mes_qc_defect_record` WHERE `qc_type` IN (1, 3, 4);

-- 1.3 清理来料检验单 (IQC)
DELETE FROM `mes_qc_iqc_line`;
DELETE FROM `mes_qc_iqc`;

-- 1.4 清理出厂/出货检验单 (OQC)
DELETE FROM `mes_qc_oqc_line`;
DELETE FROM `mes_qc_oqc`;

-- 1.5 清理退货检验单 (RQC)
DELETE FROM `mes_qc_rqc_line`;
DELETE FROM `mes_qc_rqc`;


-- -------------------------------------------------------------------
-- 第二部分：清洗 8 大仓储业务单据（严格按 Detail -> Line -> Header 顺序）
-- -------------------------------------------------------------------

-- 2.1 采购入库单
DELETE FROM `mes_wm_item_receipt_detail`;
DELETE FROM `mes_wm_item_receipt_line`;
DELETE FROM `mes_wm_item_receipt`;

-- 2.2 到货通知单
DELETE FROM `mes_wm_arrival_notice_line`;
DELETE FROM `mes_wm_arrival_notice`;

-- 2.3 采购退货单（退供应商）
DELETE FROM `mes_wm_return_vendor_detail`;
DELETE FROM `mes_wm_return_vendor_line`;
DELETE FROM `mes_wm_return_vendor`;

-- 2.4 生产退料单（车间退料入库）
DELETE FROM `mes_wm_return_issue_detail`;
DELETE FROM `mes_wm_return_issue_line`;
DELETE FROM `mes_wm_return_issue`;

-- 2.5 产品入库单（完工生产入库）
DELETE FROM `mes_wm_product_receipt_detail`;
DELETE FROM `mes_wm_product_receipt_line`;
DELETE FROM `mes_wm_product_receipt`;

-- 2.6 发货通知单
DELETE FROM `mes_wm_sales_notice_line`;
DELETE FROM `mes_wm_sales_notice`;

-- 2.7 销售退货单（客户退货）
DELETE FROM `mes_wm_return_sales_detail`;
DELETE FROM `mes_wm_return_sales_line`;
DELETE FROM `mes_wm_return_sales`;

-- 2.8 销售出库单（成品发运出库）
DELETE FROM `mes_wm_product_sales_detail`;
DELETE FROM `mes_wm_product_sales_line`;
DELETE FROM `mes_wm_product_sales`;


-- -------------------------------------------------------------------
-- 第三部分：重置上述业务单据的自动编码流水号生成记录
-- （确保后续重新生成采购/销售/检验单据时，编码从 0001 重新递增起步）
-- -------------------------------------------------------------------
DELETE FROM `mes_md_auto_code_record` 
WHERE `rule_id` IN (
    SELECT `id` FROM `mes_md_auto_code_rule` 
    WHERE `code` IN (
        'WM_ITEM_RECEIPT_CODE',
        'WM_ARRIVAL_NOTICE_CODE',
        'WM_RETURN_VENDOR_CODE',
        'WM_RETURN_ISSUE_CODE',
        'WM_PRODUCT_RECEIPT_CODE',
        'WM_SALES_NOTICE_CODE',
        'WM_RETURN_SALES_CODE',
        'WM_PRODUCT_SALES_CODE',
        'QC_IQC_CODE',
        'QC_OQC_CODE',
        'QC_RQC_CODE'
    )
);

SET FOREIGN_KEY_CHECKS = 1;
