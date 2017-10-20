Class Ext_T_MonsterPRI extends PlayerReplicationInfo;

var repnotify class<Pawn> MonsterType;
var repnotify PlayerReplicationInfo OwnerPRI;
var Controller OwnerController;
var string MonsterName;
var int HealthStatus,HealthMax;
var Pawn PawnOwner;
var KFExtendedHUD OwnerHUD;

replication
{
	// Things the server should send to the client.
	if (bNetDirty)
		OwnerPRI,MonsterType,HealthStatus,HealthMax;
}

// Make no efforts with this one.
simulated event PostBeginPlay()
{
	if( WorldInfo.NetMode!=NM_Client )
		SetTimer(1,true);
}
simulated event Destroyed()
{
	if( OwnerHUD!=None )
	{
		OwnerHUD.MyCurrentPet.RemoveItem(Self);
		OwnerHUD = None;
	}
	if ( WorldInfo.GRI != None )
		WorldInfo.GRI.RemovePRI(self);
}
simulated event ReplicatedEvent(name VarName)
{
	if( VarName=='OwnerPRI' && OwnerPRI!=None )
		NotifyOwner();
	else if( VarName=='MonsterType' && MonsterType!=None )
		MonsterName = Class'KFExtendedHUD'.Static.GetNameOf(MonsterType);
}
simulated function Timer()
{
	if( PawnOwner==None || PawnOwner.Health<=0 )
		Destroy();
	else if( HealthStatus!=PawnOwner.Health )
		HealthStatus = PawnOwner.Health;
}
simulated final function NotifyOwner()
{
	local PlayerController PC;
	
	PC = GetALocalPlayerController();
	if( PC==None || PC.PlayerReplicationInfo!=OwnerPRI || KFExtendedHUD(PC.MyHUD)==None )
		return;
	OwnerHUD = KFExtendedHUD(PC.MyHUD);
	OwnerHUD.MyCurrentPet.AddItem(Self);
}

defaultproperties
{
	bBot=true
	MonsterName="Petty"
}