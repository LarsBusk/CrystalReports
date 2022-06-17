--USE [MilkoScanFT3];
declare @SamplesNotCanceled Table (SampleID int);

With DefTimes as
(
	Select		Min(ThisDef) as FirstDef
			,	Max(NextDef) as LastDef
			,	Max(ProductLogicalID) as ProductLogicalID
	From
	(
		Select		AnalysisStartUTC as ThisDef
				,	ISNULL(LEAD(AnalysisStartUTC, 1) Over (Order By SampleID), GETUTCDATE()) as NextDef
				,	SampleID
				,	ProductLogicalID
		From	tblMfCdSample
		Where	SampleType = 5
	) as defs
	Where	SampleID = {?SampleID}
)

--select * from DefTimes

Insert Into @SamplesNotCanceled
Select		SampleID
From		tblMfCdSample sa
Where		sa.AnalysisStartUTC Between (Select FirstDef From DefTimes) and (Select LastDef From DefTimes)
	and		sa.SampleType = 1
	and		sa.ProductLogicalID = (Select ProductLogicalID From DefTimes)
	and		SampleID Not In
(
	Select		sa.SampleID
	from		tblMfCdSample sa
	Inner Join	tblMfCdSubSample	sub
		on		sub.SampleID = sa.SampleID
	Inner Join	tblMfCdSubSampleEvent sue
		on		sue.SubSampleID = sub.SubSampleID
	Inner Join	tblMfAeEvent e
		on		e.EventID = sue.EventID
	Where		sa.SampleType = 1
		and		sa.AnalysisStartUTC Between (Select FirstDef From DefTimes) and (Select LastDef From DefTimes)
		and		e.EventCode = 14
)


declare @DerivedValueList Table (DerivedValueID bigint, PredictedValueID bigint, Type int, DoubleResult float)
insert into @DerivedValueList (DerivedValueID, PredictedValueID, Type, DoubleResult)
select dv.DerivedValueID,
       dv.PredictedValueID,
       dv.Type,
       dv.DoubleResult
 from tblMfCdDerivedValue dv
inner join tblMfCdPredictedValue pv on pv.PredictedValueID = dv.PredictedValueID
inner join tblMfCdSubSample ssp on ssp.SubSampleID = pv.SubSampleID
inner join tblMfCdSample sp on sp.SampleID = ssp.SampleID
where (dv.Type=17 or dv.Type = 18 or dv.Type=19 or dv.Type=23)
  and ssp.SequenceNumber = 0
  and sp.SampleType = 1

-- Get Sample list for last 5 days Check sample
declare @SampleList TABLE(NetWorkName nvarchar(50), InstrumentGroupName nvarchar(50), InstrumentName nvarchar(50),
                          SerialNumber nvarchar(50), ProductName nvarchar(50), ProductLogicalID int,
                          Parametername nvarchar(50), ParameterLogicalId int,  SampleID int, AnalysisStartUTC datetime, 
                          DoubleResult float, EventsStatus int, ProductLimitsStatus int, MovingAverage float, LowerMD float, UpperMD float, DefinitionSd float,
                          AuditTrailParameterID int)
insert into @SampleList (NetWorkName, InstrumentGroupName, InstrumentName, SerialNumber, ProductName, ProductLogicalID,
                         ParameterName, ParameterLogicalId, SampleID, AnalysisStartUTC,
                         DoubleResult, EventsStatus, ProductLimitsStatus, MovingAverage, UpperMD, LowerMD, DefinitionSd,
                         AuditTrailParameterID)
