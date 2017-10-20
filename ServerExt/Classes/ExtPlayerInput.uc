Class ExtPlayerInput extends KFPlayerInput;

var KF2GUIController MyGUIController;
var bool bHandledTravel;

exec function StartCrouch()
{
	bDuck = 1;
}
exec function ToggleCrouch()
{
	bDuck = (bDuck == 0) ? 1 : 0;
}

simulated exec function IronSights(optional bool bHoldButtonMode)
{
	local KFWeapon KFW;

	if( Pawn != none )
	{
		if( KFPawn_Monster(Pawn)!=None )
			Pawn.StartFire(1);
		else
		{
			KFW = KFWeapon(Pawn.Weapon);
			if ( KFW != None )
				KFW.SetIronSights((bHoldButtonMode) ? true : !KFW.bUsingSights);
		}
	}
}
simulated exec function IronSightsRelease(optional bool bHoldButtonMode)
{
	local KFWeapon KFW;

	if( Pawn != none )
	{
		if( KFPawn_Monster(Pawn)!=None )
			Pawn.StopFire(1);
		else
		{
			KFW = KFWeapon(Pawn.Weapon);
			if ( !KFW.bHasIronSights || bHoldButtonMode )
				KFW.SetIronSights(false);
		}
	}
}

simulated exec function ToggleFlashlight()
{
	if( KFPawn_Monster(Pawn)!=None && Pawn.Health>0 )
		SetNightVision(!bNightVisionActive);
	else Super.ToggleFlashlight();
}

function PreClientTravel( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel)
{
	Super.PreClientTravel(PendingURL,TravelType,bIsSeamlessTravel);
	if( !bHandledTravel )
	{
		bHandledTravel = true;
		if( KFExtendedHUD(MyHUD)!=None )
			KFExtendedHUD(MyHUD).NotifyLevelChange(true);
	}
}

event bool FilterButtonInput(int ControllerId, Name Key, EInputEvent Event, float AmountDepressed, bool bGamepad)
{
	if ( MyGfxManager.bAfterLobby && Event==IE_Pressed && (Key == 'Escape' || Key == 'XboxTypeS_Start') )
	{
		if( MyGUIController==None || MyGUIController.bIsInvalid )
		{
			MyGUIController = class'KF2GUIController'.Static.GetGUIController(Outer);
			if( MyGUIController==None )
			{
				ExtPlayerController(Outer).CancelConnection();
				return false;
			}
		}
		if( MyGUIController.bIsInMenuState )
		{
			return false;
		}
		else if( MyGFxManager.bMenusOpen )
		{
			return MyGFxManager.ToggleMenus();
		}
		else
		{
			MyGUIController.OpenMenu(ExtPlayerController(Outer).MidGameMenuClass);
			return true;
		}
	}
	return false;
}
