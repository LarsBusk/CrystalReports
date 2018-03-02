Use MeatMasterII;

With IdsZeroFat as
(
	Select		sa.SampleId
	From		tblMfCdSample sa
	Inner join	tblMfCdSubSample su on
				su.SampleID = sa.SampleID
	Inner Join	tblMfCdPredictedValue pv on
				pv.SubSampleID = su.SubSampleID
	Inner Join	tblMfCdParameter pa on
				pa.ParameterLogicalID = pv.ParameterLogicalID
	Where		pa.Obsolete = 0 and
				pa.Identification = 'Fat' and
				pv.DoubleResult = 0 and
				--sa.SystemID = {?@SystemID} and
				--sa.SampleID In ({?@SampleID})
				sa.AnalysisStartUTC Between '2018-02-21' and '2018-02-22'
)

Select			sa.SampleNumber
			,	sa.AnalysisStartUTC
			,	Case pa.Identification
					When 'Weight' then DoubleResult Else 0 End [Weight]
			,	Case pa.Identification
					When 'Fat' then DoubleResult Else 0 End [Fat]
			,	rsv.StringValue
			,	ra.Data 
	--		,	*
From			tblMfCdSample sa
Inner Join		tblMfCdSubSample su on
				su.SampleID = sa.SampleID
Inner Join		tblMfCdRawData ra on
				ra.SubSampleID = su.SubSampleID
Inner Join		tblMfCdPredictedValue pv on
				pv.SubSampleID = su.SubSampleID
Inner Join		tblMfCdParameter pa on 
				pv.ParameterLogicalID = pa.ParameterLogicalID
Inner Join		tblMfCdSampleRegistrationValue srv on
				srv.SampleID = sa.SampleID
Inner Join		tblMfCdRegistrationField rf on
				srv.RegistrationFieldID = rf.RegistrationFieldID	
Inner Join		tblMfCdRegistrationFieldStringValue rsv on
				rsv.RegistrationFieldID = rf.RegistrationFieldID and
				rsv.StringValueID = srv.StringValueID
Where			sa.SampleID In
				(
					Select SampleId From IdsZeroFat
				) and
				ra.Identification = 'JpegPicture' and
				rf.Identification = 'SampleRegistration01' and
				pa.Identification In ('Weight') and
				pa.Obsolete = 0
Order By		sa.SampleID