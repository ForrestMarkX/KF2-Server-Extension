Class Ext_T_AutoFireHelper extends Info
	transient;

var class<KFPerk> AssociatedPerkClass;
var Pawn PawnOwner;
var PlayerController LocalPC;
var bool bNetworkOwner;

replication
{
	if ( bNetOwner )
		PawnOwner,AssociatedPerkClass;
}

function PostBeginPlay()
{
	PawnOwner = Pawn(Owner);
	if( PawnOwner==None )
		Destroy();
	else SetTimer(0.5+FRand()*0.4,true);
}
function Timer()
{
	if( PawnOwner==None || PawnOwner.Health<=0 || PawnOwner.InvManager==None )
		Destroy();
}
simulated function Tick( float Delta )
{
	if( WorldInfo.NetMode==NM_DedicatedServer || PawnOwner==None || PawnOwner.InvManager==None || KFWeapon(PawnOwner.Weapon)==None || KFWeapon(PawnOwner.Weapon).GetWeaponPerkClass(AssociatedPerkClass)!=AssociatedPerkClass )
		return;
	
	// Find local playercontroller.
	if( LocalPC==None )
	{
		LocalPC = PlayerController(PawnOwner.Controller);
		if( LocalPC==None )
			return;
		bNetworkOwner = (LocalPlayer(LocalPC.Player)!=None);
	}
	if( !bNetworkOwner )
		return;

	// Force always to pending fire.
	if( LocalPC.bFire!=0 && !PawnOwner.InvManager.IsPendingFire(None,0) )
		PawnOwner.Weapon.StartFire(0);
	else if( LocalPC.bAltFire!=0 && !PawnOwner.InvManager.IsPendingFire(None,1) )
		PawnOwner.Weapon.StartFire(1);
}

defaultproperties
{
	Components.Empty()
	RemoteRole=ROLE_SimulatedProxy
	bOnlyRelevantToOwner=true
}