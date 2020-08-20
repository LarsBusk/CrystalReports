Use		MilkoScanFT3;


 Create table #Limits 
 (
		ParameterLogicalID int
	,	GoodProductLimit float
 )

 Create Table #Values
 (
		AnalysisTime datetime
	,	ParameterName nvarchar(50)
	,	Result float
	,	SampleID bigint
	,	ParameterLogicalID int
	,	Median float
	,	StdDev float
	,	Cnt int
 )	


 --Insert the current values of the Good Product detection limits
 Insert Into #Limits
	Select		pa.ParameterLogicalID
			,	ps.NumericValue

	From		tblMfCdPredictionModelTypeSettingGroup ptsg
	Inner Join	tblMfCdPredictionModelTypeSetting pts
		on		pts.PredictionModelTypeSettingGroupID = ptsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdParameterSetting ps
		on		ps.PredictionModelTypeSettingID = pts.PredictionModelTypeSettingID
	Inner Join	tblMfCdParameterSettingGroup psg
		on		psg.ParameterSettingGroupID = ps.ParameterSettingGroupID
	Inner Join	tblMfCdParameter pa
		on		pa.ParameterID = psg.ParameterID
	Where		ptsg.PredictionModelTypeID = 133
		and		ptsg.Identification = 'Threshold'
		and		pa.Obsolete = 0

Insert Into #Values

	Select		sa.AnalysisEndUTC
			,	pa.Name as ParamaterName
			,	pv.DoubleResult as Result
			,	sa.SampleID
			,	pa.ParameterLogicalID
			,	PERCENTILE_DISC(0.5) Within Group (Order By DoubleResult) Over (Partition By pa.ParameterLogicalID) 
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
		--and		sa.SampleID In ({?@SampleID})

Select		AnalysisTime 
		,	ParameterName 
		,	Result 
		,	SampleID 
		,	v.ParameterLogicalID
		,	Median
		,	StdDev
		,	Cnt
		,	GoodProductLimit
From		#Values v
Inner Join	#Limits l
	on		l.ParameterLogicalID = v.ParameterLogicalID
Order By v.ParameterLogicalID, Result

Drop Table #Limits
Drop Table #Values