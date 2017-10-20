class ExtTraderContainer_PlayerInfo extends KFGFxTraderContainer_PlayerInfo;

function SetPerkInfo()
{
	local Ext_PerkBase CurrentPerk;
	local ExtPlayerController KFPC;
	local float V;

	KFPC = ExtPlayerController(GetPC());
	if( KFPC!=none && KFPC.ActivePerkManager!=None && KFPC.ActivePerkManager.CurrentPerk!=None )
	{
		CurrentPerk = KFPC.ActivePerkManager.CurrentPerk;
 		SetString("perkName", CurrentPerk.PerkName);
 		SetString("perkIconPath", CurrentPerk.GetPerkIconPath(CurrentPerk.CurrentLevel));
 		SetInt("perkLevel", CurrentPerk.CurrentLevel);
		V = CurrentPerk.GetProgressPercent()*100.f;
 		SetInt("xpBarValue", int(V));
	}
}

function SetPerkList()
{
	local GFxObject PerkObject;
	local GFxObject DataProvider;
	local ExtPlayerController KFPC;
	local byte i;
	local float PerkPercent;
	local Ext_PerkBase P;

	KFPC = ExtPlayerController(GetPC());
	if( KFPC != none && KFPC.ActivePerkManager!=None )
	{
    	DataProvider = CreateArray();

		for (i = 0; i < KFPC.ActivePerkManager.UserPerks.Length; i++)
		{
			P = KFPC.ActivePerkManager.UserPerks[i];
			PerkObject = CreateObject( "Object" );
			PerkObject.SetString("name", P.PerkName);
			PerkObject.SetString("perkIconSource",  P.GetPerkIconPath(P.CurrentLevel));
			PerkObject.SetInt("level", P.CurrentLevel);

			PerkPercent = P.GetProgressPercent()*100.f;
			PerkObject.SetInt("perkXP", int(PerkPercent));

			DataProvider.SetElementObject(i, PerkObject);
		}

		SetObject("perkList", DataProvider);
	}
}

defaultproperties
{
}