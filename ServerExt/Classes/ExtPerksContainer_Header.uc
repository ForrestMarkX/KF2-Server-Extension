class ExtPerksContainer_Header extends KFGFxPerksContainer_Header;

final function ExUpdatePerkHeader( Ext_PerkBase PerkClass )
{	
	local GFxObject PerkDataProvider;

	PerkDataProvider = CreateObject( "Object" );
    PerkDataProvider.SetString( "perkTitle", PerkClass.PerkName );
    PerkDataProvider.SetString( "perkLevel", LevelString@PerkClass.CurrentLevel);
    PerkDataProvider.SetString( "iconSource", PerkClass.GetPerkIconPath(PerkClass.CurrentLevel) );
    PerkDataProvider.SetString( "prestigeLevel", "");  //not used yet so not point to populating with data
    PerkDataProvider.SetString( "xpString",  PerkClass.CurrentEXP$"/"$PerkClass.NextLevelEXP );
    PerkDataProvider.SetFloat( "xpPercent", PerkClass.GetProgressPercent() );
	SetObject( "perkData", PerkDataProvider );
}

defaultproperties
{
}