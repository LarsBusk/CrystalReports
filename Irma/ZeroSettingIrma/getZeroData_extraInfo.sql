Use		MilkoScanFT3;

Declare @FromDate datetime = DateAdd(day, -5, GetDate());

With XMLNAMESPACES (default 'http://foss.dk/Nova/ExtraZeroData')

Select		AnalysisEndUTC
		,	SampleID
		,	unp.ProductLogicalID
		,	ShortName as ParameterName
		,	Result
		,	IIF(ShortName = 'Intensity Correction' or ShortName = 'Conductivity Correction', Null, Limits.UpperLimit) as UpperLimit
		,	IIF(ShortName = 'Intensity Correction' or ShortName = 'Conductivity Correction', Null, Limits.UpperLimit * 2) as MaxGraph --Used to set the max value on the graph to get a fixed scale
		,	IIF(ShortName = 'Intensity Correction' or ShortName = 'Conductivity Correction', Null, Limits.LowerLimit) as LowerLimit
		,	IIF(ShortName = 'Intensity Correction' or ShortName = 'Conductivity Correction', Null, Limits.LowerLimit *2) as MinGraph
From
(
	Select		AnalysisEndUTC
			,	SampleID
			,	ProductLogicalID
			,	Zero1
			,	Zero2
			,	Zero3
			,	IntensCorr as "Intensity Correction"
			,	CondCorr as "Conductivity Correction"
		--	,	*
	From
		(--	Get the Intensity correction and Conductivity correction from the rawdata table where they are saved as Extra_Zero_Data type as XML
			Select			Cast(Cast(Cast(ra.Data as xml).query('data(//ExtraZeroData//IntensityCorrection)') as nvarchar) as float) as IntensCorr
						,	Cast(Cast(Cast(ra.Data as xml).query('data(//ExtraZeroData//ConductivityCorrection//Factor)') as nvarchar) as float) as CondCorr
						,	ra.SubSampleID
			From			tblMfCdRawData ra
			Where			ra.Identification = 'EXTRA_ZERO_DATA'
		) as ex
	Inner Join
		(-- Then join them with the predicted values for the Zero 1 - 3 parameters
			Select		*
			From
			(
				Select		pa.ShortName
						,	sa.AnalysisEndUTC
						,	su.SubSampleID
						,	pv.DoubleResult
						,	sa.SampleID
						,	sa.ProductLogicalID
						--,	*
				From		tblMfCdSample sa
				Inner join	tblMfCdSubSample su
					on		su.SampleID = sa.SampleID
				Inner Join	tblMfCdPredictedValue pv
					on		pv.SubSampleID = su.SubSampleID
				Inner Join	tblMfCdParameter pa
					on		pa.ParameterLogicalID = pv.ParameterLogicalID

				Where		sa.SampleType = 7 --Zero setting
				and			pa.Obsolete = 0
				and			pv.Type = 0 -- Main result
				and			sa.AnalysisEndUTC > @FromDate
				and			sa.InstrumentLogicalID = 1--{?@InstrumentLogicalID}
			) as s
				Pivot
			(
				Max(DoubleResult) 
				For ShortName In (Zero1, Zero2, Zero3)
			) as p
		) as ze
	On	ze.SubSampleID = ex.SubSampleID
) as piv
Unpivot
(
	Result for ShortName In (Zero1, Zero2, Zero3, "Intensity Correction", "Conductivity Correction")
) as unp
Inner Join
( -- Finally get the prodict limits. Assuming that for the zero product the limits are the same for all 3 zero parameters.
	Select		pro.ProductLogicalID
			,	max(prlv.Value) as UpperLimit
			,	min(prlv.Value) as LowerLimit
	From		tblMfCdProduct pro 		
	Inner Join	tblMfCdProductPredictionModel prpm
		on		prpm.ProductID = pro.ProductID
	Inner Join	tblMfCdProductPredictionModelParameter prpmpa
		on		prpmpa.ProductPredictionModelID = prpm.ProductPredictionModelID
	Inner Join	tblMfCdProductLimitValue prlv
		on		prlv.ProductPredictionModelParameterID = prpmpa.ProductPredictionModelParameterID
	Where		pro.Obsolete = 0 
	Group By	pro.ProductLogicalID
) as Limits
	On		Limits.ProductLogicalID = unp.ProductLogicalID