CREATE PROCEDURE  SP3S_BUILDPMT_DATEWISE  
(  
 @dfirstdate dateTime,  
 @cErrormsg varchar(1000) output   
)  
with Recompile  
AS  
  
BEGIN  
  
  declare @cStep varchar(10),@dxndt dateTime,@cPmtTable varchar(100),@cCmd nvarchar(max),@cDbName varchar(100),@nSpId varchar(50),  
          @dfm_dt dateTime,@cprevPmtTable varchar(100),@dprevxndt dateTime,@CPMT_BUILD_DATEWISE varchar(10) ,@dCurDate DateTime 
  
 BEGIN TRY    
         
    set @cDbName=DB_NAME()  
    set @nSpId=newid()  
	SET @DCURDATE=CONVERT(VARCHAR(10),GETDATE(),121)
  
  --  SET  @CPMTDBNAME=DB_NAME()+'_PMT' 
  
    SELECT @CPMT_BUILD_DATEWISE=value FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION ='PMT_BUILD_DATEWISE'  
       
      
   
    set @cStep=10  
    PRINT 'STEP 110-:'+convert(varchar,getdate(),113)    
      
    EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
  
   

	   if isnull(@CPMT_BUILD_DATEWISE,'')<>'1'
	   begin

		 if object_id ('tempdb..#tmpXnsALL','u') is not null  
            drop table #tmpXnsALL  

        SELECT * into #tmpXnsALL FROM    
		(    
		SELECT convert(date,b.xn_dt) as xn_dt, a.dept_id, bin_id, a.product_code, xn_type, XN_QTY as Xn_qty      
        FROM  VW_XNSREPS_new A with (NOLOCK)      
        join #tmpdiff b on convert(date,a.xn_dt) between b.fm_dt and  b.xn_dt and a.DEPT_ID =b.DEPT_ID    
        join sku_names c (nolock) on a.product_code=c.product_code 
        where isnull(a.PRODUCT_CODE,'') <>'' AND ISNULL(C.STOCK_NA,0)=0    
		) A     
        PIVOT (SUM(A.XN_QTY)FOR A.XN_TYPE IN     ( 
        [OPS],[PRD],[PUR],[DCO],[SCC],[JWI],[MIR],[TTM],[WPR],[RPR],[GRNPSIN],[DNPR],[CHI],[SLR],[UNC],[APR],[WSR],[PFI],[cnpi],[DCI],
        [JWR],[SCF],[cnpr], [PRT],[CHO],[SLS],[CNC],[APP],[WSL],[MIS],[WPI],[RPI],[GRNPSOUT],[DNPI],[CIP],[BOC],[CBS]
        )) B          
  

      end 

	  CREATE INDEX IX_TMPXNS_XN_DT_DEPT_ID ON #tmpXnsALL(PRODUCT_CODE)  
	  INCLUDE (DEPT_ID,XN_DT)  
       
    set @cStep=20  
    PRINT 'STEP 20-:'+convert(varchar,getdate(),113)    
         
    EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   
	
	
   if @cDbName='PUMA_NEW'
      set @CPMT_BUILD_DATEWISE=1
        
  while exists (select top 1 'u' from #tmpdiff )  
  begin  
         
    select top 1 @dxndt=xn_dt,@dfm_dt=fm_dt from #tmpdiff order by xn_dt   
  
      if object_id ('tempdb..#tmpXns','u') is not null  
               drop table #tmpXns  
  
  
    select * into #tmpXns from #tmpXnsALL where xn_dt =@dxndt  
  
    set @cStep=25  
          PRINT 'STEP 25-:'+convert(varchar,getdate(),113)    
     
	 if @DCURDATE<>@dxndt
        SET @cPmtTable=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dxndt,112)    
	 else 
	     SET @cPmtTable='PMT01106'
  
     IF OBJECT_ID(@cPmtTable,'U') IS NULL                                
     BEGIN        
      EXEC  SP3S_CREATE_LOCWISEPMTXNS_STRU    @cDbName=@cDbName,    @dXnDt=@dXnDt,    @bInsPmt=0,    @bDonotChkDb=1                                
     END      
  
      
  
     set @cStep=30  
        PRINT 'STEP 35-:'+convert(varchar,getdate(),113)    
          
        EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
    
     if @dxndt=@dfirstdate  AND @dxndt <>@dCurDate and @cDbName<>'Puma_new'
     begin  
           
		set @cCmd=' Truncate table  '+@cPmtTable+' '  
		print @CCMD  
		   exec sp_executesql @CCMD  
  
		   SET @cCmd=N'insert into '+@cPmtTable+'(DEPT_ID,PRODUCT_CODE,BIN_ID,cbs_qty)  
		select a.dept_id, a.product_code,a.bin_id, sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'',''RPR'', ''WPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',  
		''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'')   
		then 1 else -1 end * xn_qty) CBSQty  
		from VW_XNSREPS_NEW a (nolock)   
		join sku_names c (nolock) on a.product_code=c.product_code
		where  xn_type not in (''TRI'', ''TRO'',''sac'',''sau'',''saum'',''sacm'')   
		and CONVERT(DATE, XN_DT) <='''+CONVERT(varchar,@dxndt,112)+'''   
		and isnull(a.PRODUCT_CODE,'''') <>''''  
		AND ISNULL(C.STOCK_NA,0)=0
		group by a.dept_id, a.product_code,a.bin_id   
		having sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'', ''WPR'',''RPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',  
		''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'')   
		then 1 else -1 end * xn_qty)<>0'  
		PRINT @cCmd  
		EXEC SP_EXECUTESQL @cCmd  
    
     end  
     Else   
     begin  

           set @dprevxndt=@dfm_dt -1  
           SET @CPREVPMTTABLE=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dprevxndt,112)    
  
		  set @cStep=40  
		  PRINT 'STEP 40-:'+convert(varchar,getdate(),113)    
           
       
        
        EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
      
		set @cCmd='  insert into #tmpXns (xn_dt,DEPT_ID,BIN_ID,PRODUCT_CODE,OPS)  
		SELECT '''+CONVERT(varchar,@dxndt,112)+''' as xn_dt, A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE ,a.CBS_QTY  
		FROM '+@CPREVPMTTABLE+'  A WITH (NOLOCK)  
		join #tmpdiff tmp on a.dept_id =tmp.dept_id   
		LEFT JOIN  #tmpXns  B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND A.DEPT_ID=B.DEPT_ID and b.xn_dt='''+CONVERT(varchar,@dxndt,112)+'''   
		WHERE B.PRODUCT_CODE IS NULL AND A.PRODUCT_CODE<>''''   
		and tmp.xn_dt='''+CONVERT(varchar,@dxndt,112)+'''   
		group by A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE,a.CBS_QTY '  
  
		print @CCMD  
        exec sp_executesql @CCMD  
      
  
		SET @CCMD='UPDATE A SET OPS=B.CBS_QTY FROM #TMPXNS A WITH (Nolock)  
		JOIN  '+@CPREVPMTTABLE+'  B with (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND A.DEPT_ID=B.DEPT_ID   
		WHERE A.XN_DT= '''+CONVERT(VARCHAR,@DXNDT,112)+''' and isnull(a.OPS,0)<>isnull(B.CBS_QTY,0) '  
		PRINT @CCMD  
        EXEC SP_EXECUTESQL @CCMD  
  
      
  
  
		set @cStep=50  
		PRINT 'STEP 50-:'+convert(varchar,getdate(),113)    
         
	   EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
  
      Update a set CBS =  (isnull([OPS],0)+isnull([PUR],0)+isnull([PRD],0)+isnull([MIR],0)+isnull([TTM],0)+isnull([WPR],0)+isnull([RPR],0)+isnull([GRNPSIN],0)+isnull([DNPR],0)+isnull([CHI],0)+isnull([SLR],0)+isnull([UNC],0)+isnull([APR],0)+isnull([WSR],0)+isnull([PFI],0)+isnull([DCI],0)+ isnull([JWR],0)+isnull([SCF],0)+isnull([cnpI],0))       -(isnull([PRT],0)+isnull([CHO],0)+isnull([SLS],0)+isnull([CNC],0)+isnull([APP],0)+isnull([WSL],0)+isnull([MIS],0)+
	  isnull([WPI],0)+isnull([RPI],0)+isnull([GRNPSOUT],0)+isnull([DNPI],0)+isnull([CIP],0)+  isnull([DCO],0)+isnull([JWI],0)++isnull([SCC],0)+isnull([BOC],0)+isnull([cnpR],0))       
      from  #tmpXns a WITH (Nolock)  
      WHERE A.XN_DT =@dxndt    
  

	   set @cStep=60  
	   PRINT 'STEP 60-:'+convert(varchar,getdate(),113)    
       
       EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
  
     if @dxndt=@dCurDate 
        Goto LblBuildCurPmt
     
       set @cCmd='   
      ;with cte as (  
      SELECT  A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE,ISNULL(a.CBS,0) as CBS  
      FROM #tmpXns  A  
      LEFT JOIN  '+@CPMTTABLE+'  B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND A.DEPT_ID=B.DEPT_ID   
      WHERE B.PRODUCT_CODE IS NULL AND A.PRODUCT_CODE<>'' ''  
      and  a.xn_dt= '''+CONVERT(varchar,@dxndt,112)+'''   
      group by A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE,ISNULL(a.CBS,0)  
      )   
        
       insert into '+@CPMTTABLE+'(DEPT_ID,BIN_ID,PRODUCT_CODE,cbs_qty)  
       select  A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE  ,CBS as cbs_qty  
       from cte a  
       '  
  
    print @CCMD  
    exec sp_executesql @CCMD  
    
    set @cStep=70  
    PRINT 'STEP 70-:'+convert(varchar,getdate(),113)    
        
     EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
  
    SET @CCMD=' UPDATE A SET CBS_QTY=ISNULL(B.CBS,0) FROM '+@CPMTTABLE+' A with (nolock)  
    JOIN #TMPDIFF TMP ON A.DEPT_ID =TMP.DEPT_ID   
    LEFT OUTER JOIN  #TMPXNS B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND A.DEPT_ID=B.DEPT_ID AND B.XN_DT='''+CONVERT(VARCHAR,@DXNDT,112)+'''   
    WHERE TMP.XN_DT='''+CONVERT(VARCHAR,@DXNDT,112)+'''   
    AND ISNULL(A.CBS_QTY,0)<>ISNULL(B.CBS,0) '  
  
    print @CCMD  
    exec sp_executesql @CCMD  
  
    set @cStep=80  
    PRINT 'STEP 80-:'+convert(varchar,getdate(),113)    
   EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
  
  
    set @cCmd=' delete a  from '+@CPMTTABLE+' a where isnull(cbs_qty,0)=0 '  
    print @CCMD  
    exec sp_executesql @CCMD  
  
   END  
   
  if isnull(@CPMT_BUILD_DATEWISE,'')='1'  
  begin  
       
   DELETE A FROM PMTLOCSCBS A (NOLOCK)
   JOIN #TMPDIFF B ON A.DEPT_ID=B.DEPT_ID AND A.XN_DT =B.XN_DT
   WHERE A.XN_DT =@DXNDT  

   set @cCmd=' INSERT PMTLOCSCBS (dept_id,xn_dt, cbs_qty  )  
   select a.dept_id ,'''+CONVERT(VARCHAR,@DXNDT,112)+''' as xn_dt,sum(a.cbs_qty)    
   from  '+@CPMTTABLE+'  a
   JOIN #TMPDIFF B ON A.DEPT_ID=B.DEPT_ID 
    WHERE b.XN_DT='''+CONVERT(VARCHAR,@DXNDT,112)+''' 
   group by a.dept_id  
   '  
    print @CCMD      
    exec sp_executesql @CCMD     
  
  end  
  
  
  LblBuildCurPmt:
  
  
  if @dxndt =@dCurDate 
  begin
  
  BEGIN TRANSACTION
  
    
      set @cCmd='   
      ;with cte as (  
      SELECT  A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE,ISNULL(a.CBS,0) as CBS  
      FROM #tmpXns  A  
      LEFT JOIN  '+@CPMTTABLE+'  B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND A.DEPT_ID=B.DEPT_ID and isnull(b.BO_ORDER_ID,'''')=''''  
      WHERE B.PRODUCT_CODE IS NULL AND A.PRODUCT_CODE<>'' ''  
      and  a.xn_dt= '''+CONVERT(varchar,@dxndt,112)+'''   
      group by A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE,ISNULL(a.CBS,0)  
      )   
        
       insert into '+@CPMTTABLE+'(DEPT_ID,BIN_ID,PRODUCT_CODE,Quantity_in_stock,last_update)  
       select  A.DEPT_ID, A.BIN_ID, A.PRODUCT_CODE  ,CBS as cbs_qty,getdate() as last_update 
       from cte a  
       '  
  
    print @CCMD  
    exec sp_executesql @CCMD  
    
    set @cStep=150  
    PRINT 'STEP 150-:'+convert(varchar,getdate(),113)    
        
     EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
     
   
  
    SET @CCMD=' UPDATE A SET Quantity_in_stock=ISNULL(B.CBS,0),last_update=getdate() FROM '+@CPMTTABLE+' A with (nolock)  
    JOIN #TMPDIFF TMP ON A.DEPT_ID =TMP.DEPT_ID   
    LEFT OUTER JOIN  #TMPXNS B ON A.PRODUCT_CODE=B.PRODUCT_CODE AND A.BIN_ID =B.BIN_ID AND A.DEPT_ID=B.DEPT_ID AND B.XN_DT='''+CONVERT(VARCHAR,@DXNDT,112)+'''   
    WHERE TMP.XN_DT='''+CONVERT(VARCHAR,@DXNDT,112)+'''   
    AND ISNULL(A.Quantity_in_stock,0)<>ISNULL(B.CBS,0) and  isnull(a.BO_ORDER_ID,'''')='''' and isnull(a.rep_id,'''')='''' and a.bin_id<>''999'' '  
  
    print @CCMD  
    exec sp_executesql @CCMD  
  
    set @cStep=160  
    PRINT 'STEP 160-:'+convert(varchar,getdate(),113)    
    EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   
    
 
    --allocated stock reduce in original stock
    
    UPDATE B SET QUANTITY_IN_STOCK =B.QUANTITY_IN_STOCK -A.QUANTITY_IN_STOCK ,last_update =GETDATE()
    FROM PMT01106 A (NOLOCK) 
    JOIN PMT01106 B ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID =B.BIN_ID 
    WHERE ISNULL(A.BO_ORDER_ID   ,'')<>'' AND ISNULL(B.BO_ORDER_ID,'')=''
     
    Delete A from pmt01106 a where quantity_in_stock =0 and isnull(rep_id ,'')='' and BIN_ID <>'999'
     
     
  
   END  
   

    EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1     
    DELETE FROM #TMPDIFF WHERE XN_DT =@DXNDT  
  
   END  
  
  set @cStep=150  
  PRINT 'STEP 150-:'+convert(varchar,getdate(),113)    
    
  
    
END TRY       
BEGIN CATCH    
 SET @cErrormsg='Error in Procedure SP3S_BUILDPMT_DATEWISE at Step#'+@cStep+' '+ERROR_MESSAGE()    
 GOTO END_PROC    
END CATCH    
END_PROC:  

IF @@TRANCOUNT >0
BEGIN
    
    IF ISNULL(@cErrormsg,'') =''
       COMMIT 
     ELSE
     Rollback

END
  
END