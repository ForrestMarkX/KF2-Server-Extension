Class Ext_T_ArmorRegHelp extends Ext_T_HealthRegHelp
	transient;

function Timer()
{
	if( PawnOwner==None || PawnOwner.Health<=0 )
		Destroy();
	else if( PawnOwner.Armor<PawnOwner.MaxArmor )
	{
		PawnOwner.Armor = Min(PawnOwner.Armor+RegCount,PawnOwner.MaxArmor);
	}
}

defaultproperties
{
}