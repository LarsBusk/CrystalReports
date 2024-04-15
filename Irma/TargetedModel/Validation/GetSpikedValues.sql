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
 )

 Create Table #Values
 (
		AnalysisTime datetime
	,	PredictionModelName nvarchar(50)
	,	Result float
	,	SampleID nvarchar(50)
	,	ParameterLogicalID int
	,	ProductLogicalID int
	,	InstrumentLogicalID int
	,	AuditTrailID int
	,	StdDev float
	,	Cnt int
 )

 Insert Into #Settings

 Select		th.ParameterLogicalID
		,	th.ShortName 
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
	Where		ptsg.PredictionModelTypeID = 133
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

select		sa.AnalysisEndUTC
		,	pm.Name 
		,	pv.DoubleResult
		,	sa.SampleNumber
		,	pa.ParameterLogicalID
		,	sa.ProductLogicalID
		,	sa.InstrumentLogicalID		
		,	sa.AuditTrailID
		,	StDev(pv.DoubleResult) Over (Partition By pa.ParameterLogicalID)
		,	Count(sa.SampleID) Over (Partition By pa.ParameterLogicalID, sa.ProductLogicalID)
--		,	*
from		tblMfCdSample sa
inner join	tblMfCdSubSample su
	on		su.SampleID = sa.SampleID
Inner join	tblMfCdPredictedValue pv
	on		pv.SubSampleID = su.SubSampleID
Inner Join	tblMfCdParameter pa
	on		pa.ParameterLogicalID = pv.ParameterLogicalID
Inner Join	tblMfCdPredictionModel pm
	on		pm.PredictionModelLogicalID = pa.PredictionModelLogicalID
Inner Join	tblMfCdParameterProfile pap
	on		pap.ParameterProfileLogicalID = pa.ParameterProfileLogicalID



where		sa.SampleID In ({?@SampleID}) -- Between 230 and 242
--	and		pv.ParameterLogicalID = 21
	and		pm.PredictionModelTypeID = 133 --GPD targeted model
	and		su.ParentSubSampleID Is Null
	and		pv.Type = 0
	and		pa.Obsolete = 0 and pap.Obsolete = 0 and pm.Obsolete = 0
order by	sa.SampleID	

Select		AnalysisTime
		,	PredictionModelName
		,	Result 
		,	SampleID 
		,	v.ParameterLogicalID 
		,	v.ProductLogicalID 
		,	InstrumentLogicalID 
		,	v.AuditTrailID 
		,	StdDev 
		,	Cnt 
		,	ParameterName 
		,	NumberOfDecimals
		,	GoodProductLimit 
		,	ProductName

From		#Settings s
Inner Join	#Values v
	On		s.ParameterLogicalID = v.ParameterLogicalId
	and		s.AuditTrailID = v.AuditTrailID

Drop Table #Settings
Drop Table #Values