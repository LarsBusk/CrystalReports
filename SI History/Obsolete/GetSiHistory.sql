
With sichanges as
(
Select		ins.SerialNumber
		,	ins.[Name] [InstrumentName]
		,	pa.ParameterLogicalID
		,	pa.[Name] [ParameterName]
		,	pa.ShortName [ParameterShortName]
		,	pro.ProductLogicalID
		,	pro.[Name] [ProductName]
		,	ipp.ModifiedAtUTC
		,	pmts.Identification
		,	ipps.NumericValue
		,	pg.ProductGroupID
		,	pg.Name [ProductGroupName]
		,	pap.NumberOfDecimals

--		,	*
From		tblMfCdInstrumentProductParameter ipp
Inner Join	tblMfCdInstrumentProductParameterSettingGroup ippsg on
			ippsg.InstrumentProductParameterID = ipp.InstrumentProductParameterID
Inner Join	tblMfCdInstrumentProductParameterSetting ipps on
			ipps.InstrumentProductParameterSettingGroupID = ippsg.InstrumentProductParameterSettingGroupID
Inner Join	tblMfCdPredictionModelTypeSettingGroup pmtsg on
			pmtsg.PredictionModelTypeSettingGroupID = ippsg.PredictionModelTypeSettingGroupID
Inner Join	tblMfCdPredictionModelTypeSetting pmts on
			pmts.PredictionModelTypeSettingGroupID = pmtsg.PredictionModelTypeSettingGroupID and
			pmts.PredictionModelTypeSettingID = ipps.PredictionModelTypeSettingID
Inner Join	tblMfCdProduct pro on
			pro.ProductLogicalID = ipp.ProductLogicalID
Inner Join	tblMfCdParameter pa on
			pa.ParameterLogicalID = ipp.ParameterLogicalID
Inner Join	tblMfCdParameterProfile pap on
			pa.ParameterProfileLogicalID = pap.ParameterProfileLogicalID
Inner Join	tblMfCdInstrument ins on
			ins.InstrumentLogicalID = ipp.InstrumentLogicalID
Left Join	tblMfCdProductGroup pg on
			pg.ProductGroupID = pro.ProductGroupID
Where		pro.Obsolete = 0 and pa.Obsolete = 0 and ins.Obsolete = 0  and pap.Obsolete = 0
			and ipp.ModifiedAtUTC > DATEADD(YEAR, -1, GETDATE()) 
			and ins.InstrumentLogicalID = 1--{?InstrumentLogicalID}
)
Select		*
From		sichanges
Pivot		
(			max(NumericValue)
For			Identification In (Slope, Intercept)
) as piv