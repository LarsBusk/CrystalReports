Use		MilkoScanFT3;


 Create table #Settings 
 (
		ParameterLogicalID int
	,	ParameterName nvarchar(50)
	,	NumberOfDecimals int
	,	GoodProductLimit float
	,	ProductLogicalID int
	,	ProductName nvarchar(50)
	,	AuditTrailId int	
	,	Slope float
	,	Intercept float
 )

 Create Table #Values
 (
		AnalysisTime datetime
	,	Result float
	,	SampleID nvarchar(50)
	,	ParameterLogicalID int
	,	ProductLogicalID int
	,	InstrumentLogicalID int
	,	AuditTrailID int
	,	StdDev float
	,	Cnt int
 )	


 --Insert the current values of the Good Product detection limits
 Insert Into #Settings

Select		th.ParameterLogicalID
		,	th.ShortName as ParameterName
		,	th.NumberOfDecimals
		,	th.GoodProductLimit
		,	ic.ProductLogicalID
		,	ic.ProductName
		,	AuditTrailID
		,	Slope	
		,	Intercept
			
From
(
Select			pa.ParameterLogicalID
			,	ps.NumericValue as GoodProductLimit
			,	pp.NumberOfDecimals
			,	pp.ShortName
	From		tblMfCdPredictionModelTypeSettingGroup ptsg
	Inner Join	tblMfCdPredictionModelTypeSetting pts
		on		pts.PredictionModelTypeSettingGroupID = ptsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdParameterSetting ps
		on		ps.PredictionModelTypeSettingID = pts.PredictionModelTypeSettingID
	Inner Join	tblMfCdParameterSettingGroup psg
		on		psg.ParameterSettingGroupID = ps.ParameterSettingGroupID
	Inner Join	tblMfCdParameter pa
		on		pa.ParameterID = psg.ParameterID
	Inner Join	tblMfCdParameterProfile pp
		on		pp.ParameterProfileLogicalID = pa.ParameterProfileLogicalID
	Where		ptsg.PredictionModelTypeID = 133
		and		ptsg.Identification = 'Threshold'
		and		pa.Obsolete = 0
		and		pp.Obsolete = 0
) th
Left join
(
	Select		AuditTrailID
			,	PredictionModelLogicalID
			,	ParameterLogicalID
			,	ProductLogicalID
			,	Slope
			,	Intercept
			,	ProductName
From
(
	Select		atr.AuditTrailID
			,	atps.NumericValue
			,	pmts.Identification
			,	atpm.PredictionModelLogicalID
			,	atpa.ParameterLogicalID
			,	atr.ProductLogicalID
			,	pro.Name as ProductName

	From		tblMfCdAuditTrail atr
	Inner Join	tblMfCdAuditTrailPredictionModel atpm
		on		atpm.AuditTrailID = atr.AuditTrailID
	Inner Join	tblMfCdAuditTrailParameter atpa
		on		atpa.AuditTrailPredictionModelID = atpm.AuditTrailPredictionModelID
	Inner Join	tblMfCdAuditTrailParameterSettingGroup atpsg
		on		atpsg.AuditTrailParameterID = atpa.AuditTrailParameterID
	Inner Join	tblMfCdAuditTrailParameterSetting atps
		on		atps.AuditTrailParameterSettingGroupID = atpsg.AuditTrailParameterSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSettingGroup pmtsg
		on		pmtsg.PredictionModelTypeSettingGroupID = atpsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSetting pmts
		on		pmts.PredictionModelTypeSettingGroupID = pmtsg.PredictionModelTypeSettingGroupID
		and		pmts.PredictionModelTypeSettingID = atps.PredictionModelTypeSettingID
	Inner Join	tblMfCdProduct pro
		on		pro.ProductLogicalID = atr.ProductLogicalID
	Where		pmts.Identification In ('Intercept', 'Slope')
		and		pro.Obsolete = 0
) as s
pivot 
(
	Max(NumericValue)
	For Identification In (Slope, Intercept)
) as p
) ic
	on		th.ParameterLogicalID = ic.ParameterLogicalID

Insert Into #Values

	Select		sa.AnalysisEndUTC
			,	pv.DoubleResult as Result
			,	sa.SampleNumber
			,	pa.ParameterLogicalID
			,	sa.ProductLogicalID
			,	sa.InstrumentLogicalID
			,	sa.AuditTrailID
			,	StDev(DoubleResult) Over (Partition By pa.ParameterLogicalID)
			,	Count(sa.SampleID) Over (Partition By pa.ParameterLogicalID, sa.ProductLogicalID)

	From		tblMfCdSample sa
	Inner Join	tblMfCdSubSample su
		On		sa.SampleID = su.SampleID
	Inner Join	tblMfCdPredictedValue pv
		on		pv.SubSampleID = su.SubSampleID
	Inner Join	tblMfCdParameter pa
		on		pa.ParameterLogicalID = pv.ParameterLogicalID
	Inner Join	tblMfCdPredictionModel pm
		on		pm.PredictionModelLogicalID = pa.PredictionModelLogicalID

	Where		pa.Obsolete = 0
		and		pm.Obsolete = 0
		and		pv.Type = 0
		and		sa.SampleType = 0
		and		su.ParentSubSampleID is NULL
		and		pm.PredictionModelTypeID = 133
		and		pv.DoubleResult Is Not Null
		and		sa.SampleID In (73618,73619,73617,73616,73615,72791,72790,72789,72788,72787,72786,72785)

Select		AnalysisTime 
		,	ParameterName 
		,	ProductName
		,	ProductLogicalID
		,	Result
		,	SampleID 
		,	ParameterLogicalID
		,	InstrumentLogicalID
		,	NumberOfDecimals
		,	PERCENTILE_DISC(0.5) Within Group (Order By Result) Over (Partition By ParameterLogicalID) as Median
		,	StdDev
		,	Cnt
		,	GoodProductLimit
		,	Slope
		,	Intercept
From
(
Select		AnalysisTime 
		,	ParameterName 
		,	ProductName
		,	v.ProductLogicalID
		,	(Result - Intercept) / Slope as Result
		,	SampleID 
		,	v.ParameterLogicalID
		,	InstrumentLogicalID
		,	NumberOfDecimals
		,	StdDev
		,	Cnt
		,	GoodProductLimit
		,	Intercept
		,	Slope
From		#Values v
Inner Join	#Settings s
	on		s.ParameterLogicalID = v.ParameterLogicalID
	and		s.AuditTrailId = v.AuditTrailID
) as res
Order By ParameterLogicalID, AnalysisTime

Drop Table #Settings
Drop Table #Values