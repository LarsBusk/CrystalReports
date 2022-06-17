Declare @TimeZone as nvarchar(6);
Select @TimeZone = current_utc_offset
	From sys.time_zone_info
	Where [name] = SUBSTRING({?TimeZone}, 0, CHARINDEX(',',{?TimeZone}));
--Select @TimeZone

With Results as
( --To get the registration values as parameters
	Select		sa.SampleID
			,	rf.[Name] as ParameterName
			,	rfsv.StringValue as Result
			,	1000 + rf.RegistrationFieldID as DisplayOrder

	From		tblMfCdSample sa
	Inner Join 	tblMfCdSampleRegistrationValue sr
		on		sr.SampleID = sa.SampleID
	Inner Join	tblMfCdRegistrationField rf
		on		sr.RegistrationFieldID = rf.RegistrationFieldID
	Inner Join	tblMfCdRegistrationFieldStringValue rfsv
		on		rfsv.StringValueID = sr.StringValueID
Union --To get the predicted values
	Select		sa.SampleID
			,	pp.ShortName + ' ' + dbo.udfMnmRepGetIntEnumString('Unit', pp.Unit) as ParameterName
			,	Cast(ROUND(pv.DoubleResult, pp.NumberOfDecimals) as nvarchar) as Result
			,	pp.DisplayOrder

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
		and		pp.Obsolete = 0
		and		sa.Obsolete = 0
		and		pv.[Type] = 0
Union	--To get the date as a parameter the conversion to local itme must be done here
	Select		sa.SampleID
			,	'Sample Date' as ParameterName
			,	Substring(Cast(Convert(date, SWITCHOFFSET(Cast(AnalysisStartUTC at time zone 'UTC' as datetimeoffset ), @TimeZone)) as nvarchar), 3,8) as Result
			,	1 as DisplayOrder
	From		tblMfCdSample sa
Union	--To get time as a parameter
	Select		sa.SampleID
			,	'Sample Time' as ParameterName
			,	Cast(Convert(time, SWITCHOFFSET(Cast(AnalysisStartUTC at time zone 'UTC' as datetimeoffset ), @TimeZone)) as nvarchar(8)) as Result
			,	2 as DisplayOrder
	From		tblMfCdSample sa
)

Select		res.SampleID
		,	ParameterName
		,	Result
		,	DisplayOrder
		,	sa.AnalysisStartUTC as SampleTime
		,	sa.SampleNumber
		,	ins.[Name] as InstrumentName
		,	ins.SerialNumber 
		,	ig.[Name] as InstrumentGroupName
		,	net.[Name] as NetworkName

From		Results res
Inner Join	tblMfCdSample sa
	On		sa.SampleID = res.SampleID
Inner Join	tblMfCdInstrument ins
	on		ins.InstrumentLogicalID = sa.InstrumentLogicalID
Inner Join	tblMfCdInstrumentGroup ig
	on		ig.InstrumentGroupLogicalID = ins.InstrumentGroupLogicalID
Inner Join	tblMfCdNetwork net
	on		ig.NetworkID = net.NetworkID

Where		res.SampleId In ({?@SampleID})
	and		ins.Obsolete = 0
	and		ig.Obsolete = 0
	and		res.Result Is Not Null


