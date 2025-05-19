CREATE PROCEDURE SP3S_UPDATEPMT_WITHXNSRPT_LOC
(
 @cDept_id varchar(5),
 @cErrormsg varchar(1000) output
)
AS
BEGIN


BEGIN TRY

	
	SET @cErrormsg=''
	DECLARE @cCmd NVARCHAR(MAX),@cStep VARCHAR(6)
	
    
	SET @cStep='10'
    

	print 'view stock'

	
   if exists (select Top 1 'u' from pmt01106 where Pick_list_id <>'')
   begin
       Delete a  from pmt01106 (nolock) a where Pick_list_id <>''
   end

	
	CREATE TABLE  #PMTXNSUPD1(dept_id VARCHAR(4), product_code varchar(50),bin_id varchar(50),
	ORDER_ID varchar(50),Pick_list_id varchar(50), CBSQty numeric(10,3))
	

	SET @cStep='20'
    SET @cCmd=N'select a.dept_id, a.product_code,a.bin_id , sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'',''RPR'', ''WPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',
	''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'') 
	then 1 else -1 end * xn_qty) CBSQty
	from VW_XNSREPS_NEW a (nolock) 
	JOIN SKU_NAMES B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE
	where  xn_type not in (''TRI'', ''TRO'',''sac'',''sau'',''saum'',''sacm'') 
	AND BIN_ID <>''999'' and isnull(b.SKU_ITEM_TYPE,0)<>4
	and a.dept_id='''+@cDept_id+'''
	group by a.dept_id, a.product_code,a.bin_id 
	having sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'', ''WPR'', ''RPR'',''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',
	''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'') 
	then 1 else -1 end * xn_qty)<>0'

	PRINT @cCmd

	INSERT INTO #PMTXNSUPD1 (dept_id,product_code,bin_id,cbsqty)
	EXEC SP_EXECUTESQL @cCmd

	
	SET @CSTEP='32'
	SET @CCMD=N'UPDATE A SET QUANTITY_IN_STOCK = ISNULL(C.CBSQTY,0),LAST_UPDATE=GETDATE()  
	FROM  PMT01106 A WITH (ROWLOCK)
	JOIN SKU_NAMES B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE
	LEFT JOIN #PMTXNSUPD1 C ON A.DEPT_ID=C.DEPT_ID AND A.BIN_ID =C.BIN_ID AND A.PRODUCT_CODE =C.PRODUCT_CODE 
	WHERE isnull(b.SKU_ITEM_TYPE,0)<>4 and A.QUANTITY_IN_STOCK <>ISNULL(C.CBSQTY,0) AND A.BIN_ID<>''999'' AND A.DEPT_ID='''+@CDEPT_ID+''' 
	and isnull(a.rep_id,'''')='''' '
	
	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD

	
	SET @cStep='40'
	 SET @cCmd=N'INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK  )  
	 SELECT 	 A. BIN_ID,A. DEPT_ID,'''' DEPT_ID_NOT_STUFFED,GETDATE() last_update,A. product_code,
				A.CBSQty quantity_in_stock,'''' rep_id,0 STOCK_RECO_QUANTITY_IN_STOCK 				
	 FROM #PMTXNSUPD1 A
	 join location l (nolock) on a.dept_id =l.dept_id 
	 LEFT JOIN pmt01106 B (nolock) ON A.PRODUCT_CODE =B.product_code AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID=B.BIN_ID   AND ISNULL(B.BO_ORDER_ID,'''')=ISNULL(A.ORDER_ID,'''')
	 AND ISNULL(B.Pick_list_id,'''')=ISNULL(A.Pick_list_id,'''')
	 WHERE B.product_code IS NULL'

	 PRINT @cCmd
	 EXEC SP_EXECUTESQL @cCmd
	    
	

	END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'Error in Procedure SP3S_UPDATEPMT_WITHXNSRPT_LOC at Step#'+@cStep+ ' ' + ERROR_MESSAGE()
		GOTO END_PROC
	END CATCH
	
END_PROC:
	

END
