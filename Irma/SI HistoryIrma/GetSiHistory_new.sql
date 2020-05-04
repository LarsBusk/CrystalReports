Select			pg.Name							ProductGroupName
			,	pro.Name						ProductName
			,	pa.ShortName					ParameterName
			,	pro.ProductLogicalID			ProductLogicalID
			,	pa.ParameterLogicalID			ParameterLogicalID
			,	pg.ProductGroupID				ProductGroupID
			,	sihist.AppliedSlope				Slope
			,	sihist.AppliedIntercept			Intercept
			,	sihist.CalculatedAdjustmentType	CalculatedAdjustmentType
			,	sihist.AppliedAdjustmentType	AppliedAdjustmentType
			,	sihist.ModifiedAtUTC			ModifiedAtUTC
			,	sihist.AcceptedAtUTC			AcceptedAtUTC
			,	sihist.SampleSetID				SampleSetID
			,	sihist.InstrumentLogicalID		InstrumentLogicalID
--			,	*
From			hist.tblMfCdSlopeInterceptAdjustmentHistory sihist
Inner Join		tblMfCdParameter pa
	on			pa.ParameterLogicalID = sihist.ParameterLogicalID
Inner Join		tblMfCdProduct pro
	on			pro.ProductLogicalID = sihist.ProductLogicalID
Left Join		tblMfCdProductGroup pg
	on			pg.ProductGroupID = pro.ProductGroupID


Where			pa.Obsolete = 0		
	and			pro.Obsolete = 0
	and			sihist.AcceptedAtUTC > DATEADD(YEAR, -1, GETDATE())
	and			sihist.InstrumentLogicalID = 1 --{?InstrumentLogicalID}