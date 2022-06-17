/****** Script for SelectTopNRows command from SSMS  ******/
With Regvalues as
(
	Select		sa.SampleID
			,	rf.[Name]
			,	rfsv.StringValue
			--,	*
	From		tblMfCdSample sa
	Inner Join 	tblMfCdSampleRegistrationValue sr
		on		sr.SampleID = sa.SampleID
	Inner Join	tblMfCdRegistrationField rf
		on		sr.RegistrationFieldID = rf.RegistrationFieldID
	Inner Join	tblMfCdRegistrationFieldStringValue rfsv
		on		rfsv.StringValueID = sr.StringValueID
)
Select *
from Regvalues