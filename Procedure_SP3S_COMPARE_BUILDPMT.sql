CREATE PROCEDURE SP3S_COMPARE_BUILDPMT  --(LocId 3 digit change by Sanjay:04-11-2024)
(  
  @cErrormsg varchar(1000) output,
  @bclouddb bit =1
)  
as  
begin  
       
  Declare @cStep varchar(10),@dminxndt DateTime,@cCmd nvarchar(max),@dUptoDt dateTime,@dfmdate dateTime,  
          @cPmtTable varchar(100),@dfirstdate dateTime,@dVwMinXndt dateTime ,@nSpId varchar(50) ,@DPMTBUILDDATE VARCHAR(10),
          @ccurdbname varchar(100),@cpmtDbName varchar(100),@CDB_PATH varchar(1000),@PMTBUILD_CUTOFFDATE varchar(10),
		  @cPMT_BUILD_DATEWISE varchar(5),@dxndt dateTime
  
       SELECT @DPMTBUILDDATE=value   From config  where config_option= 'PMTBUILDDATE'
       SELECT @CPMT_BUILD_DATEWISE=value FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION ='PMT_BUILD_DATEWISE'

    BEGIN TRY    
    
	   set @ccurdbname=db_name()
	   SET  @CPMTDBNAME=DB_NAME()+'_PMT'  
	    
       DECLARE @TBLDATE TABLE (fm_dt DATETIME ,SRNO INT,MONTHDATE DATETIME)  
       
       IF OBJECT_ID('TEMPDB..#tmpdiff ','U') IS NOT NULL
	   DROP TABLE #tmpdiff
	   
       create table #tmpdiff(fm_dt dateTime ,xn_dt DateTime,dept_id varchar(4),CBS numeric(18,3),locpmtcbs numeric(18,3))
       
     
	  DECLARE @DT VARCHAR(20)  
	  SET @DT=GETDATE()  
	  SELECT @DT=SUBSTRING( @DT,12,LEN(@DT))  
	  IF  CAST(@DT AS DATETIME) BETWEEN '1900-01-01 11:00:00.000' AND '1900-01-01 19:59:00.000'  and @bclouddb=1
	  BEGIN  
		   GOTO END_PROC  
	  END  
	 
	 IF @DPMTBUILDDATE=CONVERT(VARCHAR(10),GETDATE(),121)
	    GOTO END_PROC

	set @nSpId=newid()
	set @cStep=5  



	EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   

    CREATE TABLE #tmpXnOps (dept_id varCHAR(4),xn_type VARCHAR(50),xnqty NUMERIC(20,3))    
   
    SELECT @dVwMinXndt= min(xn_dt) from vw_xnsreps_new With (nolock) where xn_dt <>''
    SET @dVwMinXndt=CONVERT(DATE,@dVwMinXndt)  
	

	IF ISNULL(@CPMT_BUILD_DATEWISE,'')='1' and DB_ID(@CPMTDBNAME) IS not NULL
   BEGIN
         SELECT @dminxndt=DATEADD(yy,-1,convert(date,getdate()))          
         select  @dminxndt=cast(cast((case when DATEPART(month, @dminxndt) < 4 then DATEPART(year, @dminxndt) - 1 else DATEPART(year, @dminxndt) end) as varchar(4))+'-04-'+'01' as dateTime)      
        
   END
    
   SELECT @PMTBUILD_CUTOFFDATE=value  FROM CONFIG WHERE CONFIG_OPTION ='PMTBUILD_CUTOFFDATE'
   SET @PMTBUILD_CUTOFFDATE=ISNULL(@PMTBUILD_CUTOFFDATE,'')
  
  IF DB_ID(@CPMTDBNAME) IS NULL     
   BEGIN    
       
     IF left(DB_NAME (),4)='PUMA'  
      SET @DMINXNDT='2022-07-01'  
    ELSE IF @PMTBUILD_CUTOFFDATE<>''
      SET @DMINXNDT=@PMTBUILD_CUTOFFDATE
	
	
    IF isnull(@dminxndt,'')<ISNULL(@dVwMinXndt,'')    
        set @dminxndt=DATEADD(month, -1, @dVwMinXndt)    
     
    if (@dminxndt<='2000-01-01' or isnull(@dminxndt,'')='')
    begin
        set @cErrormsg='Invalid minimum Pmt build Date '
        goto END_PROC
    end

	IF ISNULL(@CPMT_BUILD_DATEWISE,'')<>'1'
	begin

       ;with cte_date as   
	  (  
	  SELECT dateadd(month,datediff(month,0,getdate()),-1) as MONTHDATE,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0) fm_dt, 1 As SrNo union all  
	  SELECT dateadd(month,datediff(month,0,getdate())-srno,-1) as MONTHDATE,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-(srno+1), 0) fm_dt,srno+1 As SrNo  
	  from cte_date where fm_dt>@dminxndt  
	  )  
	 insert into @TBLDATE(fm_dt,MONTHDATE,SRNO)  
	 select fm_dt, MONTHDATE,SrNo from cte_date  
	 option (maxrecursion 32767);

	 end
	 else
	 begin
	      

		  set  @dUptoDt=convert(date,getdate()-1)  
		  
		  ;with cte_ALldate as   
		  (  
		  select @dminxndt as fm_dt, @dminxndt MONTHDATE, 1 as SrNo
		  union all
		  select fm_dt+1 fm_dt,MONTHDATE+1 as MONTHDATE,sr=SrNo+1 
		  from cte_ALldate where fm_dt+1<=@dUptoDt

		  )

		 insert into @TBLDATE(fm_dt,MONTHDATE,SRNO)  
		 select fm_dt, MONTHDATE,SrNo 
		 from cte_ALldate  
		 option (maxrecursion 32767);

	 end

	 
	insert into #tmpdiff(fm_dt,xn_dt,dept_id,CBS,locpmtcbs)
	select b.fm_dt ,b.MONTHDATE xn_dt,dept_id ,0 CBS,0 locpmtcbs  
    from location   a
    join @TBLDATE b on 1=1
        
     SELECT TOP 1   @CDB_PATH=REVERSE(RIGHT(REVERSE(PHYSICAL_NAME), LEN(PHYSICAL_NAME) - 
             (CASE WHEN CHARINDEX('\', REVERSE(PHYSICAL_NAME))>0 THEN  CHARINDEX('\', REVERSE(PHYSICAL_NAME)) ELSE CHARINDEX('/', REVERSE(PHYSICAL_NAME)) END ) ))  
    FROM SYS.DATABASES DB JOIN SYS.MASTER_FILES F ON DB.DATABASE_ID=F.DATABASE_ID  
    WHERE DB.NAME =DB_NAME() AND FILE_ID = 1 
           
    IF RIGHT(@CDB_PATH,1)<>'\'  
    SET @CDB_PATH=@CDB_PATH+'\'  
   
    SET @CCMD=N'CREATE DATABASE '+@CPMTDBNAME+'    
    ON    
    ( NAME = '+@CPMTDBNAME+'_DAT,    
    FILENAME = '''+@CDB_PATH+'\'+@CPMTDBNAME+'.MDF'')    
    LOG ON     
    ( NAME = '+@CPMTDBNAME+'_LOG,    
    FILENAME = '''+@CDB_PATH+'\'+@CPMTDBNAME+'.LDF'') '       
     
    PRINT @CCMD    
    EXEC SP_EXECUTESQL @CCMD
        
    
    
    goto lblpumbuild
    
    END   
  
  IF ISNULL(@CPMT_BUILD_DATEWISE,'')<>'1'  
   SELECT @dminxndt=DATEADD(yy,-2,convert(date,getdate()))    
  ELSE 
  begin
      SELECT @dminxndt=DATEADD(yy,-1,convert(date,getdate()))          
      select  @dminxndt=cast(cast((case when DATEPART(month, @dminxndt) < 4 then DATEPART(year, @dminxndt) - 1 else DATEPART(year, @dminxndt) end) as varchar(4))+'-04-'+'01' as dateTime)      
        

  end


   
   IF left(DB_NAME (),4)='PUMA'  
      SET @DMINXNDT='2022-07-01'  
   ELSE IF @PMTBUILD_CUTOFFDATE<>''
      SET @DMINXNDT=@PMTBUILD_CUTOFFDATE
	
    IF @dminxndt<ISNULL(@dVwMinXndt,'')    
          set @dminxndt=DATEADD(month, -1, @dVwMinXndt)       

    set  @dUptoDt=convert(date,getdate()-1)   
    set @dfmdate=@dminxndt 
    set @dfirstdate=@dfmdate  

  
   set @cStep=10  
   PRINT 'STEP 10:'+convert(varchar,getdate(),113)  

    if object_id ('pmtLocscbs','u') is null  and ISNULL(@cPMT_BUILD_DATEWISE,'')='1'    
    begin      
             
     SET @cCmd=N'EXEC DBO.SP3S_CREATELOCWISEPMT_SINGLE '''+@CCURDBNAME+''','''+convert(varchar(10),@DMINXNDT,121)+''' '      
     print @cCmd      
     EXEC SP_EXECUTESQL @cCmd      
            
    end     

   EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   
 
   if left(db_name (),4)='PUMA'  
   begin  
  
   SET @cCmd=N'select a.dept_id,xn_type,sum(xn_qty) xnqty 
   from vw_xnsreps_new a (nolock)   
   join loc_names b (nolock) on a.dept_id=b.dept_id  
   join sku_names c (nolock) on a.product_code=c.product_code  
   where CONVERT(DATE, XN_DT) <'''+CONVERT(varchar,@dminxndt,112)+'''    
   and isnull(a.PRODUCT_CODE,'''') <>''''
   and b.LOCattr15_key_name in(''HO INTEGRATION'',''PUMA SPONSORED'')  
   AND ISNULL(C.STOCK_NA,0)=0
   group by a.dept_id,xn_type'    
   INSERT INTO #tmpXnOps (dept_id,xn_type,xnqty)    
   exec sp_executesql @cCmd    
  
  
   end  
   else   
   begin  
          
     SET @cCmd=N'select a.dept_id,xn_type,sum(xn_qty) xnqty from vw_xnsreps_new a (nolock) 
     join sku_names c (nolock) on a.product_code=c.product_code   
     where CONVERT(DATE, XN_DT) <'''+CONVERT(varchar,@dminxndt,112)+'''    
	 and isnull(a.PRODUCT_CODE,'''') <>''''
	 AND ISNULL(C.STOCK_NA,0)=0
     group by a.dept_id,xn_type'    
     INSERT INTO #tmpXnOps (dept_id,xn_type,xnqty)    
     exec sp_executesql @cCmd    
  
  
   end  
  
     set @cStep=20  

	 EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   

    PRINT 'STEP 20:'+convert(varchar,getdate(),113)  
  
    SELECT @dfmdate as ops_dt,dept_id,sum(case when xn_type in ('PFI', 'WSR', 'APR', 'CHI', 'WPR', 'OPS', 'DCI', 'SCF', 'PUR', 'UNC', 'SLR',    
    'JWR','DNPR','TTM','API','PRD', 'PFG', 'BCG','MRP','PSB','JWR','MIR','GRNPSIN','MAQ','OLOAQ','CNPI')     
    then 1 else -1 end * xnqty) CBSQty   
    INTO #tmpObs   
    FROM #tmpXnOps    
    WHERE xn_type NOT IN ('TRI', 'TRO','sac','sau','saum','sacm','MAQ','MDQ','OLODQ','OLOAQ')     
    GROUP BY dept_id    
  
    set @cStep=30  
    PRINT 'STEP 30-:'+convert(varchar,getdate(),113)  

	EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1  
 
  	IF OBJECT_ID('TEMPDB..#tmptblxnx','U') IS NOT NULL
	   DROP TABLE #tmptblxnx

       create table #tmptblxnx  (xn_dt dateTime,dept_id varchar(4), xn_type varchar(10),XN_QTY numeric(18,3))

	   CREATE INDEX IX_TMPTBLXNX_XNDT ON #TMPTBLXNX(XN_DT)
	   INCLUDE (XN_TYPE)

  if left(db_name (),4)='PUMA'  
   begin  
		
		  INSERT INTO #TMPTBLXNX(XN_DT,DEPT_ID,XN_TYPE,XN_QTY)
		  SELECT CONVERT(DATE, XN_DT)  AS XN_DT, A.DEPT_ID, XN_TYPE, 
		         SUM(XN_QTY) AS XN_QTY  
		  FROM VW_XNSREPS_NEW A with (NOLOCK)    
		  JOIN LOC_NAMES B (NOLOCK) ON A.DEPT_ID=B.DEPT_ID    
		  join sku_names c (nolock) on a.product_code=c.product_code    
		  WHERE B.LOCATTR15_KEY_NAME IN('PUMA SPONSORED','HO INTEGRATION')  
		  AND ISNULL(A.PRODUCT_CODE,'')<>''
		  AND ISNULL(C.STOCK_NA,0)=0
		  GROUP BY CONVERT(DATE, XN_DT) , A.DEPT_ID, XN_TYPE
   
   end 
   else 
   begin
          INSERT INTO #TMPTBLXNX(XN_DT,DEPT_ID,XN_TYPE,XN_QTY)
		  SELECT CONVERT(DATE, XN_DT)  AS XN_DT, A.DEPT_ID, XN_TYPE, 
		         SUM(XN_QTY) AS XN_QTY  
		    FROM VW_XNSREPS_new A with (NOLOCK)    
		    join sku_names c (nolock) on a.product_code=c.product_code 
			WHERE  ISNULL(A.PRODUCT_CODE,'')<>''
			AND ISNULL(C.STOCK_NA,0)=0
		    GROUP BY CONVERT(DATE, XN_DT)  , A.DEPT_ID, XN_TYPE
   
   end 

    set @cStep=35
    EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   

	IF OBJECT_ID('TEMPDB..#TMPXNCBS','U') IS NOT NULL
	   DROP TABLE #TMPXNCBS

      SELECT * into #tmpXncbs FROM     (     
	   SELECT Xn_dt, a.DEPT_ID, XN_TYPE, XN_QTY 
	  FROM #tmptblxnx a 
	  ) A     
	  PIVOT (SUM(A.XN_QTY)FOR A.XN_TYPE IN    
	  ( [OPS],[PRD],[PUR],[MIR],[TTM],[WPR],[RPR],[GRNPSIN],[DNPR],[FIN-PRD],[CHI],[SLR],[UNC],[APR],[WSR],[PFI],[PFG],[BCG],[MRP],[DCI],[PSB],[JWR],[WIP-JWR],[SCF],[WIP-SCF],[cnpr],     
	  [PRT],[CHO],[SLS],[CNC],[APP],[WSL],[MIS],[WPI],[RPI],[GRNPSOUT],[DNPI],[CIP], [CRM], [DCO],[mIP],[CSB],[JWI],[DLM],[WIP-JWI],[SCC],[PRD_SCC],[WIP-SCC],[BOC],[cnpi], [CBS],[calCBS],[locpmtcbs])) B    
	  WHERE CONVERT(DATE, XN_DT)  BETWEEN @dfmdate AND @dUptoDt    
	  ORDER BY DEPT_ID, XN_DT   

 
    set @cStep=40  
    PRINT 'STEP 40-:'+convert(varchar,getdate(),113)    

    EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   

	IF OBJECT_ID('TEMPDB..#tmpdates','U') IS NOT NULL
	   DROP TABLE #tmpdates
    
	SELECT b.dept_id, DATEADD(DAY,number,@dfmdate) [Date]
		into #tmpdates
	 FROM MASTER..SPT_VALUES A
	 join (select dept_id from #tmptblxnx group by dept_id) b on 1=1
	 WHERE type = 'P'
	 AND DATEADD(DAY,number+1,@dfmdate) <= @dUptoDt+1

	  INSERT INTO #TMPXNCBS(DEPT_ID,XN_DT)
	  SELECT A.DEPT_ID,A.DATE  FROM #TMPDATES A
	  LEFT JOIN #TMPXNCBS B ON A.DEPT_ID=B.DEPT_ID AND A.DATE=B.XN_DT
	  WHERE B.XN_DT IS NULL

	 set @cStep=42  
    PRINT 'STEP 42-:'+convert(varchar,getdate(),113)    

	  Update a set calCBS =  (isnull([OPS],0)+isnull([PUR],0)+isnull([PRD],0)+isnull([MIR],0)+isnull([TTM],0)+
							  isnull([WPR],0)+isnull([RPR],0)+isnull([GRNPSIN],0)+isnull([DNPR],0)+isnull([FIN-PRD],0)+isnull([CHI],0)+isnull([SLR],0)+isnull([UNC],0)+isnull([APR],0)+isnull([WSR],0)+isnull([PFI],0)+isnull([PFG],0)+isnull([BCG],0)+isnull([MRP],0)+isnull([DCI],0)+isnull([PSB],0)+       isnull([JWR],0)+isnull([WIP-JWR],0)+isnull([SCF],0)+isnull([WIP-SCF],0)+isnull([cnpI],0))       
		                    -(isnull([PRT],0)+isnull([CHO],0)+isnull([SLS],0)+isnull([CNC],0)+isnull([APP],0)+isnull([WSL],0)+isnull([MIS],0)+
							  isnull([WPI],0)+isnull([RPI],0)+isnull([GRNPSOUT],0)+isnull([DNPI],0)+isnull([CIP],0)+ isnull([CRM],0)+ isnull([DCO],0)+isnull([mIP],0)+isnull([CSB],0)+isnull([JWI],0)+isnull([DLM],0)+        isnull([WIP-JWI],0)+isnull([SCC],0)+isnull([PRD_SCC],0)+isnull([WIP-SCC],0)+isnull([BOC],0)+isnull([cnpr],0))       
      from #TMPXNCBS a  

	   set @cStep=44  
	   PRINT 'STEP 44-:'+convert(varchar,getdate(),113)  
	   
	   	

	   UPDATE A SET OPS =isnull(a.OPS,0)+isnull(B.CBSQTY,0),cbs=isnull(calcbs,0) +isnull(B.CBSQTY,0)  FROM #TMPXNCBS A  
	   left JOIN #TMPOBS B ON A.DEPT_ID =B.DEPT_ID   and A.XN_DT =b.ops_dt  
	   WHERE A.XN_DT =@dfmdate 

	 
	    ;WITH xndt_CTE   as
	    (  
		SELECT xn_dt ,dept_id,ops  ,calCBS ,CBS
		FROM #TMPXNCBS A  
		where a.xn_dt =@dfmdate
		union all
		SELECT a.XN_DT+1 as XN_DT,A.DEPT_ID ,A.CBS AS OPS ,B.calCBS ,isnull(A.CBS,0)+ isnull(B.calCBS,0)
		FROM XNDT_CTE A
		JOIN #TMPXNCBS B ON a.XN_DT +1=B.XN_DT AND A.DEPT_ID =B.DEPT_ID 
		WHERE B.XN_DT<=@dUptoDt
		)

		Update a set OPS =b.OPS ,CBS =b.CBS  from #TMPXNCBS A
		join xndt_CTE b on a.dept_id =b.dept_id and a.xn_dt =b.xn_dt 
		option (maxrecursion 32767);
		
	
		 

    set @cStep=50  
    PRINT 'STEP 50-:'+convert(varchar,getdate(),113)    
    
	 EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   
	 
    IF ISNULL(@CPMT_BUILD_DATEWISE,'')<>'1'
	begin

	  ;with cte_date as   
	  (  
	  SELECT dateadd(month,datediff(month,0,getdate()),-1) as MONTHDATE,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-1, 0) fm_dt, 1 As SrNo union all  
	  SELECT dateadd(month,datediff(month,0,getdate())-srno,-1) as MONTHDATE,DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-(srno+1), 0) fm_dt,srno+1 As SrNo  
	  from cte_date where srno<24  
	  )  
	  insert into @TBLDATE(fm_dt,MONTHDATE,SRNO)  
	  select fm_dt, MONTHDATE,SrNo from cte_date  
  
	 DELETE A  FROM @TBLDATE A WHERE MONTHDATE <@DFIRSTDATE
	
	
    insert into #tmpdiff(fm_dt,xn_dt,dept_id,CBS,locpmtcbs)
    select b.fm_dt , xn_dt,dept_id ,CBS,locpmtcbs  
    from #TMPXNCBS  a
    join @TBLDATE b on a.xn_dt =b.MONTHDATE   
   -- where abs( isnull(CBS,0)-isnull(locpmtcbs,0)  )>.99
   
   
   
    
 
		   WHILE EXISTS (SELECT TOP 1 'U' FROM @TBLDATE)
		   begin
          
          
				  SELECT @DXNDT=MONTHDATE FROM  @TBLDATE ORDER BY MONTHDATE 
          
				  SET @cPmtTable=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dxndt,112) 
          
				   IF OBJECT_ID(@cPmtTable,'U') IS not  NULL                              
				   BEGIN      
						 print 'Update locpmtcbd'
			     
						  SET @CCMD=N'Update a set locpmtcbs=isnull(b.cbs_QTY,0) FROM #TMPDIFF A
						   left JOIN (SELECT  DEPT_ID ,SUM(CBS_QTY) CBS_QTY FROM  '+@CPMTTABLE+ ' WHERE ISNULL(PRODUCT_CODE,'''')<>'''' GROUP BY DEPT_ID) B ON A.DEPT_ID=B.DEPT_ID 
						   WHERE CONVERT(DATE, A.XN_DT) ='''+CONVERT(VARCHAR,@DXNDT,112)+''' 
						  '
						  PRINT  @CCMD
						  EXEC SP_EXECUTESQL @CCMD                       
				   END    
				   ELSE  				   BEGIN		        						UPDATE A SET LOCPMTCBS= ISNULL(CBS,0)+1 FROM #TMPDIFF A						WHERE CONVERT(DATE, A.XN_DT) =CONVERT(VARCHAR,@DXNDT,112)
			    
					END

				 delete from @TBLDATE where MONTHDATE=@DXNDT
   
		   END
		 
		   
 END
 ELSE
 BEGIN
      
	  Update a set locpmtcbs =isnull(b.cbs_qty,0) from #TMPXNCBS A      
	  left join pmtLocscbs b on a.dept_id =b.dept_id and a.xn_dt =b.xn_dt       
      
	   insert into #tmpdiff(fm_dt,xn_dt,dept_id,CBS,locpmtcbs)
	   select xn_dt fm_dt, xn_dt,dept_id ,CBS,locpmtcbs      
       from #TMPXNCBS        
      where abs( isnull(CBS,0)-isnull(locpmtcbs,0)  )>.99      
 

 END
 
   
     
    DELETE  FROM #TMPDIFF
    WHERE ABS( ISNULL(CBS,0)-ISNULL(LOCPMTCBS,0)  )<=.99
    
 
    set @cStep=60  
    PRINT 'STEP 60-:'+convert(varchar,getdate(),113)     
  
  lblpumbuild:
  
    IF ISNULL(@CPMT_BUILD_DATEWISE,'')='1'
   BEGIN
       INSERT INTO #TMPDIFF(FM_DT,XN_DT,DEPT_ID ,CBS ,LOCPMTCBS  )
       SELECT CONVERT(VARCHAR(10), GETDATE(),121) AS FM_DT,
              CONVERT(VARCHAR(10), GETDATE(),121) AS XN_DT,DEPT_ID,0 CBS,0 LOCPMTCBS
       FROM LOCATION 
   END
   else 
   begin
        
       INSERT INTO #TMPDIFF(FM_DT,XN_DT,DEPT_ID ,CBS ,LOCPMTCBS  )
       SELECT CONVERT(VARCHAR(10), DATEADD(DD,-(DAY(GETDATE())-1),GETDATE()),121) FM_DT, 
              CONVERT(VARCHAR(10), GETDATE(),121) AS XN_DT,DEPT_ID,0 CBS,0 LOCPMTCBS
       FROM LOCATION 
       
   end
   
 
   select top 1 @DFIRSTDATE=xn_dt   FROM #tmpdiff order by xn_dt  

   
   IF EXISTS (SELECT TOP 1 'U' FROM #tmpdiff)
   begin
        
        --date wise table create in th
        if isnull(@CPMT_BUILD_DATEWISE,'')='1'
        begin
        
			  if object_id ('tempdb..#tmpxnsdet','u') is not null      
			  drop table #tmpxnsdet    
	   
			 SELECT b.xn_dt, A.XN_TYPE ,A.DEPT_ID ,A.BIN_ID ,A.PRODUCT_CODE ,A.XN_QTY    
				 into #tmpxnsdet  
			 FROM VW_XNSREPS_new A (NOLOCK)  
			 JOIN #TMPDIFF B ON A.DEPT_ID =B.DEPT_ID AND convert(date,a.xn_dt)=B.XN_DT  
			 join sku_names c (nolock) on a.product_code=c.product_code     
			 where isnull(a.PRODUCT_CODE,'') <>'' AND ISNULL(C.STOCK_NA,0)=0   

		     SELECT * 
			 into #tmpXnsALL   
             FROM    
			(      
             SELECT a.xn_dt, a.dept_id, bin_id, a.product_code, xn_type, XN_QTY as Xn_qty          
              FROM  #tmpxnsdet A          
             ) A         
             PIVOT (SUM(A.XN_QTY)FOR A.XN_TYPE IN     ( 
             [OPS],[PRD],[PUR],[DCO],[SCC],[JWI],[MIR],[TTM],[WPR],[RPR],[GRNPSIN],[DNPR],[CHI],[SLR],[UNC],[APR],[WSR],[PFI],[cnpi],[DCI],
             [JWR],[SCF],[cnpr], [PRT],[CHO],[SLS],[CNC],[APP],[WSL],[MIS],[WPI],[RPI],[GRNPSOUT],[DNPI],[CIP],[BOC],[CBS]
             )) B              
        
        end 
       
       if object_id('LocationnotinUsestock','u') is not null--for Cantabil
       begin
               delete a from #TMPDIFF A
               join LocationnotinUsestock b (nolock) on a.dept_id=b.dept_id 
       end
   
       EXEC SP3S_BUILDPMT_DATEWISE @DFIRSTDATE, @CERRORMSG OUTPUT   
    
    end
  
  
    set @cStep=200  
    PRINT 'STEP 200-:'+convert(varchar,getdate(),113)    
	EXEC SP_CHKXNSAVELOG 'PMTBUILd',@cStep,1,@nSpId,'',1   

	

END TRY       
BEGIN CATCH    
 SET @cErrormsg='Error in Procedure SP3S_COMPARE_BUILDPMT at Step#'+@cStep+' '+ERROR_MESSAGE()    
 GOTO END_PROC    
END CATCH    
    
END_PROC:   
  IF EXISTS (SELECT TOP 1 'U'   FROM CONFIG  WHERE CONFIG_OPTION= 'PMTBUILDDATE')
	   UPDATE  CONFIG SET value =CONVERT(VARCHAR(10),GETDATE(),121)  WHERE CONFIG_OPTION= 'PMTBUILDDATE'
	ELSE
	BEGIN
	     
		 INSERT CONFIG	( config_option, Description, GROUP_NAME, last_update, REMARKS, row_id, value, VALUE_TYPE )  
		 SELECT 	'PMTBUILDDATE'  config_option,'PMTBUILDDATE' Description,'MISC' GROUP_NAME,getdate() last_update,'PMTBUILDDATE' REMARKS,newid() row_id,CONVERT(VARCHAR(10),GETDATE(),121) value,'Date' VALUE_TYPE 
		 


	END
  
end