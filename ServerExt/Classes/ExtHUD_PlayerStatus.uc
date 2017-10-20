class ExtHUD_PlayerStatus extends KFGFxHUD_PlayerStatus;

var ExtPlayerController ExPC;
var class<Ext_PerkBase> ExLastPerkClass;
var string CurPerkPath;

function InitializeHUD()
{
	Super.InitializeHUD();
	ExPC = ExtPlayerController(MyPC);
}

function UpdatePerk()
{
	local int CurrentPerkLevel,CurrentPerkEXP;
	local Ext_PerkBase CurrentPerk;

	if( ExPC == none || ExPC.ActivePerkManager==None || ExPC.ActivePerkManager.CurrentPerk==None )
		return;

	CurrentPerk = ExPC.ActivePerkManager.CurrentPerk;
	CurrentPerkLevel = CurrentPerk.CurrentLevel;
	CurrentPerkEXP = CurrentPerk.CurrentEXP;

	// Update the perk class.
	if( ( ExLastPerkClass != CurrentPerk.Class ) || ( LastPerkLevel != CurrentPerkLevel ) )
	{
		CurPerkPath = CurrentPerk.GetPerkIconPath(CurrentPerkLevel);
		SetString("playerPerkIcon" , CurPerkPath);
		SetInt("playerPerkXPPercent", CurrentPerk.GetProgressPercent() * 100.f );
		if( LastPerkLevel != CurrentPerkLevel && ExLastPerkClass==CurrentPerk.Class )
		{
			SetBool("bLevelUp", true);
			ShowXPBark(CurrentPerkEXP-LastEXPValue,CurPerkPath,true);
		}
		ExLastPerkClass = CurrentPerk.class;

		SetInt("playerPerkLevel" , CurrentPerkLevel);
		LastPerkLevel = CurrentPerkLevel;
		LastEXPValue = CurrentPerkEXP;
	}
	else if( LastEXPValue!=CurrentPerkEXP )
	{
		SetBool("bLevelUp", false);
		SetInt("playerPerkXPPercent", CurrentPerk.GetProgressPercent() * 100.f );
		ShowXPBark(CurrentPerkEXP-LastEXPValue,CurPerkPath,true);
		LastEXPValue = CurrentPerkEXP;
	}
}
function ShowXPBark( int DeltaXP, string IconPath, bool bIsCurrentPerk )
{
	ActionScriptVoid("showXPBark");
}

function UpdateHealth()
{
	if( MyPC.Pawn == none )
	{
		LastHealth = 0;
		SetInt("playerHealth" , LastHealth);
	}
	else if( LastHealth != MyPC.Pawn.Health )
	{
		LastHealth = MyPC.Pawn.Health;
		SetInt("playerHealth" , LastHealth);
	}
}

defaultproperties
{
}