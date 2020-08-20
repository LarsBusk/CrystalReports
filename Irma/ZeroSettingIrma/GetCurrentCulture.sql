--Finds the language set by Nova or if the setting is not there the current language for the session
Declare @Language nvarchar(25)

Set @Language =
	( 
		Select 	alias
		From 	sys.syslanguages
		Where 	@@Language = name
	)
-- Check if the table exists to be able to run from Foss Manager
If exists
(
	Select name
	From sys.all_objects
	Where name Like 'tblNovaSystemSetting' and type = 'U'
) 
Begin
	If Exists --Check that the setting is in the table
	(
		Select  SettingString
		From 	tblNovaSystemSetting
		Where 	SettingName = 'CurrentCultureName'
	 )
	 Select  SettingString as CurrentCulture --In case it is an Irma
	 From 	tblNovaSystemSetting
	 Where 	SettingName = 'CurrentCultureName'

	 Else
		Select 	@Language as CurrentCulture --Not an Irma but a local mosaic db
End
Else
		Select 	@Language as CurrentCulture --A Mosaic server db

