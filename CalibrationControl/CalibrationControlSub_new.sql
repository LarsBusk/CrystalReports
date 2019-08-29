Select			sa.AnalysisStartUTC
			,	sa.SampleID
			,	pre.DoubleResult
			,	rv.[Value] as ReferenceValue
			,	rv.[Value] - pre.DoubleResult as [Difference]
			,	pm.[Name] as PmName
			,	0.7 as UpperError
			,	0.3 as UpperWarning
			,	-0.7 as LowerError
			,	-0.3 as LowerWarning
			,	*

From			tblMfCdSample sa
Inner Join		tblMfCdSubSample sub
	on			sub.SampleID = sa.SampleID
Inner Join		tblMfCdPredictedValue pre
	on			pre.SubSampleID = sub.SubSampleID
Inner Join		tblMfCdParameter par
	on			par.ParameterLogicalID = pre.ParameterLogicalID
Inner Join		tblMfCdPredictionModel pm
	on			pm.PredictionModelLogicalID = par.PredictionModelLogicalID
Inner Join		tblMfCdSampleReferenceValue srv 
	on			srv.SampleID = sa.SampleID
Inner Join		tblMfCdReferenceValue rv
	on			rv.ReferenceValueID = srv.ReferenceValueID
	and			rv.ParameterLogicalID = par.ParameterLogicalID

Where			par.Obsolete = 0
	and			sa.Obsolete = 0
	and			pm.Obsolete = 0
	and			sub.ParentSubSampleID Is Null
	and			sa.SampleID In (686,700) --Just for test
	and			par.ParameterLogicalID = {?ParameterId}
	and			pm.PredictionModelLogicalID = {?PmId}
	and			sa.sampleID in ({?SampleID})
	and			sa.ProductLogicalID = {?ProductId}