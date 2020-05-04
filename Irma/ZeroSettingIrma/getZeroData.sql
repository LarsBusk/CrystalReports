Use		MilkoScanFT3;
 
Declare @WayOutLimit float = 1.75;
Declare @Days int = 5;

Select		pa.Name as ParameterName
		,	pa.ParameterLogicalID
		,	sam.AnalysisStartUTC
		,	sam.SampleID
--		,	pv.DoubleResult
		,	IIF(sam.EventsStatus <> 2 and sam.ProductLimitsStatus <> 2, pv.DoubleResult, Null) as AprovedZeroResult
		,	IIF(sam.EventsStatus = 2 and pv.DoubleResult <  @WayOutLimit * limits.UpperLimit and pv.DoubleResult >  @WayOutLimit * limits.LowerLimit, pv.Doubleresult, Null) as RejectedByEvent
		,	IIF(sam.ProductLimitsStatus = 2 and pv.DoubleResult <  @WayOutLimit * limits.UpperLimit and pv.DoubleResult >  @WayOutLimit * limits.LowerLimit, pv.doubleresult, Null) as RejectedByLimit
		,	IIF(sam.EventsStatus <> 2 and pv.DoubleResult >  @WayOutLimit * limits.UpperLimit, 1.5 * limits.UpperLimit, Null) as FarOver
		,	IIF(sam.EventsStatus <> 2 and pv.DoubleResult <  @WayOutLimit * limits.LowerLimit, 1.5 * limits.LowerLimit, Null) as FarUnder
--		,	sam.EventsStatus
--		,	sam.ProductLimitsStatus
		,	limits.LowerLimit
		,	limits.UpperLimit
--		,	*
From		tblMfCdSample sam
Inner Join	tblMfCdSubSample sub 
	on		sub.SampleID = sam.SampleID
Inner Join	tblMfCdPredictedValue pv
	on		pv.SubSampleID = sub.SubSampleID
Inner Join	tblMfCdParameter pa
	on		pa.ParameterLogicalID = pv.ParameterLogicalID
Inner Join	
(
	Select		pro.ProductLogicalID
			,	max(prlv.Value) as UpperLimit
			,	min(prlv.Value) as LowerLimit
	From		tblMfCdProduct pro 		
	Inner Join	tblMfCdProductPredictionModel prpm
		on		prpm.ProductID = pro.ProductID
	Inner Join	tblMfCdProductPredictionModelParameter prpmpa
		on		prpmpa.ProductPredictionModelID = prpm.ProductPredictionModelID
	Inner Join	tblMfCdProductLimitValue prlv
		on		prlv.ProductPredictionModelParameterID = prpmpa.ProductPredictionModelParameterID
	Where		pro.Obsolete = 0 
	Group By	pro.ProductLogicalID
) as limits
	on		limits.ProductLogicalID = sam.ProductLogicalID
Where		sam.SampleType = 7 --Zero setting
	and		sam.Obsolete = 0 --Not deleted
	and		pa.Obsolete = 0	
	and		sub.ParentSubSampleID Is Null --Only the main sample
	and		pv.Type = 0 --Main result
	and		sam.AnalysisStartUTC > DATEADD(Day, -@Days, GETDATE())
	and		sam.InstrumentLogicalID = 1 --{?InstrumentLogicalID}
Order by	sam.SampleID desc

