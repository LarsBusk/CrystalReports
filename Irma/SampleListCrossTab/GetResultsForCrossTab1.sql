use MilkoScanFT3;

Select		pa.Name as Parametername
		,	sa.SampleID
		,	pv.DoubleResult as Result
		,	sa.AnalysisStartUTC as SampleTime
		,	sa.SampleNumber
		,	dbo.udfMnmRepGetIntEnumString('Unit', pp.Unit) as Unit
		,	pp.NumberOfDecimals 
		,	pp.DisplayOrder
		,	su.Comment		
		,	ins.[Name] as InstrumentName
		,	ins.SerialNumber
		,	ig.[Name] as InstrumentGroupName
		,	net.[Name] as NetworkName
		--,*

From		tblMfCdSample sa
Inner Join	tblMfCdSubSample su
	On		su.SampleID = sa.SampleID
Inner Join	tblMfCdPredictedValue pv
	On		pv.SubSampleID = su.SubSampleID
Inner Join	tblMfCdParameter pa
	On		pa.ParameterLogicalID = pv.ParameterLogicalID
Inner Join	tblMfCdParameterProfile pp
	on		pp.ParameterProfileLogicalID = pa.ParameterProfileLogicalID
Inner Join	tblMfCdInstrument ins
	on		ins.InstrumentLogicalID = sa.InstrumentLogicalID
Inner Join	tblMfCdInstrumentGroup ig
	on		ig.InstrumentGroupLogicalID = ins.InstrumentGroupLogicalID
Inner Join	tblMfCdNetwork net
	on		ig.NetworkID = net.NetworkID
Where		su.ParentSubSampleID Is Null
	and		pa.Obsolete = 0
	and		pp.Obsolete = 0
	and		ins.Obsolete = 0
	and		ig.Obsolete = 0
	and		pv.Type = 0
	and		sa.SampleId In (
		Select SampleId
		From tblMfCdSample
		Where SampleType = 0)

	--{?@SampleId})--
