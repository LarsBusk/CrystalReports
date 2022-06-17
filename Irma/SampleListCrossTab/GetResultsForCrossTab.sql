Select		sa.SampleID
		,	pa.Name as Parametername
		,	Cast(ROUND(pv.DoubleResult, pp.NumberOfDecimals) as nvarchar) + ' ' + dbo.udfMnmRepGetIntEnumString('Unit', pp.Unit) as Result

From		tblMfCdSample sa
Inner Join	tblMfCdSubSample su
	On		su.SampleID = sa.SampleID
Inner Join	tblMfCdPredictedValue pv
	On		pv.SubSampleID = su.SubSampleID
Inner Join	tblMfCdParameter pa
	On		pa.ParameterLogicalID = pv.ParameterLogicalID
Inner Join  tblMfCdParameterProfile pp
	on		pp.ParameterProfileLogicalID = pa.ParameterProfileLogicalID
Where		su.ParentSubSampleID Is Null
	and		pa.Obsolete = 0
	and		pv.Type = 0
	and		sa.SampleId In (3,4)--{?@SampleId})--5,61,77,156,157)


