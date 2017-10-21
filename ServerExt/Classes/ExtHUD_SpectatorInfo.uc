class ExtHUD_SpectatorInfo extends KFGFxHUD_SpectatorInfo;

var class<Ext_PerkBase> ExtLastPerkClass;
var bool bUnsetInfo;

function LocalizeText()
{
	local GFxObject TempObject;
	TempObject = CreateObject("Object");

    TempObject.SetString("prevPlayer", "FREE CAMERA");
    TempObject.SetString("nextPlayer", PrevPlayerString);
    TempObject.SetString("changeCamera", ChangeCameraString);

    SetObject("localizedText", TempObject);
}

function UpdatePlayerInfo( optional bool bForceUpdate )
{
	local GFxObject TempObject;
	local ExtPlayerReplicationInfo E;
	
	if( SpectatedKFPRI == None )
		return;
	
	E = ExtPlayerReplicationInfo(SpectatedKFPRI);

	if( LastPerkLevel != E.ECurrentPerkLevel || LastPerkLevel != E.ECurrentPerkLevel || bForceUpdate )
	{
		LastPerkLevel = E.ECurrentPerkLevel;
		ExtLastPerkClass = E.ECurrentPerk;
		TempObject = CreateObject( "Object" );
		TempObject.SetString( "playerName", SpectatedKFPRI.GetHumanReadableName() );
		if( ExtLastPerkClass!=None && TempObject !=None )
		{
			TempObject.SetString( "playerPerk", SpectatedKFPRI.CurrentPerkClass.default.LevelString @LastPerkLevel @ExtLastPerkClass.default.PerkName );
			TempObject.SetString( "iconPath", ExtLastPerkClass.Static.GetPerkIconPath(LastPerkLevel) );
			SetObject( "playerData", TempObject );
		}
		else TempObject.SetString( "playerPerk","No perk" );
		SetVisible( true );
	}
}

defaultproperties
{
}