select nw.Name,
       imtg.Name,
       imt.Name,
       imt.SerialNumber,
       product.Name ProductName,
       product.ProductLogicalID,
       pmtp.Name ParameterName,
	   pmt.ParameterLogicalID,
       sp.SampleID,
       sp.AnalysisStartUTC,
       pv.DoubleResult,
       sp.EventsStatus,
       pv.ProductLimitsStatus,
       dvma.DoubleResult MovingAverage,
       dvup.DoubleResult UpperMD,
       dvlo.DoubleResult LowerMD,
       dvsd.DoubleResult DefinitionSD,
       atp.AuditTrailParameterID
  from tblmfcdsample sp
 inner join tblMfCdSubSample ssp on sp.SampleID = ssp.SampleID and ssp.ParentSubSampleID is null
 inner join tblMfCdPredictedValue pv on pv.SubSampleID = ssp.SubSampleID
  left join (select * from @DerivedValueList dv where dv.Type=17) dvma on dvma.PredictedValueID = pv.PredictedValueID
  left join (select * from @DerivedValueList dv where dv.Type=18) dvup on dvup.PredictedValueID = pv.PredictedValueID
  left join (select * from @DerivedValueList dv where dv.Type=19) dvlo on dvlo.PredictedValueID = pv.PredictedValueID
  left join (select * from @DerivedValueList dv where dv.Type=23) dvsd on dvsd.PredictedValueID = pv.PredictedValueID
 inner join tblMfCdAuditTrail at on at.AuditTrailID = sp.AuditTrailID
 inner join tblMfCdProduct product on product.ProductLogicalID = at.ProductLogicalID
 inner join tblMfCdInstrument imt on imt.InstrumentLogicalID = at.InstrumentLogicalID
 inner join tblMfCdInstrumentGroup imtg on imt.InstrumentGroupLogicalID = imtg.InstrumentGroupLogicalID
 inner join tblMfCdNetwork nw on nw.NetworkID = imtg.NetworkID
 inner join tblMfCdAuditTrailPredictionModel atpm on atpm.AuditTrailID = at.AuditTrailID
 inner join tblMfCdPredictionModel pm on pm.PredictionModelLogicalID = atpm.PredictionModelLogicalID and pm.Version = atpm.PredictionModelVersion
 inner join tblMfCdAuditTrailParameter atp on atp.AuditTrailPredictionModelID = atpm.AuditTrailPredictionModelID
 inner join tblMfCdParameter pmt on pmt.ParameterLogicalID = atp.ParameterLogicalID
 inner join tblMfCdParameterProfile pmtp on pmtp.ParameterProfileLogicalID = pmt.ParameterProfileLogicalID
 where sp.SampleType = 1
   and isnull(sp.Obsolete, 0) = 0
   and sp.SampleID In (Select SampleID From @SamplesNotCanceled)
   and ssp.SequenceNumber = 0
   and product.Latest = 1
   and imt.Obsolete = 0
   and imtg.Obsolete = 0
   and pmt.Obsolete = 0
   and pmtp.Obsolete = 0
   and pmt.PredictionModelLogicalID = atpm.PredictionModelLogicalID
   and pv.ParameterLogicalID = pmt.ParameterLogicalID
   and pv.Type = 0
 order by pmtp.Name, sp.AnalysisStartUTC

-- Get limits data from audit trail
declare @LimitList table (AuditTrailParameterID int, ProductLimitTypeID int, ProductLimitKind int, Limits float)
insert into @LimitList (AuditTrailParameterID, ProductLimitTypeID, ProductLimitKind, Limits)
select distinct crosssql.*, atplv.ProductLimitKind, atplv.Value Limits
  from (select rlst.AuditTrailParameterID, pltsql.ProductLimitTypeID
          from @SampleList rlst
         cross join (select ProductLimitTypeID
                       from tblMfCdProductLimitType
                      where ProductLimitTypeID in (1,2,4,8,16)) pltsql) crosssql
  left join tblMfCdAuditTrailProductLimitValue atplv on atplv.AuditTrailParameterID = crosssql.AuditTrailParameterID and atplv.ProductLimitTypeID = crosssql.ProductLimitTypeID

-- Combine sample data and limit data
-- TCR: Added MaxGrafDraw and MaxGrafDraw so that all of the graphs will have same max and min values thus giving same scale on report
--		also added the lines to draw using different colors for warning and action values
declare @LimitTable table(  NetWorkName nvarchar(50),
  InstrumentGroupName nvarchar(50),
  InstrumentName nvarchar(50),
  SerialNumber nvarchar(50),
  ProductName nvarchar(50),
  ProductLogicalID int,
  Parametername nvarchar(50),
  ParameterLogicalId int,
  SampleID int,
  AnalysisStartUTC datetime,
  DoubleResult float,
  EventsStatus int,
  ProductLimitsStatus int,
  MovingAverage float,
  LowerMD float,
  UpperMD float,
  DefinitionSD float,
  AuditTrailParameterID int,
  LowerAction float,
  LowerWarning float,
  Target float,
  UpperWarning float,
  UpperAction float)

