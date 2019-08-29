Select			net.Name as NetworkName
			,	net.NetworkID
			,	ig.InstrumentGroupLogicalID  as GroupID
			,	ins.InstrumentLogicalID as InstrumentID
			,	ig.Name as GroupName
			,	ins.Name as InstrumentName
--			,	*
From			tblMfCdNetwork net
Inner Join		tblMfCdInstrumentGroup ig
	on			ig.NetworkID = net.NetworkID
Inner Join		tblMfCdInstrument ins
	on			ins.InstrumentGroupLogicalID = ig.InstrumentGroupLogicalID
Where			ins.Obsolete = 0 and ig.Obsolete = 0