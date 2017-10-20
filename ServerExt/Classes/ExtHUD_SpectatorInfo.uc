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

function UpdateSpectateeInfo(optional bool bForceUpdate)
{
	local ExtPlayerReplicationInfo E;

	E = ExtPlayerReplicationInfo(SpectatedKFPRI);
    if( !GetPC().IsSpectating() || E==None )
    {
		if( !bUnsetInfo )
		{
			SetVisible(false);
			bUnsetInfo = true;
		}
        return;
    }

    // Update the perk class.
    if( ExtLastPerkClass!=E.ECurrentPerk || LastPerkLevel!=E.ECurrentPerkLevel || bForceUpdate || bUnsetInfo )
	{
        LastPerkLevel = E.ECurrentPerkLevel;
        ExtLastPerkClass = E.ECurrentPerk;
        UpdatePlayerInfo(bForceUpdate);
		bUnsetInfo = false;
	}
}

function UpdatePlayerInfo(optional bool bForceUpdate)
{
	local GFxObject TempObject;

	TempObject = CreateObject("Object");
	TempObject.SetString("playerName", SpectatedKFPRI.GetHumanReadableName());
	if( ExtLastPerkClass!=None )
	{
		TempObject.SetString("playerPerk", SpectatedKFPRI.CurrentPerkClass.default.LevelString @LastPerkLevel @ExtLastPerkClass.default.PerkName );
		TempObject.SetString("iconPath", ExtLastPerkClass.Static.GetPerkIconPath(LastPerkLevel));
	}
	else TempObject.SetString("playerPerk","No perk");
	SetObject("playerData", TempObject);
	SetVisible(true);
}

defaultproperties
{
}