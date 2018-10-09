	Use		ProFoss;
	
	Select		stops.EventCode
			,	stops.TimeStampUTC
			,	stops.InstrumentLogicalID
			,	stops.SerialNumber
			,	stops.InstrumentName
			,	sa.SampleNumber
			,	stops.LastSampleUTC
			,	pa.Name [ParameterName]
			,	dv.DoubleResult [BatchResult]
	From
	(	
		Select		Max(e.EventCode) [EventCode]
				,	e.TimeStampUTC
				,	i.InstrumentLogicalID
				,	Max(i.SerialNumber) [SerialNumber]
				,	Max(i.Name) [InstrumentName]
				,	Max(sa.AnalysisEndUTC) [LastSampleUTC]
		From		tblMfAeEvent e
		Inner Join	tblMfAeDeviceSource ds on
					e.DeviceSourceID = ds.DeviceSourceID and
					e.SystemID = ds.SystemID
		Inner Join	tblMfAeDeviceModule dm on
					dm.DeviceModuleID = ds.DeviceModuleID and
					dm.SystemID = ds.SystemID
		Inner Join	tblMfAeDevice d on
					d.DeviceID = dm.DeviceID and
					d.SystemID = dm.SystemID
		Inner Join	tblMfCdInstrument i on
					i.InstrumentLogicalID = d.InstrumentLogicalID and
					i.SystemID = d.SystemID
		Inner Join	tblMfCdSample sa on
					sa.InstrumentLogicalID = i.InstrumentLogicalID and
					sa.AnalysisEndUTC Between DATEADD(SECOND,-60, e.TimeStampUTC) and e.TimeStampUTC and
					sa.SystemID = i.SystemID
		Where		e.Severity = 0 and
					e.EventCode In (1, 2) and
					i.Obsolete = 0 and
					e.EventCode = 2
		Group By	i.InstrumentLogicalID, e.TimeStampUTC
	) as stops
	Inner Join	tblMfCdSample sa on
				sa.AnalysisEndUTC = stops.LastSampleUTC
	Inner Join	tblMfCdSubSample sub on
			sub.SampleID = sa.SampleID
	Inner Join	tblMfCdPredictedValue pv on
				pv.SubSampleID = sub.SubSampleID
	Inner Join	tblMfCdDerivedValue dv on
				dv.PredictedValueID = pv.PredictedValueID
	Inner Join	tblMfCdParameter pa on
				pa.ParameterLogicalID = pv.ParameterLogicalID
	Where		pa.Obsolete = 0 and
				dv.Type = 22