Use MilkoScanFT3;

select		pap.ShortName as ParameterName
		,	pa.ParameterLogicalID
		,	pm.Name as PredictionModelName
		,	pm.PredictionModelLogicalID
		,	sa.AnalysisEndUTC
		,	sa.SampleNumber
		,	pv.DoubleResult
		,	sa.SampleID
		,	sa.AuditTrailID
		,	sa.ProductLogicalID
		,	sa.InstrumentLogicalID
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



where		sa.SampleID Between 230 and 242
	and		pv.ParameterLogicalID = 21
	and		pm.PredictionModelTypeID = 133 --GPD targeted model
	and		su.ParentSubSampleID Is Null
	and		pv.Type = 0
	and		pa.Obsolete = 0 and pap.Obsolete = 0 and pm.Obsolete = 0
order by	sa.SampleID	


