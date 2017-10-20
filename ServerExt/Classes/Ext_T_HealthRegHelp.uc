Class Ext_T_HealthRegHelp extends Info
	transient;

var KFPawn_Human PawnOwner;
var byte RegCount;

function PostBeginPlay()
{
	PawnOwner = KFPawn_Human(Owner);
	if( PawnOwner==None )
		Destroy();
	else SetTimer(9+FRand(),true);
}
function Timer()
{
	if( PawnOwner==None || PawnOwner.Health<=0 )
		Destroy();
	else if( PawnOwner.Health<PawnOwner.HealthMax )
	{
		PawnOwner.Health = Min(PawnOwner.Health+RegCount,PawnOwner.HealthMax);
	}
}

defaultproperties
{
}