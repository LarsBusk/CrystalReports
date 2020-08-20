declare @CanceledSamples Table (SampleID int)
Insert Into @CanceledSamples
Select		sa.SampleID
from		tblMfCdSample sa
Inner Join	tblMfCdSubSample	sub
	on		sub.SampleID = sa.SampleID
Inner Join	tblMfCdSubSampleEvent sue
	on		sue.SubSampleID = sub.SubSampleID
Inner Join	tblMfAeEvent e
	on		e.EventID = sue.EventID
Where		sa.SampleType = 1
	and		sa.AnalysisEndUTC > DATEADD(DAY, -7, GETDATE())
	and		e.EventCode = 14

	Select * from @CanceledSamples