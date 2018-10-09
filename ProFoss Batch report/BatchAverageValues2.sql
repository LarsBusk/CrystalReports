Use		ProFoss;

With	StartStop as
(
	Select			Max(e.InstrumentLogicalID) [InstrumentLogicalID]
				,	Max(SerialNumber) [SerialNumber]
				,	Max(InstrumentName) [InstrumentName]
				,	Max(StartTime) [StartTime]
				,	Stop
				,	Max(sa.AnalysisEndUTC) [LastSampleUTC] --Select the sample closest to the stop event
	From
	(
			Select			InstrumentLogicalID
						,	SerialNumber
						,	InstrumentName
						,	EventID
						,	EventRow
						,	Start
						,	Stop
						,	LAG(Start, 1) OVER (Partition By InstrumentLogicalID Order By EventRow) [StartTime]
			From
			(--First get all start and stop events 
			Select				Case
									When e.EventCode = 1 Then 'Start'
									When e.EventCode = 2 Then 'Stop'
								End [EventType]
							,	e.EventCode
							,	e.TimeStampUTC
							,	i.InstrumentLogicalID
							,	i.SerialNumber [SerialNumber]
							,	i.Name [InstrumentName]
							,	ROW_NUMBER() OVER (Partition By i.InstrumentLogicalID Order By e.EventID) [EventRow]
							,	e.EventID						
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
					Where		e.Severity = 0 and
								e.EventCode In (1, 2) and --1 is start measuring, 2 is stop
								i.Obsolete = 0 and
								e.TimeStampUTC > DATEADD(DAY, -10, GETDATE())
			) as d
			Pivot
			( -- pivot so time stamps start and stop events are in their own column
						Max(TimeStampUTC)
						For EventType In(Start, Stop)
			) as p
	) as e
	Inner Join		tblMfCdSample sa on
					sa.AnalysisEndUTC Between DATEADD(SECOND, -60, Stop) and Stop --Find the samples that are closest to the stop event
	Where	Start Is NULL
	Group By	Stop
)
	Select		StartStop.InstrumentLogicalID
			,	StartStop.InstrumentName
			,	StartStop.SerialNumber
			,	StartStop.StartTime
			,	StartStop.Stop
			,	StartStop.LastSampleUTC
			,	sa.SampleNumber
			,	pa.ShortName 
			,	dv.DoubleResult
	From		StartStop 
	Inner Join	tblMfCdSample sa on
				sa.AnalysisEndUTC = StartStop.LastSampleUTC and
				sa.InstrumentLogicalID = StartStop.InstrumentLogicalID --In case 2 instruments stop at the same time
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
	Order By	InstrumentLogicalID, Stop