Select		th.ParameterLogicalID
		,	th.ShortName as ParameterName
		,	th.NumberOfDecimals
		,	th.GoodProductLimit
		,	ic.ProductLogicalID
		,	ic.ProductName
		,	AuditTrailID
		,	IsNull(ic.Intercept, 0) as Intercept
		,	Slope		
From
(
Select			pa.ParameterLogicalID
			,	ps.NumericValue as GoodProductLimit
			,	pp.NumberOfDecimals
			,	pp.ShortName
	From		tblMfCdPredictionModelTypeSettingGroup ptsg
	Inner Join	tblMfCdPredictionModelTypeSetting pts
		on		pts.PredictionModelTypeSettingGroupID = ptsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdParameterSetting ps
		on		ps.PredictionModelTypeSettingID = pts.PredictionModelTypeSettingID
	Inner Join	tblMfCdParameterSettingGroup psg
		on		psg.ParameterSettingGroupID = ps.ParameterSettingGroupID
	Inner Join	tblMfCdParameter pa
		on		pa.ParameterID = psg.ParameterID
	Inner Join	tblMfCdParameterProfile pp
		on		pp.ParameterProfileLogicalID = pa.ParameterProfileLogicalID
	Where		ptsg.PredictionModelTypeID = 133
		and		ptsg.Identification = 'Threshold'
		and		pa.Obsolete = 0
		and		pp.Obsolete = 0
) th
Left join
(
	Select		AuditTrailID
			,	PredictionModelLogicalID
			,	ParameterLogicalID
			,	ProductLogicalID
			,	Slope
			,	Intercept
			,	ProductName
From
(
	Select		atr.AuditTrailID
			,	atps.NumericValue
			,	pmts.Identification
			,	atpm.PredictionModelLogicalID
			,	atpa.ParameterLogicalID
			,	atr.ProductLogicalID
			,	pro.Name as ProductName

	From		tblMfCdAuditTrail atr
	Inner Join	tblMfCdAuditTrailPredictionModel atpm
		on		atpm.AuditTrailID = atr.AuditTrailID
	Inner Join	tblMfCdAuditTrailParameter atpa
		on		atpa.AuditTrailPredictionModelID = atpm.AuditTrailPredictionModelID
	Inner Join	tblMfCdAuditTrailParameterSettingGroup atpsg
		on		atpsg.AuditTrailParameterID = atpa.AuditTrailParameterID
	Inner Join	tblMfCdAuditTrailParameterSetting atps
		on		atps.AuditTrailParameterSettingGroupID = atpsg.AuditTrailParameterSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSettingGroup pmtsg
		on		pmtsg.PredictionModelTypeSettingGroupID = atpsg.PredictionModelTypeSettingGroupID
	Inner Join	tblMfCdPredictionModelTypeSetting pmts
		on		pmts.PredictionModelTypeSettingGroupID = pmtsg.PredictionModelTypeSettingGroupID
		and		pmts.PredictionModelTypeSettingID = atps.PredictionModelTypeSettingID
	Inner Join	tblMfCdProduct pro
		on		pro.ProductLogicalID = atr.ProductLogicalID
	Where		pmts.Identification In ('Intercept', 'Slope')
		and		pro.Obsolete = 0
) as s
pivot 
(
	Max(NumericValue)
	For Identification In (Slope, Intercept)
) as p
) ic
	on		th.ParameterLogicalID = ic.ParameterLogicalID





