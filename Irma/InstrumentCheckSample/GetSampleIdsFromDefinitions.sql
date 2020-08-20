With DefTimes as
(
	Select		Min(ThisDef) as FirstDef
			,	Max(NextDef) as LastDef
	From
	(
		Select		AnalysisStartUTC as ThisDef
				,	ISNULL(LEAD(AnalysisStartUTC, 1) Over (Order By SampleID), GETDATE()) as NextDef
				,	SampleID
		From	tblMfCdSample
		Where	SampleType = 5
	) as defs
	Where	SampleID In (385,389,393)
)

Select		SampleID
From		tblMfCdSample
Where		AnalysisStartUTC Between (Select FirstDef From DefTimes) and (Select LastDef From DefTimes)
	and		SampleType = 1

