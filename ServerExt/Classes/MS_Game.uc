// Minimal intermission gametype.
Class MS_Game extends GameInfo;

event Timer();

event InitGame( string Options, out string ErrorMessage )
{
    MaxPlayers = 99;
    MaxSpectators = 99;
	class'MS_TMPUI'.Static.Remove();
}

// Add or remove reference to this game for GC
static final function SetReference()
{
	class'MS_TMPUI'.Static.Apply();
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local NavigationPoint StartSpot;
	local PlayerController NewPlayer;
	local rotator SpawnRotation;

	// Find a start spot.
	StartSpot = FindPlayerStart( None, 255, Portal );
	SpawnRotation.Yaw = StartSpot.Rotation.Yaw;
	NewPlayer = SpawnPlayerController(StartSpot.Location, SpawnRotation);

	NewPlayer.GotoState('PlayerWaiting');
	return newPlayer;
}

event PostLogin( PlayerController NewPlayer )
{
	GenericPlayerInitialization(NewPlayer);
}

function GenericPlayerInitialization(Controller C)
{
	local PlayerController PC;

	PC = PlayerController(C);
	if (PC != None)
		PC.ClientSetHUD(HudType);
}

defaultproperties
{
	PlayerControllerClass=class'MS_PC'
	HUDType=class'MS_HUD'
}