insert @LimitTable
select rl.*,
       'LowerAction' = case when llla.ProductLimitKind=1 then llla.Limits
                            when llla.ProductLimitKind=2 then llt.Limits*(1-llla.Limits/100)
							when llla.ProductLimitKind=4 then llt.Limits - llla.Limits
                            when llla.ProductLimitKind=8 then llt.Limits - llla.Limits * rl.DefinitionSD
                            else null
                            end,
       'LowerWarning' = case when lllw.ProductLimitKind=1 then lllw.Limits
                             when lllw.ProductLimitKind=2 then llt.Limits*(1-lllw.Limits/100)
							 when lllw.ProductLimitKind=4 then llt.Limits - lllw.Limits
                             when lllw.ProductLimitKind=8 then llt.Limits - lllw.Limits * rl.DefinitionSD
                             else null
                             end,
       llt.Limits  'Target',
       'UpperWarning' = case when lluw.ProductLimitKind=1 then lluw.Limits
                             when lluw.ProductLimitKind=2 then llt.Limits*(1+lluw.Limits/100)
							 when lluw.ProductLimitKind=4 then llt.Limits + lluw.Limits
                             when lluw.ProductLimitKind=8 then llt.Limits + lluw.Limits * rl.DefinitionSD
                             else null
                             end,
       'UpperAction' = case when llua.ProductLimitKind=1 then llua.Limits
                             when llua.ProductLimitKind=2 then llt.Limits*(1+llua.Limits/100)
							 when llua.ProductLimitKind=4 then llt.Limits + llua.Limits
                             when llua.ProductLimitKind=8 then llt.Limits + llua.Limits * rl.DefinitionSD
                             else null
                             end
from @SampleList rl
inner join @LimitList llla on llla.AuditTrailParameterID = rl.AuditTrailParameterID
inner join @LimitList lllw on lllw.AuditTrailParameterID = rl.AuditTrailParameterID
inner join @LimitList llt on llt.AuditTrailParameterID = rl.AuditTrailParameterID
inner join @LimitList llua on llua.AuditTrailParameterID = rl.AuditTrailParameterID
inner join @LimitList lluw on lluw.AuditTrailParameterID = rl.AuditTrailParameterID
where llla.ProductLimitTypeID = 16
  and lllw.ProductLimitTypeID = 8
  and llt.ProductLimitTypeID = 4
  and lluw.ProductLimitTypeID = 2
  and llua.ProductLimitTypeID = 1

declare @ArrowTable table(
  NetWorkName nvarchar(50),
  InstrumentGroupName nvarchar(50),
  InstrumentName nvarchar(50),
  SerialNumber nvarchar(50),
  ProductName nvarchar(50),
  ProductLogicalID int,
  Parametername nvarchar(50),
  ParameterLogicalId int,
  SampleID int,
  AnalysisStartUTC datetime,
  DoubleResult float,
  EventsStatus int,
  ProductLimitsStatus int,
  MovingAverage float,
  LowerMD float,
  UpperMD float,
  DefinitionSD float,
  AuditTrailParameterID int,
  LowerAction float,
  LowerWarning float,
  Target float,
  UpperWarning float,
  UpperAction float,
  RedArrowUpper float,
  RedArrowLower float)

Declare @GroupedLimitTable table(ProductLogicalID int, Parametername nvarchar(50), MaxLim float, MinLim float)
insert into @GroupedLimitTable
select multiLimits.ProductLogicalID,
       multiLimits.Parametername,
       max(multiLimits.UpperLimits),
       min(multiLimits.LowerLimits)
 from (select lta.ProductLogicalID,
              lta.Parametername,
              lta.UpperAction as UpperLimits,
              lta.LowerAction as LowerLimits
         from @LimitTable lta union
       select ltw.ProductLogicalID,
              ltw.Parametername,
              ltw.UpperWarning as UpperLimits,
              ltw.LowerWarning as LowerLimits
         from @LimitTable ltw union
       select ltm.ProductLogicalID,
              ltm.Parametername,
              ltm.UpperMD as UpperLimits,
              ltm.LowerMD as LowerLimits
         from @LimitTable ltm) multiLimits
group by multiLimits.ProductLogicalID, multiLimits.Parametername

insert @ArrowTable
select r1.*,
       'RedArrowUpper' =  case when (t2.MaxLim+(t2.MaxLim-t2.MinLim)*0.1 < r1.DoubleResult) then t2.MaxLim+(t2.MaxLim-t2.MinLim)*0.1
			else NULL
			end,
       'RedArrowLower' =  case when (t2.MinLim-(t2.MaxLim-t2.MinLim)*0.1 > r1.DoubleResult) then t2.MinLim-(t2.MaxLim-t2.MinLim)*0.1
			else NULL
			end
FROM @LimitTable r1
left join @GroupedLimitTable t2 on r1.ProductLogicalID = t2.ProductLogicalID and r1.Parametername = t2.Parametername

Declare @MaxMinTable table(ProductLogicalID int, Parametername nvarchar(50), MaxVal float, MinVal float)
-- Gathering all max and min values
insert into @MaxMinTable
select ProductLogicalID,
       Parametername,
       max(DoubleResult),
       min(DoubleResult)
from @ArrowTable
where RedArrowUpper is null AND RedArrowLower is null
group by ProductLogicalID,Parametername

insert into @MaxMinTable
select ProductLogicalID, Parametername, max(Target), min(Target)
from @LimitTable group by ProductLogicalID, Parametername

