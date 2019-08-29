With Inst as
(
Select Distinct	ins.Name [InstrumentName]
			,	ins.SerialNumber
			,	nw.Name as NetWorkName
			,	ig.Name as InstrumentGroupName
From			tblMfCdSample sa
Inner Join		tblMfCdInstrument ins on
				sa.InstrumentLogicalId = ins.InstrumentLogicalID
Inner Join		tblMfCdInstrumentGroup ig on
				ins.InstrumentGroupLogicalID = ig.InstrumentGroupLogicalID
Inner Join		tblMfCdNetwork nw on
				nw.NetworkID = ig.NetworkID
Where			ins.Obsolete = 0 and	
				ig.Obsolete = 0 and
				sa.SampleID In ({?SampleID})
)
Select			Inst.InstrumentName
			,	SerialNumber
			,	NetWorkName
			,	InstrumentGroupName
			,	CalData.parameterlogicalid
			,	CalData.PredictionModelLogicalID
From			Inst
Left Join
(
Select			rsd.parameterlogicalid	
			,	pm.PredictionModelLogicalID
			,	rsd.instrumentname
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
		CalData.instrumentname = Inst.InstrumentName