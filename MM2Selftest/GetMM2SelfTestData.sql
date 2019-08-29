Use MeatMasterII;

with refdata as
(
	Select		sa.InstrumentLogicalID
			,	sa.SampleNumber
			,	AnalysisStartUTC
			,	AnalysisEndUTC
			,	REPLACE(pa.Name, ' ', '') as ParameterName
			,	pv.DoubleResult as Result

	From		tblMfCdSample sa
	Inner Join	tblMfCdSubSample su
		on		su.SampleID = sa.SampleID
	Inner Join	tblMfCdPredictedValue pv
		on		pv.SubSampleID = su.SubSampleID
	Inner join	tblMfCdParameter pa 
		on		pa.ParameterLogicalID = pv.ParameterLogicalID
	Inner Join	tblMfCdRawData rd
		on		rd.SubSampleID = su.SubSampleID
	Where		sa.SampleType = 4
		and		sa.Obsolete = 0
		and		pa.Obsolete = 0
)
select	refpivot.InstrumentLogicalID
	,	SampleNumber
	,	AnalysisStartUTC
	,	AnalysisEndUTC
	,	Ref2LE
	,	Ref2HE
	,	Ref1LE
	,	Ref1HE
	,	selftest.SelfTestID
	,	selftest.SelfTestStepID
	,	selftest.StepStatus
	,	selftest.TestStatus
	,	selftest.StartedAtUTC
	,	selftest.CompletedAtUTC
	,	selftest.Identification
	,	selftest.ValueIndetification
	,	selftest.ParameterUpperLimit
	,	selftest.XrayHighEnergy
	,	selftest.XrayLowEnergy
	,	instrument.InstrumentName
	,	instrument.SerialNumber
	,	instrument.ChassisID
	,	instrument.InstrumentGorupName
	,	instrument.NetworkName


From	refdata

pivot
(
	Max(Result)
	For ParameterName In (Ref2LE, Ref2HE, Ref1LE, Ref1HE)
) as refpivot
Right Join
(
	Select		SelfTestID
			,	InstrumentLogicalID
			,	TestStatus
			,	SelfTestStepID
			,	Identification
			,	StartedAtUTC
			,	CompletedAtUTC
			,	StepStatus
			,	ParameterUpperLimit	
			,	ValueIndetification
			,	XrayHighEnergy
			,	XrayLowEnergy

	From
	(
		Select		st.SelfTestID
				,	dbo.udfMnmRepGetIntEnumString('Status', st.Status) as TestStatus
				,	sts.SelfTestStepID
				,	sts.Identification
				,	sts.StartedAtUTC
				,	sts.CompletedAtUTC
				,	dbo.udfMnmRepGetIntEnumString('Status', sts.Status) as StepStatus
				,	stdn.ParameterUpperLimit
				,	stdn.DetectorType
				,	stdn.Value
				,	stdn.ValueIndetification
				,	st.InstrumentLogicalID

		From		tblMfCdSelfTest st
		Inner Join	tblMfCdSelfTestStep sts
			on		sts.SelfTestID = st.SelfTestID
		Left Join	vwRepSelfTestDetailsNoise stdn
			on		stdn.SelfTestStepID = sts.SelfTestStepID
		Where		st.SelfTestLogicalID = 672 --{?SelfTestLogicalID}
	) as s
	pivot
	(
	max(value) 
	For DetectorType In (XrayHighEnergy, XrayLowEnergy)
	) as p	
) as selftest
	on		selftest.InstrumentLogicalID = refpivot.InstrumentLogicalID
	and		refpivot.AnalysisStartUTC Between selftest.StartedAtUTC and selftest.CompletedAtUTC
Inner Join	
(
	Select		ins.Name as InstrumentName
			,	ins.ChassisID
			,	ins.SerialNumber
			,	net.Name as NetworkName
			,	ig.Name as InstrumentGorupName
			,	ins.InstrumentLogicalID
	From		tblMfCdInstrument ins
	Inner Join	tblMfCdInstrumentGroup ig
		on		ig.InstrumentGroupLogicalID = ins.InstrumentGroupLogicalID
	Inner Join	tblMfCdNetwork net
		on		ig.NetworkID = net.NetworkID
	Where		ins.Obsolete = 0
		and		ig.Obsolete = 0		
) as instrument
	on		instrument.InstrumentLogicalID = selftest.InstrumentLogicalID
	
Order by	selftest.SelfTestStepID, selftest.ValueIndetification