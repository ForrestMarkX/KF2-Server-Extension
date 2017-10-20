Class Ext_T_GhostHelper extends Ext_TraitDataStore;

var KFPawn_Human LastDied;
var float LastDiedTimer,TeleTime;
var vector ResPoint,TeleStartPoint;
var ExtSpawnPointHelper SpawnPointer;
var bool bTeleporting,bIsDelayed;

function bool CanResPlayer( KFPawn_Human Other, byte Level )
{
	if( bTeleporting )
	{
		if( LastDied!=None )
			LastDied.Health = 9999;
		return true;
	}

	if( LastDied==Other )
	{
		if( Level==1 || LastDiedTimer>WorldInfo.TimeSeconds )
			return false;
	}
	else if( Level==1 && Rand(2)==0 )
		return false;

	LastDied = Other;
	bTeleporting = true;
	if( SpawnPointer==None )
		SpawnPointer = class'ExtSpawnPointHelper'.Static.FindHelper(WorldInfo);
	ResPoint = SpawnPointer.PickBestSpawn().Location;
	LastDied.FindSpot(vect(36,36,86),ResPoint);
	if( VSizeSq(LastDied.Location-ResPoint)<1.f ) // Prevent division by zero errors in future.
		ResPoint.Z+=5;
	Enable('Tick');
	StartResurrect();
	return true;
}

final function StartResurrect()
{
	TeleStartPoint = LastDied.Location;
	LastDied.Health = 9999;
	LastDied.LastStartTime = WorldInfo.TimeSeconds;
	
	if( ExtHumanPawn(LastDied)!=None )
	{
		ExtHumanPawn(LastDied).bCanBecomeRagdoll = false;
		if( !ExtHumanPawn(LastDied).CanBeRedeemed() )
		{
			bIsDelayed = true;
			return;
		}
	}

	LastDied.SetCollision(false);
	LastDied.bIgnoreForces = true;
	LastDied.bAmbientCreature = true;
	LastDied.SetPhysics(PHYS_None);
	LastDied.bCollideWorld = false;
	TeleTime = FClamp(VSize(ResPoint-TeleStartPoint)/900.f,1.f,10.f);
	LastDiedTimer = WorldInfo.TimeSeconds+TeleTime;
}

function Tick( float Delta )
{
	if( !bTeleporting )
	{
		Disable('Tick');
		return;
	}
	if( LastDied==None || LastDied.Health<=0 )
	{
		bTeleporting = false;
		return;
	}
	if( bIsDelayed )
	{
		bIsDelayed = false;
		StartResurrect();
		return;
	}
	Delta = (LastDiedTimer-WorldInfo.TimeSeconds);
	if( Delta<=0 )
	{
		EndGhostTeleport();
		return;
	}
	Delta /= TeleTime;
	LastDied.Velocity = Normal(ResPoint-TeleStartPoint)*900.f;
	LastDied.SetLocation(TeleStartPoint*Delta+ResPoint*(1.f-Delta));
	if( LastDied.Physics!=PHYS_None )
		LastDied.SetPhysics(PHYS_None);
}

final function EndGhostTeleport()
{
	LastDiedTimer = WorldInfo.TimeSeconds+180.f;
	bTeleporting = false;
	LastDied.Health = LastDied.HealthMax;
	LastDied.SetCollision(true);
	LastDied.bIgnoreForces = false;
	LastDied.bAmbientCreature = false;
	LastDied.bCollideWorld = true;
	LastDied.FindSpot(vect(36,36,86),ResPoint);
	LastDied.SetLocation(ResPoint);
	LastDied.SetPhysics(PHYS_Falling);
	LastDied.Velocity = vect(0,0,0);
	LastDied.LastStartTime = WorldInfo.TimeSeconds; // For spawn protection, if any.
	if( LastDied.IsDoingSpecialMove() ) // Stop any grabbing zeds.
		LastDied.EndSpecialMove();

	if( ExtHumanPawn(LastDied)!=None )
		ExtHumanPawn(LastDied).bCanBecomeRagdoll = true;
}

function Destroyed()
{
	if( bTeleporting && LastDied!=None && LastDied.Health>0 )
		EndGhostTeleport();
}

defaultproperties
{
}