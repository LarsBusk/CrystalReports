Select		pa.Name as ParameterName
		,	ps.NumericValue
		,	ptsg.Name as SettingName
		,	pa.ParameterLogicalID
		,	*
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