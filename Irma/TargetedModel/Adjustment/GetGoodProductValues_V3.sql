Use		MilkoScanFT3;


 Create table #Settings 
 (
		ParameterLogicalID int
	,	ParameterName nvarchar(50)
	,	NumberOfDecimals int
	,	GoodProductLimit float
	,	ProductLogicalID int
	,	ProductName nvarchar(50)
	,	Intercept float
 )

 Create Table #Values
 (
		AnalysisTime datetime
	,	Result float
	,	SampleID nvarchar(50)
	,	ParameterLogicalID int
	,	InstrumentLogicalID int
	,	Median float
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
		,	IsNull(ic.Intercept, 0) as Intercept
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
	Select		pr.Name as ProductName
			,	pr.ProductLogicalID
			,	ipp.ParameterLogicalID
			,	IsNull(ipps.NumericValue, 0) as Intercept
			--,	*
	From		tblMfCdProduct pr
	Inner Join	tblMfCdInstrumentProductParameter ipp
		on		ipp.ProductLogicalID = pr.ProductLogicalID
	Inner Join	tblMfCdInstrumentProductParameterSettingGroup ippsg
		on		ippsg.InstrumentProductParameterID = ipp.InstrumentProductParameterID
	Inner Join	tblMfCdInstrumentProductParameterSetting ipps
		on		ipps.InstrumentProductParameterSettingGroupID = ippsg.InstrumentProductParameterSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSettingGroup pmtsg
		on		pmtsg.PredictionModelTypeSettingGroupID = ippsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSetting pmts
		on		pmts.PredictionModelTypeSettingGroupID = pmtsg.PredictionModelTypeSettingGroupID
		and		pmts.PredictionModelTypeSettingID = ipps.PredictionModelTypeSettingID
	Where		ipp.Obsolete = 0
		and		pr.Obsolete = 0
		and		pmts.Identification = 'Intercept'
) ic
	on		th.ParameterLogicalID = ic.ParameterLogicalID

Insert Into #Values

	Select		sa.AnalysisEndUTC
			,	pv.DoubleResult as Result
			,	sa.SampleNumber
			,	pa.ParameterLogicalID
			,	sa.InstrumentLogicalID
			,	PERCENTILE_DISC(0.5) Within Group (Order By DoubleResult) Over (Partition By pa.ParameterLogicalID) --Median
			,	StDev(DoubleResult) Over (Partition By pa.ParameterLogicalID)
			,	Count(sa.SampleID) Over (Partition By pa.ParameterLogicalID)

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
		and		sa.SampleID In ({?@SampleID})

Select		AnalysisTime 
		,	ParameterName 
		,	ProductName
		,	ProductLogicalID
		,	Result 
		,	SampleID 
		,	v.ParameterLogicalID
		,	InstrumentLogicalID
		,	NumberOfDecimals
		,	Median
		,	StdDev
		,	Cnt
		,	GoodProductLimit
		,	Intercept
From		#Values v
Inner Join	#Settings s
	on		s.ParameterLogicalID = v.ParameterLogicalID
Order By v.ParameterLogicalID, Result

Drop Table #Settings
Drop Table #Values