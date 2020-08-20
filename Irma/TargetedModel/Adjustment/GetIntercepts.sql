Use	MilkoScanFT3;

Select		th.ParameterLogicalID
		,	th.GoodProductLimit
		,	ic.ProductLogicalID
		,	ic.ProductName
		,	IsNull(ic.Intercept, 0) as Intercept
From
(
	Select		pa.ParameterLogicalID
			,	ps.NumericValue as GoodProductLimit

	From		tblMfCdPredictionModelTypeSettingGroup ptsg
	Inner Join	tblMfCdPredictionModelTypeSetting pts
		on		pts.PredictionModelTypeSettingGroupID = ptsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdParameterSetting ps
		on		ps.PredictionModelTypeSettingID = pts.PredictionModelTypeSettingID
	Inner Join	tblMfCdParameterSettingGroup psg
		on		psg.ParameterSettingGroupID = ps.ParameterSettingGroupID
	Inner Join	tblMfCdParameter pa
		on		pa.ParameterID = psg.ParameterID
	Where		ptsg.PredictionModelTypeID = 133
		and		ptsg.Identification = 'Threshold'
		and		pa.Obsolete = 0
) th
Left join
(
	Select		pr.Name as ProductName
			,	pr.ProductLogicalID
			,	ipp.ParameterLogicalID
			,	IsNull(ipps.NumericValue, 0) as Intercept
			--,	*
	From		tblMfCdProduct pr
	Inner Join	tblMfCdInstrumentProductParameter ipp
		on		ipp.ProductLogicalID = pr.ProductLogicalID
	Inner Join	tblMfCdInstrumentProductParameterSettingGroup ippsg
		on		ippsg.InstrumentProductParameterID = ipp.InstrumentProductParameterID
	Inner Join	tblMfCdInstrumentProductParameterSetting ipps
		on		ipps.InstrumentProductParameterSettingGroupID = ippsg.InstrumentProductParameterSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSettingGroup pmtsg
		on		pmtsg.PredictionModelTypeSettingGroupID = ippsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSetting pmts
		on		pmts.PredictionModelTypeSettingGroupID = pmtsg.PredictionModelTypeSettingGroupID
		and		pmts.PredictionModelTypeSettingID = ipps.PredictionModelTypeSettingID
	Where		ipp.Obsolete = 0
		and		pr.Obsolete = 0
		and		pmts.Identification = 'Intercept'
) ic
	on		th.ParameterLogicalID = ic.ParameterLogicalID