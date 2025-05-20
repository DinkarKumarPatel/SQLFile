CREATE VIEW VW_XNSREPS_NEW    
AS    
--chnages for git hub
CHANGES FOR GIT
 SELECT  A.DEPT_ID,    
   'OPS' AS XN_TYPE,     
   XN_DT,     
   'OPS' AS XN_NO,     
   A.DEPT_ID AS XN_ID,    
    A.PRODUCT_CODE AS PRODUCT_CODE,    
   CONVERT(VARCHAR(40),'') AS XN_PARTY_CODE,     
   A.QUANTITY_OB AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT     
   ,ISNULL(A.BIN_ID,'000')  AS [BIN_ID] ,
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast('' as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM OPS01106 A WITH (NOLOCK)
 
 
 UNION ALL    
     
 SELECT  B.DEPT_ID,    
   'PRD' AS XN_TYPE,     
   B.MEMO_DT  AS XN_DT,     
   B.MEMO_ID  AS XN_NO,  
   'PRD'+B.MEMO_ID  AS XN_ID,        
   A.PRODUCT_CODE AS PRODUCT_CODE,      
    'LOC' + DEPT_ID AS XN_PARTY_CODE,    
   A.QUANTITY AS XN_QTY,    
   A.MRP AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,'000'  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast('' as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM PRD_STK_TRANSFER_DTM_DET A WITH (NOLOCK)
 JOIN PRD_STK_TRANSFER_DTM_MST B WITH (NOLOCK) ON A.MEMO_ID = B.MEMO_ID     
 WHERE B.CANCELLED=0     
 
   
 UNION ALL    
   
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'DCO' AS XN_TYPE,     
   B.MEMO_DT   AS XN_DT,    
   B.MEMO_NO  AS XN_NO,     
   B.MEMO_ID  AS XN_ID,     
   A.PRODUCT_CODE AS PRODUCT_CODE,     
   CONVERT(VARCHAR(40),'') AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,         
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,A.SOURCE_BIN_ID  AS [BIN_ID]  ,   
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast('' as varchar(50)) AS order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM FLOOR_ST_DET A WITH (NOLOCK)
 JOIN FLOOR_ST_MST B WITH (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
 JOIN LOCATION C WITH (NOLOCK) ON C.DEPT_ID= B.location_code/*LEFT(A.MEMO_ID,2) *//*Rohit 05-11-2024*/
 WHERE  B.CANCELLED = 0    
     

 UNION ALL    
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'DCI' AS XN_TYPE,     
   B.RECEIPT_DT   AS XN_DT,    
   B.MEMO_NO  AS XN_NO,     
   B.MEMO_ID  AS XN_ID,     
   A.PRODUCT_CODE AS PRODUCT_CODE,     
   CONVERT(VARCHAR(40),'') AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,         
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,A.ITEM_TARGET_BIN_ID  AS [BIN_ID],
   cast('' as varchar(100))  AS BATCHLOTNO,
   cast('' as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM FLOOR_ST_DET A (NOLOCK)    
 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
 JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=  B.location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 05-11-2024*/
 WHERE  B.CANCELLED = 0 AND ISNULL(B.RECEIPT_DT,'')<>''     
         
 
 UNION ALL    
 
 SELECT B.DEPT_ID,    
 (CASE WHEN  (B.INV_MODE IN (0,1)) THEN 'PUR' ELSE 'CHI' END) AS XN_TYPE,     
 B.RECEIPT_DT AS XN_DT,    
 B.MRR_NO AS XN_NO,  
 'PIM'+B.MRR_ID AS XN_ID,     
 A.PRODUCT_CODE AS PRODUCT_CODE,     
 'LM'+B.AC_CODE AS XN_PARTY_CODE,     
 A.QUANTITY AS XN_QTY,    
 a.rfnet AS XN_NET,    
 CONVERT(NUMERIC(10,2),0) AS XN_DA,
 A.TAX_AMOUNT,   
 b.BIN_ID AS [BIN_ID],
 cast('' as varchar(100)) AS BATCHLOTNO,
 cast(a.Order_id  as varchar(50)) AS Order_id,
 cast('' as varchar(50)) AS Pick_list_id
 FROM PID01106 A WITH(NOLOCK)    
 JOIN PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID') LOC ON 1=1
 JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID') HO ON 1=1 
 LEFT OUTER JOIN pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
 WHERE B.CANCELLED = 0 AND c.mrr_id IS NULL
 AND A.PRODUCT_CODE<>'' AND B.RECEIPT_DT<>'' AND (b.inv_mode IN (0,1) OR loc.value<>ho.value)

 
 UNION ALL
 
 SELECT B.DEPT_ID,    
  'CHI' AS XN_TYPE,     
 B.RECEIPT_DT AS XN_DT,    
 B.MRR_NO AS XN_NO,  
 'PIM'+B.MRR_ID AS XN_ID,     
 A.PRODUCT_CODE AS PRODUCT_CODE,     
 'LM'+B.AC_CODE AS XN_PARTY_CODE,     
 A.QUANTITY AS XN_QTY,    
 CONVERT(NUMERIC(10,2),0) AS XN_NET,    
 CONVERT(NUMERIC(10,2),0) AS XN_DA,
 0  AS TAX_AMOUNT,   
 b.BIN_ID AS [BIN_ID],
 cast('' as varchar(100)) AS BATCHLOTNO ,
 cast('' as varchar(50)) AS Order_id,
 cast('' as varchar(50)) AS Pick_list_id
 FROM IND01106 A WITH(NOLOCK)    
 JOIN PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
 JOIN inm01106 d (nolock) on d.inv_id=a.inv_id
 WHERE B.CANCELLED = 0 AND b.inv_mode=2 AND d.cancelled=0
 AND B.RECEIPT_DT<>'' 
 
 UNION ALL
 SELECT B.location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID ,    
 'GRNPSIN' AS XN_TYPE,     
 B.MEMO_DT AS XN_DT,    
 B.MEMO_NO AS XN_NO,  
 B.MEMO_ID AS XN_ID,     
 A.PRODUCT_CODE AS PRODUCT_CODE,     
 'LM'+B.AC_CODE AS XN_PARTY_CODE,     
 cast(A.QUANTITY as numeric(10,3)) AS XN_QTY,    
 CONVERT(NUMERIC(10,2),0) AS XN_NET,    
 CONVERT(NUMERIC(10,2),0) AS XN_DA,
 0 AS TAX_AMOUNT,   
 a.BIN_ID AS [BIN_ID],
 cast('' as varchar(100)) AS BATCHLOTNO  ,
 cast('' as varchar(50)) AS Order_id,
 cast('' as varchar(50)) AS Pick_list_id
 FROM GRN_PS_DET  A WITH(NOLOCK)    
 JOIN GRN_PS_MST B WITH(NOLOCK) ON A.MEMO_ID  = B.MEMO_ID
 WHERE B.CANCELLED = 0 
 
 UNION ALL
 SELECT B.DEPT_ID,    
 'GRNPSOUT' AS XN_TYPE,     
 B.RECEIPT_DT AS XN_DT,    
 B.MRR_NO AS XN_NO,  
 B.MRR_ID AS XN_ID,     
 A.PRODUCT_CODE AS PRODUCT_CODE,     
 'LM'+B.AC_CODE AS XN_PARTY_CODE,     
 A.QUANTITY AS XN_QTY,    
 CONVERT(NUMERIC(10,2),0) AS XN_NET,    
 CONVERT(NUMERIC(10,2),0) AS XN_DA,
 A.TAX_AMOUNT,   
 b.BIN_ID AS [BIN_ID] ,
 cast('' as varchar(100)) AS BATCHLOTNO  ,
 cast(a.Order_id  as varchar(50)) AS Order_id,
 cast('' as varchar(50)) AS Pick_list_id
 FROM PID01106 A WITH(NOLOCK)    
 JOIN PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
 WHERE B.CANCELLED = 0 
 AND A.PRODUCT_CODE<>'' AND B.RECEIPT_DT<>''
 AND ISNULL(B.PIM_MODE,0)=6
 
 
 
 UNION ALL    
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   (CASE WHEN MODE=2 THEN 'CHO'  
    ELSE 'PRT' END) AS XN_TYPE,     
   B.RM_DT AS XN_DT,    
   B.RM_NO AS XN_NO,    
   'RMM'+B.RM_ID AS XN_ID,     
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   A.RFNET AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,A.ITEM_TAX_AMOUNT AS TAX_AMOUNT    
   ,A.BIN_ID  AS [BIN_ID] ,
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM RMD01106 A WITH(NOLOCK)
 JOIN RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
 JOIN LOCATION C WITH(NOLOCK) ON C.DEPT_ID=  B.location_code/*LEFT(A.RM_ID,2)*//*Rohit 05-11-2024*/
 WHERE B.CANCELLED = 0 AND B.DN_TYPE IN (0,1) 
    
 UNION ALL    
 
 
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,      
   ( CASE WHEN A.QUANTITY > 0 THEN 'SLS' ELSE 'SLR' END) AS XN_TYPE,       
   B.CM_DT AS XN_DT,      
   B.CM_NO AS XN_NO,      
   'CMM'+B.CM_ID AS XN_ID,    
   A.PRODUCT_CODE AS PRODUCT_CODE,      
   'CUS'+B.CUSTOMER_CODE AS XN_PARTY_CODE,       
   ABS(A.QUANTITY) AS XN_QTY,      
   ABS(A.RFNET) AS XN_NET,      
   ((A.QUANTITY*A.MRP)-(A.NET - (A.NET * B.DISCOUNT_PERCENTAGE/100)))*      
   (CASE WHEN A.QUANTITY>0 THEN 1 ELSE -1 END) AS XN_DA,  
   A.TAX_AMOUNT+isnull(a.igst_amount,0)+ isnull(a.cgst_amount,0)+isnull(a.sgst_amount,0)  as TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID],  
   cast('' as varchar(100)) AS BATCHLOTNO  ,  
   cast(''  as varchar(50)) AS Order_id,  
   cast('' as varchar(50)) AS Pick_list_id  
 FROM CMD01106 A WITH(NOLOCK)      
 JOIN CMM01106 B WITH(NOLOCK) ON A.CM_ID = B.CM_ID      
 JOIN LOCATION C WITH(NOLOCK) ON C.DEPT_ID=   B.location_code/*LEFT(A.CM_ID,2) *//*Rohit 05-11-2024*/
 WHERE B.CANCELLED = 0  
 --1
   
 
 UNION ALL    
 SELECT B.location_code/*LEFT(B.CM_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   ( CASE WHEN A.QUANTITY > 0 THEN 'RPI' ELSE 'RPR' END) AS XN_TYPE,     
   B.CM_DT AS XN_DT,    
   B.CM_NO AS XN_NO,    
   B.CM_ID AS XN_ID,  
   A.PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   ABS(A.RFNET) AS XN_NET,    
   ((A.QUANTITY*A.MRP)-(A.NET - (A.NET * B.DISCOUNT_PERCENTAGE/100)))*    
   (CASE WHEN A.QUANTITY>0 THEN 1 ELSE -1 END) AS XN_DA,A.TAX_AMOUNT    
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM RPS_DET A (NOLOCK)    
 JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID  
 WHERE B.CANCELLED = 0  
 
 UNION ALL    
 SELECT B.location_code/*LEFT(B.CM_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   ( CASE WHEN A.QUANTITY > 0 THEN 'RPR' ELSE 'RPI' END) AS XN_TYPE,     
   B.CM_DT AS XN_DT,    
   B.CM_NO AS XN_NO,    
   B.CM_ID AS XN_ID,  
   A.PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   ABS(A.RFNET) AS XN_NET,    
   ((A.QUANTITY*A.MRP)-(A.NET - (A.NET * B.DISCOUNT_PERCENTAGE/100)))*    
   (CASE WHEN A.QUANTITY>0 THEN 1 ELSE -1 END) AS XN_DA,A.TAX_AMOUNT    
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM RPS_DET A (NOLOCK)    
 JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID  
 JOIN cmm01106 c (NOLOCK) ON c.cm_id=b.ref_cm_id
 WHERE B.CANCELLED = 0  AND c.cancelled=0
   
 UNION ALL    
 SELECT B.location_code/*LEFT(B.MEMO_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   'APP' AS XN_TYPE,    
   B.MEMO_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   B.MEMO_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   (CASE WHEN B.MEMO_TYPE=1 THEN 'CUS'+B.CUSTOMER_CODE ELSE 'LM'+B.AC_CODE END) AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   A.RFNET AS XN_NET,((A.QUANTITY*A.MRP)-(A.NET - (A.NET * B.DISCOUNT_PERCENTAGE/100)))*    
   (CASE WHEN A.QUANTITY>0 THEN 1 ELSE -1 END) AS XN_DA,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM APD01106 A WITH(NOLOCK)    
 JOIN APM01106 B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 WHERE B.CANCELLED = 0    
   
 
 UNION ALL    
 SELECT C.location_code/*LEFT(C.MEMO_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   'APR' AS XN_TYPE,    
   C.MEMO_DT AS XN_DT,    
   C.MEMO_NO AS XN_NO,    
   C.MEMO_ID AS XN_ID,  
   a.apd_PRODUCT_CODE AS PRODUCT_CODE,    
   (CASE WHEN C.MODE=1 THEN 'CUS'+C.CUSTOMER_CODE ELSE 'LM'+C.AC_CODE END) AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   a.RFNET  AS XN_NET ,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM APPROVAL_RETURN_DET A WITH(NOLOCK)    
 JOIN APPROVAL_RETURN_MST C WITH(NOLOCK) ON C.MEMO_ID = A.MEMO_ID    
 WHERE  C.CANCELLED = 0    
     
   
 UNION ALL    
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
 (CASE WHEN B.STOCK_ADJ_NOTE=1 THEN 
	(CASE WHEN ISNULL(b.stock_adj_type,0) IN (0,1) THEN 
		   (CASE WHEN B.CNC_TYPE=1 THEN 'SAC' ELSE 'SAU' END)  
	 ELSE
		   (CASE WHEN B.CNC_TYPE=1 THEN 'SACM' ELSE 'SAUM' END)  
	 END)
 ELSE
 (CASE WHEN B.CNC_TYPE=1 THEN 'CNC' ELSE 'UNC' END) 	   	
  END) AS XN_TYPE,
   B.CNC_MEMO_DT AS XN_DT,    
   B.CNC_MEMO_NO AS XN_NO,    
   B.CNC_MEMO_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   CONVERT(VARCHAR(40),'') AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   A.RATE AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO   ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM ICD01106 A WITH(NOLOCK)    
 JOIN ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
 JOIN LOCATION C WITH(NOLOCK) ON C.DEPT_ID=B.location_code/*LEFT(A.CNC_MEMO_ID,2)*//*Rohit 05-11-2024*/  
 WHERE B.CANCELLED = 0   
     
  
 UNION ALL    
 SELECT B.location_code/*LEFT(b.inv_id,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   (CASE WHEN B.INV_MODE=2 THEN 'CHO' ELSE (CASE WHEN B.BIN_TRANSFER=1 THEN 'APO' ELSE 'WSL' END) END)  AS XN_TYPE,    
   B.INV_DT AS XN_DT,    
   B.INV_NO AS XN_NO,    
   'INM'+B.INV_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   A.RFNET AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   A.ITEM_TAX_AMOUNT AS TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM IND01106 A WITH(NOLOCK)    
 JOIN INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
 WHERE B.CANCELLED = 0   AND ISNULL(B.PENDING_GIT,0)=0
 
 
  
  UNION ALL
  
 SELECT B.location_code/*LEFT(b.inv_id,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   'WPR'  AS XN_TYPE,    
   c.INV_DT AS XN_DT,    
   b.PS_NO AS XN_NO,    
   a.ps_id AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   A.mrp*a.quantity AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   0 AS TAX_AMOUNT   
   ,a.BIN_ID  AS [BIN_ID] ,
   cast('' as varchar(100)) AS BATCHLOTNO,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM wps_det A WITH(NOLOCK)   
 JOIN wps_mst b (NOLOCK) ON  b.ps_id=a.ps_id
  JOIN INM01106 c WITH(NOLOCK) ON b.wsl_inv_id=c.inv_id
 WHERE B.CANCELLED = 0 AND c.cancelled=0 AND ISNULL(c.PENDING_GIT,0)=0
     
 
 UNION ALL    
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'API' AS XN_TYPE,    
   B.INV_DT AS XN_DT,    
   B.INV_NO AS XN_NO,    
   B.INV_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   A.RFNET AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   A.ITEM_TAX_AMOUNT AS TAX_AMOUNT   
   ,B.TARGET_BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM IND01106 A WITH(NOLOCK)    
 JOIN INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
 JOIN LOCATION C WITH(NOLOCK) ON C.DEPT_ID= B.location_code/*LEFT(A.INV_ID,2)*//*Rohit 05-11-2024*/ 
 WHERE B.CANCELLED = 0 AND B.BIN_TRANSFER=1  
 AND B.ENTRY_MODE<>2    AND ISNULL(B.PENDING_GIT,0)=0
    
 UNION ALL    
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'WPI'  AS XN_TYPE,    
   B.PS_DT AS XN_DT,    
   B.PS_NO AS XN_NO,    
   B.PS_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   0 AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   A.TAX_AMOUNT AS TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO   ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM WPS_DET A WITH(NOLOCK)    
 JOIN WPS_MST B WITH(NOLOCK) ON A.PS_ID = B.PS_ID    
 JOIN LOCATION C WITH(NOLOCK) ON C.DEPT_ID=  B.location_code/*LEFT(A.PS_ID,2)*//*Rohit 05-11-2024*/
 WHERE B.CANCELLED = 0   
 
 UNION ALL    

 SELECT LOC.MAJOR_DEPT_ID AS DEPT_ID,    
   (CASE WHEN MODE=2 THEN 'CHI'   
    ELSE   
    (CASE WHEN (B.BIN_TRANSFER=1 OR B.MODE=3) THEN 'API' ELSE 'WSR' END)  
    END) AS XN_TYPE,    
   (CASE WHEN MODE=2 THEN B.RECEIPT_DT ELSE CN_DT END) AS XN_DT,    
   B.CN_NO AS XN_NO,    
   'CNM'+B.CN_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   A.RFNET AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   A.ITEM_TAX_AMOUNT AS TAX_AMOUNT    
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM CND01106 A (NOLOCK)    
 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
 JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID=B.location_code/*LEFT(B.cn_id,2)*//*Rohit 05-11-2024*/
 WHERE B.CANCELLED = 0 AND B.CN_TYPE<>2 AND (MODE<>2 OR B.RECEIPT_DT<>'') 
  
  
 UNION ALL    
 SELECT (CASE WHEN B.BIN_TRANSFER=1 THEN B.location_code/*LEFT(B.CN_ID,2)*//*Rohit 05-11-2024*/ ELSE B.PARTY_DEPT_ID END) AS DEPT_ID,    
   (CASE WHEN B.BIN_TRANSFER=1 THEN 'APO' ELSE 'CHO' END) AS XN_TYPE,    
   CN_DT AS XN_DT,    
   B.CN_NO AS XN_NO,    
   'CNM'+B.CN_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   A.RFNET AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   A.ITEM_TAX_AMOUNT AS TAX_AMOUNT    
   ,case when isnull(B.SOURCE_BIN_ID,'')='' then b.BIN_ID else B.SOURCE_BIN_ID end   AS [BIN_ID] ,
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM CND01106 A (NOLOCK)    
 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
 LEFT OUTER JOIN LOCATION C ON C.DEPT_ID=B.PARTY_DEPT_ID  
 JOIN (SELECT TOP 1 * FROM  config WHERE CONFIG_OPTION='LOCATION_ID') CL ON 1=1
 JOIN (SELECT TOP 1 * FROM  config WHERE CONFIG_OPTION='HO_LOCATION_ID') HL ON 1=1
 WHERE B.CANCELLED = 0 AND B.BIN_TRANSFER=1

  and (CL.value =HL.value or CL.value = (CASE WHEN B.BIN_TRANSFER=1 THEN B.location_code/*LEFT(B.CN_ID,2)*//*Rohit 05-11-2024*/ ELSE B.PARTY_DEPT_ID END))
    
 UNION ALL     
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'PFI' AS XN_TYPE,    
   B.IRM_MEMO_DT AS XN_DT,    
   B.IRM_MEMO_NO AS XN_NO,    
   'IRM'+B.IRM_MEMO_ID AS XN_ID,  
   A.NEW_PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT ,    
   B.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100))  AS BATCHLOTNO  ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM IRD01106 A (NOLOCK)    
 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID    
 JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=  B.location_code/*LEFT(A.IRM_MEMO_ID,2)*//*Rohit 05-11-2024*/
 WHERE A.NEW_PRODUCT_CODE<>''    
    

 UNION ALL     
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'PFI' AS XN_TYPE,    
   B.MEMO_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   'SCM'+B.MEMO_ID AS XN_ID,     
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT      
   ,'000'  AS [BIN_ID] ,
   cast('' as varchar(100)) AS BATCHLOTNO,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM SCF01106 A (NOLOCK)    
 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 JOIN LOCATION C (NOLOCK) ON C.DEPT_ID= B.location_code/*LEFT(A.MEMO_ID,2) *//*Rohit 05-11-2024*/
 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>''    
     
 UNION ALL     
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'CIP' AS XN_TYPE,    
   B.IRM_MEMO_DT AS XN_DT,    
   B.IRM_MEMO_NO AS XN_NO,    
   'IRM'+B.IRM_MEMO_ID AS XN_ID,  
    A.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT  
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,   
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM IRD01106 A (NOLOCK)    
 JOIN IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID    
 JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=  B.location_code/*LEFT(A.IRM_MEMO_ID,2)*//*Rohit 05-11-2024*/
 WHERE  A.NEW_PRODUCT_CODE<>''    
     
 UNION ALL     
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'CIP' AS XN_TYPE,    
   B.MEMO_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   'SCM'+B.MEMO_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   cast(ABS(A.QUANTITY+ADJ_QUANTITY) as numeric (14,3)) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,'000'  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM SCC01106 A (NOLOCK)    
 JOIN SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=  B.location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 05-11-2024*/
 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>''     
      

  UNION ALL     
 SELECT LOC.MAJOR_DEPT_ID AS DEPT_ID,    
   'JWI' AS XN_TYPE,    
   B.ISSUE_DT AS XN_DT,    
   B.ISSUE_NO AS XN_NO,    
   B.ISSUE_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+D. AC_CODE AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA ,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT  
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM JOBWORK_ISSUE_DET A (NOLOCK)    
 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
 JOIN PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE      
 JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID=  B.location_code/*LEFT(A.ISSUE_ID,2)*//*Rohit 05-11-2024*/
 WHERE  B.CANCELLED=0 AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
 AND ISNULL(B.ISSUE_MODE,0)<>1  
     
 UNION ALL     
 SELECT LOC.MAJOR_DEPT_ID AS DEPT_ID,    
   'JWR' AS XN_TYPE,    
   B.RECEIPT_DT AS XN_DT,    
   B.RECEIPT_NO AS XN_NO,    
   B.RECEIPT_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+PAM.AC_CODE AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   ABS(A.JOB_RATE* A.QUANTITY) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA ,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM JOBWORK_RECEIPT_DET A (NOLOCK)    
 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID    
 JOIN JOBWORK_ISSUE_DET D (NOLOCK) ON D.ROW_ID=A.REF_ROW_ID    
 JOIN JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = D.ISSUE_ID    
 JOIN LOCATION LOC (NOLOCK) ON LOC.DEPT_ID=  B.location_code/*LEFT(A.RECEIPT_ID,2)*//*Rohit 05-11-2024*/
 JOIN PRD_AGENCY_MST PAM(NOLOCK) ON PAM.AGENCY_CODE=B.AGENCY_CODE  
 WHERE  B.CANCELLED=0 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 
 UNION ALL    
 
 SELECT D.location_code/*LEFT(D.ORDER_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,          
 'BOC' AS XN_TYPE,      
 D.ORDER_DT AS XN_DT,     
 D.ORDER_NO AS XN_NO,      
 D.ORDER_ID AS XN_ID,  
 E.PRODUCT_CODE AS PRODUCT_CODE,      
 'CUS'+D.CUSTOMER_CODE AS XN_PARTY_NAME,       
 cast((E.CONS_QTY_PER_PICE*P.QUANTITY) as numeric(14,3)) AS XN_QTY,       
 0 AS XN_NET,    
 CONVERT(NUMERIC(10,2),0) AS XN_DA,    
 CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT  
 ,'000'  AS [BIN_ID],
 cast('' as varchar(100)) AS BATCHLOTNO,
 cast(''  as varchar(50)) AS Order_id,
 cast('' as varchar(50)) AS Pick_list_id
 FROM WSL_ORDER_BOM E(NOLOCK)     
 LEFT OUTER JOIN WSL_ORDER_DET C (NOLOCK) ON E.REF_ROW_ID=C.ROW_ID    
 LEFT OUTER JOIN WSL_ORDER_MST D (NOLOCK) ON C.ORDER_ID=D.ORDER_ID    
 JOIN POD01106 P ON C.ROW_ID = P.WOD_ROW_ID     
 JOIN POM01106 PM ON P.PO_ID = PM.PO_ID      
 --LEFT OUTER JOIN SKU ON E.PRODUCT_CODE=SKU.PRODUCT_CODE    
 WHERE  PM.CANCELLED = 0    
    
 UNION ALL   

 SELECT B.location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 05-11-2024*/ AS [DEPT_ID],    
   'SCF' AS XN_TYPE,    
   B.RECEIPT_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   B.MEMO_ID AS XN_ID,  
   B2.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   cast((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN B2.TOTAL_QTY ELSE A.QUANTITY END) as Numeric(10,3)) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT  
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM SNC_DET A (NOLOCK)    
 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 JOIN  
 (  
 SELECT REFROW_ID AS [ROW_ID],PRODUCT_CODE,COUNT(*) AS [TOTAL_QTY]  
 FROM SNC_BARCODE_DET (NOLOCK)  
 GROUP BY REFROW_ID,PRODUCT_CODE  
 )B2 ON A.ROW_ID = B2.ROW_ID  
 JOIN ARTICLE A1 WITH(NOLOCK) ON A1.ARTICLE_CODE=A.ARTICLE_CODE 
 JOIN SKU S1(NOLOCK) ON S1.product_code=B2.PRODUCT_CODE 
 WHERE  B.WIP=0 AND B.CANCELLED=0 AND B2.PRODUCT_CODE<>''    
  
 UNION ALL     
   
 SELECT B.location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 05-11-2024*/ AS [DEPT_ID],   
   'SCC' AS XN_TYPE,    
   B.RECEIPT_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   B.MEMO_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,ISNULL(A.BIN_ID,'000')  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO   ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM SNC_CONSUMABLE_DET A (NOLOCK)    
 JOIN SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 WHERE A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>''   
 UNION ALL  
   
  SELECT  B.location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 05-11-2024*/ AS [DEPT_ID],   
   'TTM' AS XN_TYPE,    
   B.MEMO_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   B.MEMO_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QTY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,'000'  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM PRD_TRANSFER_MAIN_DET A (NOLOCK)    
 JOIN PRD_TRANSFER_MAIN_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>''     
 UNION ALL  
   
  SELECT LEFT(A.MEMO_ID,2)/*Rohit 05-11-2024*/ AS [DEPT_ID],   
   'TTM' AS XN_TYPE,    
   B.MEMO_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   B.MEMO_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,'000'  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO  ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM PPC_TRANSFER_TO_TRADING_DET A (NOLOCK)    
 JOIN PPC_TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>''
 
  UNION ALL  
  SELECT B.location_code/*LEFT(A.MEMO_ID,2)*//*Rohit 05-11-2024*/ AS [DEPT_ID],   
   'TTM' AS XN_TYPE,    
   B.MEMO_DT AS XN_DT,    
   B.MEMO_NO AS XN_NO,    
   B.MEMO_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   '' AS XN_PARTY_CODE,     
   ABS(A.QUANTITY) AS XN_QTY,    
   CONVERT(NUMERIC(10,2),0) AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT    
   ,A.BIN_ID   AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM TRANSFER_TO_TRADING_DET A (NOLOCK)    
 JOIN TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
 WHERE B.CANCELLED=0 AND A.PRODUCT_CODE<>''            

  
 UNION ALL    
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'DNPI'  AS XN_TYPE,    
   B.PS_DT AS XN_DT,    
   B.PS_NO AS XN_NO,    
   B.PS_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   0 AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   0 AS TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM DNPS_DET A (NOLOCK)    
 JOIN DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
 JOIN LOCATION C (NOLOCK) ON C.DEPT_ID= B.location_code/*LEFT(A.PS_ID,2) *//*Rohit 05-11-2024*/
 WHERE B.CANCELLED = 0    

  
  UNION ALL
  
  SELECT B.location_code/*LEFT(B.ps_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   'DNPR'  AS XN_TYPE,    
   c.RM_DT AS XN_DT,    
   b.PS_NO AS XN_NO,    
   b.ps_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   0 AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,
   0 AS TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID] ,
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM dnps_det A (NOLOCK)    
 JOIN dnps_mst B (NOLOCK) ON A.ps_ID = B.ps_ID 
 JOIN rmm01106 C (NOLOCK) ON b.prt_rm_id=c.rm_id
 WHERE B.CANCELLED = 0 AND ISNULL(A.PS_ID,'')<>''
 
 
 UNION ALL    
 SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   'CNPI'  AS XN_TYPE,    
   B.PS_DT AS XN_DT,    
   B.PS_NO AS XN_NO,    
   B.PS_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   0 AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,    
   0 AS TAX_AMOUNT   
  ,a.BIN_ID  AS [BIN_ID],
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM CNPS_DET A (NOLOCK)    
 JOIN CNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
 JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=  B.location_code/*LEFT(A.PS_ID,2)*//*Rohit 05-11-2024*/
 WHERE B.CANCELLED = 0    

 
  UNION ALL
  
  SELECT B.location_code/*LEFT(B.PS_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   'CNPR'  AS XN_TYPE,    
   C.CN_DT AS XN_DT,    
   B.PS_NO AS XN_NO,    
   b.ps_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'LM'+B.AC_CODE AS XN_PARTY_CODE,     
   A.QUANTITY AS XN_QTY,    
   0 AS XN_NET,    
   CONVERT(NUMERIC(10,2),0) AS XN_DA,
   0 AS TAX_AMOUNT   
   ,A.BIN_ID  AS [BIN_ID] ,
   cast('' as varchar(100)) AS BATCHLOTNO ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM CNPS_DET A (NOLOCK)    
 JOIN CNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID 
 JOIN cnm01106 C ON B.wsr_cn_id=C.cn_id    
 WHERE B.CANCELLED = 0 
 
 UNION ALL
  SELECT B.location_code/*LEFT(B.ISSUE_ID,2)*//*Rohit 05-11-2024*/ AS DEPT_ID
		,CASE WHEN ISNULL(B.ISSUE_TYPE,0)=0 THEN 'MIS' ELSE 'MIR' END AS XN_TYPE
	    ,B.ISSUE_DT AS XN_DT
	    ,B.ISSUE_NO AS XN_NO
		,B.ISSUE_ID AS XN_ID
	    ,A.PRODUCT_CODE
	   ,'LM'+D.AC_CODE AS XN_PARTY_CODE
	   ,ABS(A.STOCK_QTY) AS XN_QTY
	   ,CONVERT(NUMERIC(10,2),0) AS XN_NET
	   ,CONVERT(NUMERIC(10,2),0) AS XN_DA  
	   ,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT
	   ,A.BIN_ID  AS [BIN_ID]
	   ,'' AS BATCHLOTNO ,     
	   a.BOM_ORDER_ID AS Order_id,
	   cast('' as varchar(50)) AS Pick_list_id
  FROM BOM_ISSUE_DET A (NOLOCK)  
  JOIN BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
  JOIN PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE  
  WHERE B.CANCELLED=0     

  union all
   SELECT C.MAJOR_DEPT_ID AS DEPT_ID,    
   ( CASE WHEN A.QUANTITY > 0 THEN 'SLS' ELSE 'SLR' END) AS XN_TYPE,     
   B.CM_DT AS XN_DT,    
   B.CM_NO AS XN_NO,    
   'CMM'+B.CM_ID AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'CUS'+B.CUSTOMER_CODE AS XN_PARTY_CODE,     
   cast(ABS(A.QUANTITY) as numeric(10,3)) AS XN_QTY,    
   0 AS XN_NET,    
   0 AS XN_DA,
   0  as TAX_AMOUNT 
   ,'000'  AS [BIN_ID],
   '' AS BATCHLOTNO     ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM cmd_cons A WITH(NOLOCK)    
 JOIN CMM01106 B WITH(NOLOCK) ON A.CM_ID = B.CM_ID    
 JOIN LOCATION C WITH(NOLOCK) ON C.DEPT_ID=B.location_code/*LEFT(A.CM_ID,2)*//*Rohit 05-11-2024*/  
 WHERE B.CANCELLED = 0  
 
  union all
   SELECT B.location_code/*Left(b.memo_id,2)*//*Rohit 05-11-2024*/ AS DEPT_ID,    
   'SLS' AS XN_TYPE,     
   B.memo_dt AS XN_DT,    
   B.memo_no AS XN_NO,    
   'DLV'+B.memo_id AS XN_ID,  
   A.PRODUCT_CODE AS PRODUCT_CODE,    
   'CUS'+B.CUSTOMER_CODE AS XN_PARTY_CODE,     
   cast(ABS(A.QUANTITY) as numeric(10,3)) AS XN_QTY,    
   0 AS XN_NET,    
   0 AS XN_DA,
   0  as TAX_AMOUNT 
   ,'000'  AS [BIN_ID],
   '' AS BATCHLOTNO     ,
   cast(''  as varchar(50)) AS Order_id,
   cast('' as varchar(50)) AS Pick_list_id
 FROM sls_delivery_cons A WITH(NOLOCK)    
 JOIN sls_delivery_mst B WITH(NOLOCK) ON A.memo_id = B.memo_id    
 WHERE B.CANCELLED = 0  
 
 UNION ALL  
  select  b.location_code AS DEPT_ID,      
  'SLS' AS XN_TYPE,       
   convert(varchar(10),GETDATE(),121) AS XN_DT,      
   'PENDINGRECO' AS XN_NO,      
    'GRRECO'+b.cm_ID AS XN_ID,    
    a.ProductCode AS PRODUCT_CODE,      
   'CUS'+b.CUSTOMER_CODE AS XN_PARTY_CODE,       
    sum(A.GRQuantity -A.RecoQty)  AS XN_QTY,      
    0 AS XN_NET,      
    0 AS XN_DA,  
    0  as TAX_AMOUNT   
   ,cmd.BIN_ID   AS [BIN_ID],  
   '' AS BATCHLOTNO     ,  
   cast(''  as varchar(50)) AS Order_id,  
   cast('' as varchar(50)) AS Pick_list_id   
 from POSGRRecos A (nolock)
 join cmd01106 cmd (nolock) on A.CMDRowId =cmd.ROW_ID 
 join cmm01106 b (nolock) on A.cm_id =b.cm_id 
 where b.CANCELLED =0
 group by b.location_code, b.cm_ID,b.CUSTOMER_CODE,a.ProductCode,cmd.BIN_ID
 having sum(A.GRQuantity -A.RecoQty)>0
--2
  UNION ALL
  SELECT LEFT(B.memo_id,2) AS DEPT_ID
		,CASE WHEN ISNULL(B.MEMO_TYPE ,0)=1 THEN 'MAQ' ELSE 'MDQ' END AS XN_TYPE
	    ,B.memo_dt AS XN_DT
	    ,B.memo_no AS XN_NO
		,B.memo_id AS XN_ID
	    ,A.PRODUCT_CODE
	   ,'' AS XN_PARTY_CODE
	   ,ABS(A.QUANTITY) AS XN_QTY
	   ,CONVERT(NUMERIC(10,2),0) AS XN_NET
	   ,CONVERT(NUMERIC(10,2),0) AS XN_DA  
	   ,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT
	   ,A.BIN_ID  AS [BIN_ID]
	   ,'' AS BATCHLOTNO     
	   ,cast(CASE WHEN B.MEMO_TYPE =1 THEN A.REF_ORDER_ID ELSE '' END  as varchar(50)) AS Order_id,
	   cast('' as varchar(50)) AS Pick_list_id
  FROM BOMDQRQDET  A (NOLOCK)  
  JOIN BOMDQRQMST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
  WHERE B.CANCELLED=0     
   UNION ALL
  SELECT LEFT(B.memo_id,2) AS DEPT_ID
		,CASE WHEN ISNULL(B.MEMO_TYPE ,0)=1 THEN 'MDQ' ELSE 'MAQ' END AS XN_TYPE
	    ,B.memo_dt AS XN_DT
	    ,B.memo_no AS XN_NO
		,B.memo_id AS XN_ID
	    ,A.PRODUCT_CODE
	   ,'' AS XN_PARTY_CODE
	   ,(A.QUANTITY) AS XN_QTY
	   ,CONVERT(NUMERIC(10,2),0) AS XN_NET
	   ,CONVERT(NUMERIC(10,2),0) AS XN_DA  
	   ,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT
	   ,A.BIN_ID  AS [BIN_ID]
	   ,'' AS BATCHLOTNO     
	   ,cast(CASE WHEN B.MEMO_TYPE =1 THEN '' ELSE A.REF_ORDER_ID  END  as varchar(50)) AS Order_id,
	   cast('' as varchar(50)) AS Pick_list_id
  FROM BOMDQRQDET  A (NOLOCK)  
  JOIN BOMDQRQMST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
  WHERE B.CANCELLED=0 
  UNION ALL
  SELECT b.DEPT_ID  AS DEPT_ID
		,'OLODQ' AS XN_TYPE
	    ,a.order_dt AS XN_DT
	    ,a.order_no  AS XN_NO
		,a.order_id  AS XN_ID
	    ,b.PRODUCT_CODE
	   ,'' AS XN_PARTY_CODE
	   ,(b.quantity_in_stock) AS XN_QTY
	   ,CONVERT(NUMERIC(10,2),0) AS XN_NET
	   ,CONVERT(NUMERIC(10,2),0) AS XN_DA  
	   ,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT
	   ,b.BIN_ID  AS [BIN_ID]
	   ,'' AS BATCHLOTNO     
	   , cast(''  as varchar(50))  AS Order_id,
	   cast('' as varchar(50)) AS Pick_list_id
  FROM BUYER_ORDER_MST   A (NOLOCK)  
  JOIN pmt01106 B (NOLOCK) ON A.order_id  = isnull(B.bo_order_id ,'')  
  left outer join cmm01106 cmm (nolock) on isnull(cmm.BOM_ORDER_ID,'') =a.order_id and cmm.CANCELLED =0
  WHERE a.CANCELLED=0  and a.MODE =3
  and b.quantity_in_stock<>0 and cmm.BOM_ORDER_ID is null
   UNION ALL
  SELECT b.DEPT_ID  AS DEPT_ID
		,'OLOAQ' AS XN_TYPE
	    ,a.order_dt AS XN_DT
	    ,a.order_no  AS XN_NO
		,a.order_id  AS XN_ID
	    ,b.PRODUCT_CODE
	   ,'' AS XN_PARTY_CODE
	   ,(b.quantity_in_stock) AS XN_QTY
	   ,CONVERT(NUMERIC(10,2),0) AS XN_NET
	   ,CONVERT(NUMERIC(10,2),0) AS XN_DA  
	   ,CONVERT(NUMERIC(10,2),0) AS TAX_AMOUNT
	   ,b.BIN_ID  AS [BIN_ID]
	   ,'' AS BATCHLOTNO     
	   , A.order_id   AS Order_id,
	   cast('' as varchar(50)) AS Pick_list_id
  FROM BUYER_ORDER_MST   A (NOLOCK)  
  JOIN pmt01106 B (NOLOCK) ON A.order_id  = isnull(B.bo_order_id ,'')  
  left outer join cmm01106 cmm (nolock) on isnull(cmm.BOM_ORDER_ID,'') =a.order_id and cmm.CANCELLED =0
  WHERE a.CANCELLED=0  and a.MODE =3
  and b.quantity_in_stock<>0 and cmm.BOM_ORDER_ID is null
 
--***************** END OF CREATING VIEW VW_XNSREPS 

