Select		ins.Description
		,	ins.SerialNumber
		,	ins.ChassisID
		,	ins.InstrumentLogicalID
		,	ins.InstrumentTypeID
		,	ig.InstrumentGroupLogicalID
		,	ig.Name as GroupName
		,	it.InstrumentTypeID
		,	it.Name as InstrumentName
		,	net.NetworkID
		,	net.Name as NetworkName
--		,	*
From	tblMfCdInstrument ins
Inner Join	tblMfCdInstrumentGroup ig
on			ig.InstrumentGroupLogicalID = ins.InstrumentGroupLogicalID
Inner Join	tblMfCdNetwork net
on			net.NetworkID = ig.NetworkID
Inner Join	tblMfCdInstrumentType it
on			it.InstrumentTypeID = ins.InstrumentTypeID
Where		ins.Obsolete = 0 and ig.Obsolete = 0