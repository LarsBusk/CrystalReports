With XMLNAMESPACES (default 'http://foss.dk/Nova/ExtraZeroData')

--	Get the Intensity correction and Conductivity correction from the rawdata table where they are saved as Extra_Zero_Data type as XML
				Select			Cast(Cast(ra.Data as xml).query('data(//ExtraZeroData//IntensityCorrection)') as nvarchar)   as IntensCorr
							,	Cast(Cast(ra.Data as xml).query('data(//ExtraZeroData//ConductivityCorrection//Factor)') as nvarchar)   as CondCorr
							,	ra.SubSampleID
							, Cast( ra.Data as xml)
				From			tblMfCdRawData ra
				Where			ra.Identification = 'EXTRA_ZERO_DATA'
			