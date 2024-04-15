--Use		MilkoScanFT3;


 Create table #Settings 
 (
		ParameterLogicalID int
	,	ParameterName nvarchar(50)
	,	NumberOfDecimals int
	,	GoodProductLimit float
	,	ProductLogicalID int
	,	ProductName nvarchar(50)
	,	AuditTrailId int	
 )

 Create Table #Values
 (
		AnalysisTime datetime
	,	PredictionModelName nvarchar(50)
	,	Result float
	,	SampleID nvarchar(50)
	,	RealSampleId int
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
		,	s.ProductLogicalID
		,	s.ProductName
		,	AuditTrailID
			
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
	Where		ptsg.PredictionModelTypeID = 132
		and		ptsg.Identification = 'Threshold'
		and		pa.Obsolete = 0
		and		pp.Obsolete = 0
) th
Left join
(
	Select		atr.AuditTrailID
			,	atps.NumericValue
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
	Where		pmts.Identification In ('Threshold')
		and		pro.Obsolete = 0
) s
	on	s.ParameterLogicalID = th.ParameterLogicalID

Insert Into #Values

	Select		sa.AnalysisEndUTC
			,	pm.[Name] as PredictionModelName
			,	pv.DoubleResult as Result
			,	sa.SampleNumber
			,	sa.SampleID
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
		and		pm.PredictionModelTypeID = 132
		and		pv.DoubleResult Is Not Null
		and		sa.SampleID In ({?@SampleID})

Select		AnalysisTime 
		,	ParameterName 
		,	ProductName
		,	PredictionModelName
		,	ProductLogicalID
		,	Result
		,	SampleID 
		,	ROW_NUMBER() Over (Partition By ProductLogicalID, ParameterLogicalID Order By RealSampleId) as RowNumber
		,	RealSampleId
		,	ParameterLogicalID
		,	InstrumentLogicalID
		,	NumberOfDecimals
		,	PERCENTILE_DISC(0.5) Within Group (Order By Result) Over (Partition By ParameterLogicalID) as Median
		,	StdDev
		,	Cnt
		,	GoodProductLimit
		,	SUM(IsOverLimit) Over (Partition By ParameterLogicalID) * 100.0 / Count(SampleID) Over (Partition By ParameterLogicalID) as PercentOverLimit
		,	PERCENTILE_CONT(0.99) Within Group (Order By Result) Over (Partition By ParameterLogicalID) as SugLimit
		
From
(
Select		AnalysisTime 
		,	ParameterName 
		,	ProductName
		,	v.PredictionModelName
		,	v.ProductLogicalID
		,	Result
		,	SampleID 
		,	RealSampleId
		,	v.ParameterLogicalID
		,	InstrumentLogicalID
		,	NumberOfDecimals
		,	StdDev
		,	Cnt
		,	GoodProductLimit
		,	IIF(Result > GoodProductLimit, 1, 0) as IsOverLimit
From		#Values v
Inner Join	#Settings s
	on		s.ParameterLogicalID = v.ParameterLogicalID
	and		s.AuditTrailId = v.AuditTrailID
) as res
Order By ParameterLogicalID, RealSampleId

Drop Table #Settings
Drop Table #Values