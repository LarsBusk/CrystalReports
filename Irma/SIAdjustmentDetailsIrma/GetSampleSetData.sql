/****** Script for SelectTopNRows command from SSMS  ******/
Use		MilkoScanFt3;

Create Table #ProductNames  (ProductName NvarChar(50));

--To hold all the data for the adjustment
Create Table #RefData 
(
		SlopeInterceptAdjustmentID int
	,	AcceptedAtUTC DateTime
	,	AdjustmentAccuracyType int
	,	AmountOfSamples int
	,	AppliedIntercept float
	,	AppliedSlope float
	,	Bias float
	,	CalculatedAdjustmentType int
	,	ParameterLogicalID int
	,	ParameterName NvarChar(50)
	,	ProductLogicalID int
	,	ProductName NvarChar(50)
	,	CalculatedSlope float
	,	CalculatedIntercept float
	,	Correlation float
	,	RepeatabilityAbs float
	,	RMSEP float
	,	RSD float
	,	SlopeStdError float
	,	SampleSetID int
	,	SampleSetName NvarChar(50)
	,	SDPredicted float
	,	SEP float
	,	SampleID int
	,	SampleNumber NvarChar(50)
	,	DoubleResult float
	,	Unit int
	,	NumberOfDecimals int
	,	RefValue float
	,	Deviation as RefValue - DoubleResult
)

Declare @Res NvarChar(Max);

Insert Into #RefData

Select			sia.SlopeInterceptAdjustmentID
			,	sia.AcceptedAtUTC
			,	sia.AdjustmentAccuracyType
			,	sia.AmountOfSamples
			,	sia.AppliedIntercept
			,	sia.AppliedSlope
			,	sia.Bias
			,	sia.CalculatedAdjustmentType
			,	sia.ParameterLogicalID
			,	pap.ShortName as ParameterName
			,	sia.ProductLogicalID
			,	pro.[Name] as ProductName
			,	sia.CalculatedSlope
			,	sia.CalculatedIntercept
			,	sia.Correlation
			,	sia.RepeatabilityAbs
			,	sia.RMSEP
			,	sia.RSD
			,	sia.SlopeStdError
			,	sia.SampleSetID
			,	ss.[Name]
			,	sia.SDPredicted
			,	sia.SEP
			,	sss.SampleID
			,	sa.SampleNumber
			,	pv.DoubleResult
			,	pv.Unit
			,	pap.NumberOfDecimals
			,	ref.[Value] 

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

-- Create a comma seperated string with all product names affected---
-- First enter the product names into a table
Insert Into #ProductNames
Select Distinct	ProductName
From			#RefData
-- Then use COALESCE to create the comma seperated string
Select		@Res = Coalesce(@Res + ', ' + #ProductNames.ProductName, #ProductNames.ProductName) 
From		#ProductNames

Select		
--		,	Max(SlopeInterceptAdjustmentID) as SlopeInterceptAdjustmentID
			Max(SampleSetID)  as SampleSetID
		,	Max(SampleSetName) as SampleSetName
		,	Max(AcceptedAtUTC) as AcceptedAtUTC
		,	@Res as ProductNames
		,	Max(AdjustmentAccuracyType) as AdjustmentAccuracyType
		,	Max(AmountOfSamples) as AmountOfSamples
		,	Max(AppliedIntercept) as AppliedIntercept
		,	Max(AppliedSlope) as AppliedSlope
		,	Max(Bias) as Bias
		,	Max(CalculatedAdjustmentType) as CalculatedAdjustmentType
		,	Max(ParameterLogicalID) as ParameterLogicalID
		,	Max(ParameterName) as ParameterName
--		,	Max(ProductLogicalID) as ProductLogicalID
--		,	Max(ProductName) as ProductName
		,	Max(CalculatedSlope) as CalculatedSlope
		,	Max(CalculatedIntercept) as CalculatedIntercept
		,	Max(Correlation) as Correlation
		,	Max(RepeatabilityAbs) as RepeatabilityAbs
		,	Max(RMSEP) as RMSEP
		,	Max(RSD) as RSD
		,	Max(SlopeStdError) as SlopeStdError
		,	Max(SDPredicted) as SDPredicted
		,	Max(SEP) as SEP
		,	SampleID
		,	Max(SampleNumber) as SampleNumber
		,	Max(DoubleResult) as DoubleResult
		,	Max(Unit) as Unit
		,	Max(NumberOfDecimals) as NumberOfDecimals
		,	Max(RefValue) as RefValue
		,	Max(Deviation) as Deviation
From		#RefData
Group by	SampleID

Select * from #RefData Order by SlopeInterceptAdjustmentID

Drop Table #ProductNames
Drop Table #RefData