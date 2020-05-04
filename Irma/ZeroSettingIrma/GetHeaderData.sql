Use	MilkoScanFT3;


Select		ins.Name as InstrumentName
		,	ig.Name as InstrumentGroupName
		,	net.Name as NetworkName
		,	ins.SerialNumber 
--		,	*

From		tblMfCdInstrument ins
Inner Join	tblMfCdInstrumentGroup ig
	on		ig.InstrumentGroupLogicalID = ins.InstrumentGroupLogicalID
Inner Join	tblMfCdNetwork net
	on		net.NetworkID = ig.NetworkID
Where		ins.InstrumentLogicalID = {?@InstrumentLogicalID}
	and		ins.Obsolete = 0
	and		ig.Obsolete = 0