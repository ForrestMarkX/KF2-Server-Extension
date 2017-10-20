class ExtHUD_PlayerBackpack extends KFGFxHUD_PlayerBackpack;

var class<Ext_PerkBase> EPerkClass;

function UpdateGrenades()
{
	local int CurrentGrenades;
	local ExtPerkManager PM;

	if(MyKFInvManager != none)
		CurrentGrenades = MyKFInvManager.GrenadeCount;

	//Update the icon the for grenade type.
	if( ExtPlayerController(MyKFPC)!=None )
	{
		PM = ExtPlayerController(MyKFPC).ActivePerkManager;
		
		if( PM!=None && PM.CurrentPerk!=None && EPerkClass!=PM.CurrentPerk.Class )
		{
			SetString("backpackGrenadeType", "img://"$PM.CurrentPerk.GrenadeWeaponDef.Static.GetImagePath());
			EPerkClass = PM.CurrentPerk.Class;
		}
	}
	// Update the grenades count value
	if(CurrentGrenades != LastGrenades)
	{
		SetInt("backpackGrenades" , Min(CurrentGrenades,9));
		LastGrenades = CurrentGrenades;
	}
}

DefaultProperties
{
}