insert into @MaxMinTable
select ProductLogicalID, Parametername, max(UpperMD), min(LowerMD)
from @LimitTable group by ProductLogicalID, Parametername

insert into @MaxMinTable
select ProductLogicalID, Parametername, max(UpperAction), min(LowerAction)
from @LimitTable group by ProductLogicalID, Parametername

insert into @MaxMinTable
select ProductLogicalID, Parametername, max(UpperWarning), min(LowerWarning)
from @LimitTable group by ProductLogicalID, Parametername

insert into @MaxMinTable
select ProductLogicalID, Parametername, max(RedArrowUpper), min(RedArrowLower)
from @ArrowTable group by ProductLogicalID, Parametername

insert into @MaxMinTable
select ProductLogicalID, Parametername, max(MovingAverage), min(MovingAverage)
from @ArrowTable group by ProductLogicalID, Parametername

-- Now find what values to use


select   NetWorkName,
	InstrumentGroupName,
	InstrumentName,
	SerialNumber,
    ProductName,
    --ProductLogicalID,
	Parametername,
	ParameterLogicalId,
	ROW_NUMBER() Over (Partition By ParameterName Order By SampleID ) as Row,
	SampleID,
	AnalysisStartUTC,
	r1.Doubleresult as RawResult,
	'DoubleResult' = CASE	when	((r1.Doubleresult < r1.LowerAction OR r1.DoubleResult > r1.UpperAction) OR
									((r1.Doubleresult < r1.LowerWarning AND r1.Doubleresult >= ISNULL(r1.LowerAction,r1.Doubleresult))
									OR (r1.DoubleResult > r1.UpperWarning AND r1.Doubleresult <= ISNULL(r1.UpperAction,r1.Doubleresult)))) Then NULL
							when	((r1.RedArrowUpper is not null OR r1.RedArrowLower is not null) and r1.EventsStatus != 2) then NULL
							when	((r1.LowerAction is null AND r1.UpperAction is null) and r1.EventsStatus != 2) AND
									((r1.UpperWarning is null AND r1.LowerWarning is null) and r1.EventsStatus != 1) then DoubleResult
							else	DoubleResult end,
    EventsStatus,
	ProductLimitsStatus,
    MovingAverage,
	LowerMD,
	UpperMD,
	LowerAction,
	LowerWarning,
	Target,
	UpperWarning,
	UpperAction,
	RedArrowUpper,
	RedArrowLower,
	'MaxGrafDraw' = (select MAX(MaxVal) from @MaxMinTable t1 where t1.ProductLogicalID = r1.ProductLogicalID and t1.Parametername=r1.Parametername) +
	                ((select MAX(MaxVal) from @MaxMinTable t1 where t1.ProductLogicalID = r1.ProductLogicalID and t1.Parametername=r1.Parametername)-
	                (select MIN(MinVal) from @MaxMinTable t1 where t1.ProductLogicalID = r1.ProductLogicalID and t1.Parametername=r1.Parametername))*0.1,
	'MinGrafDraw' = (select MIN(MinVal) from @MaxMinTable t1 where t1.ProductLogicalID = r1.ProductLogicalID and t1.Parametername=r1.Parametername) -
	                ((select MAX(MaxVal) from @MaxMinTable t1 where t1.ProductLogicalID = r1.ProductLogicalID and t1.Parametername=r1.Parametername)-
	                (select MIN(MinVal) from @MaxMinTable t1 where t1.ProductLogicalID = r1.ProductLogicalID and t1.Parametername=r1.Parametername))*0.1,
	'DROutsideAction' = CASE when(r1.LowerAction is null AND r1.UpperAction is null) and r1.EventsStatus != 2 THEN NULL
			when(r1.RedArrowUpper is not null OR r1.RedArrowLower is not null) and r1.EventsStatus != 2  THEN NULL
			when(r1.Doubleresult < r1.LowerAction OR r1.DoubleResult > r1.UpperAction) /*or r1.EventsStatus = 2*/ Then r1.DoubleResult
			else NULL END,
	'RDOutsideWarning' = CASE when(r1.UpperWarning is null AND r1.LowerWarning is null) and r1.EventsStatus != 1  THEN NULL
			when(r1.RedArrowUpper is not null OR r1.RedArrowLower is not null) THEN NULL
			when((r1.Doubleresult < r1.LowerWarning AND r1.Doubleresult >= ISNULL(r1.LowerAction,r1.Doubleresult))
				OR (r1.DoubleResult > r1.UpperWarning AND r1.Doubleresult <= ISNULL(r1.UpperAction,r1.Doubleresult))) Then r1.DoubleResult
			else NULL END
from @ArrowTable r1
order by ProductLogicalID, Parametername, AnalysisStartUTC