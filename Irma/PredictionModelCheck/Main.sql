Select			pro.ProductLogicalID
			,	pro.[Name] as ProductName
			,	pm.PredictionModelLogicalID
			,	par.ParameterLogicalID
			,	ins.[Name] InstrumentName
			,	ins.SerialNumber
			,	ig.[Name] as InstrumentGroupName
			,	net.[Name] as NetworkName		
			,	sa.SampleID
--			,	*

From			tblMfCdSample sa
Inner Join		tblMfCdProduct pro
	on			pro.ProductLogicalID = sa.ProductLogicalID
Inner Join		tblMfCdSubSample sub
	on			sub.SampleID = sa.SampleID
Inner Join		tblMfCdPredictedValue pre
	on			pre.SubSampleID = sub.SubSampleID
Inner Join		tblMfCdParameter par
	on			par.ParameterLogicalID = pre.ParameterLogicalID
Inner Join		tblMfCdPredictionModel pm
	on			par.PredictionModelLogicalID = pm.PredictionModelLogicalID
Inner Join		tblMfCdSampleReferenceValue srv
	on			srv.SampleID = sa.SampleID
Inner Join		tblMfCdReferenceValue rv
	on			rv.ReferenceValueID = srv.ReferenceValueID
	and			rv.ParameterLogicalID = par.ParameterLogicalID
	
Inner Join		tblMfCdInstrument ins
	on			ins.InstrumentLogicalID = sa.InstrumentLogicalID
Inner Join		tblMfCdInstrumentGroup ig
	on			ig.InstrumentGroupLogicalID = ins.InstrumentGroupLogicalID
Inner Join		tblMfCdNetwork net
	on			net.NetworkID = ig.NetworkID

Where			pro.Obsolete = 0
	and			par.Obsolete = 0			
	and			pm.Obsolete = 0
	and			ins.Obsolete = 0
	and			ig.Obsolete = 0
	and			sa.Obsolete = 0
	and			pre.[Type] = 0 -- Primary value
	and			sa.SampleType = 10 --Quality Control
	and			sub.ParentSubSampleID Is Null
	and			sa.AnalysisStartUTC Between '{?Parameter1}' and '{?Parameter2}'
	and			sa.InstrumentLogicalID = {?Parameter3}