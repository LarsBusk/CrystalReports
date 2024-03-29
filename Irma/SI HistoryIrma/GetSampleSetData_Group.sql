/****** Script for SelectTopNRows command from SSMS  ******/
Use				MilkoScanFt3;

Select		--	sia.SlopeInterceptAdjustmentID
				max(sia.AcceptedAtUTC) as AcceptedAtUTC
		--	,	sia.AdjustmentAccuracyType
			,	max(sia.AmountOfSamples) as AmountOfSamples
			,	max(sia.AppliedIntercept) as AppliedIntercept
			,	max(sia.AppliedSlope) as AppliedSlope
			,	max(sia.Bias) as Bias
			,	max(sia.CalculatedAdjustmentType) as CalculatedAdjustmentType
			,	pa.ParameterLogicalID
			,	pap.ShortName as ParameterName
		--	,	sia.ProductLogicalID
			,	max(pro.[Name]) as ProductName
			,	max(sia.CalculatedSlope) as CalculatedSlope
			,	max(sia.CalculatedIntercept) as CalculatedIntercept
			,	max(sia.Correlation) as Correlation
			,	max(sia.RepeatabilityAbs) as RepeatabilityAbs
			,	max(sia.RMSEP) as RMSEP
			,	max(sia.RSD) as RSD
			,	max(sia.SlopeStdError) as SlopeStdError
		--	,	sia.SampleSetID
			,	max(sia.SDPredicted) as SDPredicted
			,	max(sia.SEP) as SEP
			,	sa.SampleID
			,	max(sa.SampleNumber) as SampleNumber
			,	max(pv.DoubleResult) as DoubleResult
		--	,	pv.Unit
		--	,	pap.NumberOfDecimals
			,	max(ref.[Value]) as RefValue
			--,	*
From			tblMfCdSlopeInterceptAdjustment sia
Inner Join		tblMfCdSampleSet ss on
				ss.SampleSetLogicalID = sia.SampleSetID
Inner Join		tblMfCdSampleSetSample sss on
				sss.SampleSetID = ss.SampleSetID
Inner Join		tblMfCdSample sa on 
				sa.SampleID = sss.SampleID
Inner Join		tblMfCdSubSample sub on
				sub.SampleID = sa.SampleID
Inner Join		tblMfCdPredictedValue pv on
				sub.SubSampleID = pv.SubSampleID and
				pv.ParameterLogicalID = sia.ParameterLogicalID
Inner Join		tblMfCdSampleReferenceValue srv on
				srv.SampleID = sa.SampleID
Inner Join		tblMfCdReferenceValue ref on
				ref.ReferenceValueID = srv.ReferenceValueID and
				ref.ParameterLogicalID = pv.ParameterLogicalID
Inner Join		tblMfCdProduct pro on
				pro.ProductLogicalID = sia.ProductLogicalID
Inner Join		tblMfCdParameter pa on
				pa.ParameterLogicalID = sia.ParameterLogicalID
Inner Join		tblMfCdParameterProfile pap on
				pap.ParameterProfileLogicalID = pa.ParameterProfileLogicalID
Where			ss.Obsolete = 0 and pro.Obsolete = 0 and pa.Obsolete = 0 and pap.Obsolete = 0 and
				sub.ParentSubSampleID IS NULL and
				pv.Type = 0
Group by		pa.ParameterLogicalID, pap.ShortName, sa.SampleID
--Order By		sia.ProductLogicalID
