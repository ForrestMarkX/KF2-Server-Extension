Class Ext_T_UnCloakHelper extends Info
	transient;

var Pawn PawnOwner;
var float HandleRadius;

function PostBeginPlay()
{
	PawnOwner = Pawn(Owner);
	if( PawnOwner==None )
		Destroy();
	else SetTimer(0.5+FRand()*0.1,true);
}
function Timer()
{
	local KFPawn_Monster M;

	if( PawnOwner==None || PawnOwner.Health<=0 )
		Destroy();
	else
	{
		foreach WorldInfo.AllPawns(class'KFPawn_Monster',M,PawnOwner.Location,HandleRadius)
			if( M.bCanCloak )
				M.CallOutCloaking();
	}
}

defaultproperties
{
}