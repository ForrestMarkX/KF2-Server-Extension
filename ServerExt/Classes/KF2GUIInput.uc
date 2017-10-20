// Input while in a menu.
class KF2GUIInput extends KFPlayerInput;

var KF2GUIController ControllerOwner;
var PlayerInput BaseInput;

function DrawHUD( HUD H )
{
	//ControllerOwner.RenderMenu(H.Canvas);
}
function PostRender( Canvas Canvas )
{
	if( ControllerOwner.bIsInMenuState )
		ControllerOwner.HandleDrawMenu();
		//ControllerOwner.RenderMenu(Canvas);
}

// Postprocess the player's input.
function PlayerInput( float DeltaTime )
{
	// Do not move.
	ControllerOwner.MenuInput(DeltaTime);
	
	if( !ControllerOwner.bAbsorbInput )
	{
		aMouseX = 0;
		aMouseY = 0;
		aBaseX = BaseInput.aBaseX;
		aBaseY = BaseInput.aBaseY;
		aBaseZ = BaseInput.aBaseZ;
		aForward = BaseInput.aForward;
		aTurn = BaseInput.aTurn;
		aStrafe = BaseInput.aStrafe;
		aUp = BaseInput.aUp;
		aLookUp = BaseInput.aLookUp;
		Super.PlayerInput(DeltaTime);
	}
	else
	{
		aMouseX = 0;
		aMouseY = 0;
		aBaseX = 0;
		aBaseY = 0;
		aBaseZ = 0;
		aForward = 0;
		aTurn = 0;
		aStrafe = 0;
		aUp = 0;
		aLookUp = 0;
	}
}

function PreClientTravel( string PendingURL, ETravelType TravelType, bool bIsSeamlessTravel)
{
	ControllerOwner.BackupInput.PreClientTravel(PendingURL,TravelType,bIsSeamlessTravel); // Let original mod do stuff too!
	ControllerOwner.NotifyLevelChange(); // Close menu NOW!
}

defaultproperties
{
}