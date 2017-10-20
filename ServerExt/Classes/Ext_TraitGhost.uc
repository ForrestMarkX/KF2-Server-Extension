Class Ext_TraitGhost extends Ext_TraitBase;

static function bool PreventDeath( KFPawn_Human Player, Controller Instigator, Class<DamageType> DamType, Ext_PerkBase Perk, byte Level, optional Ext_TraitDataStore Data )
{
	local Controller C;

	if( (Instigator==None || Instigator==Player.Controller) && DamType==Class'DmgType_Suicided' )
		return false; // Allow normal suicide to go ahead.

	if( Ext_T_GhostHelper(Data).CanResPlayer(Player,Level) )
	{
		// Abort current special move
		if( Player.IsDoingSpecialMove() )
			Player.SpecialMoveHandler.EndSpecialMove();

		// Notify AI to stop hunting me.
		foreach Player.WorldInfo.AllControllers(class'Controller',C)
			C.NotifyKilled(Instigator,Player.Controller,Player,DamType);
		return true;
	}
	return false;
}

defaultproperties
{
	bHighPriorityDeath=true
	NumLevels=2
	TraitData=class'Ext_T_GhostHelper'
	TraitName="Redemption"
	DefLevelCosts(0)=30
	DefLevelCosts(1)=30
	DefMinLevel=30
	Description="With this trait you will turn into ghost when you die and redeem at another spot in the map.|Level 1: Works 50 % of the time, but never again until you respawned after death.|Level 2: Always works, and it lets you redeem again after 3 minutes"
}