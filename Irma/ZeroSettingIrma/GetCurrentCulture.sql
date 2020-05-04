--Finds the language set by Nova or if the setting is not there the current language for the session
Declare @Language nvarchar(25)

Set @Language =
	( 
		Select	alias
		From	sys.syslanguages
		Where	@@Language = name
	)

If exists
(
	Select name
	From sys.all_objects
	Where name Like 'tblNovaSystemSetting' and type = 'U'
) 
	 Select ISNULL(SettingString, @Language) as CurrentCulture
	 From	tblNovaSystemSetting
	 Where	SettingName = 'CurrentCultureName'
 Else
	Select	@Language as CurrentCulture

