With Inst as
(
Select Distinct	ins.Name [InstrumentName]
			,	ins.SerialNumber
From			tblMfCdSample sa
Inner Join		tblMfCdInstrument ins on
				sa.InstrumentLogicalId = ins.InstrumentLogicalID
Where			ins.Obsolete = 0 and	
				sa.SampleID In ({?SampleID})
)
Select			*
From			Inst
Left Join
(
Select			instrumentname as IName
			,	productname
			,	analysisstartutc
			,	numberofdecimals
			,	rsd.unit
			,	parametershortname
			,	rsd.parameterlogicalid
			,	doubleresult
			,	referencevalue
			,	referencevalue - doubleresult [difference]
			,	sampleid
			,	pm.Name [PmName]
			,	pm.PredictionModelLogicalID
			,	0.7 [UpperError]
			,	-0.7 [LowerError]
			,	0.3 [UpperWarning]
			,	-0.3 [LowerWarning]
		--	,	*
From			vwMnmRepSampleDetail rsd 
Inner Join		tblMfCdParameter pa on
				rsd.parameterlogicalid = pa.ParameterLogicalID
		and		rsd.systemid = pa.SystemID
		and		pa.Obsolete = 0
Inner Join		tblMfCdPredictionModel pm on
				pm.PredictionModelLogicalID = pa.PredictionModelLogicalID
		and		pm.SystemID = pa.SystemID
		and		pm.Obsolete = 0				
Where			sampletype = 'Quality Control'
		and		type = 0
		and		referencevalue IS NOT NULL
		and		parentsubsampleid IS NULL
		and		rsd.sampleID in ({?SampleID})
		) as CalData on
		CalData.IName = inst.InstrumentName