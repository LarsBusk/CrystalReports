select		*
from		tblMfCdSample sa
inner join	tblMfCdSubSample su
on			su.SampleID = sa.SampleID
Inner join	tblMfCdPredictedValue pv
on			pv.SubSampleID = su.SubSampleID



where	sa.SampleID Between 230 and 242
	and	pv.ParameterLogicalID = 21
order by sa.SampleID desc


select * from tblMfCdParameter where Obsolete = 0