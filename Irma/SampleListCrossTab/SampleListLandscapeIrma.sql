Declare @TimeZone as nvarchar(6);
Select @TimeZone = current_utc_offset
	From sys.time_zone_info
	Where [name] = SUBSTRING('{?TimeZone}', 0, CHARINDEX(',','{?TimeZone}'));
--	Where [name] = SUBSTRING('Astrakhan Standard Time,-240', 0, CHARINDEX(',','Astrakhan Standard Time,-240'));
--Select @TimeZone = '+02:00';
--use MilkoScanFT3;

With Results as
( 
	 --To get the predicted values
	Select		sa.SampleID
			,	sa.ProductLogicalID
			,	pp.ShortName + ' ' + dbo.udfMnmRepGetIntEnumString('Unit', pp.Unit) as ParameterName
			,	pp.NumberOfDecimals
			,	Cast(ROUND(pv.DoubleResult, pp.NumberOfDecimals) as nvarchar) as Result
			,	pp.DisplayOrder
			,	pv.ProductLimitsStatus
			,	pv.OutlierStatus

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

Union	--To get time as a parameter
	Select		sa.SampleID
			,	sa.ProductLogicalID
			,	'Sample Time' as ParameterName
			,	2 as NumberOfDecimals
			,	Cast(Convert(time, SWITCHOFFSET(Cast(AnalysisStartUTC at time zone 'UTC' as datetimeoffset), @TimeZone)) as nvarchar(5)) as Result
			,	1 as DisplayOrder
			,	0 as ProductLimitsStatus
			,	0 as OutlierStatus
	From		tblMfCdSample sa
)

--Select * From Results

Select		res.SampleID
		,	res.ProductLogicalID
		,	pro.Name as ProductName
		,	ParameterName
		,	NumberOfDecimals
		,	Result
		,	Case
				When res.ProductLimitsStatus > res.OutlierStatus then res.ProductLimitsStatus + 1
				When res.ProductLimitsStatus < res.OutlierStatus then res.OutlierStatus + 1
				Else res.ProductLimitsStatus + 1
			End as LimitStatus
		,	ROW_NUMBER() Over (Partition By res.SampleID Order By DisplayOrder) as DisplayOrder
		,	Convert(datetime, SWITCHOFFSET(Cast(AnalysisStartUTC at time zone 'UTC' as datetimeoffset), @TimeZone)) as SampleTime
		,	sa.SampleNumber
		,	ins.[Name] as InstrumentName
		,	ins.SerialNumber 
		,	ig.[Name] as InstrumentGroupName
		,	net.[Name] as NetworkName
                                ,	Dense_Rank() Over (Partition By res.ProductLogicalID Order By res.SampleID) /14 as PageNumber

From		Results res
Inner Join	tblMfCdSample sa
	On		sa.SampleID = res.SampleID
Inner Join	tblMfCdInstrument ins
	on		ins.InstrumentLogicalID = sa.InstrumentLogicalID
Inner Join	tblMfCdInstrumentGroup ig
	on		ig.InstrumentGroupLogicalID = ins.InstrumentGroupLogicalID
Inner Join	tblMfCdNetwork net
	on		ig.NetworkID = net.NetworkID
Inner join	tblMfCdProduct pro
	on		pro.ProductLogicalID = res.ProductLogicalID

Where		res.SampleId In ({?@SampleID})
	and		ins.Obsolete = 0
	and		ig.Obsolete = 0
	and		pro.Obsolete = 0
	and		res.Result Is Not Null

Order by ProductLogicalID, PageNumber


